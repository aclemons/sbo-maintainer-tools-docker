# syntax=docker/dockerfile:1.3-labs

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

# hadolint ignore=DL3003
RUN <<EOF
cd /usr/share/sbo-maintainer-tools/sbopkglint.d/ && cat << PATCH | patch -p2
diff --git a/sbopkglint.d/20-arch.t.sh b/sbopkglint.d/20-arch.t.sh
index 376074d..d43d1df 100644
--- a/sbopkglint.d/20-arch.t.sh
+++ b/sbopkglint.d/20-arch.t.sh
@@ -11,10 +11,14 @@
 # ARCH, and that libs are in the correct directory (lib vs. lib64).
 
 # warnings:
+# if an arm* package has any 64-bit ELF objects (libs or bins)
 # if an i?86 package has any 64-bit ELF objects (libs or bins)
+# if an aarch package has any 32-bit ELF objects (libs or bins)
 # if an x86_64 package has any 32-bit ELF objects (libs or bins)
+# if an arm* package has lib64 or usr/lib64 at all
 # if an i?86 package has lib64 or usr/lib64 at all
 # if an x86_64 package has 64-bit libs in lib or usr/lib
+# if an aarch64 package has 64-bit libs in lib or usr/lib
 
 # note: sometimes files in /lib/firmware are ELF, and would cause
 # false "wrong directory" warnings, so we exclude that dir from the
@@ -23,8 +27,10 @@
 case "$ARCH" in
 	noarch) ;; # ok, do nothing.
 	i?86) WRONGDIR="lib64"; CPU="80386" ;;
+	arm*) WRONGDIR="lib64"; CPU="ARM" ;;
 	x86_64) WRONGDIR="lib"; CPU="x86-64" ;;
-	*) warn "ARCH isn't noarch, i?86, or x86_64. don't know how to check binaries." ;;
+	aarch64) WRONGDIR="lib"; CPU="aarch64" ;;
+	*) warn "ARCH isn't noarch, arm*, i?86, aarch64, or x86_64. don't know how to check binaries." ;;
 esac
 
 INWRONGDIR=""
PATCH
EOF
