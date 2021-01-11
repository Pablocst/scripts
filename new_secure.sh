#!/bin/bash
#Joe B.

# Merged with jsecuredediclone and added checks for csf
# in order to unify script
# Andrew D.

#Some checks
if [ "$UID" -ne "0" ]; then
        echo "You must be root to run this script."
        exit 1
fi


# check if cpanel server
CPANEL=1
if ! [[ -d /usr/local/cpanel || -d /var/cpanel ]];then
    CPANEL=0
fi


#Initialize Values
FANT=0
RVSKIN=0
CLICKBE=0


#Get Arguments
while getopts "frc" OPTION
do
     case $OPTION in
         f)
             FANT=1
             ;;
         r)
             RVSKIN=1
             ;;
         c)
             CLICKBE=1
             ;;
     esac
done

cd ~

touch /etc/motd
mv /etc/motd /etc/motd.securebak
wget legal.hostdime.com/scripts/motd.txt -O /etc/motd

#Do initial NTP sync for puppet certs to work, etc. 
ntpdate -buv tk.dimenoc.com

#Send Secure Started Email ~ArielP
HDNUM="$(curl "https://core.hostdime.com/auth/ip-to-hd/ip/$(hostname -i | head -n1)" -k 2>/dev/null)"

# csf boolean
CSF=$(curl --silent "https://core.hostdime.com/auth/hasswfw/id/$HDNUM")

if [ -n "${HDNUM}" -a -n "${SECURETAG}" ];
then
	SECURETAG="${HDNUM}-${SECURETAG}"
elif [ -n "${HDNUM}" -a -z "${SECURETAG}" ];
then
	SECURETAG="${HDNUM}"
elif [ -z "${HDNUM}" -a -z "${SECURETAG}" ];
then
	SECURETAG=`hostname -i`
fi

#Notificação desativada
#cat << NEOF | sendmail -t -i
#From: secure.sh <root@$HOSTNAME>
#To: Abuse Team <abuseteam@hostdime.com>
#Subject: ($SECURETAG) New Dedicated Server Secure Started

#server secure execution has started
#NEOF


#secure /etc/fstab
sed -i.BAK -r -e '/\/dev\/shm/d' -e '/\/tmp/s@defaults@rw,nosuid,nodev,auto,nouser,async,noatime,nodiratime,noexec@' -e '/\/(boot|backup)?[ \t]+/s@defaults@defaults,noatime@' /etc/fstab
umount /dev/shm
umount /var/tmp
for i in / /boot /tmp /backup; do mount -o remount $i; done

if [[ `grep 'usrjquota=quota.user,jqfmt=vfsv0' /etc/fstab` ]]; then
	sed -i.BAK -r -e '/\/[ \t]+/s@usrjquota=quota.user,jqfmt=vfsv0@noatime,usrjquota=quota.user,jqfmt=vfsv0@' /etc/fstab
	if [[ `mount -o remount / 2>&1` ]]; then 
		mv /etc/fstab.BAK /etc/fstab
		mount -o remount /
	fi
fi


#config history
if [ ! -f "/etc/profile.d/history.sh" ];then
	cat > /etc/profile.d/history.sh << NEOF
export HISTTIMEFORMAT="[%F %T] - "
unset HISTCONTROL
unset HISTIGNORE
export HISTFILESIZE=9999999999999
export HISTSIZE=9999999999999
export HISTIGNORE="*codex.hostdime.com*:*codex.dimenoc.com*:*codesilo.hostdime.com*:*codesilo.dimenoc.com*:*legal.hostdime.com*"
NEOF
fi

#Harden my.cnf
#rm -vf /var/lib/mysql/ib_logfile*
cp /etc/my.cnf{,.orig}
cat > /etc/my.cnf << NEOF
[mysqld]
bind-address=127.0.0.1
datadir="/var/lib/mysql"
socket="/var/lib/mysql/mysql.sock"
user=mysql
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
default-storage-engine=MyISAM
innodb_file_per_table=1
open_files_limit=10000
key_buffer_size = 128M
max_allowed_packet = 16M
max_connections = 100
max_user_connections = 25
wait_timeout=40
connect_timeout=10
sort_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
myisam_sort_buffer_size = 64M
thread_cache_size = 32
query_cache_size = 32M
query_cache_limit = 16M
query_cache_type = 1
innodb_fast_shutdown = 0
innodb_log_file_size = 1500M
server-id = 1

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
NEOF

