#!/usr/bin/sh

for mgm in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42;do
  echo "${mgm}:"
  /opt/OV/bin/ovdeploy -node $mgm -ovrg server -cmd "$@"|sed '/^$/d;s/^/  /'
done
