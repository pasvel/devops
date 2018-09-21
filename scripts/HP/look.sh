#!/usr/bin/sh

et=et5468;file=".profile"
for mgm in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42;do
  /opt/OV/bin/ovdeploy -node $mgm -download -file "$file" -sd /home/${et} -td /home/et4956/tmp -ovrg server
  [ -a /home/et4956/tmp/${file} ]&& cat /home/et4956/tmp/$file|grep -v "sudo su -" > /home/et4956/tmp/${file}_${et}_${mgm}
done
