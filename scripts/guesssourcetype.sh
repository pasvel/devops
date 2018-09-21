#!/bin/bash

col1_out () {
#$1 - col1or, $2 - Text, $3 - Additional text
  case ${1} in
    red ) col1=31;;
    green ) col1=32;;
    yellow ) col1=33;;
  esac
  echo -e "\e[0;${col1}m${2}\e[m${3}"
echo
}

stf=~/sourcetypes.conf
stl=`cat ${stf}|grep "^\[extract_\w\+\]$"|tr -d '[]'`
for st in `echo ${stl}`;do
  #sec=`sed -n "/^\[${st}\]$/,/^$/p" ${stf}`
  #echo $sec
  sed -n "/^\[${st}\]$/,/^$/p" ${stf} > ${0}.tmp
  del=`grep DELIMS ${0}.tmp|awk {'print $3'}|tr -d '"'`
  fds=`grep FIELDS ${0}.tmp|awk {'print $3'}|tr -d '"'`

  echo; echo "${st}:"
  k=1; b=0; v=0;
  sed '1q;d' ${1}|tr "${del}" "\n" > ${0}.tmp
  for str in `echo ${fds}|tr "${del}" "\n"`;do
    val=`sed -n ${k}p ${0}.tmp`
    if [[ -n ${val} ]];then
      #col1=32
      col1=''
      let v+=1 
    else
      col1=31
      let b+=1
    fi

    col2='' 
    case ${str} in
      *port* ) [[ ${val} =~ ^[0-9]{2,4}$ ]]&& col2=32|| col2=33;;
      *ip* ) [[ ${val} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]&& col2=32|| col2=33;;
      * ) ;;
    esac

    echo -e "\e[0;${col1}m${str}\e[0m : \e[0;${col2}m${val}\e[m"
    let k+=1
  done

  echo; echo -e "${v}:\e[0;31m${g}\e[m:\e[0;31m${b}\e[m:\e[0;33m${y}\e[m"
  read
done
