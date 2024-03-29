. $DIST_ROOT/build_scripts/inc-start.sh $1 $(basename $0)

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

. $DIST_ROOT/build_scripts/inc-end.sh $1 $(basename $0)
