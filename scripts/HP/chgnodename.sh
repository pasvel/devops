#!/usr/bin/sh
#$1 - old nodename, $2 - new nodename.

if [ $# -eq 0 ];then echo "Usage: $0 nodename new_nodename"; exit; fi

label=`echo $2|cut -d. -f1`
etcip=`grep $label /etc/hosts|awk {'print $1'}`
if [[ -z $etcip ]];then echo "  $label not found in /etc/hosts. Terminating!"; exit 1; fi

sed "/$label/d" /etc/hosts > /home/et4956/hosts
[[ $label = $2 ]]&& label=''
echo "${etcip}\t${2}\t${label}\t# changed manually. Old name $1 doesn't equal TNDB FQN Name $2 `date '+%Y/%m/%d-%H:%M:%S'`" >> /home/et4956/hosts
cp /home/et4956/hosts /etc/hosts

/opt/OV/contrib/OpC/opcchgaddr IP $etcip $1 IP $etcip $2|sed 's/^/  /'
