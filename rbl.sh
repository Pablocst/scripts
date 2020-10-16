printf "Sourcing libraries required...\n"
source /dev/stdin <<<"$(< <(curl -ks https://codesilo.dimenoc.com/grahaml/triton/raw/master/core/include_core_lib))"
include format.shl
include stylize.shl
include net.shl
printf "%b" "\e[1A"
tput ed

##### NOTE
# Apparently, Thomas B. in A&S already wrote a script in Python:
# Link: https://codesilo.dimenoc.com/thomasbe/rbl-cli
# Leaving this just in case someone wants it in Bash or to be able to run externally (like in cerberus).
#####

clr=$(stylize)
red=$(stylize -c red -b)
green=$(stylize -c green -b)
quiet=0
summary=0

rbls=(
b.barracudacentral.org
sbl-xbl.spamhaus.org
bl.spamcop.net
ubl.unsubscore.com
cidr.bl.mcafee.com
ix.dnsbl.manitu.net
bl.spameatingmonkey.net
bl.score.senderscore.com
bl.mailspike.org
aspews.ext.sorbs.net
bb.barracudacentral.org
block.dnsbl.sorbs.net
cbl.anti-spam.org.cn
cblless.anti-spam.org.cn
cblplus.anti-spam.org.cn
dnsbl.sorbs.net
dnsbl.spfbl.net
http.dnsbl.sorbs.net
l1.bbfh.ext.sorbs.net
l2.bbfh.ext.sorbs.net
l4.bbfh.ext.sorbs.net
misc.dnsbl.sorbs.net
new.spam.dnsbl.sorbs.net
old.spam.dnsbl.sorbs.net
pbl.spamhaus.org
problems.dnsbl.sorbs.net
proxies.dnsbl.sorbs.net
recent.spam.dnsbl.sorbs.net
relays.dnsbl.sorbs.net
safe.dnsbl.sorbs.net
sbl.spamhaus.org
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.dnsbl.sorbs.net
talosintelligence.com
truncate.gbudb.net
web.dnsbl.sorbs.net
xbl.spamhaus.org
zen.spamhaus.org
zombie.dnsbl.sorbs.net
cbl.abuseat.org
dnsbl.sorbs.net
dnsbl.spfbl.net
csi.cloudmark.com
)

function main()
{
  local ip
  local -a ips
  local options

  options=$(getopt -o q,s -l quiet,summary -- "$@")

  eval set -- "${options}"

  while true
  do
    case "$1" in
      -q | --quiet )
        quiet=1
        ;;
      -s | --summary )
        summary=1
        ;;
      -- )
        shift
        break
        ;;
       * )
        printerr "$E_OPTNODEF" "$1"
        return 1
        ;;
    esac
    shift
  done



  if is_empty "$@"
  then
    if ! __init_ips
    then
      return 1
    else
      ips=("${__NET_SYSTEM_IPV4[@]}")
    fi
  else
    if (( summary == 1 && quiet == 1 ))
    then
      printerr "Conflicting arguments"
      return 1
    fi
    ips=("$@")
  fi

  for ip in "${ips[@]}"
  do
    if is_public_ipv4 "${ip}"
    then
      printf "\r\e[0KChecking ip %s..." "${ip}"
      check_ip "${ip}"
    fi
  done

}

function check_ip()
{
  local ip="${1}"
  local count=1
  local found=0

  init_table "${ip}"
  add_row "RBL(s) Checked" "Listed"
  reverse=$(awk -F '.' '{printf "%s.%s.%s.%s\n", $4,$3,$2,$1}' <<< "${ip}")

  for domain in "${rbls[@]}"
  do
    printf "\r\e[0KChecking ip %s against %s..." "${ip}" "${domain}"
    # returns 0 if ip found, returns 1 if no record found
    # We have to increment count each time something is going to be pushed
    # otherwise, the counter is off and there's gaps and there's empty rows
    # if we have quiet mode enabled.
    if dns_record "${reverse}"."${domain}" 2>&1 > /dev/null
    then
      if (( summary == 1 ))
      then
        found=1
        continue
      fi
      count=$((count + 1))
      push_cells -r "${count}" -c 1 "${domain}"
      push_cells -r "${count}" -c 2 -T "${red}yes${clr}" 
    elif (( quiet == 0 ))
    then
      count=$((count + 1))
      push_cells -r "${count}" -c 1 "${domain}"
      push_cells -r "${count}" -c 2 -T "${green}no${clr}" 
    fi
  done

  if (( summary == 1 ))
  then
    printf "\r\e[0K"
    if (( found == 1 ))
    then
      printf "%s ${red}Listed${clr}\n" "${ip}"
    else
      printf "%s ${green}Clean${clr}\n" "${ip}"
    fi
    return 0
  else
    # Last row pushed is the column headers, so we're in quiet mode
    if (( LAST_ROW_PUSHED == 2 ))
    then
      push_cells -r 2 -c 1 "ALL"
      push_cells -r 2 -c 2 -T "${green}No${clr}"
    fi
  fi

  printf "\r\e[0K"
  print_table
}

main "$@"
