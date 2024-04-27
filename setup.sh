#!/bin/bash





HOST_IP="x.x.x.x"
HOST_SUBNET="32"
HOST_GATEWAY="x.x.x.x"

NFS_IP="x.x.x.x"
NFS_PATH="/folder/folder/folder"

MYSQL_USER="root"
MYSQL_PASSWORD=""

NEXTCLOUD_USER="nextcloud"
NEXTCLOUD_PASSWORD="nextcloud"






# --- UPDATE and UPGRADE ---
sudo apt update
sudo apt upgrade -y
sudo apt install -y openssh-server nano ufw curl wget git unzip zsh neofetch lm-sensors



# --- Allow SSH on FIREWALL ---
#sudo ufw default deny incoming
#sudo ufw default deny outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2049/tcp
sudo ufw enable



# --- Setting up IP ---
sudo nmcli con mod "Wired connection 1" \
ipv4.addresses "${HOST_IP}/${HOST_SUBNET}" \
ipv4.gateway "${HOST_GATEWAY}" \
ipv4.dns "1.1.1.1,8.8.8.8" \
ipv4.method "manual"



# --- Setting up NANO ---
sudo rm /etc/nanorc
sudo wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/nanorc -P /etc/



# --- Setting up MOTD ---
sudo chmod -x /etc/update-motd.d/10-uname
sudo wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/20-neofetch -P /etc/update-motd.d/
sudo chmod +x /etc/update-motd.d/20-neofetch



# --- Setting up SENSORS ---
echo "Y Y Y" | sudo sensors-detect



# --- Setting up ZSH ---
echo "N exit" | sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm .zshrc
wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/.zshrc
wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/.p10k.zsh
chsh -s /bin/zsh



# --- CONFIGURE NFS ---
sudo apt install -y nfs-common
sudo mkdir /mnt/NFS
sudo mount ${NFS_IP}:${NFS_PATH} /mnt/NFS
echo "${NFS_IP}:${NFS_PATH} /mnt/NFS nfs defaults 0 0" | sudo tee -a /etc/fstab



# --- NEXTCLOUD ---
sudo apt install -y apache2 php libapache2-mod-php mariadb-server
sudo apt install -y php-gd php-mysql php-curl php-xml php-mbstring php-zip php-intl

PHP_VERSION=$(php -v | grep '[1-9]\.[1-9]' -o -m 1)
sudo sed -i 's/memory_limit = 128M/memory_limit = 4G/g' /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 16G/g' /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i 's/post_max_size = 8M/post_max_size = 16G/g' /etc/php/${PHP_VERSION}/apache2/php.ini
sudo systemctl restart apache2

sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "CREATE USER '${NEXTCLOUD_USER}'@'localhost' identified by '${NEXTCLOUD_PASSWORD}';"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "GRANT ALL PRIVILEGES on nextcloud.* to '${NEXTCLOUD_USER}'@'localhost';"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "FLUSH PRIVILEGES;"

sudo wget https://download.nextcloud.com/server/releases/latest.zip -P /var/www/html
sudo unzip /var/www/html/latest.zip -d /var/www/html
sudo rm /var/www/html/latest.zip
sudo chown -R www-data:www-data /var/www/html/nextcloud
sudo chown -R www-data:www-data /mnt/NFS

sudo wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/nextcloud.conf -P /etc/apache2/sites-available/
sudo wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/nextcloud_ssl.conf -P /etc/apache2/sites-available/

sudo rm /etc/apache2/apache2.conf
sudo wget https://raw.githubusercontent.com/LoBrol/raspi-nextcloud/main/file_to_be_copied/apache2.conf -P /etc/apache2/

sudo a2ensite nextcloud.conf
sudo a2ensite nextcloud_ssl.conf
sudo a2enmod rewrite
sudo a2enmod ssl
sudo service apache2 restart
