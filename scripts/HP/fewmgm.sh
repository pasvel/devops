#!/usr/bin/sh

hprepl () {
### Fix config if wrong value was found, f.e. ihpmgm11 instead of ihpmgm01. If value is OK - do nothing..
##echo "  Do you want to change $2 to $MGM.mgmt.oper.no? [Y/n]"
##read answer0; [[ -z $answer0 ]]&& answer0='y'
##if [ $answer0 = 'y' ];then
  ovdepl="$bpath/ovdeploy -node $label -cmd \"ovconfchg -ns $1 -set $2 $MGM.mgmt.oper.no\" $ovrg"
  $bpath/ovdeploy -node $MGM -cmd "$ovdepl" $ovrg|sed /^$/d && echo "  $2 value has been fixed, correct mgm is $MGM"
  manfix=0
##fi
}

DATE=`date '+%Y%m%d'`
bpath=/opt/OV/bin; ovrg="-ovrg server"
manfix=1
PASD=/home/et4956; HOME=`pwd`
[ -a $HOME/tmp/fewmgm.tmp ]&& rm -f $HOME/tmp/fewmgm.tmp

for str in `<$HOME/tmp/fewmgm.lst`;do
  label=`echo $str|cut -d: -f1`
  echo "$label:"
  CMD="^${label}[ |	|\.]"
  echo $str|cut -d: -f2|tr ',' '\n'|while read mgm;do
    if $bpath/ovdeploy -node $mgm -cmd "$bpath/OpC/opcragt $label" $ovrg > $HOME/tmp/fewmgm.tmp;then
      $bpath/ovdeploy -node $mgm -cmd "$bpath/ovdeploy -node $label -cmd \"ovconfget\" $ovrg" $ovrg > $HOME/tmp/fewmgm.tmp
      echo "  Current config, ihpmgm records:"
      cat $HOME/tmp/fewmgm.tmp|grep ihpmgm|sed 's/^/    /'
      break
    else
      echo "! ERROR: Agent's status is unreachable from $mgm!"
      cat $HOME/tmp/fewmgm.tmp|sed -n "/Node `echo $label|tr 'A-Z' 'a-z'`/,\$p"|sed '/^ *$/d;s/^/    /'
      continue
    fi
  done

  if [ -a $PASD/banks/${DATE}_$mgm ];then
    node=`grep -i "$CMD" $PASD/banks/${DATE}_$mgm|awk {'print $1'}|cut -d: -f2`
    echo "  Choose mgm's NUMBER for $node [`echo $mgm|sed 's/ihpmgm//'`]:"
    read answer1; [[ -z $answer1 ]]&& answer1=`echo $mgm|sed 's/ihpmgm//'`
    mgm="ihpmgm$answer1"; MGM=$mgm
    hosts=`$bpath/ovdeploy -node $mgm -cmd "grep -i $label /etc/hosts" $ovrg|sed /^$/d`

    for hpval in OPC_PRIMARY_MGR general_licmgr CERTIFICATE_SERVER MANAGER=;do
      mgm=`grep $hpval $HOME/tmp/fewmgm.tmp|cut -d= -f2|cut -d. -f1`
      case $mgm in
        ihpmgm11|ihpmgm14 ) mgm=ihpmgm01;;
        ihpmgm17|ihpmgm18 ) mgm=ihpmgm05;;
        ihpmgm21 ) mgm=ihpmgm02;;
        ihpmgm31 ) mgm=ihpmgm03;;
        ### We skip hprepl execution here!
        * ) [[ -z $mgm || $mgm = $MGM ]]&& continue
      esac
      [[ $hpval != 'MANAGER=' ]]&& hprepl `sed -e '/./{H;$!d;}' -e "x;/$hpval/!d" $HOME/tmp/fewmgm.tmp|grep "\[.*\]"|tr -d []` $hpval
    done

##    if [ $manfix -eq 0 ];then
##      $bpath/ovdeploy -node $mgm -cmd "$bpath/ovdeploy -node $label -cmd \"ovconfget\" $ovrg" $ovrg > $HOME/tmp/fewmgm.tmp
##      cat $HOME/tmp/fewmgm.tmp|grep ihpmgm|sed 's/^/    /'
##    fi
##    echo "  Do you really want to remove $node from $(echo $str|cut -d: -f2|sed "s/,*ihpmgm$answer1,*//g") and keep it on ihpmgm$answer1 [Y/n]?"
##    read answer2; [[ $answer2 = 'n' ]]&& continue; [[ -z $answer2 ]]&& answer2='y'

    echo $str|cut -d: -f2|tr ',' '\n'|grep -v $answer1|while read rem;do
      if [ $rem != ihpmgm43 ];then
        echo; echo "  Layout group on $rem\t[`$bpath/ovdeploy -node $rem -cmd \"sh $bpath/OpC/call_sqlplus.sh sel_laygrp $node\" $ovrg|sed '/^$/d'`]"
        echo "  NodeGropus on $rem:"
        $bpath/ovdeploy -node $rem -cmd "sh /home/et4956/nglist.sh $node" $ovrg|sed '/^$/d;s/^/    /'
      fi
      echo; echo "  Removing $node from $rem..."
      $bpath/ovdeploy -node $rem -cmd "/opt/OV/edb/bin/deleteNode.sh $node" $ovrg|sed '/^$/d;s/^/    /'; echo
      cat $PASD/banks/${DATE}_$rem|grep -v $node > $HOME/tmp/fewmgm.tmp
      cp $HOME/tmp/fewmgm.tmp $PASD/banks/${DATE}_$rem > /dev/null && echo "  Updating $rem banks file"
    done
    $bpath/ovdeploy -node $mgm -cmd "if ! grep -iq $label /etc/hosts;then echo \"$hosts\" >> /etc/hosts;fi" $ovrg > /dev/null && echo "  Updating /etc/hosts"
  fi
done