#killall -9 mysqld safe_mysqld mysqld_safe 2>/dev/null
#pkill -9 mysql 
#pkill -9 mysqld

#service mysql start
/scripts/restartsrv_mysql

#Deixei o audit e o adutd habilitados pois acredito que sejam importantes
#Disable unnecessary services.
for SERVICE in autofs pcscd cups cups-config-daemon xfs netfs irda isdn nfs nfslock rhnsd anacron tux ip6tables mdmonitor bluetooth portreserve rpcbind rpcidmapd rpcsvcgssd rpcgssd canna iiim avahi-daemon hidd gpm portmap
do
        service "$SERVICE" stop > /dev/null 2>&1
        chkconfig "$SERVICE" off > /dev/null 2>&1
done

# Disable xinetd
echo -n "Disabling all xinetd services except cpimap.. "
cd /etc/xinetd.d
for i in *
do
        [ "$i" != "cpimap" ] && sed -i 's/^[ \t]*disable.*/disable = yes/' /etc/xinetd.d/$i
done
echo ".. Done"

# Install CSF for all cPanel servers or if CSF addon is present
if [ "$CSF" = "1" -o "$CPANEL" = "1" ];then

	if [[ ! -f "/usr/sbin/csf" ]]; then 
		cd /usr/src
		wget https://download.configserver.com/csf.tgz -O /usr/src/csf.tgz --no-check-certificate
		if [ ! -f "csf.tgz" ]; then
			echo "Error: CSF not downloaded." 
		else
				tar -zxvf csf.tgz
				cd csf/
				sh install.sh
				cd ..
				rm -rf csf/ csf.tgz
		fi
	fi
	
    cat >> /etc/csf/csf.ignore << NEOF
