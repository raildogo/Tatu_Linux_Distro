#!/bin/bash
# LFS 12.1 Build Script
# Builds the basic system software from chapter 8
# by Raildo Oliveira :)
# 15/Mar/2024

package_name=""
package_ext=""

begin() {
	package_name=$1
	package_ext=$2

	echo "[lfs-system] Iniciando a construção de $package_name em $(date)"
sleep 2

	tar xf $package_name.$package_ext
	cd $package_name
}

finish() {
	echo "[lfs-system] Finalizando a construção de $package_name em $(date)"
sleep 2

	cd /sources
	rm -rf $package_name
}
cd /sources

# 8.3. Man-pages-6.06
begin man-pages-6.06 tar.xz
rm -v man3/crypt*
make prefix=/usr install
finish

# 8.4. Iana-Etc-20240125
begin iana-etc-20240125 tar.gz
cp services protocols /etc
finish

# 8.5. Glibc-2.39
begin glibc-2.39 tar.xz
patch -Np1 -i ../glibc-2.39-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.19                     \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib
make
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
make localedata/install-locales

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2024a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
ln -sfv /usr/share/zoneinfo/America/Fortaleza /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -pv /etc/ld.so.conf.d
finish

# 8.6. Zlib-1.3.1
begin zlib-1.3.1 tar.xz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libz.a
finish

# 8.7. Bzip2-1.0.8
begin bzip2-1.0.8 tar.gz
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
finish

# 8.8. Xz-5.4.6
begin xz-5.4.6 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.4.6
make
make install
finish

# 8.9. Zstd-1.5.5
begin zstd-1.5.5 tar.gz
make prefix=/usr
make prefix=/usr install
rm -v /usr/lib/libzstd.a
finish

# 8.10. File-5.45
begin file-5.45 tar.gz
./configure --prefix=/usr
make
make install
finish

# 8.11. Readline-8.2
begin readline-8.2 tar.gz
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
patch -Np1 -i ../readline-8.2-upstream_fixes-3.patch
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2
finish

# 8.12. M4-1.4.19
begin m4-1.4.19 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.13. Bc-6.7.5
begin bc-6.7.5 tar.xz
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
make install
finish

# 8.14. Flex-2.6.4
begin flex-2.6.4 tar.gz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make
make install
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
finish

# 8.15. Tcl-8.6.13
mv tcl8.6.13-src.tar.gz tcl8.6.13.tar.gz
begin tcl8.6.13 tar.gz
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd ..
tar -xf ../tcl8.6.13-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.13
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.13
finish

# 8.16. Expect-5.45.4
begin expect5.45.4 tar.gz
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
finish

# 8.17. DejaGNU-1.6.3
begin dejagnu-1.6.3 tar.gz
mkdir -v build
cd       build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
finish

# 8.18. Pkg-config-2.1.1
begin pkg-config-0.29.2 tar.gz
./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.1.1
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
finish

# 8.19. Binutils-2.42
begin binutils-2.42 tar.xz
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib  \
             --enable-default-hash-style=gnu
make tooldir=/usr
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
finish

# 8.20. GMP-6.3.0
begin gmp-6.3.0 tar.xz
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
make
make html
make install
make install-html
finish

# 8.21. MPFR-4.2.1
begin mpfr-4.2.1 tar.xz
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1
make
make html
make install
make install-html
finish

# 8.22. MPC-1.3.1
begin mpc-1.3.1 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
make
make html
make install
make install-html
finish

# 8.23. Attr-2.5.2
begin attr-2.5.2 tar.gz
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2
make
make install
finish

# 8.24. Acl-2.3.2
begin acl-2.3.2 tar.xz
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2
make
make install
finish

# 8.25. Libcap-2.69
begin libcap-2.69 tar.xz
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make prefix=/usr lib=lib install
finish

#8.26. Libxcrypt-4.4.36
begin libxcrypt-4.4.36 tar.xz
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens

make
make install
finish

# 8.27. Shadow-4.14.5
begin shadow-4.14.5 tar.xz
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man
pwconv
grpconv
mkdir -p /etc/default
useradd -D --gid 999
sed -i '/MAIL/s/yes/no/' /etc/default/useradd
passwd root
finish

# 8.28. GCC-13.2.0
begin gcc-13.2.0 tar.xz
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
make
make install
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
finish


