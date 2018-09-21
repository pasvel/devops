for mgm in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42;do
  echo "${mgm}:"
  /opt/OV/bin/ovdeploy -node $mgm -ovrg server -cmd "sh /home/et4956/lgetmgmcfgs.sh" && echo "  Preparing...\t[OK]"
  /opt/OV/bin/ovdeploy -node $mgm -ovrg server -download -sd /home/et4956 -td /home/et4956/LOG_org -dir LOG > /dev/null && echo "  Downloading...\t[OK]"
done
