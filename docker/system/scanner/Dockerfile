# Brother's drivers and scan-key tool are glibc binaries, so this can't be Alpine (musl).
FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

ENV DEBIAN_FRONTEND=noninteractive

# scanimage (SANE), ImageMagick for the PDF, libusb-0.1 for the scan-key tool.
# bsdtar is only needed to unpack the scan-key .rpm (Brother ships no .deb for it).
RUN apt-get update \
    && apt-get install -y --no-install-recommends sane-utils imagemagick libusb-0.1-4 libarchive-tools \
    && rm -rf /var/lib/apt/lists/* \
    # Debian's ImageMagick policy blocks writing PDFs
    && sed -i 's|rights="none" pattern="PDF"|rights="read\|write" pattern="PDF"|' /etc/ImageMagick-*/policy.xml

# Brother SANE backend (brscan5)
ADD --checksum=sha256:9c3a200db3dc7b2b3332dff8c5226b4f3ee560d20b2e1f4918b1faf7124517b2 \
    https://download.brother.com/welcome/dlf104033/brscan5-1.7.0-0.amd64.deb /tmp/brscan5.deb

# Only load the Brother backend: SANE otherwise probes dozens of others, including network ones
RUN dpkg -i /tmp/brscan5.deb && rm /tmp/brscan5.deb \
    && echo brother5 > /etc/sane.d/dll.conf \
    && rm -f /etc/sane.d/dll.d/*

# Brother scan-key tool: watches the scanner's physical Scan button over USB
ADD --checksum=sha256:01dc859f1978e645147ced5ec4b5448cc3e26b1c6d2f1104834f5891c0e17469 \
    https://download.brother.com/welcome/dlf006650/brscan-skey-0.3.5-0.x86_64.rpm /tmp/brscan-skey.rpm

RUN bsdtar -xf /tmp/brscan-skey.rpm -C / \
    && rm /tmp/brscan-skey.rpm \
    && apt-get purge -y libarchive-tools \
    && apt-get autoremove -y

# Every scan-key function (file, image, OCR, email) runs our own script
COPY button-scan.sh /opt/brother/scanner/brscan-skey/script/scantofile.sh
RUN cd /opt/brother/scanner/brscan-skey/script \
    && for f in scantoimage.sh scantoocr.sh scantoemail.sh; do ln -sf scantofile.sh "$f"; done
