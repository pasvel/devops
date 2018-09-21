#!/usr/bin/sh

if [ $# -eq 0 ];then echo "Usage: $0 file"; exit 2; fi
bpath=/opt/OV/bin
DATE=`date '+%Y%m%d'`*
tot=`wc -l < $1`; cou=1
[ -a mpolicy.log ]&& rm -f mpolicy.log

upexec () {
  $bpath/ovdeploy -upload -file remote.sh -sd /home/et4956 -node $mgm -td /home/et4956 -ovrg server > /dev/null
  $bpath/ovdeploy -node $mgm -cmd "sh /home/et4956/remote.sh" -ovrg server > remote.log 2>$1
}

for str in `<$1`;do
  echo "Progress: $cou / $tot" | tr '\n' '\r'; let cou+=1;
  tmp=`grep -i $str banks/$DATE`
  mgm=`echo $tmp | cut -d: -f1 | cut -d_ -f2`
  node=`echo $tmp | awk {'print $1'} | cut -d: -f2`
  echo "$bpath/ovpolicy -host $node -list -ovrg server" > remote.sh
  upexec
  echo "################################################################################" >> mpolicy.log
  echo "$node, $mgm:" >> mpolicy.log
  cat remote.log >> mpolicy.log
done
