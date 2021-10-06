#!/bin/bash

current_d=$(LC_TIME=en_US date +"%d\/%b\/%Y")

touch tmptophits2.txt
for i in `/bin/ls -lh /var/cpanel/users/ | grep -v system |tr -s " " | cut -f9 -d" "`;do for j in `grep $i /etc/userdomains | cut -f1 -d":"`; do zgrep $current_d /home/$i/logs/$j-Oct-2021.gz | wc -l > tmptophits.txt && echo "$j: " >> tmptophits2.txt  && echo -n $(cat tmptophits.txt) >> tmptophits2.txt && echo "" >> tmptophits2.txt $j;done;done 
echo "Top 5 Hits porta 80"
cat tmptophits2.txt | sort -n | tail -n5
rm -f tmptophits2.txt && rm -f tmptophits.txt

touch tmptophits2.txt
for i in `/bin/ls -lh /var/cpanel/users/ | grep -v system |tr -s " " | cut -f9 -d" "`;do for j in `grep $i /etc/userdomains | cut -f1 -d":"`; do zgrep $current_d /home/$i/logs/$j-ssl_log-Oct-2021.gz | wc -l > tmptophits.txt && echo "$j: " >> tmptophits2.txt  && echo -n $(cat tmptophits.txt) >> tmptophits2.txt && echo "" >> tmptophits2.txt $j;done;done 
echo "Top 5 Hits porta 443"
cat tmptophits2.txt | sort -n | tail -n5
rm -f tmptophits2.txt && rm -f tmptophits.txt

