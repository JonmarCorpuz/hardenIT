APACHE_GROUP=$(grep -E '^export APACHE_RUN_GROUP=' /etc/apache2/envvars | cut -d= -f2)

sudo find /var/www/html \( -type f -o -type d \) -group "$APACHE_GROUP" -perm /020 -exec ls -ld {} +
