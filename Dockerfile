FROM aclemons/slackware:15.0@sha256:cc2f89d292e843fdf7a23ab12620f64e82dc983769a86e4c558dff0f0d38b751 as build-sbo-maintainer-tools
COPY build_sbo-maintainer-tools.sh /
ARG TARGETARCH
RUN archwrapper="" && \
    if [ "$TARGETARCH" = "386" ] ; then archwrapper="linux32" ; fi && \
    $archwrapper ./build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM aclemons/slackware:15.0@sha256:cc2f89d292e843fdf7a23ab12620f64e82dc983769a86e4c558dff0f0d38b751
RUN --mount=type=bind,from=build-sbo-maintainer-tools,source=/tmp,target=/pkgs \
    installpkg /pkgs/*.txz

WORKDIR /mnt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG TARGETARCH
RUN slackpkg -default_answer=yes -batch=on update && \
    archwrapper="" && \
    if [ "$TARGETARCH" = "386" ] ; then archwrapper="linux32" ; fi && \
    $archwrapper slackpkg -default_answer=yes -batch=on install \
    brotli \
    binutils \
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
    libfl \
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
    texinfo \
    && rm -rf /var/cache/packages/* && find /var/lib/slackpkg/ -mindepth 1 \! -name current -print0 | xargs -0 rm -rf
