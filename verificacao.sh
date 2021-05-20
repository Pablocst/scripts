#!/bin/bash
# *********************************************
# * Script para verificação do servidor *
# * Author: Renan Pessoa *
# * HDBR Team *
# * E-Mail: renan.s@hostdime.com.br *
# * Date: 2015-07-08 *
# *********************************************
# ======================================================================
# Este script utiliza códigos reunidos do codex, os créditos são de seus respectivos criadores.
# ======================================================================


<< 'CHANGELOG'

2.8 - 28/12/2020 [ Autores: Pablo Bezerra ]
  *Corrigido:
    - Corrigido bug na exibição da utilização de memória real
  +Adicionado:
    - Informações sobre a utilização individual de cada núcleo do CPU
    - Adição de algumas variáveis relevantes no my.cnf   
    - Remoção da função de conxeões dos domínios uma vez que era redundante o script não mais funcionava
    - Adição de verificação de ataque ao wp-login 
    - Adição de verificação de ataque de amplificação com xmlrpc

2.7 - 20/02/2017 [ Autores: Renan Pessoa ]

  *Corrigido:
    - Corrigido o status do Apache em servidores com Centos 7

2.6 - 10/02/2017 [ Autores: Renan Pessoa ]

  *Corrigido:
    - Servidores com o idioma PT-BR agora exibem o número de hits dos domínios corretamente
    
2.5 - 05/01/2016 [ Autores: Renan Pessoa ]

  +Adicionado:
    - Informação sobre a velocidade da porta das interfaces
    - Informação sobre a Frequência do CPU

2.4 - 26/12/2016 [ Autores: Renan Pessoa ]

  +Adicionado:
    - Informações de Hardware
    - Informações de Rede
    - Temperatura dos processadores
    - Status e uptime do serviço Apache
    - Uptime do serviço MySQL
    - Principais diretivas do httpd.conf (Apache)

  *Alterado:
    - Código otimizado para ser executado mais rápido

2.3 - 26/06/2016 [ Autores: Renan Pessoa ]

  +Adicionado:
    - Domínios com mais hits no dia

2.2 - 20/06/2016 [ Autores: Renan Pessoa ]

  +Adicionado:
    -Informações sobre a saúde dos discos se for executado em um servidor dedicado
    -Conexões nos domínios

  -Removido:
    - Últimas mensagens do buffer do Kernel


2.1 - 26/02/2016 [ Autores: Renan Pessoa ]
  
  +Adicionado:
    - Informa se a rotina de backup está configurada no servidor 

2.0 - 15/01/2016 [ Autores: Renan Pessoa ]

  +Adicionado: 
   - O processo "upcp" é verificado se está sendo executado, caso sim, é informado na opção "Verificação de execução de cpbackup, restorepkg, rsync, pkgacct"
   - É informado a quanto tempo o servidor está ativo(uptime)
   - Adicionado a informação dos últimos reboots
   - É informado o status do cPanel
   - Informa qual o handler do PHP 
   - Adicionado as últimas mensagens de erro do MySQL
   - Adicionado as últimas mensagens do buffer do kernel


1.0 - 08 Julho 2015 [ Autores: Renan Pessoa ]
  * Versão inicial

CHANGELOG


#Limpa a tela
clear;

#. Altera o idioma da sessão para inglês .#
LANG=C
export LANG

#. Identifica qual a versão do sistema operacional .#
SO=$(lsb_release -a | awk '/Release:/{print $2}' | cut -d\. -f1);

# Adiciona cores ao script
RS="\e[0;00m";
H1="\e[1m\e[34m";
H2="\e[1m\e[97m";
CM1="\e[1m\e[95m";
W1="\e[97m";
R1="\e[31m";
R2="\E[1;31m";
Y1="\e[1;33m";
G1="\e[1;32m";  
G2="\e[90m";

echo -e "\n$H1===========$H2 Informações do Servidor $H1===========$RS\n";
echo "Tempo em que o servidor está ativo:" "$(uptime | cut -d"," -f1 | awk '{print $3,$4}')"
echo "Hostname: $(hostname)";
echo -e "Sistema operacional: $(cat /etc/redhat-release)";
echo -e "Kernel: $(uname -r)";

## Verifica se existe CloudLinux
if [[ -z $(uname -r | grep lve 2>/dev/null) ]]; then
 
  echo -e "Cloudlinux: Não\n";
    
else

 echo -e "Cloudlinux: Sim\n";
 
