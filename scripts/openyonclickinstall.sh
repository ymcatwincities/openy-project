#!/bin/bash
# To get latest dev OpenY on DigitalOcean 16.04 LST x64 droplet run the command:
#   curl -Ls https://raw.githubusercontent.com/AndreyMaximov/openy-project/8.1.x/scripts/openyonclickinstall.sh | bash -s
# To get particular version or branch:
#   curl -Ls https://raw.githubusercontent.com/AndreyMaximov/openy-project/8.1.x/scripts/openyonclickinstall.sh | bash -s 8.1.10
# as root user

OPENYBETA="8.2.*@beta"
OPENYDEV="dev-8.x-1.x"

OPENYVERSION="$1"
OPENYVERSION=${OPENYVERSION:-stable}

printf "Hello, OpenY evaluator.\n OpenY one click install version 1.4.\n"

printf "Installing OpenY into /var/www/html\n"

printf "\nMaking backup of existing /var/www/html folder to /var/www/html.bak\n"
sudo rm -rf /var/www/html.bak/html || true
sudo mv /var/www/html /var/www/html.bak || true

printf "\nInstalling mysql server\n"
sudo apt-get -y update || true

root_pass="root"

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server

sudo mysql -uroot -p$root_pass -e "drop database drupal;" || true
sudo mysql -uroot -p$root_pass -e "create database drupal;" || true
sudo mkdir -p /var/www || true
cd /var/www
sudo rm -rf cibox || true
git clone --branch=ansible_lamp https://github.com/cibox/cibox.git
cd cibox
bash core/cibox-project-builder/files/vagrant/box/provisioning/shell/initial-setup.sh core/cibox-project-builder/files/vagrant/box/provisioning
bash core/cibox-project-builder/files/vagrant/box/provisioning/shell/ansible.sh
sh cilamp.sh
sudo sed -i "s/var\/www/var\/www\/html\/docroot/g" /etc/apache2/sites-enabled/vhosts.conf

sudo service apache2 restart

drush dl -y drupal-8.4.x --dev --destination=/tmp --default-major=8 --drupal-project-rename=drupal
cd /tmp/drupal
drush si -y minimal --db-url=mysql://root:$root_pass@localhost/drupal && drush sql-drop -y

printf "\nPreparing OpenY code tree \n"
sudo rm -rf /var/www/html.bak/html || true
sudo mv /var/www/html /var/www/html.bak || true
composer create-project ymcatwincities/openy-project:8.1.x-dev /var/www/html --no-interaction
cd /var/www/html/

# Check if the Open Y version must be adjusted.
if [[ "$OPENYVERSION" == "stable" ]]; then
  echo "Installing Latest Stable Open Y"
elif [[ "$OPENYVERSION" == "dev" ]]; then
  echo "Installing Latest Dev Open Y"
  composer remove ymcatwincities/openy --no-update
  composer require ymcatwincities/openy:${OPENYDEV} --update-with-dependencies
elif [[ "$OPENYVERSION" == "beta" ]]; then
  echo "Installing Latest Beta Open Y"
  composer remove ymcatwincities/openy --no-update
  composer require ymcatwincities/openy:${OPENYBETA} --update-with-dependencies
else
  echo "Installing Open Y $OPENYVERSION"
  composer remove ymcatwincities/openy --no-update
  composer require ymcatwincities/openy:${OPENYVERSION} --update-with-dependencies
fi
composer update

cp /tmp/drupal/sites/default/settings.php /var/www/html/docroot/sites/default/settings.php
sudo mkdir /var/www/html/docroot/sites/default/files
echo "\$config['system.logging']['error_level'] = 'hide';" >> /var/www/html/docroot/sites/default/settings.php
sudo chmod -R 777 /var/www/html/docroot/sites/default/settings.php
sudo chmod -R 777 /var/www/html/docroot/sites/default/files

IP="$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"

printf "\nOpen http://$IP/core/install.php to proceed with OpenY installation.\n"
