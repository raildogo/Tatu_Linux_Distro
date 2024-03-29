pwconv
grpconv

mkdir -p /etc/default
useradd -D --gid 999

sed -i '/MAIL/s/yes/no/' /etc/default/useradd