### DimeNOC Support IPs
# Down Town office IP added on 8/20/2019 by Yoshi Q.
72.29.72.130
72.29.76.254
72.29.91.30
72.29.91.42
72.29.95.155
72.29.95.172
50.88.15.90
###
NEOF

    #Set correct CSF settings
    if [ ! -f "/etc/csf/csf.conf" ]; then
            echo "Error: CSF config not found."
    else
            if [ -f /bin/sed ]; then
                    echo "$HOSTNAME - MAKING MODIFICATIONS TO /etc/csf/csf.conf!"
		    sed -i 's@TESTING = "1"@TESTING = "0"@' /etc/csf/csf.conf
		    sed -i 's@AUTO_UPDATES ="0"@AUTO_UPDATES = "1"@' /etc/csf/csf.conf
		    sed -i 's@LF_MODSEC = "5"@LF_MODSEC = "0"@' /etc/csf/csf.conf
		    sed -i 's@LF_MODSEC_PERM = "1"@LF_MODSEC_PERM = "0"@' /etc/csf/csf.conf
		    sed -i 's@SMTP_BLOCK = "0"@SMTP_BLOCK = "1"@' /etc/csf/csf.conf
		    sed -i 's@SMTP_ALLOWLOCAL = "0"@SMTP_ALLOWLOCAL = "1"@' /etc/csf/csf.conf
		    sed -i 's@SMTP_PORTS = "25"@SMTP_PORTS = "25,26"@' /etc/csf/csf.conf
		    sed -i 's@TCP_OUT = "@TCP_OUT = "8140,3306,@' /etc/csf/csf.conf
		    sed -i 's@TCP_IN = "@TCP_IN = "30000:32000,3306,@' /etc/csf/csf.conf
                    sed -i 's@PT_LIMIT = "60"@PT_LIMIT = "240"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_TRIGGER[[:space:]]*=[[:space:]]*.*$@LF_TRIGGER = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_TRIGGER_PERM[[:space:]]*=[[:space:]]*.*$@LF_TRIGGER_PERM = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SELECT[[:space:]]*=[[:space:]]*.*$@LF_SELECT = "1"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SSHD[[:space:]]*=[[:space:]]*.*$@LF_SSHD = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SSHD_PERM[[:space:]]*=[[:space:]]*.*$@LF_SSHD_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_FTPD[[:space:]]*=[[:space:]]*.*$@LF_FTPD = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_FTPD_PERM[[:space:]]*=[[:space:]]*.*$@LF_FTPD_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SMTPAUTH[[:space:]]*=[[:space:]]*.*$@LF_SMTPAUTH = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SMTPAUTH_PERM[[:space:]]*=[[:space:]]*.*$@LF_SMTPAUTH_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_POP3D[[:space:]]*=[[:space:]]*.*$@LF_POP3D = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_POP3D_PERM[[:space:]]*=[[:space:]]*.*$@LF_POP3D_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_IMAPD[[:space:]]*=[[:space:]]*.*$@LF_IMAPD = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_IMAPD_PERM[[:space:]]*=[[:space:]]*.*$@LF_IMAPD_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_HTACCESS[[:space:]]*=[[:space:]]*.*$@LF_HTACCESS = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_HTACCESS_PERM[[:space:]]*=[[:space:]]*.*$@LF_HTACCESS_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_MODSEC[[:space:]]*=[[:space:]]*.*$@LF_MODSEC = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_MODSEC_PERM[[:space:]]*=[[:space:]]*.*$@LF_MODSEC_PERM = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_CPANEL[[:space:]]*=[[:space:]]*.*$@LF_CPANEL = "30"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_CPANEL_PERM[[:space:]]*=[[:space:]]*.*$@LF_CPANEL_PERM = "10800"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SUHOSIN[[:space:]]*=[[:space:]]*.*$@LF_SUHOSIN = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_SUHOSIN_PERM[[:space:]]*=[[:space:]]*.*$@LF_SUHOSIN_PERM = "1"@' /etc/csf/csf.conf
                    sed -i -r 's@^LF_INTERVAL[[:space:]]*=[[:space:]]*.*$@LF_INTERVAL = "300"@' /etc/csf/csf.conf
                    sed -i -r 's@^LT_POP3D[[:space:]]*=[[:space:]]*.*$@LT_POP3D = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^LT_IMAPD[[:space:]]*=[[:space:]]*.*$@LT_IMAPD = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^CT_LIMIT[[:space:]]*=[[:space:]]*.*$@CT_LIMIT = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^PT_DELETED[[:space:]]*=[[:space:]]*.*$@PT_DELETED = "0"@' /etc/csf/csf.conf
                    sed -i -r 's@^ICMP_IN_RATE[[:space:]]*=[[:space:]]*.*$@ICMP_IN_RATE = "50/s"@' /etc/csf/csf.conf
                    sed -i -r 's@^PS_INTERVAL[[:space:]]*=[[:space:]]*.*$@PS_INTERVAL = "0"@' /etc/csf/csf.conf

                    #Add spamd ignore
                    if [ -f "/etc/exim.conf.localopts" ] && [ ! "`grep 'cmd:spamd child' /etc/csf/csf.pignore`" ]; then
                            echo "cmd:spamd child" >> /etc/csf/csf.pignore
                    fi

                    echo "$HOSTNAME - Restarting CSF and LFD!"
                    service csf restart > /dev/null
                    if [ $! ]; then
                            echo "$HOSTNAME - Error restarting CSF!"
                    fi
                    service lfd restart > /dev/null
                    if [ $! ]; then
                            echo "$HOSTNAME - Error restarting LFD!"
                    fi
            else
                    echo "$HOSTNAME - Error: /bin/sed not available!"
            fi


    fi

    if [[ ! -f "/usr/sbin/csf" ]]; then
	#Enable SMTP Tweak if no CSF
	/scripts/smtpmailgidonly on
    else
        /scripts/smtpmailgidonly off
    fi

    csf -u
    csf -r

fi # END CSF

cd ~
yum -y update

