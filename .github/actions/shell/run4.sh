#!/bin/bash
set -x
set -eu
set -o pipefail

docker build --file Dockerfile.builder -t tmp .
docker run --rm -i tmp tar zpc --exclude=/etc/hostname --exclude=/etc/resolv.conf --exclude=/etc/hosts --one-file-system / >rootfs.tar.gz

# docker import - tmp02 <rootfs.tar.gz
# docker build --force-rm --no-cache --rm=true -t base - <<-'END'
# FROM tmp02
# ENTRYPOINT [ "/usr/bin/tini", "--", "/entrypoint.sh" ]
# CMD [ "bash" ]
# END

find
pwd
ls
