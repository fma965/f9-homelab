# doco-cd

Doco-CD runs as a Compose stack of its own and deploys itself: bumping the pinned image in
[compose.yaml](./compose.yaml) (Renovate opens the PR) makes it replace itself. It used to be a TrueNAS custom app
whose definition lived only in TrueNAS.

## How it works

- `SELF_UPDATE_ENABLED=true`. A merged image bump is deployed like any other change; doco-cd starts the new version, keeps it only
  once it reports healthy, and otherwise restores the previous container.
- `SELF_UPDATE_STRATEGY=applier`: the published ports (6584 webhook/health, 9130 metrics) rule out `scale_out`, so an
  update is a short restart (it does not interrupt the other stacks).
- Image pinned by tag and digest; digest bumps are not auto-merged, so each update is a reviewed commit.
- Data (`/data`) is the same bind as before, `/mnt/apps/appdata/doco-cd`, so the repository cache carries over.

## Secrets

Files on the NAS, never in git, mounted as Compose secrets:

| File (`/mnt/apps/appdata/doco-cd/secrets/`) | Used for |
|---|---|
| `git_access_token` | `GIT_ACCESS_TOKEN_FILE` |
| `webhook_secret` | `WEBHOOK_SECRET_FILE` |
| `connect_token` | `SECRET_PROVIDER_CONNECT_TOKEN_FILE` (1Password Connect) |

The Connect URL is not a secret: it is set in this stack's entry in [.doco-cd.yaml](../../../.doco-cd.yaml).

## One-time cutover from the TrueNAS app

Run as root on the NAS. The other stacks keep running throughout; only deploy automation pauses.

1. **Copy the secrets out of the running app** (prints nothing; `81553019a7c2` is the app's container, check with `docker ps`):
   ```sh
   C=81553019a7c2; S=/mnt/apps/appdata/doco-cd/secrets; install -d -m 700 "$S"
   for pair in GIT_ACCESS_TOKEN:git_access_token WEBHOOK_SECRET:webhook_secret SECRET_PROVIDER_CONNECT_TOKEN:connect_token; do
     docker inspect "$C" --format '{{range .Config.Env}}{{println .}}{{end}}' \
       | sed -n "s/^${pair%%:*}=//p" | head -n1 | tr -d '\n' > "$S/${pair##*:}"
   done
   chmod 600 "$S"/*; wc -c "$S"/*   # all three should be non-empty
   ```
2. **Stop the TrueNAS `doco-cd` app** (Apps -> doco-cd -> Stop). Do not delete it yet. If it keeps running when this PR merges
   it will try to deploy the new `doco-cd` entry itself and fail on the ports.
3. **Merge the PR.**
4. **Bootstrap**, from a checkout of this repo on the NAS:
   ```sh
   SECRET_PROVIDER_CONNECT_HOST=<same value as the app used> sh docker/system/doco-cd/bootstrap.sh
   ```
5. **Check**: `docker compose ls` shows project `doco-cd` running; `https://doco-cd.f9.casa/v1/health` is OK;
   `docker logs doco-cd-doco-cd-1` shows polling `github.com/fma965/f9-homelab` with no errors; metrics on `:9130`.
   Stacks that were already running are adopted by name and should not be recreated.
6. After a few days, delete the stopped TrueNAS app and remove the old `latest` image.

**Rollback:** `docker compose -p doco-cd down`, then start the TrueNAS app again. Its definition is untouched until you delete it.

## Updating

Merge the Renovate PR that bumps the image in `compose.yaml`. The next poll deploys it. Keep a TrueNAS-shell session handy
the first time: a failed update restores the old container, but check `docker logs` for the reason.
