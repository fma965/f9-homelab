# Printer & scanner

Both devices are USB-attached to the TrueNAS host and run as Doco-CD stacks.

## Printer: Ricoh SP 211 (`docker/system/cups`)

- CUPS runs from `ydkn/cups`, with a build that adds Ricoh's `rastertolilo` filter and the `RICOH-SP-211.ppd` file.
- The SP 211 is a **GDI** printer. Generic and PostScript drivers print nothing. Only the Ricoh filter works. Both files come from [athuld/ricoh-sp210-drivers](https://github.com/athuld/ricoh-sp210-drivers), pinned by commit and sha256 in the Dockerfile.
- The only queue is `RICOH_SP_211_GDI`. Clients print to `ipp://nas.main.internal:631/printers/RICOH_SP_211_GDI`.
- The admin user is `admin`. Its password comes from 1Password (`op://kubernetes/cups/ADMIN_PASSWORD`).
- The USB device is `/dev/ricoh_printer`, and the container runs privileged.

Managing queues:

```sh
sudo -n docker exec -u admin cups lpstat -p -v
sudo -n docker exec -u admin cups lpadmin -x <queue>
```

## Scanner: Brother DS-740D (`docker/system/scanner`)

- Debian slim image (the Brother `brscan5` driver and `brscan-skey` need glibc) with `sane-utils` and ImageMagick.
- `brscan-skey` waits for the scanner's **Scan** button. All four button actions run `button-scan.sh`.
- The script finds the device with `scanimage -L` (the bus number the button reports differs from the one SANE needs), then scans duplex from the feeder at 300 dpi with auto size, deskew and blank-page skipping.
- Pages are combined into a JPEG-compressed PDF and written to `/mnt/F9/Documents/incoming` as a hidden temp file first, then renamed, so Paperless never sees a half-written file.
- Paperless polls that folder every 10 seconds (`PAPERLESS_CONSUMER_POLLING`).

There is no web UI by choice: it couldn't crop or auto-size feeder scans.

## Troubleshooting

| Symptom                                   | Check                                                                                         |
| ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| Nothing prints                            | `lpstat -p`. Is the printer powered and the queue enabled? The device may need power-cycling. |
| Scan button does nothing                  | `sudo -n docker logs scanbutton`. Confirm `lsusb` shows the scanner.                          |
| Scan lands but isn't consumed             | Is the file in `incoming`? Check the Paperless logs.                                          |
| Stack redeploys fail with a name conflict | Remove the old container, then let Doco-CD retry.                                             |
