#!/bin/bash
set -euo pipefail

# Defaults
DRY_RUN=false            # Dry-run mode (off by default)
AUTO_APPROVE=false       # Auto-approve apply (dangerous, off by default)

color_echo() {
  local color="$1"
  local text="$2"
  echo -e "\e[${color}m${text}\e[0m"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -y|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
    esac
done

# Dry-run: Simulate actions
if [ "$DRY_RUN" = true ]; then
    color_echo "34" "🌵 DRY RUN MODE: Simulating workflow"
    color_echo "34" "-> Would run: tofu init -input=false"
    color_echo "34" "-> Would run: tofu plan -input=false"
    if [ "$AUTO_APPROVE" = true ]; then
        color_echo "34" "-> Would run: tofu apply -input=false  -auto-approve"
    else
        color_echo "34" "-> Would run: tofu apply -input=false"
    fi
    exit 0
fi

# Execute workflow
cd "$(dirname "${BASH_SOURCE[0]}")"/tofu

color_echo "34"  "Initializing OpenTofu..."
tofu init -input=false

color_echo "34"  "Generating plan..."
tofu plan -input=false

# Apply with confirmation (unless --auto-approve)
if [ "$AUTO_APPROVE" = false ]; then
    read -p $'\e[35m❓ Apply changes? (y/n):  \e[0m' -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        color_echo "34"  "⚠️ Apply cancelled."
        exit 0
    fi
fi

color_echo "34" "Applying changes..."
if [ "$AUTO_APPROVE" = true ]; then
    color_echo "34"  "⚠️ Auto-approve mode enabled. Proceeding without confirmation."
    tofu apply -input=false -auto-approve
else
    color_echo "34"  "⚠️ Manual approval required. Proceeding with confirmation."
    tofu apply -input=false
fi

export KUBECONFIG="$PWD/output/kube-config.yaml"