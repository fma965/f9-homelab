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
2. In the Tdarr UI (`https://tdarr.f9.casa`, behind Authelia), add a library on `/media/TV Shows/<show>` and set its output folder to `/output`.
3. Limit GPU workers to 1-2 on the node. The RTX 3060 is shared with llamacpp and immich-machine-learning and has little VRAM free.
4. Filter by bitrate (start above 12 Mbps), transcode a handful of episodes, and check playback on your devices.
5. Only then mount `/media` read-write and switch to in-place replacement, or move the verified files over by hand.

Tdarr has no authentication of its own. Port `8266` (the server port nodes connect to) is not published: the only node is the internal one, which does not need it.

### Access (allow-list gate)

The Tdarr web UI (`8265`) is not published directly. `tdarr-gate` (nginx, `gate/nginx.conf`) publishes port `8265` and only accepts connections from the three Kubernetes nodes (`10.10.100.1-3`), where Envoy runs and which is the address every cluster pod appears to have. Everything else on the network (Main LAN, Media, ...) gets `403`. Reach it through `https://tdarr.f9.casa`, which adds Authelia.

This is an allow-list, not a login: anything running in the cluster can still reach the port directly, so the app should not be given more trust than it has. If a new in-cluster client needs it, it works already (it comes from a node address); if a client outside the cluster needs it, add its address to `gate/nginx.conf` deliberately. The published port is IPv4-only on purpose: Docker's IPv6 proxy hides the client address.
