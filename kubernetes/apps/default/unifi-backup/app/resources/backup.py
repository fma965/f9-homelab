"""Copy the newest UniFi auto-backup (.unf) from the gateway to /backup, keep the newest KEEP files."""
import hashlib
import http.client
import http.cookiejar
import json
import os
import ssl
import sys
import urllib.request

HOST = os.environ["UNIFI_HOST"]
KEEP = int(os.environ.get("KEEP", "30"))
OUT = "/backup"

PIN = os.environ["UNIFI_CERT_SHA256"].replace(":", "").lower()


class PinnedConnection(http.client.HTTPSConnection):
    """The gateway's certificate is self-signed, so trust it only if it matches the pinned SHA-256."""

    def connect(self):
        super().connect()
        der = self.sock.getpeercert(binary_form=True)
        if hashlib.sha256(der).hexdigest() != PIN:
            self.close()
            raise ssl.SSLError("gateway certificate does not match UNIFI_CERT_SHA256")


class PinnedHandler(urllib.request.HTTPSHandler):
    def https_open(self, req):
        return self.do_open(PinnedConnection, req, context=ctx)


ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE  # replaced by the fingerprint pin in PinnedConnection
opener = urllib.request.build_opener(
    urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),
    PinnedHandler(),
)


def call(path, body=None, csrf=""):
    headers = {"Content-Type": "application/json", "X-CSRF-Token": csrf}
    data = json.dumps(body).encode() if body is not None else None
    return opener.open(urllib.request.Request(f"https://{HOST}{path}", data=data, headers=headers), timeout=60)


login = call("/api/auth/login", {"username": os.environ["UNIFI_USERNAME"], "password": os.environ["UNIFI_PASSWORD"]})
csrf = login.headers.get("X-CSRF-Token") or login.headers.get("x-updated-csrf-token") or ""

backups = json.load(call("/proxy/network/api/s/default/cmd/backup", {"cmd": "list-backups"}, csrf))["data"]
if not backups:
    sys.exit("no backups listed by the controller")
newest = max(backups, key=lambda b: b.get("time", 0))
name = os.path.basename(newest["filename"])
dest = os.path.join(OUT, name)

if os.path.exists(dest):
    print(f"already have {name}")
else:
    data = call(f"/proxy/network/dl/autobackup/{name}", None, csrf).read()
    # A .unf is a binary archive; an HTML or JSON error page means the download failed.
    if len(data) < 1024 or data[:1] in (b"<", b"{"):
        sys.exit(f"unexpected download for {name}: {len(data)} bytes")
    tmp = dest + ".part"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, dest)
    print(f"saved {name} ({len(data)} bytes)")

files = sorted(f for f in os.listdir(OUT) if f.endswith(".unf"))
for old in files[:-KEEP]:
    os.remove(os.path.join(OUT, old))
    print(f"pruned {old}")
