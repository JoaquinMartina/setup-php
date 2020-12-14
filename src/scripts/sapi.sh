#!/bin/bash

sapi=$1
php=$2
conf_dir=$3
debconf_fix=DEBIAN_FRONTEND=noninteractive
install_apache2() {
  sudo service nginx stop 2>/dev/null || true
  if ! command -v apache2 >/dev/null; then
    sudo "$debconf_fix" apt-fast install apache2-bin apache2 -y;
  else
    if ! [[ "$(apache2 -v 2>/dev/null | grep -Eo "([0-9]+\.[0-9]+)")" =~ 2.[4-9] ]]; then
      sudo "$debconf_fix" apt-get purge apache* apache-* >/dev/null
      sudo "$debconf_fix" apt-fast install apache2-bin apache2 -y;
    fi
  fi
  sudo cp "$conf_dir"/default_apache /etc/apache2/sites-available/000-default.conf
}

install_nginx() {
  sudo service apache2 stop 2>/dev/null || true
  if ! command -v nginx >/dev/null; then
    sudo "$debconf_fix" apt-fast install nginx -y
  fi
  sudo cp "$conf_dir"/default_nginx /etc/apache2/sites-available/default
}

if ! command -v apt-fast >/dev/null; then sudo ln -sf /usr/bin/apt-get /usr/bin/apt-fast; fi

case $sapi in
  apache*:apache*)
    install_apache2
    sudo "$debconf_fix" apt-fast install libapache2-mod-php"$php" -y
    sudo a2dismod mpm_event 2>/dev/null || true
    sudo a2enmod mpm_prefork php"$php"
    sudo service apache2 restart
    ;;
  fpm:apache*)
    install_apache2
    sudo "$debconf_fix" apt-fast install libapache2-mod-fcgid php"$php"-fpm -y
    sudo a2dismod php"$php" 2>/dev/null || true
    sudo a2enmod proxy_fcgi
    sudo a2enconf php"$php"-fpm
    sudo service apache2 restart
    ;;
  cgi:apache*)
    install_apache2
    sudo "$debconf_fix" apt-fast install php"$php"-cgi -y
    sudo a2dismod php"$php" mpm_event 2>/dev/null || true
    sudo a2enmod mpm_prefork actions cgi
    sudo a2disconf php"$php"-fpm 2>/dev/null || true
    sudo a2enconf php"$php"-cgi
    sudo service apache2 restart
    ;;
  fpm:nginx)
    install_nginx
    sudo service nginx restart
    ;;
  apache*)
    sudo "$debconf_fix" apt-fast install libapache2-mod-php"$php" -y
    ;;
  fpm|embed|cgi)
    sudo "$debconf_fix" apt-fast install php"$php"-"$sapi" -y
    ;;
esac

exit 0