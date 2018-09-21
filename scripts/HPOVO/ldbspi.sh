#!/usr/bin/sh
#$1 = $osval, $2 = $node

bpath=/opt/OV/bin
rmt0=/home/et4956/tmp/remote.tmp0; rmt1=/home/et4956/tmp/remote.tmp1; rmt2=/home/et4956/tmp/remote.tmp2
[ -a $rmt2 ]&& rm -f $rmt2
ctos="-cmd_timeout 170000 -ovrg server"

case $1 in
  WIN ) CMD="dbspiadm verify -nw"; cfgp="dir C:\usr\OV\dbspi\local.cfg"; a1=1; a2=2;;
  UNIX ) CMD="dbspiverify"; cfgp="ls -l /var/opt/OV/dbspi/local.cfg"; a1=6; a2=7;;
esac

$bpath/ovdeploy -node $2 -cmd "$CMD" $ctos > $rmt0 2>&1
cat $rmt0|sed -n '/Number of DBSPI monitors installed/,$p'|sed "/Verifying/d;/^$/d" > $rmt1 2>&1

if [ -s $rmt1 ];then
  echo "  DBSPI verifying:"
  if ! egrep -qi "error|unable|fail" $rmt1;then
#    echo "  DBSPI verifying...\t[ERROR]"
#  else
    if grep -q "cfg present" $rmt1;then
      ldate="`$bpath/ovdeploy -node $2 -cmd "$cfgp" $ctos|sed -n '/local.cfg/p'|awk -v v1=$a1 -v v2=$a2 '{print $v1,$v2}'`"
      echo "#local.cfg file\t[$ldate]" >> $rmt1
      $bpath/ovdeploy -node $2 -cmd "dbspicfg -e" $ctos|sed /^$/d >> $rmt1

      case $1 in
        WIN )
          tmp=`sed -n 's/ *SERVER \"\(.*\)\"/\1/p' $rmt1|cut -d'"' -f1`
          for inst in $tmp;do
            echo "\r#osql -E -S $inst -Q \"select @@version\":\r" >> $rmt2
            $bpath/ovdeploy -node $2 -cmd "osql -w 255 -E -S $inst -Q \"select @@version\"" $ctos >> $rmt2
          done;;
#        UNIX ) ;;
      esac
    else echo "#local.cfg file\t[MISSED]" >> $rmt1
    fi
  fi
  echo "\r" >> $rmt2
  sed "s/^/    /g;s/  #//" $rmt1
  sed "s/^[ |	]*//g;s/   *//g;s/---*//g;s/(depl/%&/g;s/error:/&%/" $rmt2|tr -d '\n'|tr '%' '\r'|tr '\r' '\n'|sed "s/^/    /g;s/  #//;s/Copyright.*$//"
else
  echo "! DBSPI verifying...\t[ERROR]"
  cat $rmt0|sed 's/^/    /'
fi
