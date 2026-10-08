FROM sbs20/scanservjs:v3.3.0@sha256:7a0c0dfd546f483c2fe8c5ccdcd8fc96301a41fb0d4309747fc8268108defb6a

# Brother SANE backend (brscan5), not shipped in the upstream image.
ADD --checksum=sha256:9c3a200db3dc7b2b3332dff8c5226b4f3ee560d20b2e1f4918b1faf7124517b2 \
    https://download.brother.com/welcome/dlf104033/brscan5-1.7.0-0.amd64.deb /tmp/brscan5.deb

RUN dpkg -i /tmp/brscan5.deb && rm /tmp/brscan5.deb
