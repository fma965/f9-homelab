## Frigate

NVR / object detection, previously run in the cluster (`kubernetes/apps/default/frigate`, removed in c42e9d3d) and now run here instead, so it doesn't depend on the cluster being up and can use the CCTV dataset directly instead of over NFS.

### Before the first deploy

1. Create the appdata directory on the NAS (Doco-CD creates it as `root`, which is fine - Frigate's container runs as root):

    ```bash
    sudo mkdir -p /mnt/apps/appdata/frigate/config
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

- `/config` (db, logs) - `/mnt/apps/appdata/frigate/config` on the apps NVMe pool.
- `/media/frigate` (recordings, snapshots, exports) - `/mnt/Archive/CCTV`, the CCTV dataset (2 TiB refquota, on the `Archive` pool, a single 8 TB disk with no redundancy). Frigate bind-mounts it directly since it runs on the NAS itself; there is no NFS export.
- `/tmp/cache` - 1 GB tmpfs, per Frigate's own recommendation for recording segment staging.

Retention is set to 30 days for motion-triggered recording (`record.motion.days`), 14 days for alerts/detections (`record.alerts.retain.days` / `record.detections.retain.days`), keep an eye on `Archive/CCTV` usage against the 2 TiB quota and tighten those in `config/config.yml` if it fills up faster than expected.

### Hardware acceleration

- **Decode**: VAAPI via the Ryzen 5500GT's integrated Radeon graphics (`/dev/dri`, `LIBVA_DRIVER_NAME=radeonsi`). Deliberately not using the RTX 3060 for this - it's already shared by tdarr (NVENC), llamacpp and immich-machine-learning with little VRAM to spare, and the iGPU is otherwise idle.
- **Detection**: the same Radeon iGPU, via the ONNX detector on a community fork of Frigate's ROCm image (`ghcr.io/garymathews/frigate`, ROCm 7.2.4, digest-pinned in `compose.yaml`) running YOLOv9-s at 320x320 (`model_type: yolo-generic`). The container needs `/dev/kfd` as well as `/dev/dri`, and `HSA_OVERRIDE_GFX_VERSION=9.0.0` because the Vega 7 (gfx90c) is not an officially supported ROCm target (the image maps it to the same value itself). Detection ran on the CPU through OpenVINO before (about 20 ms per frame; YOLOv9-t was about 8.5 ms but left overlapping boxes on parked cars). The RTX 3060 is left alone for the same reason as decode above. The bundled `ssdlite_mobilenet_v2` was replaced because it flickered between car, no car and two cars on the night footage.

    **Why the fork, not upstream's `-rocm` image:** the Vega 7 (gfx90c, run as gfx900 through `HSA_OVERRIDE_GFX_VERSION=9.0.0`) has no rocBLAS kernels in upstream's ROCm 7.x image, so the detector aborts while MIGraphX compiles the model (`rocBLAS error: Cannot read .../TensileLibrary.dat: Illegal seek for GPU arch : gfx900`) and Frigate's watchdog restarts the container about once a minute (`Detection appears to have stopped. Exiting Frigate...`). The fork builds MIGraphX with gfx900 as a target and copies the gfx900 rocBLAS kernels from ROCm 6.3.4 into the image. It is a one-maintainer community build: check its release notes and Dockerfile before moving the digest, and Renovate will not know about newer tags. The first start compiles the model into `/config/model_cache/migraphx` and can take a while. If the log shows the same rocBLAS error or the restart loop returns, roll back: set `image:` in `compose.yaml` to the upstream non-rocm `0.18.2` tag, drop the `/dev/kfd` device, `HSA_OVERRIDE_GFX_VERSION` and `HSA_ENABLE_SDMA`, and restore the OpenVINO `detectors:` block (`type: openvino`, `device: CPU`) in `config/config.yml`.

    The model file is not in git. The existing `yolov9-s-320.onnx` is reused as is; ONNX Runtime runs the same file on the GPU, so nothing needs rebuilding. Build it once and put it on the NAS **before** the commit that references it deploys, or Frigate will not start. Build `yolov9-s-320.onnx` with the YOLOv9 export `docker build` command in Frigate's object detector docs (<https://docs.frigate.video/configuration/object_detectors/>, YOLOv9 section) using `MODEL_SIZE=s` and `IMG_SIZE=320`, then copy it over:

    ```bash
    sudo mkdir -p /mnt/apps/appdata/frigate/config/model_cache
    sudo cp yolov9-s-320.onnx /mnt/apps/appdata/frigate/config/model_cache/
    ```

    To roll back, point `model.path` at `yolov9-t-320.onnx` if you kept it, or restore the original `model:` block (the `ssdlite_mobilenet_v2` one bundled in the image: `width: 300`, `height: 300`, `input_tensor: nhwc`, `input_pixel_format: bgr`, `path: /openvino-model/ssdlite_mobilenet_v2.xml`, `labelmap_path: /openvino-model/coco_91cl_bkgr.txt`).

### Doorbell (Aqara G410)

- RTSP only works when the G410 is hardwired (12-24V AC/DC) - it's disabled on battery power. Confirm it's powered that way before expecting the stream to come up.
- No sub stream is exposed for this device (unlike the Reolink NVR channels), so `doorbell` necessarily uses its single main stream for both `detect` and `record` - that's not a config gap, there's nothing else to point at.
- Some G410 units report intermittent RTSP timeouts/drops (Aqara forum reports on this exact model). Frigate auto-restarts a dead ffmpeg process, so brief drops should self-heal; if it's constant, it's worth checking the doorbell's own firmware version.

### MQTT / Home Assistant

Points at the cluster's Mosquitto (`10.10.69.203:1883`, anonymous auth) so the Home Assistant Frigate integration keeps working the same way it did when Frigate ran in-cluster. If Mosquitto isn't reachable from the NAS's network segment, set `mqtt.enabled: false` in `config/config.yml` instead.

### Ports

Frigate has its own address on the NAS Docker network, so nothing is "published" any more: the firewall decides what reaches it. The ports in use are `8971` (authenticated UI/API) and `8554`/`8555` (go2rtc RTSP/WebRTC restream). Port `5000` is Frigate's internal unauthenticated API and must stay closed to everything except the container itself. Traffic between containers on the same network is not filtered by the firewall, so another container on that network can still reach it.
