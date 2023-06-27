FROM ghcr.io/aclemons/slackware:15.0@sha256:bfead2e71b801bdf9f97e3430d5f754d43a324709385e5d35acb0f2a10564c23 as build-sbo-maintainer-tools-386
COPY build_sbo-maintainer-tools.sh /
RUN linux32 bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0@sha256:bfead2e71b801bdf9f97e3430d5f754d43a324709385e5d35acb0f2a10564c23 as build-sbo-maintainer-tools-amd64
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0@sha256:bfead2e71b801bdf9f97e3430d5f754d43a324709385e5d35acb0f2a10564c23 as build-sbo-maintainer-tools-arm
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:current@sha256:22834314c2c708fb5fdb1d7078b9dc5ab671e2d269ca910e997ee994dda5c181 as build-sbo-maintainer-tools-arm64
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0@sha256:bfead2e71b801bdf9f97e3430d5f754d43a324709385e5d35acb0f2a10564c23 as sbo-maintainer-tools-386
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-386 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:15.0@sha256:bfead2e71b801bdf9f97e3430d5f754d43a324709385e5d35acb0f2a10564c23 as sbo-maintainer-tools-amd64
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-amd64 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:15.0@sha256:bfead2e71b801bdf9f97e3430d5f754d43a324709385e5d35acb0f2a10564c23 as sbo-maintainer-tools-arm
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-arm /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:current@sha256:22834314c2c708fb5fdb1d7078b9dc5ab671e2d269ca910e997ee994dda5c181 as sbo-maintainer-tools-arm64
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-arm64 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

ARG TARGETARCH
# hadolint ignore=DL3006
FROM sbo-maintainer-tools-$TARGETARCH
WORKDIR /mnt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG TARGETARCH
RUN slackpkg -default_answer=yes -batch=on update && \
    archwrapper="" && \
    if [ "$TARGETARCH" = "386" ] ; then archwrapper="linux32" ; fi && \
    $archwrapper slackpkg -default_answer=yes -batch=on install \
    brotli \
    cyrus-sasl \
    desktop-file-utils \
    fftw \
    fontconfig \
    freetype \
    git \
    glibc \
    gnutls \
    graphite2 \
    harfbuzz \
    imagemagick \
    lcms2 \
    libICE \
    libSM \
    libX11 \
    libXau \
    libXdmcp \
    libXext \
    libXt \
    libwebp \
    libxcb \
    libxml2 \
    libzip \
    mozilla-nss \
    nettle \
    nghttp2 \
    openjpeg \
    p11-kit \
    parallel \
    perl \
    popper-data \
    poppler \
    sudo \
    && rm -rf /var/cache/packages/* && find /var/lib/slackpkg/ -mindepth 1 \! -name current -print0 | xargs -0 rm -rf
