wget https://invisible-mirror.net/archives/lynx/tarballs/lynx2.9.2.tar.bz2

tar -xvf lynx2.9.2.tar.bz2

cd lynx2.9.2

./configure --prefix=/usr           \
            --sysconfdir=/etc/lynx  \
            --with-zlib             \
            --with-bzlib            \
            --with-ssl              \
            --with-screen=ncursesw  \
            --enable-locale-charset \
            --datadir=/usr/share/doc/lynx-2.9.2 &&
make

su

make install-full
chgrp -v -R root /usr/share/doc/lynx-2.9.2/lynx_doc

sed -e '/#LOCALE/     a LOCALE_CHARSET:TRUE'     \
    -i /etc/lynx/lynx.cfg

sed -e '/#DEFAULT_ED/ a DEFAULT_EDITOR:vi'       \
    -i /etc/lynx/lynx.cfg

sed -e '/#PERSIST/    a PERSISTENT_COOKIES:TRUE' \
    -i /etc/lynx/lynx.cfg