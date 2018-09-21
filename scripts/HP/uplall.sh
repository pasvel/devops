#!/usr/bin/sh
#$1 - file. $2 - additional path in my home.

if [ $# -eq 0 ]; then echo "Usage: $0 file"; exit 2; fi
for mgm in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42 ihpmgm43;do
  /opt/OV/bin/ovdeploy -upload -file $1 -sd /home/et4956 -node $mgm -td /home/et4956/$2 -ovrg server
done
