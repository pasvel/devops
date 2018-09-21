#!/usr/bin/sh

HOME=/home/et4956
bpath=/opt/OV/bin
rm -f $HOME/tmp/scr.tmp

for str in `<$HOME/tmp/templates.W`;do
  ngpg=''
echo $str
  let cou=`echo "$str"|tr -cd '\\\'|wc -c`+1
  pol=`echo "$str"|cut -d'\' -f$cou`
echo "DEBUG pol=$pol"
#  val="C:\\TEMP\\sel_polsbypg.bat $pol"
#echo "DEBUG val=$val"
#  ngpg=$($bpath/ovdeploy -node 146.192.79.150 -cmd "$val" -ovrg server|grep "[A-Z0-9]-.*-.*-.*-.*")
ngpg=`$bpath/ovdeploy -node 146.192.79.150 -cmd "C:\\TEMP\\sel_pgbyng.bat $pol" -ovrg server|grep "[A-Z0-9]-.*-.*-.*-.*"`


echo "DEBUG ngpg:"
echo $ngpg
  if [[ ! -z $ngpg ]];then
#    let cou=`echo "$str"|tr -cd '\\\'|wc -c`+1
#    pol=`echo "$str"|cut -d'\' -f$cou`
    echo $str|sed "s/$pol//;s/^/W $pol \"/"|sed 's/\\$//g;s/\\/\\\\/g'|sed 's/^/---------->/'
    echo $str|sed "s/$pol//;s/^/W $pol \"/"|sed 's/\\$//g;s/\\/\\\\/g' >> $HOME/tmp/scr.tmp
  fi
echo
done
