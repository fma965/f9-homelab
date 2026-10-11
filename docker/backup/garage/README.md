## Garage S3 Metadata Recovery Guide

Quick recovery procedure for resolving metadata corruption errors (such as Messagepack decode error or Merkle worker panic) when restoring an LMDB snapshot file.

1. Stop Garage

```bash
docker stop garage
```

2.  Move corrupted live directory aside

```bash
mv db.lmdb db.lmdb.corrupted
```

3.  Create target directory

```bash
mkdir -p db.lmdb
```

4. Copy single snapshot file into place as data.mdb

```bash
cp -a /path/to/snapshot/db.lmdb db.lmdb/data.mdb
```

5. Set Permissions & Ownership

```Bash
chown -R root:root db.lmdb
chmod 755 db.lmdb
chmod 644 db.lmdb/data.mdb
```

6. Start & Verify

```bash
docker start garage
```

7. Check logs

```bash
docker logs garage
```

8. Run table repair

```bash
docker exec -it garage garage repair --yes tables
```

Do not copy data.mdb while Garage is running.

### Access (allow-list gate)

The Garage web UI (`3909`), which has no login of its own, is not published directly. `webui-gate` (nginx, `gate/nginx.conf`) publishes port `3909` and only accepts connections from the three Kubernetes nodes (`10.10.100.1-3`), where Envoy runs and which is the address every cluster pod appears to have. Everything else on the network (Main LAN, Media, ...) gets `403`. Reach it through `https://garage.f9.casa`, which adds Authelia.

This is an allow-list, not a login: anything running in the cluster can still reach the port directly, so the app should not be given more trust than it has. If a new in-cluster client needs it, it works already (it comes from a node address); if a client outside the cluster needs it, add its address to `gate/nginx.conf` deliberately. The published port is IPv4-only on purpose: Docker's IPv6 proxy hides the client address.

The Garage S3 and admin ports (`3900`-`3903`) are unchanged and still published; `3900` is what the cluster's backups use.