#Copy 3rd party drivers as necessary to new kernel
#By Joe B.
MYCURRKERNEL=`uname -r`;
MYNEWKERNEL=`grep -m1 'kernel /vmlinuz-[0-9]' /boot/grub/grub.conf | cut -f2-3 -d '-' | awk '{print $1}'`;
if [[ "$MYCURRKERNEL" != "$MYNEWKERNEL" ]]; then
	if [[ -f "/lib/modules/$MYCURRKERNEL/kernel/drivers/scsi/rr26xx/rr26xx.ko" && ! -f "/lib/modules/$MYNEWKERNEL/kernel/drivers/scsi/rr26xx/rr26xx.ko" ]]; then
			if [[ ! -d "/lib/modules/$MYNEWKERNEL/kernel/drivers/scsi/rr26xx" ]]; then
					mkdir "/lib/modules/$MYNEWKERNEL/kernel/drivers/scsi/rr26xx";
			fi
			cp /lib/modules/$MYCURRKERNEL/kernel/drivers/scsi/rr26xx/rr26xx.ko /lib/modules/$MYNEWKERNEL/kernel/drivers/scsi/rr26xx/rr26xx.ko;
			if [[ ! `grep rr26xx.ko /lib/modules/$MYNEWKERNEL/modules.dep` ]]; then
					echo "/lib/modules/$MYNEWKERNEL/kernel/drivers/scsi/rr26xx/rr26xx.ko" >>  /lib/modules/$MYNEWKERNEL/modules.dep
			fi
			if [[ ! `grep atl1e /lib/modules/$MYNEWKERNEL/modules.pcimap` ]]; then
					echo -e "rr26xx               0x00001103 0x00002640 0xffffffff 0xffffffff 0x00000000 0x00000000 0x0\nrr26xx               0x00001103 0x00002620 0xffffffff 0xffffffff 0x00000000 0x00000000 0x0" >> /lib/modules/$MYNEWKERNEL/modules.pcimap
			fi
			/sbin/new-kernel-pkg --package kernel --mkinitrd --depmod --install $MYNEWKERNEL
	fi
	if [[ -f "/lib/modules/$MYCURRKERNEL/kernel/drivers/net/atl1e/atl1e.ko" ]]; then
			if [[ ! -d "/lib/modules/$MYNEWKERNEL/kernel/drivers/net/atl1e/" ]]; then
					mkdir "/lib/modules/$MYNEWKERNEL/kernel/drivers/net/atl1e/";
			fi
			cp /lib/modules/$MYCURRKERNEL/kernel/drivers/net/atl1e/atl1e.ko /lib/modules/$MYNEWKERNEL/kernel/drivers/net/atl1e/atl1e.ko;
			if [[ ! `grep atl1e.ko /lib/modules/$MYNEWKERNEL/modules.dep` ]]; then
					echo "/lib/modules/$MYNEWKERNEL/kernel/drivers/net/atl1e/atl1e.ko" >>  /lib/modules/$MYNEWKERNEL/modules.dep
			fi
			if [[ ! `grep atl1e /lib/modules/$MYNEWKERNEL/modules.pcimap` ]]; then
					echo -e "atl1e                0x00001969 0x00001026 0xffffffff 0xffffffff 0x00000000 0x00000000 0x0\natl1e                0x00001969 0x00001066 0xffffffff 0xffffffff 0x00000000 0x00000000 0x0" >> /lib/modules/$MYNEWKERNEL/modules.pcimap
			fi
	fi
fi