# 8.29. Ncurses-6.4-20230520
begin ncurses-6.4-20230520 tar.gz
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.4
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.4-20230520
finish

# 8.30. Sed-4.9
begin sed-4.9 tar.xz
./configure --prefix=/usr
make
make html
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
finish

# 8.31. Psmisc-23.6
begin psmisc-23.6 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.32. Gettext-0.22.4
begin gettext-0.22.4 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22.4
make
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
finish

# 8.33. Bison-3.8.2
begin bison-3.8.2 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make install
finish

# 8.34. Grep-3.11
begin grep-3.11 tar.xz
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
make install
finish

# 8.35. Bash-5.2.21
begin bash-5.2.21 tar.gz
patch -Np1 -i ../bash-5.2.21-upstream_fixes-1.patch
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.2.21
make
make install
finish

# 8.36. Libtool-2.4.7
begin libtool-2.4.7 tar.xz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libltdl.a
finish

# 8.37. GDBM-1.23
begin gdbm-1.23 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make
make install
finish

# 8.38. Gperf-3.1
begin gperf-3.1 tar.gz
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
make install
finish

# 8.39. Expat-2.6.0
begin expat-2.6.0 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.0
make
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.0
finish

# 8.40. Inetutils-2.5
begin inetutils-2.5 tar.xz
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
make install
mv -v /usr/{,s}bin/ifconfig
finish

# 8.41. Less-643
begin less-643 tar.gz
./configure --prefix=/usr --sysconfdir=/etc
make
make install
finish

# 8.42. Perl-5.38.2
begin perl-5.38.2 tar.xz
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
             -Darchlib=/usr/lib/perl5/5.38/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads
make
make install
unset BUILD_ZLIB BUILD_BZIP2
finish

# 8.43. XML::Parser-2.46
begin XML-Parser-2.46 tar.gz
perl Makefile.PL
make
make install
finish

# 8.44. Intltool-0.51.0
begin intltool-0.51.0 tar.gz
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
finish

# 8.45. Autoconf-2.72
begin autoconf-2.72 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.46. Automake-1.16.5
begin automake-1.16.5 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
make
make install
finish

