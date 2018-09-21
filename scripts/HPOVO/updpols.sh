#!/usr/bin/sh

mgm=ihpmgm01
bpath=/opt/OV/bin; HOME=/home/et4956

[ -a $HOME/tmp/updpols.tmp ]&& rm -f $HOME/tmp/updpols.tmp

$bpath/ovdeploy -upload -file sel_polsbypg.bat -sd $HOME -node 146.192.79.150 -td "C:\\TEMP" -ovrg server > /dev/null && echo "Uploading sel_polsbypg.bat"
$bpath/ovdeploy -upload -file getallpols.sh -sd $HOME -node $mgm -td $HOME -ovrg server > /dev/null && echo "Uploading getallpols.sh"
$bpath/ovdeploy -node $mgm -cmd "[ -a $HOME/policies ]&& rm -f $HOME/policies" -ovrg server > /dev/null && echo "Removing policies"

echo "Please execute sh getallpols.sh $@ on $mgm. Continue?  [Y/n]"
read answer; [[ -z $answer ]]&& answer='y'

if [[ $answer = 'y' ]];then
  $bpath/ovdeploy -node $mgm -cmd "[ -a $HOME/getallpols.sh ]&& rm -f $HOME/getallpols.sh" -ovrg server > /dev/null && echo "Removing getallpols.sh"
  ###$bpath/ovdeploy -down -file policies -sd $HOME -node $mgm -td $HOME -ovrg server > /dev/null && echo "Downloading policies"
  [ -a $HOME/policies ]&& mv $HOME/policies $HOME/backup/policies.`date '+%Y%m%d'`
  if [ $# -gt 0 ];then
    params=`echo $@|tr ' ' '|'`
    $bpath/ovdeploy -node $mgm -cmd "cat $HOME/policies|sort" -ovrg server|sed /^$/d >> $HOME/tmp/updpols.tmp && echo "Downloading chosen policies"
    cat $HOME/backup/policies.`date '+%Y%m%d'`|egrep -v "$params" >> $HOME/tmp/updpols.tmp && echo "Updating all policies"
  else
    $bpath/ovdeploy -node $mgm -cmd "cat $HOME/policies" -ovrg server|sed /^$/d > $HOME/tmp/updpols.tmp && echo "Downloading all policies"
  fi

  cat $HOME/tmp/updpols.tmp|sort > $HOME/policies
  sh $HOME/uplall.sh policies > /dev/null && echo "Uploading policies on managers"
  echo; echo "Differences (NEW/OLD):"; diff $HOME/policies $HOME/backup/policies.`date '+%Y%m%d'`
fi
