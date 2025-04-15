#!/bin/bash
set -eo pipefail

# SSH Connection Multiplexing
SSH_CONTROL_PATH=~/.ssh/control-%r-%h-%p
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$SSH_CONTROL_PATH -o ControlPersist=10m"

color_echo() {
  echo -e "\e[${1}m${2}\e[0m"
}

# Validate arguments
if [ "$#" -ne 1 ]; then
  color_echo "34" "Usage: $0 username@hostname\nExample: $0 root@unraid"
  exit 1
fi

CONNECTION="$1"
[[ "$CONNECTION" != *"@"* ]] && { color_echo "31" "ERROR: Use user@host format"; exit 1; }

# Path configuration
SOURCE_FOLDER="$(dirname "${BASH_SOURCE[0]}")/komodo"
DEST_FOLDER="/boot/config/plugins/compose.manager/projects"
export SOPS_AGE_KEY_FILE="${PWD}/.sops/age/private.key"

# Master SSH connection setup
setup_connection() {
  if ! ssh -q -o BatchMode=yes $SSH_OPTS "$CONNECTION" exit; then
    color_echo "33" "🔑 Key auth failed - please enter SSH password once:"
    # Establish master connection with single password prompt
    if ! ssh $SSH_OPTS "$CONNECTION" true; then
      color_echo "31" "Authentication failed"
      exit 1
    fi
  fi
}

# Main workflow
color_echo "34" "=== Komodo Deployment ==="

# 1. Decrypt secrets
color_echo "34" "Decrypting secrets..."
sops --decrypt docker/komodo/secret.sops.env > docker/komodo/.env || {
  color_echo "31" "Decryption failed"; exit 1
}

# 2. Setup connection (password prompt happens here if needed)
setup_connection

# 3. Copy files using existing connection
color_echo "34" "Copying files to server..."
scp $SSH_OPTS -r "$SOURCE_FOLDER" "$CONNECTION:$DEST_FOLDER" || {
  color_echo "31" "Copy failed"; exit 1
}

# 4. Run docker-compose
color_echo "34" "Starting containers..."
ssh $SSH_OPTS "$CONNECTION" \
  "cd $DEST_FOLDER/komodo && docker-compose up -d" || {
    color_echo "31" "docker-compose failed"; exit 1
  }

# Cleanup
color_echo "34" "Removing temporary files..."
rm -f docker/komodo/.env
ssh -O exit "$CONNECTION" &>/dev/null || true

color_echo "32" "✅ Deployment complete! Komodo is now running."