# 8.47. OpenSSL-3.2.1
begin openssl-3.2.1 tar.gz
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.2.1
cp -vfr doc/* /usr/share/doc/openssl-3.2.1
finish

# 8.48. Kmod-31
begin kmod-31 tar.xz
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done

ln -sfv kmod /usr/bin/lsmod
finish

# 8.49. Libelf from Elfutils-0.190
begin elfutils-0.190 tar.bz2
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
make
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
finish

# 8.50. Libffi-3.4.4
begin libffi-3.4.4 tar.gz
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native
make
make install
finish

# 8.51. Python-3.12.2
begin Python-3.12.2 tar.xz
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations
make
make install
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
install -v -dm755 /usr/share/doc/python-3.12.2/html

tar --no-same-owner \
    -xvf ../python-3.12.2-docs-html.tar.bz2
cp -R --no-preserve=mode python-3.12.2-docs-html/* \
    /usr/share/doc/python-3.12.2/html
finish

# 8.52. Flit-Core-3.9.0
begin flit_core-3.9.0 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --no-user --find-links dist flit_core
finish

# 8.53. Wheel-0.42.0
begin wheel-0.42.0 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links=dist wheel
finish

# 8.54. Setuptools-69.1.0
begin Setuptools-69.1.0 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools
finish

# 8.55. Ninja-1.11.1
begin ninja-1.11.1 tar.gz
export NINJAJOBS=4
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
finish

# 8.56. Meson-1.3.2
begin meson-1.3.2 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
finish

# 8.57. Coreutils-9.4
begin coreutils-9.4 tar.xz
patch -Np1 -i ../coreutils-9.4-i18n-1.patch
sed -e '/n_out += n_hold/,+4 s|.*bufsize.*|//&|' \
    -i src/split.c
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
finish

# 8.58. Check-0.15.2
begin check-0.15.2 tar.gz
./configure --prefix=/usr --disable-static
make
make docdir=/usr/share/doc/check-0.15.2 install
finish

# 8.59. Diffutils-3.10
begin diffutils-3.10 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.60. Gawk-5.3.0
begin gawk-5.3.0 tar.xz
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
make install
ln -sv gawk.1 /usr/share/man/man1/awk.1
mkdir -pv                                   /usr/share/doc/gawk-5.3.0
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0
finish

# 8.61. Findutils-4.9.0
begin findutils-4.9.0 tar.xz
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install
finish

# 8.62. Groff-1.23.0
begin groff-1.23.0 tar.gz
PAGE=A4 ./configure --prefix=/usr
make
make install
finish

# 8.63. GRUB-2.12
begin grub-2.12 tar.xz
echo depends bli part_gpt > grub-core/extra_deps.lst
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
finish

# 8.64. Gzip-1.13
begin gzip-1.13 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.65. IPRoute2-6.7.0
begin iproute2-6.7.0 tar.xz
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
mkdir -pv             /usr/share/doc/iproute2-6.7.0
cp -v COPYING README* /usr/share/doc/iproute2-6.7.0
finish

# 8.66. Kbd-2.6.4
begin kbd-2.6.4 tar.xz
patch -Np1 -i ../kbd-2.6.4-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
make install
cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4
finish

# 8.67. Libpipeline-1.5.7
begin libpipeline-1.5.7 tar.gz
./configure --prefix=/usr
make
make install
finish

# 8.68. Make-4.4.1
begin make-4.4.1 tar.gz
./configure --prefix=/usr
make
make install
finish

# 8.69. Patch-2.7.6
begin patch-2.7.6 tar.xz
./configure --prefix=/usr
make
make install
finish

# 8.70. Tar-1.35
begin tar-1.35 tar.xz
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
finish

# 8.71. Texinfo-7.1
begin texinfo-7.1 tar.xz
./configure --prefix=/usr
make
make install
make TEXMF=/usr/share/texmf install-tex
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd
finish

# 8.72. Vim-9.1.0041
begin vim-9.1.0041 tar.gz
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.0041
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
finish

# 8.73. MarkupSafe-2.1.5
begin markupSafe-2.1.5 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Markupsafe
finish

# 8.74. Jinja2-3.1.3
begin jinja2-3.1.3 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Jinja2

# 8.75. Udev-3.2.11
begin systemd-255 tar.gz
sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
sed '/systemd-sysctl/s/^/#/' -i rules.d/99-systemd.rules.in
sed '/NETWORK_DIRS/s/systemd/udev/' -i src/basic/path-lookup.h
mkdir -p build
cd       build

meson setup \
      --prefix=/usr                 \
      --buildtype=release           \
      -Dmode=release                \
      -Ddev-kvm-mode=0660           \
      -Dlink-udev-shared=false      \
      -Dlogind=false                \
      -Dvconsole=false              \
      ..
export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')

ninja udevadm systemd-hwdb                                           \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .)                         \
      $udev_helpers
install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network
mkdir -pv /usr/lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install
tar -xf ../../systemd-man-pages-255.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd.link.5'                  \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|'                                 \
    /usr/share/man/man5/systemd.link.5                                \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8

rm /usr/share/man/man*/systemd*
unset udev_helpers
udev-hwdb update

finish

# 8.76. Man-DB-2.12.0
begin man-db-2.12.0 tar.xz
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.12.0 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=
make
make install
finish

# 8.77. Procps-ng-4.0.4
begin procps-ng-4.0.4 tar.xz
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static                        \
            --disable-kill
make
make install
finish

# 8.78. Util-linux-2.39.3
begin util-linux-2.39.3 tar.xz
sed -i '/test_mkfds/s/^/#/' tests/helpers/Makemodule.am
./configure --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --sbindir=/usr/sbin  \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.39.3
make
make install
finish

# 8.79. E2fsprogs-1.47.0
begin e2fsprogs-1.47.0 tar.gz
mkdir -v build
cd       build
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf
finish

# 8.80. Sysklogd-1.5.1
begin sysklogd-1.5.1 tar.gz
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make
make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
finish

# 8.81. Sysvinit-3.08
begin sysvinit-3.08 tar.xz
patch -Np1 -i ../sysvinit-3.08-consolidated-1.patch
make
make install
finish

# 8.78. Stripping
save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.32
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.42.so
               libsframe.so.1.0.0
               libhistory.so.8.2
               libncursesw.so.6.4-20230520
               libm.so.6
               libreadline.so.8.2
               libz.so.1.3.1
               libzstd.so.1.5.5
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib

# 8.78. Cleaning Up
rm -rf /tmp/*
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
