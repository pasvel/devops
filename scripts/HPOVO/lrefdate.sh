#/usr/bin/sh
#$1 - hostname,$2 - OS.
case $2 in
  WIN )
    /opt/OV/bin/ovdeploy -node $1 -cmd "dir \"%OvDataDir%\bin\instrumentation\pm-configure-hpagent.pl\"" -ovrg server 2>/dev/null|grep hpagent|awk '{print $1,$2}'
  ;;
  UNIX )
    /opt/OV/bin/ovdeploy -node $1 -cmd "ls -l /var/opt/OV/bin/instrumentation/pm-configure-hpagent.pl" -ovrg server 2>/dev/null|awk '{print $6,$7,$8}'|tr -d '\n'
  ;;
esac
