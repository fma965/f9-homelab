## Frigate

NVR / object detection, previously run in the cluster (`kubernetes/apps/default/frigate`, removed in c42e9d3d) and now run here instead, so it doesn't depend on the cluster being up and can use the CCTV dataset directly instead of over NFS.

### Before the first deploy

1. Create the appdata directory on the NAS (Doco-CD creates it as `root`, which is fine - Frigate's container runs as root):

    ```bash
    sudo mkdir -p /mnt/apps-pool/appdata/frigate/config
    ```

2. Camera credentials come from 1Password Connect (`external_secrets` in `.doco-cd.yaml`, pulling from the existing `go2rtc` item in the `kubernetes` vault), not a hand-placed `.env` - `.env.example` documents the variable names for local/manual testing only, and `env_file: .env` in `compose.yaml` is `required: false` so its absence never blocks a deploy. For this to actually resolve, the `doco-cd` app itself needs:

    ```
    SECRET_PROVIDER=1password
    SECRET_PROVIDER_CONNECT_HOST=http://10.10.69.206
    SECRET_PROVIDER_CONNECT_TOKEN=<OP_CONNECT_TOKEN field of the "1password" item, kubernetes vault>
    ```

    `10.10.69.206` is `onepassword-connect`'s Cilium-advertised LoadBalancer IP (`kubernetes/apps/external-secrets/onepassword-connect`), reachable from the NAS the same way `mosquitto`/`go2rtc` are.

3. Once cameras are live, set motion masks and zones per camera from the Frigate UI (Settings → Masks / Zones) - these are FOV-specific and can't be guessed ahead of time; the old masks/zones from the previous house don't carry over.

### Storage

- `/config` (db, logs) - `/mnt/apps-pool/appdata/frigate/config` on the apps NVMe pool.
- `/media/frigate` (recordings, snapshots, exports) - `/mnt/Data/CCTV`, the CCTV dataset (1 TiB refquota, on the `Data` pool). Same dataset an NFS share already exists for, but Frigate here bind-mounts it directly since it's running on the NAS itself.
- `/tmp/cache` - 1 GB tmpfs, per Frigate's own recommendation for recording segment staging.

Retention is set to 30 days for motion-triggered recording (`record.motion.days`), 14 days for alerts/detections (`record.alerts.retain.days` / `record.detections.retain.days`), keep an eye on `Data/CCTV` usage against the 1 TiB quota and tighten those in `config/config.yml` if it fills up faster than expected.

### Hardware acceleration

- **Decode**: VAAPI via the Ryzen 5500GT's integrated Radeon graphics (`/dev/dri`, `LIBVA_DRIVER_NAME=radeonsi`). Deliberately not using the RTX 3060 for this - it's already shared by tdarr (NVENC), llamacpp and immich-machine-learning with little VRAM to spare, and the iGPU is otherwise idle.
- **Detection**: CPU, via Frigate's bundled OpenVINO model (`ssdlite_mobilenet_v2`). The Vega iGPU isn't a supported OpenVINO/ROCm detector target, and CPU detection was already proven sufficient for this in the old cluster config.

### Doorbell (Aqara G410)

- RTSP only works when the G410 is hardwired (12-24V AC/DC) - it's disabled on battery power. Confirm it's powered that way before expecting the stream to come up.
- No sub stream is exposed for this device (unlike the Reolink NVR channels), so `doorbell` necessarily uses its single main stream for both `detect` and `record` - that's not a config gap, there's nothing else to point at.
- Some G410 units report intermittent RTSP timeouts/drops (Aqara forum reports on this exact model). Frigate auto-restarts a dead ffmpeg process, so brief drops should self-heal; if it's constant, it's worth checking the doorbell's own firmware version.

### MQTT / Home Assistant

Points at the cluster's Mosquitto (`10.10.69.203:1883`, anonymous auth) so the Home Assistant Frigate integration keeps working the same way it did when Frigate ran in-cluster. If Mosquitto isn't reachable from the NAS's network segment, set `mqtt.enabled: false` in `config/config.yml` instead.

### Ports

Only `8971` (authenticated UI/API) plus `8554`/`8555` (go2rtc RTSP/WebRTC restream) are published. Port `5000` is Frigate's internal unauthenticated API and is deliberately not exposed.
