#!/bin/bash

err_msg () {
  echo "${1}"
  exit 1
}

chk_net () {
  if [[ ${1} == *"10.146."* || ${1} == "192.168.101.30" ]];then
    sshc="-q ${user}${1}"
  else
    sshc="-qtt ${user}192.168.101.30 ssh -qtt ${user}${1}"
  fi
}

#Link to file with servers list
lst=/splunk/dj_go.lst
[ ! -f ${lst} ]&& err_msg "Error: List file ${lst} is missing! Terminating..."

if [[ `id -un` == root ]];then
  user="ne221223@"
  key="-i .ssh/pasvel-dj "
fi

if [ $# -eq 0 ];then
  echo "Usage: $0 SERVERS_SHORTCUT, f.e: $0 if5"; echo
  cat ${lst}|grep "^#"|while read sec;do
    k=1; echo ${sec}
    sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"|while read ser;do
      echo "  `echo ${sec,,}|awk -F"[()]" '{print $2}'`${k} ${ser}"
      let k+=1
    done    
  done
  exit 0
else
  sec=`grep -i "^#.*(${1::-1}):$" ${lst}`
  [[ -z ${sec} ]]&& sec=TERM
  #[[ ${1:2:1} -gt `sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"|wc -l` ]]&& err_msg "It's very funny, rly! ;) Please run script again and pick-up existing server this time"
  scpe=`sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"`
  case ${1} in
    [a-z][a-z][0-9] )
      [[ ${1:2:1} -gt `echo "${scpe}"|wc -l` ]]&& err_msg "It's very funny, rly! ;) Please run script again and pick-up existing server this time"
      #pair=`sed -n "/${sec}/,/^#/p" ${lst}|grep -v "^#"|sed -n "${1:2:1}p"`
      pair=`echo "${scpe}"|sed -n "${1:2:1}p"`
      scpe=`echo ${pair}|awk {'print $2'}`
      #ip=`echo ${pair}|awk {'print $2'}`
      #scpe=${ip}
    ;;
    [a-z][a-z][SsXx] )
      pair=`echo "${scpe}"`
      scpe=`echo "${scpe}"|awk {'print $2'}`
    ;;
    * ) err_msg "Unrecognized shortcut format! Terminating..." ;;
  esac

  if [[ -z ${2} ]];then
    [[ ${1} == [a-z][a-z][SsXx] ]]&& err_msg "You can't connect via ssh to the group of servers, cmon! Terminating..."
    echo "###Connecting to ${pair} via ssh..."
    chk_net ${scpe}
    ssh ${key}${sshc}
  else
    for ip in ${scpe};do
      echo "###Executing \"${2}\" on `echo "${pair}"|grep ${ip}`:"
      chk_net ${ip}
      ssh -t ${key}${sshc} "${2}"
    done
  fi
fi
