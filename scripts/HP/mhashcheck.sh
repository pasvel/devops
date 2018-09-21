#!/usr/bin/sh
#$1 - filelist or hostname...

bpath=/opt/OV/bin
spipath=/var/opt/OV/conf/osspi
node=`echo $1|cut -d. -f1`

if $bpath/ovdeploy -ovrg server -node $node -cmd "if [ -a ${spipath}/osspi_fsmon-hash.cfg ];then exit 0;else exit 1;fi" >/dev/null 2>$1;then
  echo " $node\t- hash file is OK"
  exit 0
else
  echo " $node\t- hash file is missed"|tr '\n' '\t'
  echo "$bpath/ovdeploy -ovrg server -node $node -cmd \"ls -l ${spipath}\""
  exit 1
fi
