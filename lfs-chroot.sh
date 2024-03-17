#!/bin/bash
# LFS 12.1 Build Script
# Builds the additional temporary tools from chapter 7
# by Raildo Oliveira :)
# 15/Mar/2024

package_name=""
package_ext=""

begin() {
	package_name=$1
	package_ext=$2

	echo "[lfs-chroot] Iniciando a construção de $package_name em $(date)"

	tar xf $package_name.$package_ext
	cd $package_name
}
sleep 2
finish() {
	echo "[lfs-chroot] Finalizando a construção de $package_name em $(date)"

	cd /sources
	rm -rf $package_name
}
sleep 2
cd /sources

# 7.7. Gettext-0.22.4
begin gettext-0.22.4 tar.xz
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
finish

# 7.8. Bison-3.8.2
begin bison-3.8.2 tar.xz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make
make install
finish

# 7.9. Perl-5.38.2
begin perl-5.38.2 tar.xz
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Duseshrplib                                \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl     \
             -Darchlib=/usr/lib/perl5/5.38/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl
make
make install
finish

# 7.10. Python-3.12.2
begin Python-3.12.2 tar.xz
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install
finish

# 7.11. Texinfo-7.1
begin texinfo-7.1 tar.xz
./configure --prefix=/usr
make
make install
finish

# 7.12. Util-linux-2.39.3
begin util-linux-2.39.3 tar.xz
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib    \
            --runstatedir=/run   \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.39.3
make
make install
finish
