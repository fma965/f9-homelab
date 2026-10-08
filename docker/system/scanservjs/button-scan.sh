#!/bin/bash
# Run by brscan-skey when the scanner's Scan button is pressed.
# $1 is the SANE device name (e.g. brother5:bus3;dev1).
set -uo pipefail

OUT=/output
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Ignore button presses while a scan is already running
exec 9>/tmp/button-scan.lock
flock -n 9 || exit 0

cd "$WORK" || exit 1

# scanimage exits non-zero once the feeder runs out of paper, which is expected
scanimage -d "$1" \
  --source "Automatic Document Feeder(left aligned,Duplex)" \
  --resolution 300 \
  --mode "24bit Color[Fast]" \
  --AutoDocumentSize=yes \
  --AutoDeskew=yes \
  --SkipBlankPage=yes \
  --format=tiff \
  --batch="page-%04d.tif"

# Drop empty or truncated pages from failed scans
find . -name 'page-*.tif' -size -1k -delete

if ! ls page-*.tif >/dev/null 2>&1; then
  echo "No pages scanned"
  exit 0
fi

convert page-*.tif -quality 85 scan.pdf

# Write under a temporary name first so Paperless never picks up a partial file
name="scan-$(date +%Y-%m-%d-%H%M%S).pdf"
mv scan.pdf "$OUT/.$name"
mv "$OUT/.$name" "$OUT/$name"
echo "$OUT/$name is created."
