#!/usr/bin/env sh
# One-shot bootstrap: creates the doco-cd stack from this repository and exits. Afterwards Doco-CD
# manages (and updates) its own stack like any other. Run as root on the NAS, once, from a checkout:
#
#   SECRET_PROVIDER_CONNECT_HOST=<connect url> sh docker/system/doco-cd/bootstrap.sh
#
# The image is read from compose.yaml next to this script, so there is nothing to keep in step.
set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS=/mnt/apps/appdata/doco-cd/secrets
IMAGE="$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' "$DIR/compose.yaml" | head -n1)"
REPO_URL="https://github.com/fma965/f9-homelab.git"

: "${SECRET_PROVIDER_CONNECT_HOST:?set SECRET_PROVIDER_CONNECT_HOST}"
for f in git_access_token webhook_secret connect_token; do
  [ -s "$SECRETS/$f" ] || { echo "missing or empty: $SECRETS/$f" >&2; exit 1; }
done
[ -z "$(docker ps -q --filter publish=6584)" ] || { echo "port 6584 is in use: stop the TrueNAS doco-cd app first" >&2; exit 1; }

# The bootstrap deploys every stack in .doco-cd.yaml (adopting the running projects by name), so it
# needs the same secret provider and token files as the long-running instance.
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/apps/appdata/doco-cd:/data \
  -v "$SECRETS/git_access_token":/run/secrets/git_access_token:ro \
  -v "$SECRETS/webhook_secret":/run/secrets/webhook_secret:ro \
  -v "$SECRETS/connect_token":/run/secrets/connect_token:ro \
  -e TZ=Europe/London \
  -e SELF_UPDATE_ENABLED=true \
  -e SELF_UPDATE_STRATEGY=applier \
  -e GIT_ACCESS_TOKEN_FILE=/run/secrets/git_access_token \
  -e WEBHOOK_SECRET_FILE=/run/secrets/webhook_secret \
  -e SECRET_PROVIDER=1password \
  -e SECRET_PROVIDER_CONNECT_HOST="$SECRET_PROVIDER_CONNECT_HOST" \
  -e SECRET_PROVIDER_CONNECT_TOKEN_FILE=/run/secrets/connect_token \
  -e POLL_CONFIG="- url: $REPO_URL
  reference: main
  interval: 180" \
  "$IMAGE" apply-self --bootstrap
