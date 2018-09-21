#!/usr/bin/sh
#$1 - NodeGroup(s)..

progress () {
  if [ $? -eq 0 ];then
    echo "[DONE]"
    cat ${HOME}/tmp/$1.tmp|grep -v "^en"|sed /^$/d >> ${HOME}/list/$1.lst
  else
    echo "[ERROR]"
    cat ${HOME}/tmp/$1.tmp|sed '/^ *$/d;s/^/    /'
  fi
}

HOME=`pwd`
PASD=/home/et4956
bpath=/opt/OV/bin

[ -a ${HOME}/mass.sh ]&& rm -f ${HOME}/mass.sh
[ -a ${HOME}/list/$1.lst ]&& rm -f ${HOME}/list/$1.lst
[ -a ${HOME}/log/$1.err ]&& rm -f ${HOME}/log/$1.err
[ -a ${HOME}/log/bigredepl.log ]&& rm -f ${HOME}/log/bigredepl.log
[ -a ${HOME}/list/bigredepl.lst ]&& rm -f ${HOME}/list/bigredepl.lst

if [ $# -eq 0 ];then echo "Usage: $0 NodeGroup1 NodeGroup2 ... NodeGroupN"; exit; fi

while [ $# -ne 0 ];do
  echo "################################################################################"
  case `grep "$1" ${PASD}/templates|awk {'print $1'}` in
    U )
      CMD="$bpath/OpC/utils/opcnode -list_ass_nodes group_name=$1|grep Label"
      for mgm in ihpmgm01 ihpmgm02 ihpmgm05 ihpmgm41 ihpmgm42;do
        echo "  Downloading $1 members from $mgm..."|tr '\n' '\t'
        $bpath/ovdeploy -node $mgm -cmd "$CMD" -ovrg server > ${HOME}/tmp/$1.tmp
        progress $1 "awk {'print \$3'}"
      done

      if [ -a ${HOME}/list/$1.lst ];then
        cat ${HOME}/list/$1.lst|awk {'print $3'}|sort|uniq > ${HOME}/tmp/$1.tmp
        mv ${HOME}/tmp/$1.tmp ${HOME}/list/$1.lst; echo
      else echo "  No assigned servers found for $1"
      fi
    ;;
    W )
      CMD="ovownodeutil -list_nodes -group_path `grep "$1" ${PASD}/templates|awk {'print $3'}`\\\\$1\""
      for mgm in ihpmgm41 ihpmgm02 ihpmgm03;do
        case $mgm in
          ihpmgm01|ihpmgm05|ihpmgm41|ihpmgm42 ) winmgm=146.192.79.150;;
          ihpmgm02 ) winmgm=10.219.35.14;;
          ihpmgm03 ) winmgm=134.47.99.203;;
        esac
        echo "  Downloading $1 members from $winmgm..."|tr '\n' '\t'
        $bpath/ovdeploy -node $mgm -cmd "$bpath/ovdeploy -node $winmgm -cmd \"$CMD\" -ovrg server" -ovrg server > ${HOME}/tmp/$1.tmp
        progress $1
      done

      if [ -a ${HOME}/list/$1.lst ];then
        cat ${HOME}/list/$1.lst|cut -d. -f1|sort|uniq > ${HOME}/tmp/$1.tmp
        mv ${HOME}/tmp/$1.tmp ${HOME}/list/$1.lst; echo
      else echo "  No assigned servers found for $1"
      fi
    ;;
  esac

  if [ -a ${HOME}/list/$1.lst ];then
    sh ${PASD}/check.sh ${HOME}/list/$1.lst; echo
    echo "--------------------------------------------------------------------------------"
    if [ -a ${HOME}/log/check.err ];then
      cat ${HOME}/log/check.err > ${HOME}/log/$1.err
      echo "  Log saved: "|tr -d '\n'; echo "${HOME}/log/$1.err"|tee -a ${HOME}/log/bigredepl.log
    fi
    if [ -a ${HOME}/tmp/deploy ];then
      cat ${HOME}/tmp/deploy > ${HOME}/list/$1.lst
      echo "  List saved: "|tr -d '\n'; echo "${HOME}/list/$1.lst"|tee -a ${HOME}/list/bigredepl.lst
    fi
    echo "  Command for executing: "|tr -d '\n'; echo "sh ${PASD}/pasvel.sh -f ${HOME}/list/$1.lst -r|tee ${HOME}/log/$1.log"|tee -a ${HOME}/mass.sh
  fi
  shift
done

if [ -a ${HOME}/mass.sh ];then
  echo "################################################################################"
  echo "Final command for executing: ${HOME}/mass.sh|tee ${HOME}/log/mass.log"
  cat ${HOME}/mass.sh|sed 's/^/  /'
fi

if [ -a ${HOME}/list/bigredepl.lst ];then
  echo "All list files ${HOME}/list/bigredepl.lst"
  cat ${HOME}/list/bigredepl.lst|sed 's/^/  /'
fi

if [ -a ${HOME}/log/bigredepl.log ];then
  echo "Error logs: ${HOME}/log/bigredepl.log"
  cat ${HOME}/log/bigredepl.log|sed 's/^/  /'
fi
echo
