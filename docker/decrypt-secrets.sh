#!/bin/bash

# Check if required env var is set
if [ -z "$PERIPHERY_ROOT_DIRECTORY" ]; then
    echo "Error: PERIPHERY_ROOT_DIRECTORY is not set." >&2
    exit 1
fi

export SOPS_AGE_KEY_FILE="$PERIPHERY_ROOT_DIRECTORY/.sops.key"

sops="$PERIPHERY_ROOT_DIRECTORY/sops"

# Only proceed if secret.sops.env exists
if [ -f "secret.sops.env" ]; then
    # Ensure sops exists and is executable
    if [ -f "$sops" ] && [ ! -x "$sops" ]; then
        chmod +x "$sops"
    fi
    # Decrypt and write to .env
    "$sops" -d secret.sops.env > .env
fi