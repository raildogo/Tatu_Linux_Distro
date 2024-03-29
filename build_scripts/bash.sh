. $DIST_ROOT/build_scripts/inc-start.sh $1 $(basename $0)

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

make
make DESTDIR=$LFS install
#ln -sv bash $LFS/bin/sh

. $DIST_ROOT/build_scripts/inc-end.sh $1 $(basename $0)
