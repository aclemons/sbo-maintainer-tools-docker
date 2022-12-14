#!/bin/bash

# Copyright 2022 Andrew Clemons, Tokyo Japan
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e
set -o pipefail

# terse package install for installpkg
export TERSE=0

slackpkg -default_answer=yes -batch=on update

EXIT_CODE=0
slackpkg -default_answer=yes -batch=on install dcron desktop-file-utils perl ca-certificates make guile gc || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 20 ] ; then
  exit $EXIT_CODE
fi

c_rehash

rm -rf /var/cache/packages/* && rm -rf /var/lib/slackpkg/* && \

wget -O - https://github.com/SlackBuildsOrg/slackbuilds/tarball/master | tar xz

export TAG=_aclemons
(
  cd SlackBuildsOrg-slackbuilds-*

  cd system/sbo-maintainer-tools
  # shellcheck disable=SC1091
  . sbo-maintainer-tools.info

  # shellcheck disable=SC2086
  wget $DOWNLOAD
  printf "%s\t%s\n" "$MD5SUM" "$(ls ./*tar*)" | md5sum --check --quiet
  PKGTYPE=txz sh sbo-maintainer-tools.SlackBuild
)

rm -rf SlackBuildsOrg-slackbuilds-*
rm -rf /tmp/SBo
