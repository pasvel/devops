#!/usr/bin/sh
#$1 - ip-address, $2 - manager, $3 - OS.

if [ $# -eq 0 ];then echo "Usage: $0 ip-address mgm_number WIN|UNIX|AIX"; exit; fi

case $3 in
  WIN )
    upath='C:\Documents and Settings\All Users\Application Data\HP\HP BTO Software\bin\instrumentation'
    CMD="\"%OvInstallDir%\"\nonOV\perl\a\bin\perl.exe \"%OvDataDir%\"\bin\instrumentation\pm-configure-hpagent.pl -i $1 -m ihpmgm${2}.mgmt.oper.no -f"
  ;;
  UNIX|AIX )
    dirp=/opt/OV
    [[ $3 = AIX ]]&& dirp=/usr/lpp/OV
    upath='/var/opt/OV/bin/instrumentation'
    CMD="$dirp/nonOV/perl/a/bin/perl /var/opt/OV/bin/instrumentation/pm-configure-hpagent.pl -i $1 -m ihpmgm${2}.mgmt.oper.no -f"
  ;;
  * ) echo "! OS isn't specified!\t[ERROR]"; exit 1;;
esac

if [ -a `pwd`/pm-configure-hpagent.pl ];then
  /opt/OV/bin/ovdeploy -upload -file pm-configure-hpagent.pl -sd `pwd` -td "$upath" -ovrg server|sed 's/^/  /;/^$/d'
  /opt/OV/bin/ovdeploy -cmd "${CMD}" -node $1 -cmd_timeout 600000 -ovrg server|sed 's/^/  /;/^$/d'
else
  echo "File `pwd`/pm-configure-hpagent.pl not found, terminating..."
fi
