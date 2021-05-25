#!/bin/bash

current_d=$(LC_TIME=en_US date +"%d\/%B\/%Y")
for i in `cat /etc/userdomains | cut -f1 -d":"`; do for j in `grep $i /etc/userdomains | cut -f2 -d":" | tail -n1`; do VALOR=$(grep $i /var/log/apache2/domlogs/$j/* | grep $current_d | wc -l) && echo "$i : $VALOR"; done; done > /root/tmp_hits_file.txt 2>/dev/null
cat /root/tmp_hits_file.txt | tr -s " " | awk '!/^$/' | tr -d '[:blank:]' | sort -n -k 2,2 -k 1,1 -t ":" | tail -n5
rm -rf /root/tmp_hits_file.txt
