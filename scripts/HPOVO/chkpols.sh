#!/usr/bin/sh
#$1 - nodegroups, $2 - local policies, $3 - rdate...

PASD=/home/et4956; HOME=`pwd`; k=0; em=''
excl="PERF_DiskBottleneck|PM[UW]_HW|OVO|PMA_INI_BASE"
[ -a $HOME/tmp/chkpols.tmp[012] ]&& rm -f $HOME/tmp/chkpols.tmp[012]

pols=$(egrep -v "$excl" $2|wc -l)
ov=$(egrep "OVO|PMA_INI_BASE" $2|wc -l)
hw=$(egrep "PERF_DiskBottleneck|PM[UW]_HW" $2|wc -l)
let sum=$pols+$ov+$hw
[ $ov -lt 3 ]&& ov="$ov!"

for polgrp in $(grep -v RESP $1);do
  ### Count of policies according to NodeGroups list
  let k=$k+`grep -c "^$polgrp:" $PASD/policies`
done

[ $k -eq 0 ]&& em='!'
echo "[$k$em/$pols + $ov + $hw = $sum]$3"

if [[ ! -z $(grep -v RESP $1 2>/dev/null) ]];then
  for polgrp in $(grep -v RESP $1);do
    if ! grep -q $polgrp $PASD/templates;then
      echo "!   $polgrp\t[!]"
      continue
    fi

    cou=$(grep -c "^$polgrp:" $PASD/policies); k=$cou; err=''; val="\t[$k]"
    grep "^$polgrp:" $PASD/policies|cut -d: -f2|while read str;do
      if ! grep -q $str $2;then
        let k-=1
        err="$err$str,"
      fi
    done

    if [ $k -ne $cou ];then
      em='.'; [ $k -eq 0 ]&& em='!'
      echo "$em   $polgrp\t[$cou/$k]"
      ### Ne smitymo, yaksho ne vystachaye VSIH polityk - nichogo ne vyvodymo
      [ $k -ne 0 ]&& echo "${err%,}"|tr ',' '\n'|sed 's/^/     -/'
    else
      ### Ne smitymo, yaksho NG mistyt 0 polityk - 0 ne vevodymo
      [[ $k -eq 0 && $cou -eq 0 ]]&& val=''
      echo "    $polgrp$val"
    fi
    echo $polgrp >> $HOME/tmp/chkpols.tmp0
  done
else
  echo "!   No NodeGroups are assigned"
fi

###[ $k -ne 0 ] or [ $pols -ne 0 ]
egrep -v "$excl" $2|awk '{print $2}'|sed 's/"//g'|while read str;do
  if ! grep -q "$str" $PASD/policies;then
    echo $str >> $HOME/tmp/chkpols.tmp1
  else
    if ! grep -q "$(grep $str $PASD/policies|cut -d: -f1)" $1;then
      echo $str >> $HOME/tmp/chkpols.tmp2
    fi
  fi
done

if grep -q disabled $2;then
  echo "    -Disabled policies:"
  grep disabled $2|cut -d'"' -f2|sed 's/"//g;s/^/      /'
fi
if [ -s $HOME/tmp/chkpols.tmp1 ];then
  echo ".   -Unknown policies:"
  cat $HOME/tmp/chkpols.tmp1|sed 's/^/      /'
fi
if [ -s $HOME/tmp/chkpols.tmp2 ];then
  echo ".   -Unexpected policies:"
  cat $HOME/tmp/chkpols.tmp2|sed 's/^/      /'
fi

[[ -s $1 ]]&& if ! grep -q RESP $1;then
  echo "!   No RESP group is assigned"
else grep RESP $1|sed 's/^/    /'
fi
