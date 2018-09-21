#!/usr/bin/sh
# $1 - input file. Should be in the same dir..

DATE=`date '+%Y%m%d'`
HOME=`pwd`
PASD=/home/et4956
bpath=/opt/OV/bin

if [ $# -eq 0 ];then echo "Usage: $0 list"; fi

if [ -a $1 ];then
  loop=$(<$1)
else loop=$@
fi

for str in $loop;do
  CMD="^${str}[ |	|\.]"
  tmp=$(grep -i "$CMD" ${PASD}/banks/${DATE}_ihpmgm[04][1235])
  if [[ ! -z $tmp ]];then
    if [ $(echo "$tmp"|wc -l) -gt 1 ];then
      tmp=$(echo "$tmp"|sed 's/.*ihpmgm/ihpmgm/'|cut -d: -f1|tr '\n' ',')
      echo "$str\t- is located on [${tmp%,}] managers"
      echo "$str:${tmp%,}" >> ${HOME}/tmp/fewmgm.lst
      continue
    else
      tmp=`grep -i "$CMD" $HOME/banks/${DATE}_ihpmgm[04][1235]"`
      mgm=`echo $tmp|cut -d: -f1|cut -d_ -f2`
      node=`echo $tmp|awk {'print $1'}|cut -d: -f2`
      echo "$node, $mgm"|tr '\n' '\t'
      echo "######################################################## `date '+%b %d %Y %H:%M'` #####" >> $HOME/log/delete.log

      if $bpath/ovdeploy -node $mgm -cmd "/opt/OV/edb/bin/deleteNode.sh $node" -ovrg server > $HOME/tmp/delete.tmp;then
        echo "[REMOVED]"
        cat $HOME/tmp/delete.tmp >> $HOME/log/delete.log
        cat $HOME/banks/${DATE}_$mgm|grep -v $node > $HOME/tmp/delete.tmp
        cp $HOME/tmp/delete.tmp $HOME/banks/${DATE}_$mgm > /dev/null && echo "  Updating $mgm banks file"
      else
        echo "[ERROR]"
        cat $HOME/tmp/delete.tmp|sed 's/^/  /'
      fi
    fi
  else
    echo "$str\t\t- IS NOT in NodeBank (perl pm-configure-hpagent.pl -i IP-ADDRESS -m MANAGER)"
  fi
done
