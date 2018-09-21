#!/usr/bin/sh

HOME=`pwd`
[ -a $HOME/tmp/buffering.lst ]&& cat $HOME/tmp/buffering.lst|while read str;do
  mgm=$(echo $str|awk '{print $1}')
  node=$(echo $str|awk '{print $2}')
  /opt/OV/bin/ovdeploy -node $mgm -cmd "sh $HOME/Java/opcmsgarestart.sh $node" -ovrg server|sed '/^ *$/d'
done
