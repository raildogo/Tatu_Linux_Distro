set -e

echo "Entrando Chroot: ${LFS:?}"

bash -e $DIST_ROOT/build/build_scripts/mount-virt.sh

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

    bash -e $DIST_ROOT/build/build_scripts/umount-virt.sh