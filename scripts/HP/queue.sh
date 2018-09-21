#!/usr/bin/sh

fix=1; FIX=1
while [ $# -ne 0 ];do
  case $1 in
    -f ) fix=0; shift;;
    -F ) FIX=0; shift;;
    -h|* )
      echo; echo "Usage $0 [-f|-F|-h]"
      echo "\t-f\tFlush ALL files older than 24h"
      echo "\t-F\tFlush ALL files available at the moment"
      exit 2
  esac
done

[[ $fix -eq 0 || $FIX -eq 0 ]]&& [ -a /tmp/queue_lst ]&& rm -f /tmp/queue_lst
ltime=`perl -e "use Time::localtime; print time();"`
lst1=`ls /var/opt/OV/share/tmp/OpC/distrib|grep "^[a-f0-9]*[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]"`
lst2=`echo ${lst1}|tr ' ' '\n'|cut -d. -f1|sort|uniq`
echo "  `echo ${lst2}|wc -w` HEX-es / `echo ${lst1}|wc -w` files"
echo "-------------------------------------------------------------------------------"

for str in `echo ${lst2}`;do
  ftime=`perl -e "use File::stat; print stat(@ARGV[0])->mtime;" /var/opt/OV/share/tmp/OpC/distrib/${str}*`
  difft=`perl -e "use integer; print ((${ltime}-${ftime}));"`; [[ -z ${difft} ]]&& difft=0
  tmp=`/opt/OV/bin/OpC/install/opc_ip_addr -r ${str} 2>/dev/null|awk {'print $1,$3'}`
  if [[ ! -z ${tmp} ]];then
    node=`echo ${tmp}|awk {'print $1'}`
    ip=`echo ${tmp}|awk {'print $2'}`
    echo "  ${node} [${ip}],${str}\t\t${difft} sec / `let difft=${difft}/60`${difft} min / `let difft=${difft}/60`${difft} h"
    if [[ ${fix} -eq 0 && ${difft} -gt 24 || ${FIX} -eq 0 ]];then
      echo ${node} >> /tmp/queue_lst
      rm -f /var/opt/OV/share/tmp/OpC/distrib/${str}* && echo "    ${str}*\t\t[REMOVED]"
    fi
  else
    echo "! Hostname for ${str} is not found (`ls /var/opt/OV/share/tmp/OpC/distrib/${str}*|wc -l` files)"
    [[ ${fix} -eq 0 || ${FIX} -eq 0 ]]&& rm -f /var/opt/OV/share/tmp/OpC/distrib/${str}* && echo "    ${str}*\t\t[REMOVED]"
  fi
done