# Cpanel only
if [ $CPANEL -eq 1 ];then    
	#Install mod_security config

        ######
        #DEPRECATED MODSEC CONFIG
	#rm /etc/httpd/conf/modsec2.user.conf -rf
	#rm /etc/httpd/conf/modsec2.conf -rf
	#wget legal.hostdime.com/modsec2.user.conf -O /etc/httpd/conf/modsec2.user.conf
	#wget legal.hostdime.com/modsec2.conf -O /etc/httpd/conf/modsec2.conf
	#touch /usr/local/apache/conf/modsec2.custom.local.conf

	#if [[ ! -f /etc/cron.daily/modsec2_upd_new ]]; then
	#	wget legal.hostdime.com/modsec2_upd_new -O /etc/cron.daily/modsec2_upd_new
	#	chmod 755 /etc/cron.daily/modsec2_upd_new 
	#fi
        ######

        #Install Dependencies to /etc/modsecurity/
        if ! [ -d /etc/modsecurity/ ]; then
            if [ -f /root/modsecurity.tar.gz ]; then
                rm -f /root/modsecurity.tar.gz
            fi

            wget --no-verbose http://legal.hostdime.com/modsecurity/modsecurity.tar.gz -O /root/modsecurity.tar.gz
            if [ -f /root/modsecurity.tar.gz ]; then
                gzip -d /root/modsecurity.tar.gz
                tar xf /root/modsecurity.tar -C /etc/
                rm -f /root/modsecurity.tar
            fi
        fi

        #Install New ModSec Vendor 
        /scripts/modsec_vendor add http://legal.hostdime.com/modsecurity/meta_HOSTDIME.yaml

	/scripts/restartsrv_httpd

	#Upgrade mysql
	/scripts/mysqlup
	/scripts/perlinstaller Bundle::DBD::mysql

    #Configure Exim settings
    /bin/bash -ic "/usr/local/cpanel/whostmgr/bin/whostmgr2 ./saveeximtweaks" &> /dev/null
    cat <<NEOF | while read item value; do sed -r -i -e "s@^[ \t]*${item}[ \t]*=.*\$@${item}=${value}@" /etc/exim.conf.localopts; grep -qE '^[ \t]*'"${item}"'[ \t]*=' /etc/exim.conf.localopts || echo "${item}=${value}" >> /etc/exim.conf.localopts; done
