#!/usr/bin/sh
#$1 - nodename,$2 - OS

bpath=/opt/OV/bin
wpath=/home/et4956/tmp/locals/$1
[[ ! -d /home/et4956/tmp/locals ]]&& mkdir /home/et4956/tmp/locals
[[ -d $wpath ]]&& rm -rf $wpath

case $2 in
  WIN ) powermon='C:\Documents and Settings\All Users\Application Data\HP\HP BTO Software\conf';;
  UNIX )
    powermon='/var/opt/OV/conf'
    $bpath/ovdeploy -node $1 -download -sd "$powermon" -td "$wpath" -dir osspi -ovrg server > /dev/null 2>&1
  ;;
esac

$bpath/ovdeploy -node $1 -download -sd "$powermon" -td "$wpath" -dir powermon -ovrg server > /dev/null 2>&1
lst=`ls $wpath|egrep -v "harddisk.cfg|netif.cfg|opcagtinfo|osspi.cfg|osspi_fsmon-hash.cfg|osspi_fsmon.cfg|procmon.cfg|.dat$|tr 'A-Z' 'a-z'`

if [[ ! -z $lst ]];then
  for str in $lst;do
    echo >> $wpath/$str
    case $str in
      powermon.[Pp]roc[Cc]onf ) echo "  PRCS config file\t[$str]"; cat $wpath/powermon.[Pp]roc[Cc]onf|sed '/^$/d;s/^/    /';;
      powermon.diskconf ) echo "  Disk config file\t[$str]"; cat $wpath/powermon.diskconf|sed '/^$/d;s/^/    /';;
      powermon.serviceconf ) echo "  SRVC config file\t[$str]"; cat $wpath/powermon.serviceconf|sed '/^$/d;s/^/    /';;
      powermon_local.cfg ) echo "  LOGS config file\t[$str]"; cat $wpath/powermon_local.cfg|sed '/^$/d;s/^/    /';;
      procmon_local.cfg ) echo "  PRCS config file\t[$str]"; cat $wpath/procmon_local.cfg|sed 's/^/    /';;
      osspi_local_fsmon.cfg ) echo "  FSMON config file\t[$str]"; cat $wpath/osspi_local_fsmon.cfg|sed 's/^/    /';;
      * ) echo "! Unknown config\t[$str]";;
    esac
  done
  rm -rf $wpath
else echo "  Local config files\t[NONE]"
fi
