# Docker host (TrueNAS)

**Host:** `nas.main.internal`. Stacks live in `docker/<group>/<stack>/compose.yaml` and are deployed by **Doco-CD**.

## How Doco-CD works

- Reads `.doco-cd.yaml`, a list of stacks (name plus `working_dir`).
- Polls Git about every 3 minutes, runs `docker compose up` for changed stacks, and retries failures.
- **Pulls images before deploying.** A locally built image must use `build:` and must not share an `image:` name with a registry image, or the pull step fails.
- Secrets are declared per stack as `external_secrets:` (`op://vault/item/field`) and are resolved from 1Password Connect, then interpolated by Compose, e.g. `${CUPS_ADMIN_PASSWORD}`.

## Stacks

| Group         | Stack                                                      | Purpose                                                                   |
| ------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------- |
| ai            | `llamacpp`                                                 | LLM server, port 8080, shared by Home Assistant, Open WebUI and Paperless |
| ai            | `whisper`, `immich-machine-learning`, `stable-diffusion`   | Speech-to-text, Immich ML, image generation                               |
| management    | `webtop`                                                   | Browser desktop                                                           |
| media         | `tdarr`, `isponsorblocktv`                                 | Transcoding, TV ad skipping                                               |
| observability | `node-exporter`, `smartctl-exporter`, `liquidctl-exporter` | Host metrics                                                              |
| security      | `frigate`                                                  | Camera NVR                                                                |
| system        | `cups`                                                     | Print server (Ricoh SP 211)                                               |
| system        | `scanner`                                                  | Brother DS-740D Scan button, feeds Paperless                              |
| system        | `pbs`                                                      | Proxmox Backup Server                                                     |
| backup        | `garage`                                                   | S3-compatible backup target                                               |

Some stacks listed in `.doco-cd.yaml` are commented out (e.g. stable-diffusion). Check the file for the current state.

## Operating it

```sh
ssh scott@nas.main.internal
sudo -n docker ps
sudo -n docker logs --since 15m doco-cd     # deployment log
sudo -n docker logs -f <container>
```

Root SSH is disabled, and `sudo` is passwordless for `scott`.

## llama.cpp notes

`docker/ai/llamacpp/compose.yaml` serves one model with `--alias gemma-4-12b-ha`, `--parallel 1` and `--ctx-size 32768`. Because there is only one slot, a long request from one client (for example Paperless) can briefly delay another (for example the voice assistant). The API key lives in 1Password (`llamacpp`, field `API_KEY`).
