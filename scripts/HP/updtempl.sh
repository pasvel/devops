#!/usr/bin/sh

bpath=/opt/OV/bin
HOME=/home/et4956
excep="PMW_OS_WIN-SEC_BASE|PMW_VL_VMWARE_BASE"; echo "Exceptions: ${excep};"

[ -a $HOME/tmp/updtempl.tmp ]&& rm -f $HOME/tmp/updtempl.tmp
[ -a $HOME/tmp/templates.* ]&& rm -f $HOME/tmp/templates.*
mv $HOME/templates $HOME/backup/templates.`date '+%Y%m%d'`
$bpath/ovdeploy -upload -file sel_pgbyng.bat -sd $HOME -node 146.192.79.150 -td "C:\\TEMP" -ovrg server > /dev/null && echo "Uploading sel_polsbypg.bat"

for mgm in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05;do
  echo "$mgm....."|tr '\n' '\t\t'
  echo "$bpath/OpC/utils/opcnode -list_groups|grep Name|grep \"PM[UW_]\"|cut -d= -f2|sed \"s/^ /U /\"" > $HOME/remote.sh
  ### echo "if [ \$? -eq 0 ];then echo \"$mgm - OK\"; else echo \"$mgm - ERROR\"; fi" >> $HOME/remote.sh

  case $mgm in
    ihpmgm01|ihpmgm05 ) winmgm=146.192.79.150;;
    ihpmgm02 ) winmgm=10.219.35.14;;
    ihpmgm03 ) winmgm=134.47.99.203;;
  esac

  cmd="ovownodeutil -list_groups|find \\\"PM_Managed_Nodes\\\""
  echo "$bpath/ovdeploy -node $winmgm -cmd \"$cmd\" -ovrg server|sed /^$/d" >> $HOME/remote.sh

  $bpath/ovdeploy -upload -file remote.sh -sd $HOME -node $mgm -td $HOME -ovrg server > /dev/null
  $bpath/ovdeploy -node $mgm -cmd "sh $HOME/remote.sh" -ovrg server|sed /^$/d >> $HOME/tmp/updtempl.tmp
  if [ $? -eq 0 ];then echo "[DONE]"; else echo "[ERROR]"; fi
done; echo

grep "RESP" $HOME/tmp/updtempl.tmp|sort|uniq > $HOME/tmp/templates.U

grep "^U " $HOME/tmp/updtempl.tmp|awk '{print $2}'|sort|uniq|egrep -v "$excep|RESP"|while read str;do
  $bpath/ovdeploy -node ihpmgm01 -cmd "$bpath/OpC/utils/opcnode -list_ass_templs group_name=$str" -ovrg server|tr -d '\r'|sed '/^ *$/d' > $HOME/tmp/templates.tmp
  if grep -v "PMU_APP_CUST_LOG_ERROR" $HOME/tmp/templates.tmp|egrep -iq "error|fail|warn|crit";then
    echo "$str\t\t[ERROR]\t>> $HOME/tmp/templates.err"
    echo "  $str:" >> $HOME/tmp/templates.err
    cat $HOME/tmp/templates.tmp|sed 's/^/    /'|tee -a $HOME/tmp/templates.err
  else
    if [ `grep -c "PM[UW]" $HOME/tmp/templates.tmp` -gt 1 ];then
      echo "$str\t\t[OK]"
      echo "U $str" >> $HOME/tmp/templates.U
    else echo "$str\t\t[SKIPPED]"
    fi
  fi
done

for str in `grep "PM_Managed_Nodes" $HOME/tmp/updtempl.tmp|sort|uniq|sed "/PM_Managed_Nodes$/d;/PMW_[A-Z]*$/d"`;do
  let cou=`echo "$str"|tr -cd '\\\'|wc -c`+1
  pol=`echo "$str"|cut -d'\' -f$cou`
  
  $bpath/ovdeploy -node 146.192.79.150 -cmd "C:\\TEMP\\sel_pgbyng.bat $pol" -ovrg server > $HOME/tmp/templates.tmp
  if egrep -iq "^Msg [0-9]|error|fail|warn|crit" $HOME/tmp/templates.tmp;then
    echo "$pol\t\t[WARNING!]\t>> $HOME/tmp/templates.err"
    ### Dodaem, navit yaksho pomylka, krashche perebzidity...
    echo $str|sed "s/$pol//;s/^/W $pol \"/"|sed 's/\\$//g;s/\\/\\\\/g' >> $HOME/tmp/templates.W
    echo "  $pol:" >> $HOME/tmp/templates.err
    cat $HOME/tmp/templates.tmp|sed 's/^/    /'|tee -a $HOME/tmp/templates.err
  else
    if grep -q "[A-Z0-9]-.*-.*-.*-.*" $HOME/tmp/templates.tmp;then
      echo "$str\t\t[OK]"
      echo $str|sed "s/$pol//;s/^/W $pol \"/"|sed 's/\\$//g;s/\\/\\\\/g' >> $HOME/tmp/templates.W
    else echo "$str\t\t[SKIPPED]" 
    fi
  fi
done

cat $HOME/tmp/templates.U $HOME/tmp/templates.W > $HOME/templates

if [[ `cat $HOME/templates|sort|uniq -d` -gt 0 ]];then
  echo; echo "Duplicates (OMU and OMW)!:"; cut -d' ' -f2 < $HOME/templates|sort|uniq -d
fi
sh $HOME/uplall.sh templates > /dev/null && echo "Uploading templates on managers"
echo; echo "Differences (NEW/OLD):"; diff $HOME/templates $HOME/backup/templates.`date '+%Y%m%d'`
echo; [ -a $HOME/tmp/templates.err ]&& echo "There are ERRORs in log file.. [cat $HOME/tmp/templates.err]"
