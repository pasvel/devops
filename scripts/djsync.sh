#!/bin/bash
#$1 - src, $2 - dst, $3 - obj

lst=/splunk/dj_go.lst
cert=/root/.ssh/pasvel-dj
user=ne221223

get_ipa () {
  sec=`grep -i "^#.*(${1::-1}):$" ${lst}`
  if [ ${1:2:1} -gt `sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"|wc -l` ];then
    echo -e "Unknown shortcut! Please use existing one from the list below\n"
    /root/go.sh|egrep -v "^Usage|^$"
    exit 1
  fi
  scpe=`sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"|awk {'print $2'}`
  #pair=`sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"|sed -n "${1:2:1}p"`
  #ip=`echo ${pair}|awk {'print $2'}`
  ip=`echo "${scpe}"|sed -n "${1:2:1}p"`

}

chk_arg () {
  case ${1} in
    [a-z][a-z][0-9] ) get_ipa ${1} ;;
    [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ) ip=${1} ;;
    lo|my ) ;;
    [a-z][a-z][sSxX] ) get_ipa "${1::-1}1" ;;
    * ) echo "Unknown argument! Terminating..."; exit 1 ;;
  esac
}

if [[ $# -eq 0 || $# -gt 3 ]];then
  echo "Usage: $1 - src, $2 - dst, $3 - /path/obj"
  echo "Use Xx or Ss at the end to sync with group of servers, f.e. slX for all syslogs"
  exit 0
else
  chk_arg ${1}
  src=${ip}
  chk_arg ${2}
  dst=${ip}
fi

if [[ ! ${1} =~ lo|my ]];then
  sobj=${3}
  dobj=/root/rsync${3}
  [ ! -d `dirname ${dobj}` ]&& mkdir -p `dirname ${dobj}`
  echo -e "  Copying ${src}:${sobj} to ${dobj}...\t\c"
  /bin/rsync -azh -e "ssh -qi ${cert}" --rsync-path="sudo rsync" ${user}@${src}:${sobj} ${dobj}&& echo "[ OK ]"|| echo "[ FAIL ]"
else
  dobj=$3
  sobj=`echo ${dobj}|sed "s/\/root\/rsync//"`
fi
if [[ ! ${2} =~ lo|my ]];then
  [[ ! ${2} == [a-z][a-z][SsXx] ]]&& scpe=${dst}
  if [[ ! ${1:1:2} == ${2:1:2} && ! ${1} =~ lo|my ]];then
    scpe=`echo "${scpe}"|grep -v ${src}`
  fi
  #for dst in `echo "${scpe}"|grep -v ${src}`;do
  #for dst in `[[ ${1:1:2} == ${2:1:2} ]]&& echo "${scpe}"|| echo "${scpe}"|grep -v ${src}`;do
  for dst in ${scpe};do
    echo -e "  Copying ${dobj} to ${dst}:${sobj}...\t\c"
    /bin/rsync -azh -e "ssh -qi ${cert}" --rsync-path="sudo rsync" ${dobj} ${user}@${dst}:${sobj}&& echo "[ OK ]"|| echo "[ FAIL ]"
  done
fi
