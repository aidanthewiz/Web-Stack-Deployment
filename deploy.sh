#!/usr/bin/env bash

# Web Stack Deployment
# Copyright (c) 2019, aidanthewiz

# Exit if the script is not being run as root and output to stderr.
if [[ $EUID -ne 0 ]] || [[ $(id -u) -ne 0 ]]; then
   echo "This deploy script must be run as root 'sudo ./deploy.sh'" >&2
   exit 1
fi

# Update and Full Upgrade before configuration
apt update
apt full-upgrade -y

# Ask to enable firewall and allow OpenSSH
echo "Would you like to enable ufw (firewall) and allow OpenSSH?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        ufw enable
        ufw allow OpenSSH
        break
    ;;
    No)
        break
    ;;
    esac
done

# Ask to change hostname
echo "Would you like to change your hostname (input will be trimmed for white space)?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        echo "What would you like it set to?"
        read new_hostname
        # Preform trim on input
        read -rd '' new_hostname <<< "{$new_hostname}"
        hostnamectl set-hostname $new_hostname
        break
    ;;
    No)
        break
    ;;
    esac
done

lemp () {
    add-apt-repository ppa:ondrej/php -y
    add-apt-repository ppa:certbot/certbot -y
    apt update
    apt full-upgrade -y
    apt install build-essential nginx checkinstall libpcre3 libpcre3-dev zlib1g-dev unzip uuid-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev libgoogle-perftools-dev libperl-dev php7.3-fpm php7.3-opcache php7.3-common php7.3-cli php7.3-gd php7.3-zip php7.3-mbstring php7.3-xml php7.3-xmlrpc php7.3-soap php7.3-mysql php7.3-curl -y
    apt remove *nginx* -y
    NGINX_VERSION=1.16.0
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz --directory-prefix=/usr/local/src/
    tar -xzvf /usr/local/src/nginx-* --directory=/usr/local/src/
    git clone --recursive https://github.com/google/ngx_brotli.git /usr/local/src/ngx_brotli
    # Pagespeed START
    NPS_VERSION=1.13.35.2
    wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}-stable.zip --directory-prefix=/usr/local/src/
    unzip /usr/local/src/v${NPS_VERSION}-stable.zip -d /usr/local/src/
    wget https://www.modpagespeed.com/release_archive/${NPS_VERSION}/psol-${NPS_VERSION}-x64.tar.gz --directory-prefix=/usr/local/src/incubator-pagespeed-ngx-${NPS_VERSION}-stable/
    tar -xzvf /usr/local/src/incubator-pagespeed-ngx-${NPS_VERSION}-stable/psol-${NPS_VERSION}-x64.tar.gz --directory=/usr/local/src/incubator-pagespeed-ngx-${NPS_VERSION}-stable/
    # Pagespeed END
    (cd /usr/local/src/nginx-${NGINX_VERSION}/ && ./configure --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module --add-module=/usr/local/src/ngx_brotli --add-module=/usr/local/src/incubator-pagespeed-ngx-${NPS_VERSION}-stable --sbin-path=/usr/sbin/nginx)
    make --directory=/usr/local/src/nginx-${NGINX_VERSION}/
    make install --directory=/usr/local/src/nginx-${NGINX_VERSION}/
    apt-mark hold nginx*
    mkdir -p /var/lib/nginx/{body,fastcgi}
    mkdir /var/cache/ngx_pagespeed/
    chown root:root /var/cache/ngx_pagespeed/
    apt update
    apt full-upgrade -y
    systemctl unmask nginx
    systemctl enable nginx.service
    ufw allow 'Nginx Full'
}

lamp () {
    echo "lamp"
}

# Ask what server stack the user wants to set up.
echo "What server stack would you like to configure?"
select stack in "LEMP" "LAMP"; do
    case $stack in
    LEMP)
        lemp;
        break
    ;;
    LAMP)
        lamp;
        break
    ;;
    esac
done