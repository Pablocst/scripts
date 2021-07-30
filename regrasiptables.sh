#!/bin/bash
# this script will help mitigate wp-login and xmlrpc attacks for servers that not use imunify modsecrules, if you server use it, you dont need install it
# this is the first version, and we will work alot on that
# Do Git de "igorhq"


run() {
#moving old regex.custom to be safe on this action
mv /usr/local/csf/bin/regex.custom.pm /usr/local/csf/bin/regex.custom.pm.bkp

# download custom regex.custom
wget --quiet https://gist.githubusercontent.com/igorhrq/5ddc40f4d55e190bd41edc33da95eebc/raw/d23135cc0128a4ce8c3e98d11e331fbbb051b2f5/gistfile1.txt -O /usr/local/csf/bin/regex.custom.pm

# added variable on csf.conf
sed -i '/DEBUG =/ a CUSTOM49_LOG = "/var/log/apache2/domlogs/*/*"' /etc/csf/csf.conf

#check if everything was added fine on last line of csf.conf
egrep "CUSTOM49_LOG =".*"" /etc/csf/csf.conf
if [ $? -eq 0  ] 
then
 echo "csf.conf was received the right configuration"
 else
 echo "Sorry, csf.conf is not configured yet, please proceed doing this configuration manually"
fi

# restart csf and lfd
service lfd restart && csf -r >/dev/null 2>&1
echo -e "csf and lfd was restarted"

echo "the configuration was finished, all events now of bruteforce attacks on wp-login and XMLRPC should be find on var\/log\/lfd.log"
echo "example -> \(WPLOGIN\) WP Login Attack 77.zzz.zzz.13 (-) 10 in the last 3600 secs - Blocked in csf port=80"
}

run
