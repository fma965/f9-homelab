# The scanservjs web UI is not used (its entrypoint is overridden in compose); this
# image is only the base because it already ships scanimage (SANE) and ImageMagick.
FROM sbs20/scanservjs:v3.3.0@sha256:7a0c0dfd546f483c2fe8c5ccdcd8fc96301a41fb0d4309747fc8268108defb6a

# Brother SANE backend (brscan5), not shipped in the upstream image.
ADD --checksum=sha256:9c3a200db3dc7b2b3332dff8c5226b4f3ee560d20b2e1f4918b1faf7124517b2 \
    https://download.brother.com/welcome/dlf104033/brscan5-1.7.0-0.amd64.deb /tmp/brscan5.deb

RUN dpkg -i /tmp/brscan5.deb && rm /tmp/brscan5.deb

# Brother scan-key tool: watches the scanner's physical Scan button over USB.
# bsdtar is only needed to unpack the .rpm (Brother ships no .deb for this).
ADD --checksum=sha256:01dc859f1978e645147ced5ec4b5448cc3e26b1c6d2f1104834f5891c0e17469 \
    https://download.brother.com/welcome/dlf006650/brscan-skey-0.3.5-0.x86_64.rpm /tmp/brscan-skey.rpm

RUN apt-get update \
    && apt-get install -y --no-install-recommends libusb-0.1-4 libarchive-tools \
    && bsdtar -xf /tmp/brscan-skey.rpm -C / \
    && apt-get purge -y libarchive-tools \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/brscan-skey.rpm

# Every scan-key function (file, image, OCR, email) runs our own script
COPY button-scan.sh /opt/brother/scanner/brscan-skey/script/scantofile.sh
RUN cd /opt/brother/scanner/brscan-skey/script \
    && for f in scantoimage.sh scantoocr.sh scantoemail.sh; do ln -sf scantofile.sh "$f"; done
