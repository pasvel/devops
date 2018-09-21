#!/usr/bin/sh

HOME=/home/et4956
for node in `ls $HOME/LOGS_U|grep -v uploaded`;do
  if grep -i $node $HOME/tmp/deploy;then
    sh pasvel.sh -q -h $node -u $HOME/LOGS_U/$node powermon_local.cfg /var/opt/OV/conf/powermon
    mv $HOME/LOGS_U/$node $HOME/LOGS_U/uploaded/$node
  fi
done
