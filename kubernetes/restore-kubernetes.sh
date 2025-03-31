#!/bin/bash
set -euo pipefail

# Defaults
AUTO_APPROVE=false       # Auto-approve apply (dangerous, off by default)

color_echo() {
  local color="$1"
  local text="$2"
  echo -e "\e[${color}m${text}\e[0m"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
    esac
done

# Execute workflow
# Apply with confirmation (unless --auto-approve)
if [ "$AUTO_APPROVE" = false ]; then
    read -p $'\e[35m Apply Kubernetes FluxCD Configuration? (y/n):  \e[0m' -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        color_echo "34" "Apply cancelled."
        exit 0
    fi
fi

color_echo "34" "Creating flux-system namespace ..."
NAMESPACE="flux-system"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

color_echo "34" "Creating sops-age secret in flux-system namespace from $SOPS_AGE_KEY_FILE ..."
kubectl create secret generic sops-age -n flux-system --from-file=age.agekey=$SOPS_AGE_KEY_FILE -o yaml --dry-run=client | kubectl apply -f -

color_echo "34" "Bootstrapping FluxCD ..."
flux bootstrap github \
    --token-auth \
    --owner=fma965 \
    --repository=f9-homelab \
    --branch=main \
    --path=./kubernetes/clusters/home \
    --personal \
    --private=false \

color_echo "34" "Suspending FluxCD Infra-Databses and Apps to allow restoring of longhorn volumes ..."
flux suspend kustomization infra-databases
flux suspend kustomization apps

color_echo "34" "Waiting for Traefik Crowdsec Bouncer Middleware to be created so it can be temporarily disabled..."
until kubectl patch middleware bouncer -n traefik \
  --type='merge' \
  -p '{"spec": {"plugin": {"crowdsec-bouncer-traefik-plugin": {"enabled": false}}}}'; do sleep 3; done
# Run the patch command in a loop in the background
(
  while true; do
    kubectl patch middleware bouncer -n traefik \
      --type='merge' \
      -p '{"spec": {"plugin": {"crowdsec-bouncer-traefik-plugin": {"enabled": false}}}}' > /dev/null
    sleep 1
  done
) &

BOUNCER_PID=$!

color_echo "34" "Waiting for Cert-Manager certificate to be issued..."
kubectl wait --for=condition=Ready certificate/f9-casa -n default --timeout=10m

color_echo "34" "Waiting for Longhorn endpoint to become available ..."
until kubectl -n longhorn-system get endpoints longhorn-frontend \
      -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .
do
  color_echo "34" "Waiting for Longhorn endpoint to become available ..."
  sleep 5
done

kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80 > /dev/null &
PF_PID=$!
color_echo "34" "Port-forward running in background (PID: $PF_PID)"
color_echo "34" "Access Longhorn at: http://localhost:8080"
color_echo "34" "In the UI, Click on "Backups", Select all volumes, "Restore from last backup"."

REPLY=""
while ! [[ $REPLY =~ ^[Yy]$ ]]; do
    read -p $'\e[35m Have you restored your Longhorn volume? (y/n):  \e[0m' -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      color_echo "34" "Once the volumes have finished being restored or you are skipping restoring, type 'Y' to proceed."
    fi
done

color_echo "34" "Resuming FluxCD Infra-Databses and Apps now that longhorn volumes have been restored ..."
kill $PF_PID
flux resume kustomization infra-databases
flux resume kustomization apps

color_echo "34" "Reneabled the Traefik Crowdsec Bouncer Middlware ..."
kill $BOUNCER_PID
kubectl patch middleware bouncer -n traefik \
  --type='merge' \
  -p '{"spec": {"plugin": {"crowdsec-bouncer-traefik-plugin": {"enabled": true}}}}'

color_echo "34" "✅ FluxCD should now be completing the deployment and soon your Kubenetes configuration should be restored!"