acl_0tracksenders 1
acl_deny_rcpt_hard_limit 30
acl_deny_rcpt_soft_limit 25
acl_deny_spam_score_over_200 1
acl_deny_spam_score_over_int 200
acl_dictionary_attack 1
acl_dkim_disable 1
acl_dkim_bl 0
acl_mailproviders 0
acl_primary_hostname_bl 1
acl_ratelimit 1
acl_ratelimit_spam_score_over_200 1
acl_ratelimit_spam_score_over_int 200
acl_requirehelo 1
acl_requirehelonoforge 1
acl_requirehelosyntax 1
acl_spamhaus_rbl 1
acl_spamcop_rbl 1
acl_spammerlist 1
acl_trustedmailhosts 0
allowweakciphers 0
callouts 0
filter_attachments 1
filter_spam_rewrite 1
malware_deferok 1
quotadiscard 1
senderverify 1
setsenderheader 1
spam_deferok 1
spam_header ***SPAM***
systemfilter /etc/cpanel_exim_system_filter
require_secure_auth 1
NEOF
    /scripts/buildeximconf
    /scripts/restartsrv_exim

    #Add DimeNOC global scores for Spamassassin
    wget legal.hostdime.com/dimenoc.cf -O /etc/mail/spamassassin/dimenoc.cf

    #Do updates
    cpan -i XML::SAX::Expat
    cpan -i DBD::SQLite
    /scripts/sysup
    /scripts/rpmup
    perl /scripts/upcp

    if [ "$FANT" = "1" ]; then
        #Install Fantastico
        cd /usr/local/cpanel/whostmgr/docroot/cgi 
        wget -N http://files.betaservant.com/files/free/fantastico_whm_admin.tgz
        if [ ! -f "fantastico_whm_admin.tgz" ]; then
            echo "Error: Fantastico not downloaded."
        else
            tar -xzpf fantastico_whm_admin.tgz 
            rm -rf fantastico_whm_admin.tgz
            if [[ $(grep 'CentOS release 5' /etc/redhat-release) ]]; then
                rpm -qa wget ;
                wget ftp://ftp.funet.fi/pub/mirrors/ftp.redhat.com/pub/fedora/linux/core/5/`uname -i`/os/Fedora/RPMS/wget-1.10.2-3.2.1.`uname -i`.rpm
                if [ ! -f "wget-1.10.2-3.2.1.`uname -i`.rpm" ]; then
                    echo "Error: Wget not downloaded."
                else

                    chattr -ia /usr/bin/wget
                    rpm -e wget ;
                    rpm -ivh --force wget-1.10.2-3.2.1.`uname -i`.rpm ;
                    rpm -qa wget ;
                    echo "Fantastico installed...Please configure within WHM"
                fi
            fi
        fi
    fi

    if [ "$RVSKIN" = "1" ]; then
        #Install RVskin
        mkdir /root/rvadmin
        cd /root/rvadmin
        wget http://download.rvglobalsoft.com/download.php/download/rvskin-auto/saveto/rvauto.tar.bz2
        if [ ! -f "rvauto.tar.bz2" ]; then
            echo "Error: RVskin not downloaded."
        else
            bunzip2 -d rvauto.tar.bz2
            tar -xvf rvauto.tar
            perl /root/rvadmin/auto_rvskin.pl -p="`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`"
            rm rvauto.tar -f
            echo "RVskin installed...Please configure within WHM"

        fi
    fi

    if [ "$CLICKBE" = "1" ]; then
        #Install Clickbe
        mkdir -p /var/netenberg/click_be/installer/
        cd /var/netenberg/click_be/
        wget http://www.netenberg.com/files/click_be/free/click_be_installer.bz2
        if [ ! -f "click_be_installer.bz2" ]; then
            echo "Error: Clickbe not downloaded."
        else
            tar -xjpf click_be_installer.bz2
            cd /var/netenberg/click_be/installer/
            php click_be.php status
            php click_be.php update
        
            if [ "$(/usr/local/cpanel/bin/rebuild_phpconf --current | grep "PHP`/usr/local/cpanel/bin/rebuild_phpconf --current | grep DEFAULT | awk '{print $3}'` SAPI" | awk '{print $3}')" = "suphp" ]; then
            #Set SuEXEC in ClickBE Config
            sed -i "`grep "\[suEXEC\]" /var/netenberg/click_be/settings/public_settings.ini  -n -A 50  | grep "Status" -m 1 | cut -f 1 -d '-'` s/Status = \"Off\"/Status = \"On\"/" /var/netenberg/click_be/settings/public_settings.ini
            fi
        
        
            php click_be.php install
            php click_be.php cron install;
            php click_be.php status

        fi
    fi

	#Update Tweak Settings
	if [[ ! `grep 'maxemailsperhour=350' /var/cpanel/cpanel.config` ]]; then 
		sed -i '/maxemailsperhour/d' /var/cpanel/cpanel.config; 
		echo 'maxemailsperhour=350' >> /var/cpanel/cpanel.config; 
	fi
	
	if [[ ! `grep 'defaultmailaction=fail' /var/cpanel/cpanel.config` ]]; then 
		sed -i '/defaultmailaction/d' /var/cpanel/cpanel.config; 
		echo 'defaultmailaction=fail' >> /var/cpanel/cpanel.config; 
	fi
	
	if [[ ! `grep 'email_send_limits_count_mailman=1' /var/cpanel/cpanel.config` ]]; then 
		sed -i '/email_send_limits_count_mailman/d' /var/cpanel/cpanel.config; 
		echo 'email_send_limits_count_mailman=1' >> /var/cpanel/cpanel.config; 
	fi
	
	#Track email origin via X-Source email headers
	if [[ ! `grep 'eximmailtrap=1' /var/cpanel/cpanel.config` ]]; then 
		sed -i '/eximmailtrap/d' /var/cpanel/cpanel.config; 
		echo 'eximmailtrap=1' >> /var/cpanel/cpanel.config; 
	fi

    #Update WHM settings / apply Exim changes, etc
    #This has to be last as it breaks out of the bash script once this executes
    #NOT ANYMORE ~ARIELP
    #/bin/bash -ic "/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings"
    /usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings

    #Clean up queueprocd in ChkServ.d for cPanel < 11.25
    if [ "$(cut -f2 -d. /usr/local/cpanel/version)" -lt "25" ]; then 
	mv /etc/chkserv.d/queueprocd /root/_etc_chkserv.d_queueprocd.bak 
	sed -i.BAK '/queueprocd/d' /etc/chkserv.d/chkservd.conf 
    fi


    set disabled features list
    cat <<neof >> /var/cpanel/features/disabled
