"""Ask the UniFi gateway for a fresh backup, save it to /backup, keep the newest KEEP files.

Pings Healthchecks.io (start, success, fail) when HEALTHCHECKS_ID is set. Approach adapted from
auricom/home-ops (unifi_backup.py), in stdlib only, with the gateway certificate pinned.
"""
import hashlib
import http.client
import json
import logging
import os
import ssl
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
LOG = logging.getLogger("unifi-backup")

HOST = os.environ["UNIFI_HOST"]
SITE = os.environ.get("UNIFI_SITE", "default")
API_KEY = os.environ["UNIFI_API_KEY"]
PIN = os.environ["UNIFI_CERT_SHA256"].replace(":", "").lower()
KEEP = int(os.environ.get("KEEP", "30"))
OUT = Path(os.environ.get("OUTDIR", "/backup"))
HC_ID = os.environ.get("HEALTHCHECKS_ID", "").strip("/")


class PinnedConnection(http.client.HTTPSConnection):
    """The gateway's certificate is self-signed, so trust it only if it matches the pinned SHA-256."""

    def connect(self):
        super().connect()
        if hashlib.sha256(self.sock.getpeercert(binary_form=True)).hexdigest() != PIN:
            self.close()
            raise ssl.SSLError("gateway certificate does not match UNIFI_CERT_SHA256")


class PinnedHandler(urllib.request.HTTPSHandler):
    def https_open(self, req):
        return self.do_open(PinnedConnection, req, context=CTX)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


# Name and chain checks are replaced by the fingerprint pin in PinnedConnection.
CTX = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE
opener = urllib.request.build_opener(PinnedHandler(), NoRedirect())


def ping(status=""):
    if not HC_ID:
        return
    try:
        urllib.request.urlopen(f"https://hc-ping.com/{HC_ID}{'/' + status if status else ''}", timeout=10).close()
    except OSError as error:
        LOG.warning("Healthchecks ping failed: %s", error)


def unifi(path, body=None):
    request = urllib.request.Request(
        f"https://{HOST}{path}",
        data=json.dumps(body).encode() if body is not None else None,
        headers={"X-API-Key": API_KEY, "Content-Type": "application/json"},
    )
    return opener.open(request, timeout=120)


def backup():
    reply = json.load(unifi(f"/proxy/network/api/s/{SITE}/cmd/backup", {"cmd": "backup", "days": 0}))
    if reply.get("meta", {}).get("rc") != "ok" or not reply.get("data"):
        raise RuntimeError(f"backup request failed: {reply.get('meta', {})}")
    path = urlparse(reply["data"][0]["url"]).path
    if not path.startswith("/proxy/network"):
        path = "/proxy/network" + path
    name = os.path.basename(path)
    if not name.endswith(".unf"):
        raise RuntimeError(f"unexpected backup file name: {name}")

    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / f"{datetime.now():%Y%m%d_%H%M%S}_{name}"
    part = dest.with_suffix(dest.suffix + ".part")
    try:
        response = unifi(path)
        if "text/html" in response.headers.get("Content-Type", "").lower():
            raise RuntimeError("gateway returned HTML instead of a backup")
        with part.open("wb") as f:
            while chunk := response.read(65536):
                f.write(chunk)
        if part.stat().st_size == 0:
            raise RuntimeError("gateway returned an empty backup")
        part.replace(dest)
    finally:
        part.unlink(missing_ok=True)
    LOG.info("saved %s (%d bytes)", dest.name, dest.stat().st_size)

    files = sorted(OUT.glob("*.unf"), key=lambda p: p.stat().st_mtime, reverse=True)
    for old in files[KEEP:]:
        old.unlink()
        LOG.info("pruned %s", old.name)


ping("start")
try:
    backup()
except Exception:
    LOG.exception("UniFi backup failed")
    ping("fail")
    sys.exit(1)
ping()