fi

reselleraccts=$(cut -d: -f1  /var/cpanel/resellers | wc -l); echo "Contas de Revenda: $reselleraccts ";
cpanelaccts=$( wc -l /etc/trueuserdomains | awk '{print $1}'); echo "Contas cPanel: $cpanelaccts";
domainaccts=$( wc -l /etc/userdomains | awk '{print $1}'); echo "Domínios: $domainaccts  "


echo -e "\n$H1===========$H2 Informações de Hardware $H1===========$RS\n";

echo "Memória Ram =  $(free -m | awk '/Mem/{print $2}')M"
echo "Swap = $(free -m | awk '/Swap/{print $2}')M"
echo "Quantidade de CPUs = $(cat /proc/cpuinfo | grep processor | wc -l)";
echo -e "Frequência do CPU =  $(cat /proc/cpuinfo | awk '/cpu MHz/{print $4}' | sort | uniq)";
echo -e "Arquitetura: $(arch)"

if sensors &>/dev/null;then
    echo -e "\nTemperatura dos processadores"
    echo -e "============================="
    sensors | grep Core
    echo -e "============================="
fi

echo -e "\n$H1===========$H2 Informações de Rede $H1===============$RS\n";
  
    echo -e "IP do servidor: $(hostname -i)\n";
    ip -o addr | grep -v "127.0.0.1" | awk '/inet /{print "IP (" $2 "):\t" $4}'
/sbin/route -n | cat /etc/resolv.conf | awk '/^nameserver/{ printf "\nNameserver:\t" $2 ""}' | grep -v "127.0.0.1"
  
  echo "";
  for i in `ip -o addr | awk '{print $2}' | sort | tr -d \: | uniq | egrep -v "lo"`;do
    velocidade_porta=$(ethtool $i 2>/dev/null | awk '/Speed/{print $2}')
    echo -e "Interface: $i - Velocidade da porta: ${velocidade_porta:-"Não disponível"}"
  done

echo -e "\n$H1===========$H2 Rotina de backup $H1===========$RS";

TRADICIONAL=$(grep -s -i BACKUPENABLE /var/cpanel/backups/config | awk {'print$2'} | cut -d"'" -f2)
LEGACY=$(grep -s -i BACKUPENABLE /etc/cpbackup.conf | awk {'print$2'})

if [[ $TRADICIONAL == "yes" ]];then
    echo -e "\nBackup: "$G1"Ativo"$RS"";
else
    echo -e "\nBackup: "$G2"Desativado"$RS"";
fi

if [[ $LEGACY == "yes" ]];then
    echo -e "\nBackup Legacy: "$G1"Ativo"$RS"";

else
    echo -e "\nBackup Legacy: "$G2"Desativado"$RS"";
fi


[[ $TRADICIONAL == "no" ]] && [[ $LEGACY == "no" ]] && echo -e ""$R2"Nenhuma rotina de backup está configurada no servidor !"$RS""

echo -e "\n$H1===========$H2 Handler do PHP $H1===========$RS\n";

/usr/local/cpanel/bin/rebuild_phpconf --current;

echo -e "\n$H1===========$H2 Versão das aplicações $H1===========$RS\n";
cpanelv=$(cat /usr/local/cpanel/version); echo "cPanel: $cpanelv";
cat /etc/redhat-release;
mysql -V | awk '{print $1 , $5}' | tr -d ',';
php -v | awk 'FNR == 1';
if [[ -f /usr/local/lib/php53.ini ]]; then echo "Legacy PHP Versão Detectada: `php53 -v -c /usr/local/lib/php53.ini | awk 'FNR == 1'`"; fi
httpd -v | awk 'FNR == 1 {print $3}';
nginx_path=$(which nginx 2>/dev/null);
if [[ -f /etc/init.d/nginx ]]; then
        $nginx_path -v;
fi


echo -e "\n$H1===========$H2 Últimos reboots $H1===========$RS\n";
last reboot;


echo -e "\n$H1===========$H2 LOAD $H1===========$RS\n";

w;
processors=$(cat /proc/cpuinfo | grep processor | wc -l);
currentload=$(cut -d"." -f1 /proc/loadavg);

if [[ "$currentload" -gt "$processors" ]]
then
        echo -e "\n$R1 O Load está ALTO ! $RS";
else
        echo -e "\n$G1 O Load está baixo $RS";
fi;

echo -e "\n$H1===========$H2 Utilização dos núcleos $H1===========$RS\n";

