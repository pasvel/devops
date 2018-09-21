#!/usr/bin/sh

bpath=/opt/OV/bin
rm -f /home/et4956/hosts/`date '+%Y%m%d`*

for str in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42;do
 $bpath/ovdeploy -node $str -down -file "/etc/hosts" -td "/home/et4956/hosts/" -ovrg server
 cd /home/et4956/hosts; mv hosts `date '+%Y%m%d`_${str}
done
