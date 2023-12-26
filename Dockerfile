FROM aclemons/slackware:15.0@sha256:4d68c16b1467254856db03c8e12db09c3c853f9d6f98283d6f6cbe6144eb8125 as build-sbo-maintainer-tools
COPY build_sbo-maintainer-tools.sh /
ARG TARGETARCH
RUN archwrapper="" && \
    if [ "$TARGETARCH" = "386" ] ; then archwrapper="linux32" ; fi && \
    $archwrapper ./build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM aclemons/slackware:15.0@sha256:4d68c16b1467254856db03c8e12db09c3c853f9d6f98283d6f6cbe6144eb8125 as sbo-maintainer-tools
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
    cairo \
    cyrus-sasl \
    desktop-file-utils \
    fftw \
    fontconfig \
    freetype \
    fribidi \
    gdk-pixbuf2 \
    git \
    glib2 \
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
    libXrender \
    libXt \
    libglvnd \
    librsvg \
    libsrvg \
    libwebp \
    libxcb \
    libxml2 \
    libzip \
    mozilla-nss \
    nettle \
    nghttp2 \
    openjpeg \
    p11-kit \
    pango \
    parallel \
    perl \
    pixman \
    popper-data \
    poppler \
    sudo \
    texinfo\
    && rm -rf /var/cache/packages/* && find /var/lib/slackpkg/ -mindepth 1 \! -name current -print0 | xargs -0 rm -rf
