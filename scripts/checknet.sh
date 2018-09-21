#!/bin/bash

usg_ext () {
  echo -e "Usage: \e[93m${0}\e[0m [ARGUMENT1] [ARGUMENT2]"
  echo -e "  0 argument(s) mode - Highlight changes between YESTERDAY and TODAY: \e[93m${0}\e[0m"
  echo -e "  1 argument(s) mode - Highlight changes between ARGUMENT and TODAY: \e[93m${0} YYYYMMDD\e[0m, e.i. ${0} 20170901 "
  echo -e "  2 argument(s) mode - Highlight changes between ARGUMENT1 and ARGUMENT2: \e[93m${0} YYYYMMDD  YYYYMMDD\e[0m, e.i. ${0} 20170901 20170920 "
  exit ${1}
}

crt_log () {
  [ -e ${L2} ]&& rm -f ${L2}
  for dir in `find /var/log/net -mindepth 2 -type d -not -path "/var/log/net/hist/*"`;do
    echo -e "${D2}\t${dir}\t\c" >> ${L2}
    if [[ -z `ls ${dir}` ]];then
      echo "[EMPTY]" >> ${L2}
    else
      echo "[LOGGING]" >> ${L2}
    fi
  done
}

clr_tmp () {
  [ -a "${1}" ]&& rm -f ${1}
}

DATE=`date '+%Y%m%d'`
if [ $# -eq 0 ];then
  D2=${DATE}
  D1=`date '+%Y%m%d' -d yesterday`
else
  case $# in
    1 )
      if [[ ${1} == "help" ]]||[[ ${1} == "-h" ]];then
        usg_ext 0
      else D2=${DATE}; D1=${1}
      fi
    ;;
    2 ) D1=${1}; D2=${2};;
    * ) echo "Too many arguments! Terminatiing..."; usg_ext 1;;
  esac
fi

L=/var/log/net/hist
L1=/var/log/net/hist/${D1}.log
L2=/var/log/net/hist/${D2}.log

if [ ! -e ${L1} ];then
  echo "ERROR : No log file for ${D1}! Terminatiing..."
  exit 1
fi

[ $# -le 1 ]&& crt_log

clr_tmp "${L}/${D1}-${D2}.log"
diff --unchanged-line-format="" --old-line-format="-%L" --new-line-format="+%L" <(cut -f2,3 ${L1}|sort) <(cut -f2,3 ${L2}|sort) > /var/log/net/hist/${D1}-${D2}.tmp
for str in `cat ${L}/${D1}-${D2}.tmp|cut -f1|cut -d'/' -f6|sort|uniq`;do
  #echo "DEBUG ist1=$ist1, ist2=$ist2, str=$str, wc < ist2: `echo $ist2|wc -l`"; read
  k1=`grep -c ${str} ${L1}|cut -f3`
  k2=`grep -c ${str} ${L2}|cut -f3`
  if [ ${k1} -gt 1 ]||[ ${k2} -gt 1 ];then
    #echo "${str} : WARNING : 3+ dirs with current ip-address, investigation required"
    #echo "${str} : CHANGED : `grep ${str} ${L1}|cut -f2,3|sed "s/\n/ and /"` to `grep ${str} ${L2}|cut -f2,3|sed "s/\n/ and /"`"
    #echo "${str} : CHANGED : `grep ${str} ${L1}|cut -f2,3|tr '\t' ' '|tr '\n' '@'|sed 's/@[^$]/" and "/g;s/@$/"/;s/^/"/'` (${k1}) --> (${k2}) `grep ${str} ${L2}|cut -f2,3|tr '\t' ' '|tr '\n' '@'|sed 's/@[^$]/" and "/g;s/@$/"/;s/^/"/'`"
    echo -e "${str} : CHANGED : `grep ${str} ${L1}|cut -f2,3|tr '\t' ' '|tr '\n' '@'|sed 's/@[^$]/" and "/g;s/@$/"/;s/^/"/'` (${k1})\c"
    echo -e " --> \c"
    echo -e "(${k2}) `grep ${str} ${L2}|cut -f2,3|tr '\t' ' '|tr '\n' '@'|sed 's/@[^$]/" and "/g;s/@$/"/;s/^/"/'`"
    #echo "${str} : CHANGED : `grep ${str} ${L1}|cut -f2,3|tr '\t' ' '|tr '\n' '@'|sed "s/@[^$]/ and /g;s/@$/ /"` --> `grep ${str} ${L2}|cut -f2,3|tr '\t' ' '|tr '\n' '@'|sed "s/@[^$]/ and /g;s/@$/ /"`"
    continue
  fi 
  #if [ `grep -c ${str} ${L2}|cut -f3` -gt 1 ];then
  #  echo "${str} : CHANGED : \"`grep ${str} ${L1}|cut -f2,3`\" to \"`grep ${str} ${L2}|cut -f2,3|sed 2d`\" and \"`grep ${str} ${L2}|cut -f2,3|sed 1d`\". WARNING! Too many folders!"|tr '\t' ' '|tee -a ${L}/${D1}-${D2}.log
  #  continue
  #fi
  #if [ `grep -c ${str} ${L1}|cut -f3` -gt 1 ];then
  #  echo "${str} : CHANGED : \"`grep ${str} ${L1}|cut -f2,3|sed 2d`\" and \"`grep ${str} ${L1}|cut -f2,3|sed 1d`\" to \"`grep ${str} ${L2}|cut -f2,3`\". WARNING! Too many folders!"|tr '\t' ' '|tee -a ${L}/${D1}-${D2}.log
  #  continue
  #fi
  #[ `grep -c ${str} ${L2}|cut -f3` -gt 2 ]||[ `grep -c ${str} ${L1}|cut -f3` -gt 2 ]&& echo "${str} : ERROR : 3+ dirs with current ip-address, investigation required"

  ist1=`grep ${str} ${L1}|cut -f3`
  ist2=`grep ${str} ${L2}|cut -f3`

  if [ -n "${ist1}" ]&&[ -n "${ist2}" ];then
    if [[ "${ist1}" == "${ist2}" ]];then
      echo "${str} : CHANGED : `grep ${str} ${L1}|cut -f2` to `grep ${str} ${L2}|cut -f2`"|tee -a ${L}/${D1}-${D2}.log
    else
      #if [ `grep -c ${str} ${L2}|cut -f3` -gt 1 ];then
      #  echo "${str} : CHANGED : ${ist1} to `grep ${str} ${L2}|cut -f2,3|sed 2d|tr '\t' ' '` and `grep ${str} ${L2}|cut -f2,3|sed 1d|tr '\t' ' '`. WARNING! Too many folders!"|tee -a ${L}/${D1}-${D2}.log
      #else
      echo "${str} : CHANGED : ${ist1} to ${ist2}"|tee -a ${L}/${D1}-${D2}.log
      #fi
    fi
  fi
  [ -z "${ist1}" ]&&[ -n "${ist2}" ]&& echo "${str} : APPEARED : ${ist2} is current status"|tee -a ${L}/${D1}-${D2}.log
  [ -n "${ist1}" ]&&[ -z "${ist2}" ]&& echo "${str} : MISSED : ${ist1} is last confirmed status"|tee -a ${L}/${D1}-${D2}.log
done
clr_tmp "${L}/${D1}-${D2}.tmp"
