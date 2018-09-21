#!usr/bin/sh
#$1 - file with list of policies...

PASD=/home/et4956
HOME=`pwd`
[ -a $HOME/tmp/showpols.tmp* ]&& rm -f $HOME/tmp/showpols.tmp*

cat $1|egrep "PMW|PMU"|egrep -v "PM[UW]_HW|OVO|opcmsg"|sort|awk '{print $2}'|sed 's/"//g'|while read str
  do
    case `grep -c $str $PASD/policies` in
      0 ) echo $str >> $HOME/tmp/showpols.tmp2;;
      1 ) grep $str $PASD/policies|awk '{print $1}' >> $HOME/tmp/showpols.tmp1;;
    esac
  done

if [ -s $HOME/tmp/showpols.tmp1 ];then
  cat $HOME/tmp/showpols.tmp1|cut -d: -f1|sort|uniq|sed 's/^/    /'
else exit
fi

if [ -s $HOME/tmp/showpols.tmp2 ];then
  echo "   -Unknown policies:"
  cat $HOME/tmp/showpols.tmp2|sed 's/^/      /'
fi
