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
    color_echo "46" "DRY RUN MODE: Simulating workflow"
    color_echo "46" "-> Would run: tofu init -input=false"
    color_echo "46" "-> Would run: tofu plan -input=false"
    if [ "$AUTO_APPROVE" = true ]; then
        color_echo "46" "-> Would run: tofu apply -input=false  -auto-approve"
    else
        color_echo "46" "-> Would run: tofu apply -input=false"
    fi
    exit 0
fi

# Execute workflow
if [ ! -f "infrastructure/tofu/prod.auto.tfvars.json" ]; then
    sops --decrypt --config .sops.yaml infrastructure/tofu/prod.sops.auto.tfvars.json > "infrastructure/tofu/prod.auto.tfvars.json"
fi
cd "$(dirname "${BASH_SOURCE[0]}")"/tofu

color_echo "46"  "Initializing OpenTofu..."
tofu init -input=false

color_echo "46"  "Generating plan..."
tofu plan -var-file="prod.auto.tfvars.json" -input=false


if [ "$AUTO_APPROVE" = true ]; then
    color_echo "46"  "Auto-approve mode enabled. Proceeding without confirmation."
    tofu apply -var-file="prod.auto.tfvars.json" -input=false -auto-approve
else
    color_echo "46"  "Manual approval required. Proceeding with confirmation."
    tofu apply -var-file="prod.auto.tfvars.json" -input=false
fi
color_echo "46" "Applying changes..."
export KUBECONFIG="$PWD/output/kube-config.yaml"
echo export KUBECONFIG="$PWD/output/kube-config.yaml"
color_echo "42" "✅ Talos Linux should now be up and running, if it's not it should be after a few minutes!"