#!/usr/bin/sh
#nodelist - input file. Should be in the same dir...

bpath=/opt/OV/bin
DATE=`date '+%Y%m%d'`
HOME=/home/et4956
tot=$(wc -l <$HOME/tmp/nodelist); cou=1
[ -a $HOME/ping.err ]&& rm -f $HOME/ping.err
[ -a $HOME/tmp/deploy.tmp ]&& rm -f $HOME/tmp/deploy.tmp
echo `date` > ping.log; echo >> ping.log

cat $1|while read str;do
node=`echo $str|awk '{print $1}'`
nodeip=`echo $str|awk '{print $2}'`
  echo "Progress: $cou / $tot"|tr '\n' '\r'; let cou+=1
        if ping $nodeip 64 -n 2 -m 2 >/dev/null 2>&1;then
          echo "PING to $node [$nodeip] is OK" >> ping.log
        else echo "PING to $node [$nodeip] is failed" >> ping.err
        fi
done;echo;echo

[ -a ping.err ]&& cat ping.err; echo
if [[ -a ping.log && `wc -l < ping.log` -lt 100 ]];then
  cat ping.log
fi
