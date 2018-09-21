#!/usr/bin/sh
#$1 - hostname
#$2 - filename

bpath=/opt/OV/bin
HOME=/home/et4956

if $bpath/ovdeploy -upload -file "$2" -sd "$HOME" -node $1 -td "/tmp" -ovrg server>/dev/null;then
  $bpath/ovdeploy -node $1 -cmd "sh /tmp/$2" -cmd_timeout 60000 -ovrg server 2>/dev/null
fi
