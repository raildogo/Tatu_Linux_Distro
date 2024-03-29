echo
echo "Glibc"
echo
sleep 1

cd $LFS/sources
tar -xf glibc-2.39.tar.xz
cd glibc-2.39

ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3

patch -Np1 -i ../glibc-2.39-fhs-1.patch

mkdir -p build && cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.19               \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib

make

make DESTDIR=$LFS install

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo
echo "Testando GLIBC"
echo
echo 'int main(){}' | $LFS_TGT-gcc -xc -

readelf -l a.out | grep ld-linux

cd $LFS/sources
rm -rf glibc-2.39