#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "Invalid parameter, please use: removereseller.sh [RESELLER_ACCOUNT]: \033[0;31m[ERROR]\033[0m"
  exit;
else
  RESELLER=$1
fi

for i in `grep $RESELLER /etc/trueuserowners | cut -f1 -d":" | grep -v $RESELLER`; do /scripts/removeacct --force; done
