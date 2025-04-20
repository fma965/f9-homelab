#!/bin/bash
set -euo pipefail

# Defaults
AUTO_APPROVE=false       # Auto-approve apply (dangerous, off by default)
RESTORE=false

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
        -r|--restore)
            RESTORE=true
            shift
            ;;
    esac
done

# Execute workflow
if [ -z "$GITHUB_OWNER" ] || [ -z "$GITHUB_REPO" ]; then
    echo "Error: Owner and repository must be set!"
    exit 1
fi

if [ "$RESTORE" = true ]; then
  color_echo "46" "Restore mode enabled, will suspend after core apps are applied"
fi

# Apply with confirmation (unless --auto-approve)
if [ "$AUTO_APPROVE" = false ]; then
    read -p $'\e[45m Apply Kubernetes FluxCD Configuration? (y/n):  \e[0m' -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        color_echo "41" "Apply cancelled."
        exit 0
    fi
fi

color_echo "46" "Creating flux-system namespace ..."
NAMESPACE="flux-system"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

color_echo "46" "Creating sops-age secret in flux-system namespace from $SOPS_AGE_KEY_FILE ..."
kubectl create secret generic sops-age -n flux-system --from-file=age.agekey=$SOPS_AGE_KEY_FILE -o yaml --dry-run=client | kubectl apply -f -

color_echo "46" "Bootstrapping FluxCD ..."
flux bootstrap github \
    --token-auth \
    --owner="${GITHUB_OWNER}" \
    --repository="${GITHUB_REPO}" \
    --branch=main \
    --path=./kubernetes/flux/cluster \
    --personal \
    --private=false \

if [ "$RESTORE" = true ]; then
  color_echo "46" "Suspending FluxCD Databases and Apps to allow restoring of longhorn volumes ..."
  flux suspend kustomization databases
  flux suspend kustomization apps
fi
  # color_echo "46" "Waiting for Traefik Crowdsec Bouncer Middleware to be created so it can be temporarily disabled..."
  # until kubectl patch middleware bouncer -n traefik \
  #   --type='merge' \
  #   -p '{"spec": {"plugin": {"crowdsec-bouncer-traefik-plugin": {"enabled": false}}}}'; do sleep 3; done
  # # Run the patch command in a loop in the background
  # (
  #   while true; do
  #     kubectl patch middleware bouncer -n traefik \
  #       --type='merge' \
  #       -p '{"spec": {"plugin": {"crowdsec-bouncer-traefik-plugin": {"enabled": false}}}}' > /dev/null
  #     sleep 1
  #   done
  # ) &

  # BOUNCER_PID=$!


until kubectl -n traefik get certificate letsencrypt \
        -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"
do
    color_echo "46" "Waiting for Cert-Manager certificate to be issued..."
    sleep 15
    kubectl get events -n traefik --sort-by='.metadata.creationTimestamp' | tail -n 5
    kubectl logs -n cert-manager -l app.kubernetes.io/component=controller | grep -i acme | tail -n 1

done
color_echo "42" "Certificate is now ready!"

if [ "$RESTORE" = true ]; then
  until kubectl -n longhorn-system get endpoints longhorn-frontend \
        -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .
  do
    color_echo "46" "Waiting for Longhorn endpoint to become available ..."
    sleep 5
  done

  kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80 > /dev/null &
  PF_PID=$!
  color_echo "46" "Port-forward running in background (PID: $PF_PID)"
  color_echo "46" "Access Longhorn at: http://localhost:8080"
  color_echo "46" "In the UI, Click on 'Backups', Select all volumes, 'Restore Latest Backup' and click 'OK'."

  REPLY=""
  while ! [[ $REPLY =~ ^[Yy]$ ]]; do
      read -p $'\e[45mHave you restored your Longhorn volumes? (y/n):  \e[0m' -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        color_echo "46" "Once the volumes have finished being restored or you are skipping restoring, type 'Y' to proceed."
      fi
  done

  color_echo "46" "Resuming FluxCD Databases and Apps now that longhorn volumes have been restored ..."
  kill $PF_PID
  flux resume kustomization databases
  flux resume kustomization apps
fi

# color_echo "46" "Reneabled the Traefik Crowdsec Bouncer Middlware ..."
# kill $BOUNCER_PID
# kubectl patch middleware bouncer -n traefik \
#   --type='merge' \
#   -p '{"spec": {"plugin": {"crowdsec-bouncer-traefik-plugin": {"enabled": true}}}}'

color_echo "42" "✅ FluxCD should now be completing the deployment and soon your Kubenetes configuration should be restored!"