#!/bin/bash

# Check and force the usage for get an parameter
if [ $# -ne 1 ]; then
  echo -e "Invalid parameter, please use: cleanmailaccount.sh [ACCOUNT]: \033[0;31m[ERROR]\033[0m"
  exit;
else
  CONTAFULL=$1
fi


CONTA=$(echo $CONTAFULL | cut -f1 -d"@")
DOMINIO=$(echo $CONTAFULL | cut -f2 -d"@")
CONTA_CPANEL=$(cat /etc/trueuserdomains | grep "$DOMINIO" | tr -s " " | cut -f2 -d" ")
COUNT=1
ls -lha /home/$CONTA_CPANEL/mail/$DOMINIO/$CONTA/cur/ | tr -s " " | cut -f9 -d " " > /root/fullreport.txt
TAMANHO=$(cat /root/fullreport.txt | wc -l)
while [ $COUNT -lt $TAMANHO ]; do 
     TMP=$(sed -n ${COUNT}p /root/fullreport.txt)
     TMP_FULL=$(cat /home/$CONTA_CPANEL/mail/$DOMINIO/$CONTA/cur/$TMP | grep "Mail delivery failed")
     if [ -z "$TMP_FULL" ]; then
     COUNT=$(echo $(( $COUNT+1 )))
     else
     rm -fv /home/$CONTA_CPANEL/mail/$DOMINIO/$CONTA/cur/$TMP
     COUNT=$(echo $(( $COUNT+1 )))
     fi
done

rm -f /root/fullreport.txt
