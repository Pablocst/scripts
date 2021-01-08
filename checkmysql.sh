#!/bin/bash


#This script will compare the number of lines with the term "crash" in mysql logs, there will be a comparison between the current day amount of lines with the day before
#Also The current month amount of lines with the past month
#Peforms basic "Health" MySQL check 
#The finality of this script is to trigger events in zabbix so we can work as pro-active as possible.


LC_TIME=en_US
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'

#First we'll set the variables with current day amount of lines and the day before.

current_d=$(LC_TIME=en_US date +"%y-%m-%d")
host=$(hostname)
log="${host}.err"
current_lines=$(cat /var/lib/mysql/$log | grep "$current_d"| wc -l)
yesterday_d=$(LC_TIME=en_US date  --date="yesterday" +"%y-%m-%d")

echo -e "================== ${WHITE}Records of engines or tables crashed from $yesterday_d to $current_d${NC} ==================="
echo -e "=================="
sed -n "/$yesterday_d/,/$current_d/{/$current_d/d; p}" /var/lib/mysql/$log | grep "crash" | grep Table | cut -f2 -d"'" | sort | uniq
echo -e "=================="
echo -e ""
echo -e	"================== ${WHITE}Number of lines that match the term crash from $yesterday_d to $current_d${NC} ==================="
echo -e "=================="
sed -n "/$yesterday_d/,/$current_d/{/$current_d/d; p}" /var/lib/mysql/$log | grep "crash" | wc -l
echo -e "=================="
echo -e ""


#Now we'll get the current month and the past month

last_day_of_past_m=$(LC_TIME=en_US date -d "$(LC_TIME=en_US date +%Y-%m-01) -1 day" +%y-%m-%d)
first_day_of_past_m=$(LC_TIME=en_US date -d"1 $(LC_TIME=en_US date -d'last month' +%b)" +%F)
#current_m=$(LC_TIME=en_US date +'%m')
#past_m=$(LC_TIME=en_US date +'%m' -d 'last month')

echo -e "================== ${WHITE}Records of tables crashed from $first_day_of_past_m to $last_day_of_past_m${NC} ==================="
echo -e "================="
sed -n "/$first_day_of_past_m/,/$last_day_of_past_m/{/$last_day_of_past_m/d; p}" /var/lib/mysql/$log | grep "crash" | grep Table | cut -f2 -d"'" | sort | uniq
echo -e "================="
echo -e ""
echo -e "================== ${WHITE}Number of lines that match the term crash from $first_day_of_past_m to $last_day_of_past_m${NC} ==================="
echo -e "=================="
sed -n "/$first_day_of_past_m/,/$last_day_of_past_m/{/$last_day_of_past_m/d; p}" /var/lib/mysql/$log | grep "crash" | wc -l
echo -e "=================="
echo -e ""

#Starting with MySQL verification

slow_q=$(mysqladmin proc status | awk -F 'Slow' '{print $2}' | awk NF | cut -f3 -d" ")

if [ "$slow_q" -gt 500 ]; then

echo -e "================== ${RED}This server has more then 500 slow queries more specifically $slow_q${NC} ==================="

else

echo -e "================== ${GREEN}This server has less then 500 slow queries${NC} ==================="

fi

echo -e ""

echo -e "================== ${YELLOW}Pontos de Otimização${NC} ===================\n"

delete_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_delete';" | awk -F 'Com_delete' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)
insert_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_insert';" | awk -F 'Com_insert' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)
update_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_update';" |awk -F 'Com_update' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)
select_n=$(mysql -e "SHOW GLOBAL STATUS WHERE Variable_name = 'Com_select';" |awk -F 'Com_select' '{print $2}' | awk NF | tr -d '[:blank:]'nactiva)


write_total=$(( delete_n + insert_n + update_n ))
read_total=$select_n
total_consult=$(( write_total + read_total ))

read_percent=$(echo "100/$total_consult*$read_total" | bc -l)
echo -e "================== ${WHITE}MySQL read rate${NC} ===================\n"
echo -e "${GREEN}$read_percent${NC}"
echo -e ""
write_percent=$(echo "100/$total_consult*$write_total" | bc -l)
echo -e "================== ${WHITE}MySQL write rate${NC} ==================="
echo -e	"${GREEN}$write_percent${NC}"


echo -e "=================== ${WHITE}Current my.cnf config${NC} =================\n"; 
if [ -f /etc/my.cnf ]; then

        egrep ^key_buffer /etc/my.cnf
        egrep ^max_connections /etc/my.cnf
        egrep ^max_user_connections /etc/my.cnf
        egrep ^max_allowed_packet /etc/my.cnf
        egrep ^wait_timeout /etc/my.cnf
        egrep ^innodb_buffer_pool_size /etc/my.cnf
        egrep ^innodb_log_file_size /etc/my.cnf

else
        echo " The file my.cnf does not exist. ";
fi

echo -e ""

#We'll need to know exaclty how much ram RAM the server has so we can determine the ideal value for innodb_buffer_pool_size and innodb_log_file_size
#We'll be using 60% of server total RAM, this number is not random , the default value for most of servers is something around 70 to 80%, however since we are using this script in a server with multiple applications, we have to aknowledge their ram usage, so we'll use 60%


        total_ram=$(echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024))))
        ideal_innodb_buffer=$(echo $(( $total_ram*60/100 )))
       

echo -e "=================== ${WHITE}Suggested innodb_buffer_pool_size is:${NC} =================\n"
echo -e "==================="
echo -e "${GREEN}$ideal_innodb_buffer MB${NC}"
echo -e	"==================="

# Here we'll get the exact value of the most important variables

#key_buffer_size_tmp=$(mysql -e "show variables like 'key_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#innodb_buffer_pool_size_tmp=$(mysql -e "show variables like 'innodb_buffer_pool_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#innodb_log_buffer_size_tmp=$(mysql -e "show variables like 'innodb_log_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#innodb_additional_mem_pool_size_tmp=$(mysql -e "show variables like 'innodb_additional_mem_pool_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#net_buffer_size_tmp=$(mysql -e "show variables like 'net_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#query_cache_size_tmp=$(mysql -e "show variables like 'query_cache_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#sort_buffer_size_tmp=$(mysql -e "show variables like 'sort_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#myisam_sort_buffer_size_tmp=$(mysql -e "show variables like 'myisam_sort_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#read_buffer_size_tmp=$(mysql -e "show variables like 'read_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#join_buffer_size_tmp=$(mysql -e "show variables like 'join_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#read_rnd_buffer_size_tmp=$(mysql -e "show variables like 'read_rnd_buffer_size'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')
#thread_stack_tmp=$(mysql -e "show variables like 'thread_stack'" | grep "size" | awk -F 'size' '{print $2}' | tr -d '[:blank:]')

# Now we'll see the current connections

current_connections=$(mysql -e ""SHOW STATUS WHERE variable_name = 'Max_used_connections'"" | grep "connections" | awk -F 'connections' '{print $2}' | tr -d '[:blank:]')

#if []
