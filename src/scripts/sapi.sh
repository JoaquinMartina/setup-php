#!/bin/bash

install_apache2() {
  sudo mkdir -p /var/www/html
  sudo service nginx stop 2>/dev/null || true
  if ! command -v apache2 >/dev/null; then
    install_packages apache2-bin apache2 -y;
  else
    if ! [[ "$(apache2 -v 2>/dev/null | grep -Eo "([0-9]+\.[0-9]+)")" =~ 2.[4-9] ]]; then
      sudo "${debconf_fix:?}" apt-get purge apache* apache-* >/dev/null
      install_packages apache2-bin apache2 -y;
    fi
  fi  
}

install_nginx() {
  sudo mkdir -p /var/www/html
  sudo service apache2 stop 2>/dev/null || true
  if ! command -v nginx >/dev/null; then
    install_packages nginx -y
  fi  
}

switch_sapi() {
  sapi=$1
  conf_dir=$2
  
  case $sapi in
    apache*:apache*)
      install_apache2
      sudo cp "$conf_dir"/default_apache /etc/apache2/sites-available/000-default.conf
      install_packages libapache2-mod-php"${version:?}" -y
      sudo a2dismod mpm_event 2>/dev/null || true
      sudo a2enmod mpm_prefork php"${version:?}"
      sudo service apache2 restart
      ;;
    fpm:apache*)
      install_apache2
      sudo cp "$conf_dir"/default_apache /etc/apache2/sites-available/000-default.conf
      install_packages libapache2-mod-fcgid php"${version:?}"-fpm -y
      sudo a2dismod php"${version:?}" 2>/dev/null || true
      sudo a2enmod proxy_fcgi
      sudo a2enconf php"${version:?}"-fpm
      sudo service apache2 restart
      ;;
    cgi:apache*)
      install_apache2
      install_packages php"${version:?}"-cgi -y
      sudo cp "$conf_dir"/default_apache /etc/apache2/sites-available/000-default.conf
      echo "Action application/x-httpd-php /cgi-bin/php${version:?}" >> /etc/apache2/conf-available/php"${version:?}"-cgi.conf
      sudo a2dismod php"${version:?}" mpm_event 2>/dev/null || true
      sudo a2enmod mpm_prefork actions cgi
      sudo a2disconf php"${version:?}"-fpm 2>/dev/null || true
      sudo a2enconf php"${version:?}"-cgi
      sudo service apache2 restart
      ;;
    fpm:nginx)
      install_nginx
      sudo cp "$conf_dir"/default_nginx /etc/nginx/sites-available/default
      sudo sed -i "s/PHP_VERSION/${version:?}/" /etc/nginx/sites-available/default
      sudo service nginx restart
      ;;
    apache*)
      install_packages libapache2-mod-php"${version:?}" -y
      ;;
    fpm|embed|cgi)
      install_packages php"${version:?}"-"$sapi" -y
      ;;
  esac
}
