#!/usr/bin/sh
#$1 - nodename

HOME=`pwd`
PASD=/home/et4956
bpath=/opt/OV/bin
[ -a $HOME/tmp/getpols.tmp* ]&& rm -f $HOME/tmp/getpols.tmp*

$bpath/ovpolicy -list -host $1 -ovrg server|egrep "PMW|PMU"|egrep -v "PM[UW]_HW|OVO|opcmsg"|sort|awk '{print $2}'|sed 's/"//g'|while read str
  do
    case `grep -c $str $PASD/policies` in
      0 ) echo $str >> $HOME/tmp/getpols.tmp2;;
      1 ) grep $str $PASD/policies|awk '{print $1}' >> $HOME/tmp/getpols.tmp1;;
    esac
  done

if [ -s $HOME/tmp/getpols.tmp1 ];then
  cat $HOME/tmp/getpols.tmp1|cut -d: -f1|sort|uniq|sed 's/^/    /'
else exit
fi

if [ -s $HOME/tmp/getpols.tmp2 ];then
  echo "   -Unknown policies:"
  cat $HOME/tmp/getpols.tmp2|sed 's/^/      /'
fi
