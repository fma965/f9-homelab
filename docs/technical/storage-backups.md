# Storage & backups

## Storage

| Type           | Backing                                                                 | Used for                                         |
| -------------- | ----------------------------------------------------------------------- | ------------------------------------------------ |
| `ceph-block`   | Rook Ceph (on the cluster nodes)                                        | App config and databases (the default PVC class) |
| Local hostpath | OpenEBS                                                                 | Node-local volumes                               |
| NFS            | TrueNAS shares (`/mnt/F9/...`) via csi-driver-nfs or direct NFS volumes | Bulk data: media, photos, documents              |
| Postgres       | CloudNativePG (`postgres-rw.database.svc`)                              | App databases                                    |

## Backups (kopiur)

Most config PVCs use the `kopiur/backup` component. It creates:

- a `SnapshotPolicy` and schedule that snapshots the PVC with Kopia (zstd compression), and
- a `Restore` object, used as the PVC's `dataSourceRef`.

Because of the populator, **deleting an app's PVC and letting Flux recreate it restores the latest snapshot** (`onMissingSnapshot: Continue` starts empty when there is none). Browse snapshots through Kopia S3 / the Kopia UI.

Apps without the component (for example Jellyfin's config) have no automated backup and must be restored manually.

## Other backups

- Proxmox Backup Server (`docker/system/pbs`) on the Docker host.
- Garage (`docker/backup/garage`) is an S3-compatible target.
- Postgres databases run on CloudNativePG; check its `Cluster` resource for the backup configuration.

## Documents

Paperless keeps its database (SQLite), search index and stored documents (`/data/local/data` and `/data/local/media`) on its Ceph PVC, which kopiur backs up (15Gi). The incoming and export folders are on NFS (`/mnt/F9/Documents`). The scanner and phone uploads land in `/mnt/F9/Documents/incoming`.
