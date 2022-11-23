#/bin/sh

plesk bin domain --create testmail.com
plesk bin mail --create test@testmail.com -passwd "Plesk1@#$" -mailbox true
/sbin/sendmail palbuquerque@palbuquerque.online < email2.txt