sar -P ALL 1 1

echo -e "\n$H1===========$H2 Status dos serviços $H1===========$RS\n";

echo -e "\n$G1 MySQL $RS"; service mysql status;
echo -e "${Y1}Uptime${RS}: $(mysqladmin  version | grep -i uptime | cut -d: -f2 | awk '{print $1,$2,$3,$4,$5,$6,$7,$8}')"

if [[ $SO == 7 ]];then
    apache_check=$(service httpd status 2>/dev/null | grep running);
else
    apache_check=$(service httpd status 2>/dev/null| grep uptime);
fi

echo -e "\n$G1 APACHE$RS";
if [[ -z $apache_check ]];then
    echo -e "O serviço Apache está ${R2}Offline${RS}";
else
    echo -e "O serviço Apache está online";
    echo -e "${Y1}Uptime${RS}:$(httpd fullstatus 2>/dev/null | grep "Server uptime" | cut -d: -f2)"
fi

echo -e "\n$G1 EXIM $RS"; service exim status; 
echo -e "\n$G1 DOVECOT $RS"; service dovecot status;
echo -e "\n$G1 POSTGRESQL $RS"; service postgresql status;
echo -e "\n$G1 PURE-FTP $RS"; service pure-ftpd status;
echo -e "\n$G1 NAMED $RS"; service named status | tail -1;
echo -e "\n$G1 LFD $RS"; service lfd status;
echo -e "\n$G1 CROND $RS"; service crond status;
echo -e "\n$G1 CPANEL $RS"; service cpanel status | grep -v "entropychat is stopped";


