#!/usr/bin/sh

bpath=/opt/OV/bin; ostype=$2
/progs/powermon/utilities/Powertool/bin/powertool-assignedgroups.pl -n $1|grep -v "rollout_test"
[[ -z $ostype ]]&& ostype=`sh $bpath/OpC/call_sqlplus.sh sel_nodes $1|grep "OS name"|cut -d':' -f2|sed s/\ //g`
if [[ $ostype = MSWindows || $ostype = WIN ]];then
  case `hostname` in
    ihpmgm11|ihpmgm14|ihpmgm17|ihpmgm18|ihpmgm41|ihpmgm42 ) winmgm=146.192.79.150;;
    ihpmgm21 ) winmgm=10.219.35.14;;
    ihpmgm31 ) winmgm=134.47.99.203;;
    * ) echo "ERROR: Exception, hostname `hostname` is unknown!"
  esac
  CMD="cscript c:\\Powermon\\Utilities\\Powertool\\bin\\powertool-deployreport.vbs $1"
  $bpath/ovdeploy -node $winmgm -cmd "$CMD" -ovrg server|grep PolicyGroup|grep -v "Auto-Deploy"|cut -d' ' -f2
fi
