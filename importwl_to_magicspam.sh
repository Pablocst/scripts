#!/bin/bash

# If in any case anything goes wrong there will be a copy of the  original "from_whitelist" of magic Spam in /root/

ls -l /var/cpanel/users/ | tr -s " " | cut -f4 -d" " > /root/cpanel_users.txt
sed '/root/d' /root/cpanel_users.txt >> /root/cpanel_users2.txt
for i in `cat /root/cpanel_users2.txt`; do cat /home/$i/.spamassassin/user_prefs | grep "whitelist_from" | awk -F 'someone@somewhere.com' '{print $1}' | tr -s " " | cut -f3 -d"#" >> /root/listacompleta.txt; done
sed '/^$/d' /root/listacompleta.txt >> /root/listacompleta2.txt
mv -f /root/listacompleta2.txt /root/listacompleta.txt
cp /etc/magicspam/from_whitelist.lst /root/from_whitelist.lst.bkp
cat /root/listacompleta.txt | awk -F 'whitelist_from' '{print $2}' |tr -s " " | tr -d "[:space:]" >> /etc/magicspam/from_whitelist.lst
tratamento=$(cat /etc/magicspam/from_whitelist.lst | uniq > /root/teste.txt)
rm -f /root/cpanel_users*
rm -f /root/listacompleta.txt
