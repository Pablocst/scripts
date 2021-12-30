#!/bin/bash

# COMPILANDO O MODSEC

apt-get update -y
apt-get install wget -y
ufw disable
apt-get install nginx -y
ufw allow 'Nginx HTTP'
apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install
cd ..
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
VERSAO=$(nginx -v 2>&1 | cut -f2 -d"/" | cut -f1 -d" ")
wget http://nginx.org/download/nginx-$VERSAO.tar.gz
tar zxvf nginx-$VERSAO.tar.gz
cd nginx-$VERSAO
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
sed -i '4 i load_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf
mkdir /etc/nginx/modsec
wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
cp ModSecurity/unicode.mapping /etc/nginx/modsec
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
echo "# From https://github.com/SpiderLabs/ModSecurity/blob/master/" >> /etc/nginx/modsec/main.conf
echo "# modsecurity.conf-recommended" >> /etc/nginx/modsec/main.conf
echo "#" >> /etc/nginx/modsec/main.conf
echo "# Edit to set SecRuleEngine On" >> /etc/nginx/modsec/main.conf
echo "Include \"/etc/nginx/modsec/modsecurity.conf\"" >> /etc/nginx/modsec/main.conf 
echo "" >> /etc/nginx/modsec/main.conf
echo "# Basic test rule" >> /etc/nginx/modsec/main.conf
echo "SecRule ARGS:testparam \"@contains test\" \"id:1234,deny,status:403\"" >> /etc/nginx/modsec/main.conf
