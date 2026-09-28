## Tdarr

Re-encodes high-bitrate TV files to reclaim space on the F9 pool, using the RTX 3060 (NVENC).

### Before the first deploy

Doco-CD creates missing bind-mount directories as `root`, which Tdarr (running as `1000:3000`) cannot write to. Create them first, on the TrueNAS host:

```bash
sudo mkdir -p /mnt/apps-pool/appdata/tdarr/{server,configs,logs,temp} /mnt/F9/Media/.tdarr-output
sudo chown -R 1000:3000 /mnt/apps-pool/appdata/tdarr /mnt/F9/Media/.tdarr-output
```

### Safe rollout

1. `/media` is mounted **read-only**. Tdarr can read the library but cannot replace or delete anything.
2. In the Tdarr UI (`http://nas.main.internal:8265`), add a library on `/media/TV Shows/<show>` and set its output folder to `/output`.
3. Limit GPU workers to 1-2 on the node. The RTX 3060 is shared with llamacpp and immich-machine-learning and has little VRAM free.
4. Filter by bitrate (start above 12 Mbps), transcode a handful of episodes, and check playback on your devices.
5. Only then mount `/media` read-write and switch to in-place replacement, or move the verified files over by hand.

Tdarr has no authentication by default. The UI is reachable by anything that can reach the NAS on port 8265.