advguest=0
analog=0
boxtrapper=0
defaultaddress=0
frontpage=0
neof
    sort /var/cpanel/features/disabled | uniq > /var/cpanel/features/disabled.new
    mv -f /var/cpanel/features/disabled.new /var/cpanel/features/disabled

    #disable root password logins through FTP
    sed -i -e "s/RootPassLogins:.*yes.*/RootPassLogins: 'no'/g" -e "s@NoAnonymous:.*no.*@NoAnonymous: 'yes'@g" -e "s@AnonymousCantUpload:.*no.*@AnonymousCantUpload: 'yes'@g" /var/cpanel/conf/pureftpd/main

    #Set Passive Mode to use ports 30000 to 32000
    if [[ `grep PassivePortRange /var/cpanel/conf/pureftpd/main` ]]; then
        sed -i -e "s/PassivePortRange:.*/PassivePortRange: 30000 32000/g" /var/cpanel/conf/pureftpd/main
    else
        echo "PassivePortRange: 30000 32000" >> /var/cpanel/conf/pureftpd/main
    fi
    /usr/local/cpanel/whostmgr/bin/whostmgr2 ./doftpconfiguration


fi # END CPANEL



#update rkhunter
wget http://legal.hostdime.com/scripts/rkhunter.sh -O rkhunter.sh
if [ ! -s "rkhunter.sh" ]; then
	echo "Error: rkhunter not downloaded."
else
	sh rkhunter.sh && rm -f rkhunter.sh
fi


#Activate SFTP logging
if ( [ -e /etc/ssh/sshd_config ] && [ -z "$(sed -n -r -e '/[Ss]ubsystem[ \t]+sftp[ \t]+.*sftp-server.*VERBOSE/p' /etc/ssh/sshd_config)" ] );
then
	sed -r -i.BAK -e '/[Ss]ubsystem[ \t]+sftp[ \t]+.*sftp-server\b/s@(.*)sftp-server\b(.*)$@\1sftp-server\2 -l VERBOSE@' /etc/ssh/sshd_config
	service sshd restart
fi


#Ensure BusyBox is safeguarded if it is installed
if rpm -q busybox &>/dev/null;
then
	SECTARGET="$(rpm -q -l busybox | grep -m 1 bin)"
	if [[ -s "${SECTARGET}" ]];
	then
		if [[ "$(stat -c %a "${SECTARGET}")" -ne 500 ]];
		then
			chattr -ia "${SECTARGET}"
			chmod 0500 "${SECTARGET}"
		fi
		if [[ "$(lsattr "${SECTARGET}" | tr -d '-' | cut -f1 -d\ )" != "ia" ]];
		then
			chattr =ia "${SECTARGET}"
		fi
		if ! grep -Eq '^exclude=.*busybox\*' /etc/yum.conf;
		then
			sed -r -i -e '/^exclude=/s@^exclude=(.*)$@exclude=\1 busybox*@' /etc/yum.conf
		fi
	fi
fi


#Update PHP settings
if [ ! -f "/usr/local/lib/php.ini" ]; then
        echo "Error: /usr/local/lib/php.ini not found."
else
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /usr/local/lib/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /usr/local/lib/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /usr/local/lib/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /usr/local/lib/php.ini
        fi
        grep -E "allow_url|disable_function" /usr/local/lib/php.ini
fi

if [ -f "/usr/local/php4/lib/php.ini" ]; then

        echo "PHP4 found, correcting settings in PHP4"
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /usr/local/php4/lib/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /usr/local/php4/lib/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /usr/local/lib/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /usr/local/php4/lib/php.ini
#PHP4 php.ini path typo fixed by Ariel P 2009-10-17
        fi
        grep -E "allow_url|disable_function" /usr/local/php4/lib/php.ini

fi

#Update EA4 PHP settings
if [ -f "/opt/cpanel/ea-php54/root/etc/php.ini" ]; then
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php54/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php54/root/etc/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php54/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php54/root/etc/php.ini
        fi
        grep -E "allow_url|disable_function" /opt/cpanel/ea-php54/root/etc/php.ini
fi

