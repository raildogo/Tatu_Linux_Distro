FILE=$1

echo
echo "Limpando up..."
echo

cd $LFS/sources
DIR=$(echo $FILE | awk -F"\\\\.t" '{print $1}')
rm -rf $DIR

echo
echo "Processo finalinazado $FILE"
echo