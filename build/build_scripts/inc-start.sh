FILE=$1

echo
echo "Processando $2"
echo
sleep 1

cd $LFS/sources
echo "Extraindo..."
tar -xf $FILE
DIR=$(echo $FILE | awk -F"\\\\.t" '{print $1}')
cd $DIR
echo "Alterando pasta"
pwd
