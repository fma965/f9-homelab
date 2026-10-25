FROM ydkn/cups@sha256:7e44118d11dafca1a4556f40e8fe5f19a09df6e40a7a58ddb1b69a8c09b8759b

# Ricoh SP 211 is a GDI printer: it ignores PCL/PostScript and needs Ricoh's own
# CUPS raster filter. Ricoh doesn't publish a Linux driver for the SP 200 series,
# so this comes from a community repo (extracted from Ricoh's driver), pinned to a
# commit and checksum. Nothing in CUPS ships a driver for it.
ARG RICOH_REPO=https://raw.githubusercontent.com/athuld/ricoh-sp210-drivers/a4d22343814e03b12787e1c9c19f3d87a1dfb4a7

ADD --checksum=sha256:f25e5ba5bf2d30e4d7c705a91e9f5d38aeae27b8d98d6cdd3c036bd38cbfaefb --chmod=755 \
    ${RICOH_REPO}/tmp/x86_64/rastertolilo /usr/lib/cups/filter/rastertolilo

ADD --checksum=sha256:2f47fa579921f240cd487b9d3fc9dfab1de15181df239b72fc7a09718fe206ed --chmod=644 \
    ${RICOH_REPO}/ppd/RICOH-SP-211.ppd /usr/share/cups/model/ricoh/RICOH-SP-211.ppd
