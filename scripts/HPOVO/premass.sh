#!/usr/bin/sh
#$1 - filelist, $2 - layout group

if [ $# -ne 2 ];then echo "Usage: $0 filelist layout_group"; exit 2; fi
HOME=/home/et4956; [ -a $HOME/mass.sh ]&& rm -f $HOME/mass.sh
#ek='-e '
ek=''
sk='-s '
#sk=''

sed "s/[	| ]\{1,\}/ /g;s/PM[UW]/-n &/;s/-n/$sk-l $2 $ek-n/;s/^/sh pasvel\.sh -q -h /" $1 > $HOME/tmp/$1.tmp
for str in `<$HOME/tmp/deploy`;do
  if grep -qi $str $HOME/tmp/$1.tmp;then
    grep -i $str $HOME/tmp/$1.tmp >> mass.sh
    echo "$str\t[OK]"
  else echo "$str\t[ERROR]"
  fi
done
