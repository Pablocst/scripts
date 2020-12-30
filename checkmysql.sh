#!/bin/bash


#This script will compare the number of lines with the term "crash" in mysql logs, there will be a comparison between the current day amount of lines with the day before
#Also The current month amount of lines with the past month
#Peforms basic "Health" MySQL check 
#The finality of this script is to trigger events in zabbix so we can work as pro-active as possible.

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'

#First we'll set the variables with current day amount of lines and the day before.

current_d=$(date +"%y-%m-%d")
host=$(hostname)
log="${host}.err"
current_lines=$(cat /var/lib/mysql/$log | grep "$current_d"| wc -l)
yesterday_d=$(date  --date="yesterday" +"%y-%m-%d")

echo -e "================== ${GREEN}Records of engines or tables crashed from $yesterday_d to $current_d${NC} ==================="
echo -e "+++"
sed -n "/$yesterday_d/,/$current_d/{/$current_d/d; p}" /var/lib/mysql/$log | grep "crash" | grep Table | cut -f2 -d"'" | sort | uniq
echo -e "+++"
echo -e ""
echo -e	"================== ${GREEN}Number of lines that match the term crash from $yesterday_d to $current_d${NC} ==================="
echo -e "+++"
sed -n "/$yesterday_d/,/$current_d/{/$current_d/d; p}" /var/lib/mysql/$log | grep "crash" | wc -l
echo -e "+++"
echo -e ""


#Now we'll get the current month and the past month

last_day_of_past_m=$(date -d "$(date +%Y-%m-01) -1 day" +%y-%m-%d)
first_day_of_past_m=$(date -d"1 $(date -d'last month' +%b)" +%F)
#current_m=$(date +'%m')
#past_m=$(date +'%m' -d 'last month')

echo -e "================== ${GREEN}Records of tables crashed from $first_day_of_past_m to $last_day_of_past_m${NC} ==================="
echo -e "+++"
sed -n "/$first_day_of_past_m/,/$last_day_of_past_m/{/$last_day_of_past_m/d; p}" /var/lib/mysql/$log | grep "crash" | grep Table | cut -f2 -d"'" | sort | uniq
echo -e "+++"
echo -e ""
echo -e "================== ${GREEN}Number of lines that match the term crash from $first_day_of_past_m to $last_day_of_past_m${NC} ==================="
echo -e "+++"
sed -n "/$first_day_of_past_m/,/$last_day_of_past_m/{/$last_day_of_past_m/d; p}" /var/lib/mysql/$log | grep "crash" | wc -l
echo -e "+++"
echo -e ""

#Starting with MySQL verification

slow_q=$(mysqladmin proc status | awk -F 'Slow' '{print $2}' | awk NF | cut -f3 -d" ")

if [ "$slow_q" -gt 500 ]; then

echo -e "================== ${RED}This server has more then 500 slow queries more specifically $slow_q${NC} ==================="

else

echo -e "================== ${GREEN}This server has less then 500 slow queries${NC} ==================="

fi

echo -e ""

echo -e "================== ${YELLOW}Pontos de Otimização${NC} ==================="

delete_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_delete';" | awk -F 'Com_delete' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)
insert_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_insert';" | awk -F 'Com_insert' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)
update_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_update';" |awk -F 'Com_update' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)
select_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_select';" |awk -F 'Com_select' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)


write_total=$(( delete_n + insert_n + update_n ))
read_total=$select_n
total_consult=$(( write_total + read_total ))

read_percent=$(echo "100/$total_consult*$read_total" | bc -l)
echo -e "================== ${WHITE}MySQL read rate${NC} ==================="
echo -e "$read_percent"
write_percent=$(echo "100/$total_consult*$write_total" | bc -l)
echo -e "================== ${WHITE}MySQL write rate${NC} ==================="
echo -e	"$write_percent"
