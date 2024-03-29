echo
echo "Linux Headers"
echo
sleep 1

tar -xf linux-6.7.4.tar.xz
cd linux-6.7.4

make mrproper

make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr


cd $LFS/sources
rm -rf linux-6.7.4