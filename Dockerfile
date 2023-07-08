FROM aclemons/slackware:15.0@sha256:5a594b9b9d6c28754edfe71de7b59689cb8cc40e39e527399b1cab82e5cd6a91 as build-sbo-maintainer-tools
COPY build_sbo-maintainer-tools.sh /
ARG TARGETARCH
RUN archwrapper="" && \
    if [ "$TARGETARCH" = "386" ] ; then archwrapper="linux32" ; fi && \
    $archwrapper bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM aclemons/slackware:15.0@sha256:5a594b9b9d6c28754edfe71de7b59689cb8cc40e39e527399b1cab82e5cd6a91 as sbo-maintainer-tools
COPY --from=build-sbo-maintainer-tools /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM sbo-maintainer-tools
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
