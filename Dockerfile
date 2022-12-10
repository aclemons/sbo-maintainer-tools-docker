FROM ghcr.io/aclemons/slackware:15.0 as build-sbo-maintainer-tools-386
COPY build_sbo-maintainer-tools.sh /
RUN linux32 bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0 as build-sbo-maintainer-tools-amd64
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0 as build-sbo-maintainer-tools-arm
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:current as build-sbo-maintainer-tools-arm64
RUN touch /var/lib/slackpkg/current
COPY build_sbo-maintainer-tools.sh /
RUN bash /build_sbo-maintainer-tools.sh && rm /build_sbo-maintainer-tools.sh

FROM ghcr.io/aclemons/slackware:15.0 as sbo-maintainer-tools-386
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-386 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:15.0 as sbo-maintainer-tools-amd64
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-amd64 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:15.0 as sbo-maintainer-tools-arm
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-arm /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

FROM ghcr.io/aclemons/slackware:current as sbo-maintainer-tools-arm64
# hadolint ignore=DL3006
COPY --from=build-sbo-maintainer-tools-arm64 /tmp/* /tmp
RUN installpkg /tmp/*.txz && rm -rf /tmp/*.txz

ARG TARGETARCH=
# hadolint ignore=DL3006
FROM sbo-maintainer-tools-$TARGETARCH
WORKDIR /mnt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN slackpkg -default_answer=yes -batch=on update && \
    slackpkg -default_answer=yes -batch=on install \
    brotli \
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
    libxcb \
    libxml2 \
    libzip \
    nettle \
    p11-kit \
    parallel \
    perl \
    sudo \
    && rm -rf /var/cache/packages/* && find /var/lib/slackpkg/ -mindepth 1 \! -name current -print0 | xargs -0 rm -rf
