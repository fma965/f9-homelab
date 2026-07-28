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