if [ -f "/opt/cpanel/ea-php55/root/etc/php.ini" ]; then
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php55/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php55/root/etc/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php55/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php55/root/etc/php.ini
        fi
        grep -E "allow_url|disable_function" /opt/cpanel/ea-php55/root/etc/php.ini
fi

if [ -f "/opt/cpanel/ea-php56/root/etc/php.ini" ]; then
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php56/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php56/root/etc/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php56/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php56/root/etc/php.ini
        fi
        grep -E "allow_url|disable_function" /opt/cpanel/ea-php56/root/etc/php.ini
fi

if [ -f "/opt/cpanel/ea-php70/root/etc/php.ini" ]; then
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php70/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php70/root/etc/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php70/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php70/root/etc/php.ini
        fi
        grep -E "allow_url|disable_function" /opt/cpanel/ea-php70/root/etc/php.ini
fi

if [ -f "/opt/cpanel/ea-php71/root/etc/php.ini" ]; then
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php71/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php71/root/etc/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php71/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php71/root/etc/php.ini
        fi
        grep -E "allow_url|disable_function" /opt/cpanel/ea-php71/root/etc/php.ini
fi

if [ -f "/opt/cpanel/ea-php72/root/etc/php.ini" ]; then
        if [ -f /bin/sed ] && ( [ "$CLICKBE" = "0" ] && [ "$FANT" = "0" ] && [ "$RVSKIN" = "0" ] ); then

                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php72/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, shell_exec, system, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php72/root/etc/php.ini
        fi
        if [  -f /bin/sed ] && ( [ "$CLICKBE" = "1" ] || [ "$FANT" = "1" ] || [ "$RVSKIN" = "1" ] ); then
                sed -i 's@allow_url_fopen = On@allow_url_fopen = Off@' /opt/cpanel/ea-php72/root/etc/php.ini

                sed -i 's@^disable_functions =.*$@disable_functions = dl, exec, passthru, popen, pclose, proc_open, proc_nice, proc_terminate, proc_get_status, proc_close, pfsockopen, leak, apache_child_terminate, posix_kill, posix_mkfifo, posix_setpgid, posix_setsid, posix_setuid@' /opt/cpanel/ea-php72/root/etc/php.ini
        fi
        grep -E "allow_url|disable_function" /opt/cpanel/ea-php72/root/etc/php.ini
fi

#Configure Yum Automatic Updates
if [ ! -s "/etc/init.d/yum-updatesd" -o ! -s "/etc/yum/yum-updatesd.conf" ];
then
    echo "Installing Yum-Updatesd"
    yum -y install yum-updatesd
fi
echo "Editing Yum-Updatesd Configuration"
sed -r -i -e 's@^[ \t]*run_interval[ \t]*=.*@run_interval = 43200@' -e 's@^[ \t]*updaterefresh[ \t]*=.*@updaterefresh = 3600@' -e 's@^[ \t]*emit_via[ \t]*=.*@emit_via = syslog@' -e 's@^[ \t]*dbus_listener[ \t]*=.*@dbus_listener = no@' -e 's@^(do_update|do_download|do_download_deps)[ \t]*=.*@\1 = yes@' /etc/yum/yum-updatesd.conf
echo "Ensuring Yum-Updatesd runs at startup"
chkconfig --add yum-updatesd
chkconfig --level 2345 yum-updatesd on
service yum-updatesd restart
echo "Disabling DBUS and HAL Daemons"
service messagebus stop
chkconfig messagebus off
service haldaemon stop
chkconfig haldaemon off

! [[ -h /var/tmp ]] && rm -rf /var/tmp && ln -s /tmp /var/tmp

mv /etc/motd.securebak /etc/motd

# Check for RBLs ~Pablob
bash <(curl  -ks https://raw.githubusercontent.com/Pablocst/scripts/main/rbl.sh)

Desa

#Send Secure Finished Email ~ArielP
#cat << NEOF | sendmail -t -i
#From: secure.sh <root@$HOSTNAME>
#To: Abuse Team <abuseteam@hostdime.com>
#Subject: ($SECURETAG) New Dedicated Server Secure Finished

#server secure execution has finished
#NEOF
