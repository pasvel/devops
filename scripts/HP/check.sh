#!/usr/bin/sh
#nodelist - input file. Should be in `pwd`/tmp dir.
echo "################################################################################"
echo "##     (c) pasvel, 2012 (pasvel@gmail.com). The first steps of SkyNet! :)     ##"
echo "################################################################################"
echo

bpath=/opt/OV/bin
DATE=`date '+%Y%m%d'`
PASD=/home/et4956; HOME=`pwd`

if [ $# -eq 0 ];then
  loop=$(<$HOME/tmp/nodelist)
else
  if [[ -a $1 && -z $2 ]];then
    loop=$(<$1)
  else
    loop=$(echo $@|tr ' ' '\n')
  fi
fi

sep="-------------------------------------------------------------------------------"
for mgm in 01 02 03 05 41 42 43;do
  [ ! -a ${PASD}/banks/${DATE}_ihpmgm${mgm} ]&& tmp="${tmp}${mgm} "
done
if [[ ! -z $tmp ]];then
  echo "!${sep}"; echo "Update NodeBank files for [${tmp% }] (${PASD}/banks.sh ${tmp% })"; echo "${sep}!"
  exit 1
fi

tot=$(echo "$loop"|wc -l); cou=1

[ -a $HOME/log/check.err ]&& rm -f $HOME/log/check.err
[ -a $HOME/tmp/deploy ]&& mv $HOME/tmp/deploy{,.bak}
[ -a $HOME/tmp/fewmgm.lst ]&& rm -f $HOME/tmp/fewmgm.lst
[ -a $HOME/tmp/ihpmgm43 ]&& rm -f $HOME/tmp/ihpmgm43
[ -a $HOME/move.sh ]&& rm -f $HOME/move.sh
[ -a $HOME/remove.sh ]&& rm -f $HOME/remove.sh
echo `date` > $HOME/log/check.log; echo >> $HOME/log/check.log

for str in `echo $loop|tr 'a-z' 'A-Z'`;do
  echo "Progress: $cou / $tot"|tr '\n' '\r'; let cou+=1
  CMD="^${str}[ |	|\.]"
  tmp=`grep -i "$CMD" $PASD/banks/${DATE}_ihpmgm[04][1235]`
  if [[ ! -z $tmp ]];then
    if [ `echo "$tmp"|wc -l` -gt 1 ];then
      tmp=`echo "$tmp"|sed 's/.*_ihpmgm/ihpmgm/'|cut -d: -f1|tr '\n' ','`
      echo "$str\t- is located on ["${tmp%,}"] managers" >> $HOME/log/check.err
      echo "$str:${tmp%,}" >> $HOME/tmp/fewmgm.lst
      continue
    fi

    mgm=`echo $tmp|cut -d: -f1|cut -d_ -f2`;
    node=`echo $tmp|cut -d: -f2|awk {'print $1'}`
    nodeip=`echo $tmp|awk {'print $2'}`

    case $mgm in
      ### Execute everything on parent manager. Slower, but it's Jedi-way
      ihpmgm02|ihpmgm03 )
        [ -a $HOME/tmp/chemote.sh ]&& rm -f $HOME/tmp/chemote.sh
        echo "ping $nodeip 64 -n 2 -m 2 >/dev/null 2>&1" > $HOME/tmp/chemote.sh
        echo "if [ \$? -eq 0 ];then echo \"$mgm:$str\t- PING to [$nodeip] is OK\"" >> $HOME/tmp/chemote.sh
        echo "$bpath/bbcutil -ping $nodeip >/dev/null 2>&1" >> $HOME/tmp/chemote.sh
        echo "if [ \$? -eq 0 ];then echo \"$mgm:$str\t- BBCUTIL is OK\"; else echo \"$str\t- BBCUTIL from $mgm to [$nodeip] is failed\"; fi">>$HOME/tmp/chemote.sh
        echo "else echo \"$str\t- PING from $mgm to [$nodeip] is failed\"; fi" >> $HOME/tmp/chemote.sh
        $bpath/ovdeploy -upload -file $HOME/tmp/chemote.sh -sd $HOME -node $mgm -td $HOME/tmp -ovrg server >/dev/null 2>&1
        $bpath/ovdeploy -node $mgm -cmd "sh $HOME/tmp/chemote.sh" -ovrg server|sed /^$/d > $HOME/tmp/check.tmp
        tmp=`grep -i "failed" $HOME/tmp/check.tmp`
        if [[ -z $tmp ]];then
          echo $str >> $HOME/tmp/deploy
          cat $HOME/tmp/check.tmp >> $HOME/log/check.log
        else echo $tmp >> $HOME/log/check.err
        fi
      ;;

      ### Execute everything on 250. Faster, but can be false errors
      * )
        if ping $nodeip 64 -n 2 -m 2 >/dev/null 2>&1;then
          echo "$mgm:$str\t- PING to [$nodeip] is OK" >> $HOME/log/check.log
          if $bpath/bbcutil -ping $nodeip >/dev/null 2>&1;then
            echo "$mgm:$str\t- BBCUTIL is OK" >> $HOME/log/check.log
            if [ $mgm != ihpmgm43 ];then
              echo $str >> $HOME/tmp/deploy
            else
              echo $str >> $HOME/tmp/ihpmgm43
              RCMD="/progs/powermon/utilities/Powertool/bin/change_manager.sh -n $node -m ihpmgm\${1}.mgmt.oper.no"
              echo "$bpath/ovdeploy -node ihpmgm43 -cmd \"$RCMD\" -ovrg server" >> $HOME/move.sh
              echo "$bpath/ovdeploy -node ihpmgm43 -cmd \"/opt/OV/edb/bin/deleteNode.sh $node\" -ovrg server" >> $HOME/remove.sh
              echo "$str\t- Located on [ihpmgm43: $node, $nodeip] and has to be moved" >> $HOME/log/check.err
            fi
          else echo "$str\t- BBCUTIL from $mgm to [$nodeip] is failed" >> $HOME/log/check.err
          fi
        else echo "$str\t- PING from $mgm to [$nodeip] is failed" >> $HOME/log/check.err
        fi
    esac
  else
    echo "$str\t\t- IS NOT in NodeBank (perl pm-configure-hpagent.pl -i IP-ADDRESS -m MANAGER)" >> $HOME/log/check.err
  fi
done; echo; echo

[ -a $HOME/log/check.err ]&& cat $HOME/log/check.err; echo
if [[ -a $HOME/tmp/deploy && `wc -l < $HOME/tmp/deploy` -lt 100 ]];then
  tr '\n' ' ' < $HOME/tmp/deploy > $HOME/tmp/deploy.tmp; echo " are OK and ready for policy deploying" >> $HOME/tmp/deploy.tmp
  cat $HOME/tmp/deploy.tmp|sed "s/  are/ are/"; rm -f $HOME/tmp/deploy.tmp
fi
