#!/usr/bin/sh
#$1 - hostname, $2 - new ip-address

if [ $# -eq 0 ];then echo "Usage: $0 nodename new_ip-address"; exit; fi

if etcip=`grep $(echo $1|cut -d. -f1) /etc/hosts|awk {'print $1'}`;then
  if [ $etcip != $2 ];then
    echo "$2 != $etcip found in /etc/hosts"
    exit 1
  fi
else
  echo "$2 is not found in /etc/hosts"
  exit 1
fi

oldip=`/opt/OV/bin/OpC/utils/opcnode -list_nodes node_list=$1|grep "IP-Address"|awk {'print $3'}`
/opt/OV/contrib/OpC/opcchgaddr IP $oldip $1 IP $2 $1|sed 's/^/  /'