[[ `ifconfig | grep -i eth0` ]] && [[ -z `grep QEMU /proc/cpuinfo` ]] && { echo -e "\n$H1===========$H2 Saúde dos discos $H1===========$RS\n";bash <(curl -ks https://codex.hostdime.com/scripts/download/CheckDriveHealth);}


# Verificação das Portas e do Exim.conf
echo;
bash <(curl -ks https://codex.hostdime.com/scripts/download/eximconfpassiveportchecker)


#Mostra os ips acessando a porta 80
echo -e "\n$H1===========$H2 IPs acessando porta 80 (Web) $H1===========$RS\n";
netstat -plan |grep :80 | awk '{print $5}' |cut -d: -f1 | sort |uniq -c |sort -n | tail -5; 

 
echo -e "\n$H1===========$H2 Conexões Atuais $H1===========$RS\n";
bash <(curl -k -s https://codex.hostdime.com/scripts/download/connections);


echo -e "\n$H1===========$H2 MySQL proc stat $H1===========$RS\n";
    mysqladmin proc stat;

echo -e "\n$H1===========$H2 Últimas mensagens de erro do MySQL $H1===========$RS\n";

tail -30 /var/lib/mysql/$HOSTNAME.err;


#Existe algum procedimento de backup,restauração.. em execução? 
echo -e "\n$H1===========$H2 Verificação de execução de upcp, cpbackup, restorepkg, rsync... $H1======$RS";
ps aux | grep -i "cpbackup\|restorepkg\|rsync\|pkgacct\|upcp" | grep -v grep;

echo -e "\n$H1===========$H2 Screens em execução $H1===========$RS\n";
screen -ls

echo -e "\n$H1===========$H2 Quantidade de e-mails na fila $H1===========$RS\n";
exim -bpc

echo -e "\n$H1===========$H2 Uso de espaço em disco $H1===========$RS\n"; 
df -lh;

echo -e "\n$H1===========$H2 Utilização de Inodes no Disco $H1===========$RS\n"; 
#dfilength=$(df -i | wc -l);
df -i | head -1;
for (( i=2 ; i < `df -i | wc -l` +1; i++ )); do
virtflag=$(df -i | awk 'NR == '$i'' | grep -v virtfs);
  if [[ -n $virtflag  ]]; then
  perc=$(df -i | awk 'NR == '$i' {print $5}' | cut -d '%' -f1);
  
    #A mensagem é exibida verde se estiver abaixo de 90%
    if [[ $perc -lt 90 ]]; then
      export GREP_COLOR='1;32'
      df -i | awk 'NR == '$i'' | egrep -i --color=auto [a-z?0-9]+%
      export GREP_COLOR='01;31'
    else
      #A mensagem é exibida amarela se estiver entre 90-94%
      if [[ $perc -lt 95 ]]; then
        export GREP_COLOR='1;33'
        df -i | awk 'NR == '$i'' | egrep -i --color=auto [a-z?0-9]+%
        export GREP_COLOR='01;31'
      else
        #A mensagem é exibida vermelha
        df -i | awk 'NR == '$i'' | egrep -i --color=auto [a-z?0-9]+%
      fi
    fi
  fi
done;

if [[ -f /usr/local/lib/php.ini ]]; then
echo -e "\n$H1===========$H2 PHP.ini Global $H1===========$RS\n"; 
if [ ! -f /usr/local/lib/php.ini ]
then
        echo " O arquivo php.ini não existe. Isso é mal, muito mal..."
else
memlimit=$(egrep ^memory_limit /usr/local/lib/php.ini | awk '{print $3}' | cut -d 'M' -f1);
host=$(hostname | egrep 'dizinc.com|surpasshosting.com|hasweb.com|hostdime.co.uk');
  if [[ ! -z $host ]]; then
    if [[ $memlimit > 64 ]]; then
      echo -e "${W1}memory_limit = $R2 ${memlimit}M $RS";
    else
      echo -e "${W1}memory_limit = $G1${memlimit}M $RS";
    fi
  else
    if [[ $memlimit > 64 ]]; then
      echo -e "${W1}memory_limit = $R2 ${memlimit}M $RS";
    else
      echo -e "${W1}memory_limit = $G1${memlimit}M $RS";
    fi
  fi
fi
        egrep ^max_execution_time /usr/local/lib/php.ini
        egrep ^max_input_time /usr/local/lib/php.ini
        egrep ^post_max_size /usr/local/lib/php.ini
        egrep ^magic_quotes_gpc /usr/local/lib/php.ini
        egrep ^upload_max_filesize /usr/local/lib/php.ini
        egrep ^allow_url_fopen /usr/local/lib/php.ini
        egrep ^date.timezone /usr/local/lib/php.ini
        egrep ^disable_functions /usr/local/lib/php.ini
fi

echo -e "\n$H1===========$H2 my.cnf (MySQL) $H1===========$RS\n"; 
if [ -f /etc/my.cnf ]; then

        egrep ^key_buffer /etc/my.cnf
        egrep ^max_connections /etc/my.cnf
        egrep ^max_user_connections /etc/my.cnf
        egrep ^max_allowed_packet /etc/my.cnf
        egrep ^wait_timeout /etc/my.cnf
        egrep ^innodb_buffer_pool_size /etc/my.cnf
        egrep ^innodb_log_file_size /etc/my.cnf

else
        echo " O arquivo my.cnf não existe. ";

fi

echo -e "\n$H1===========$H2 httpd.conf (Apache) $H1===========$RS\n"; 
egrep -wi 'ServerLimit|^MaxRequestWorkers|^MaxClients|^KeepAlive|^MinSpareServers|^MaxSpareServers|^StartServers|^MaxConnectionsPerChild' /etc/httpd/conf/httpd.conf;


echo -e "\n$H1===========$H2 Uso de Memória $H1===========$RS\n"; 
free -m;


echo -e "\n$H1===========$H2 Utilização Real da Memória $H1===========$RS\n";
bash <(curl -ks https://codex.hostdime.com/scripts/download/realsarmemawk) | tail -10
echo -e "\n$G1 Se desejar ver completo, rode o script: python <(curl -ks https://codex.hostdime.com/scripts/download/realmemsar) $RS";


#Numero de processos que estão em execução
echo -e "\n$H1===========$H2 Numero de processos que estão em execução $H1===========$RS\n";


# Processos que estão: em execução, dormindo, parado ou como zombie.
top -n 1 | grep Tasks;


# new line takes out common server background processes
processesamount=$(ps -ef | grep -v migration | egrep -v "\[*\]" | wc -l);
if [[ -n $processesamount ]]; then
    
  if [[ $processesamount -le 249 ]]; then
      echo -e "\n $W1 O número de processos é baixo $RS = $G1 $processesamount $RS"
  else
    if [[ $processesamount -le 350 ]]; then
      echo -e " $W1 O número de processos é medio $RS = $Y1 $processesamount $RS"
    else
      if [[ $processesamount -le 450 ]]; then
        echo -e " $W1 O número de processos é alto $RS =$R1 $processesamount $RS"
    else
      if [[ $processesamount -ge 451 ]]; then
        echo -e " $W1 O número de processos está MUITO ALTO ! $RS =$BAD $processesamount $RS"
      fi
      fi
    fi
  fi
fi

httpdprocs=$(ps faux | grep "httpd" | grep -v "grep" | wc -l);
echo -e "\n $W1 Número de processos do Apache :$RS $httpdprocs $RS"; 

phpprocs=$(ps faux | grep "php" | grep -v "grep" | wc -l);
echo -e "\n $W1 Número de processos do PHP :$RS $phpprocs $RS";

imapprocs=$(ps faux | grep "dovecot/imap" | grep -v "grep" | wc -l);
echo -e "\n $W1 Número de processos do IMAP :$RS $imapprocs $RS";

popprocs=$(ps faux | grep "dovecot/pop" | grep -v "grep" | wc -l);
echo -e "\n $W1 Número de processos do POP:$RS $popprocs $RS";

#Existe alguma conta com muitos processos ?

echo -e "\n$H1===========$H2 Quantidade de processos em execução por conta $H1===========$RS\n";
ps aux | awk {'print $1'} | sort | uniq -c  | sort -n | tail -20;

echo -e "\n$H1===========$H2 Domínios com mais requisições ao wp-login $H1===========$RS\n";

bash <(curl -ks https://codex.hostdime.com/scripts/download/checkwplogin)

echo -e "\n$H1===========$H2 Domínios com mais requisições ao xmlrpc $H1===========$RS\n";

bash <(curl -ks https://codex.hostdime.com/scripts/download/checkxmlrpc)

echo -e "\n$H1===========$H2  Contas que mais utilizam recursos de CPU, MySQL e Memória $H1===========$RS\n"; 

OUT=$(/usr/local/cpanel/bin/dcpumonview | grep -v Top | sed -e 's#<[^>]*># #g' | while read i ; do NF=`echo $i | awk {'print NF'}` ; if [[ "$NF" == "5" ]] ; then USER=`echo $i | awk {'print $1'}`; OWNER=`grep -e "^OWNER=" /var/cpanel/users/$USER | cut -d= -f2` ; echo "$OWNER $i"; fi ; done) ; (echo "USER CPU" ; echo "$OUT" | sort -nrk4 | awk '{printf "%s %s%\n",$2,$4}' | head -5) | column -t ; echo; (echo -e "USER MEMORY" ; echo "$OUT" | sort -nrk5 | awk '{printf "%s %s%\n",$2,$5}' | head -5) | column -t;  echo; (echo -e "USER MYSQL" ; echo "$OUT" | sort -nrk6 | awk '{printf "%s %s%\n",$2,$6}' | head -5) | column -t;


echo -e "\n$H1===========$H2 Lista dos 10 processos que mais estão consumindo CPU $H1===========$RS\n"; 
ps -e -o pcpu,pid,user,args|sort -k1 -nr|head -10;

echo -e "\n$H1===========$H2 Lista dos 10 processos que mais estão consumindo Memória  $H1===========$RS\n";
ps -e -o pmem,pid,user,args|sort -k1 -nr|head -10;


# VPS Failtcount
bash <(curl -ks https://codex.hostdime.com/scripts/download/beancheck1);
 

echo -e "\n$H1===========$H2 Existe algum Cron rodando ? $H1===========$RS\n"; 
ps faux | grep -i cron | grep -v grep;

echo -e "\n$H1===========$H2 Logs recentes do Axon $H1===========$RS\n"; 
    \ls -lt /var/log/axond/ | awk '{print $6, $7, $8, $9}' | tail -10;

echo -e "\n$H1===========$H2 Domínios com mais hits hoje  $H1===========$RS\n"; 

echo -e "\n$Y1 Processando ...$RS\n";

current_d=$(LC_TIME=en_US date +"%d\/%B\/%Y")
for i in `cat /etc/userdomains | cut -f1 -d":"`; do for j in `grep $i /etc/userdomains | cut -f2 -d":" | tail -n1`; do VALOR=$(grep $i /var/log/apache2/domlogs/$j/* | grep $current_d | wc -l) && echo "$i : $VALOR"; done; done > /root/tmp_hits_file.txt 2>/dev/null
cat /root/tmp_hits_file.txt | tr -s " " | awk '!/^$/' | tr -d '[:blank:]' | sort -n -k 2,2 -k 1,1 -t ":" | tail -n5
rm -rf /root/tmp_hits_file.txt


# Antigo script de hitsbash <(curl -ks https://codex.hostdime.com/scripts/download/topfivedomains)

