FROM ghcr.io/aclemons/slackware:15.0@sha256:af1b10b5259ca43a5f84d9a0245a79b75fde7667cce29a7ebdaf63aa0467ebc1 as build-sbo-maintainer-tools-386
COPY build_sbo-maintainer-tools.sh /
RUN linux32 bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0@sha256:af1b10b5259ca43a5f84d9a0245a79b75fde7667cce29a7ebdaf63aa0467ebc1 as build-sbo-maintainer-tools-amd64
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0@sha256:af1b10b5259ca43a5f84d9a0245a79b75fde7667cce29a7ebdaf63aa0467ebc1 as build-sbo-maintainer-tools-arm
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:current@sha256:b34d82258d494ffbb6bd9446fd11afdb4faa8a71d8b2b5fe530b446561313d9c as build-sbo-maintainer-tools-arm64
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0@sha256:af1b10b5259ca43a5f84d9a0245a79b75fde7667cce29a7ebdaf63aa0467ebc1 as sbo-maintainer-tools-386
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-386 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:15.0@sha256:af1b10b5259ca43a5f84d9a0245a79b75fde7667cce29a7ebdaf63aa0467ebc1 as sbo-maintainer-tools-amd64
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-amd64 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:15.0@sha256:af1b10b5259ca43a5f84d9a0245a79b75fde7667cce29a7ebdaf63aa0467ebc1 as sbo-maintainer-tools-arm
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-arm /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:current@sha256:b34d82258d494ffbb6bd9446fd11afdb4faa8a71d8b2b5fe530b446561313d9c as sbo-maintainer-tools-arm64
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
