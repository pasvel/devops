#!/usr/bin/sh
#$label - hostname

bpath=/opt/OV/bin; nrec=0
label=$1; at1=''

postcheck () {
  polscou=$($bpath/ovpolicy -host $label -list -ovrg server|egrep "PMW|PMU|PMA|OVO|opcmsg"|sed /^$/d|wc -l)
  if [ $polscou -lt 3 ];then
    if [ $nrec -eq 0 ];then
#      echo "  Removing policies\t[1ST ATTEMPT FAILED]"
      at1="1ST - FAILED, 2ND - "
#      $bpath/OpC/opcragt -cleanstart $label
      $bpath/OpC/opcragt -distrib -templates $label -force
      sleep 10; nrec=1
      postcheck
    else
      echo "! Removing policies\t[FAILED]"
      exit 2
    fi
  else
    echo "  Removing policies\t[${at1}DONE]"
    exit 0
  fi
}

if $bpath/ovpolicy -host $label -remove -all -ovrg server;then
  $bpath/OpC/opcragt -distrib -templates $label -force
  sleep 5
  postcheck
else
  echo "! Removing request\t[ERROR]"
  exit 1
fi

### Old method. Takes a lot of time..
#$bpath/ovpolicy -host $label -list -ovrg server|grep "enabled"|egrep -v "OVO settings|OVO authorization|PMA_INI_BASE"|cut -d'"' -f2|while read str
#  do
#    [[ -n $str ]]&& $bpath/ovpolicy -remove -host $label -polname "$str" -ovrg server
#  done
