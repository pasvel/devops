#!/usr/bin/sh
#$1...$n - manager number(s), format: 01 02..

bpath=/opt/OV/bin
DATE=`date '+%Y%m%d'`
HOME=/home/et4956
FL=${HOME}/banks/${DATE}
cmd='/opt/OV/bin/OpC/utils/opcnode -list_nodes|egrep "Name|IP-Address|Machine Type"'

if [ $# -eq 0 ];then
  date '+%b %d %H:%M:%S'
  params="ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42 ihpmgm43"
  for i in 01 02 03 05 41 42 43;do
    [ -a ${FL}_ihpmgm${i} ]&& cp ${FL}_ihpmgm${i} ${FL}_ihpmgm${i}.bak
  done
else
  while [ $# -ne 0 ];do
    params="${params}ihpmgm$1 "
    [ -a ${FL}_ihpmgm$1 ]&& cp ${FL}_ihpmgm$1 ${FL}_ihpmgm$1.bak
    shift
  done
fi

for str in $params;do
  if $bpath/ovdeploy -node $str -cmd "$cmd" -cmd_timeout 180000 -ovrg server > $HOME/tmp/banks.tmp 2>/dev/null;then
    sed "s/Name.*= //;N;s/IP-Address.*= //;N;s/Machine Type.*=.*MACH_BBC_\([A-Z0-9]*\)_.*$/\1/;s/\n/ /g" $HOME/tmp/banks.tmp|grep -v "0.0.0.0" > ${FL}_${str}
    if [ -a ${FL}_${str}.bak ];then
      SECF=${FL}_${str}.bak
    else
      SECF=`ls banks/$(date '+%Y')*_${str}|tail -2|head -1`
    fi

    k1=`wc -l < ${FL}_${str}`; k2=`wc -l < $SECF`
    if [ $k1 -eq $k2 ];then
      echo "$str\t[$k1]"
    else
      echo "$str\t[$k1] <- $k2"
      diff ${FL}_${str} $SECF|sed -n 's/</NEW	/p;s/>/OLD	/p'|sort -k2 -u|sed 's/^/  /'
    fi
  else
    echo "$str\t[ERROR]"
  fi
done

[ -a $HOME/tmp/banks.tmp ]&& rm -f $HOME/tmp/banks.tmp; [ -a $HOME/banks/*.bak ]&& rm -f $HOME/banks/*.bak
