#!/bin/bash

usg_ext () {
  echo "Usage: ${0} 1h|1d - Set interval for log rotation"
  exit 1
}

[ $# -eq 0 ]&& usg_ext

his=/var/log/hist/rotation-history.log
exl=/root/exclrot.lst
int=120
DATE=`date +"%Y%m%d"`
YEST=`date +"%Y%m%d" -d yesterday`
DAY2=`date +"%Y%m%d" -d "2 days ago"`

case ${1} in
  1h )
    #for s in `find /var/log/net -type f -mmin +${int}`;do
    for s in `find /var/log/net -name "*${DATE}[0-9][0-9]-*.log" -mmin +${int}`;do 
      echo "${DATE} `du -sh ${s}`" >> ${his}
      rm -f ${s}
    done
    exit 0
  ;;
  1d )
    #for s in `find /var/log/net -name "*${YEST}-*.log"`;do
    for s in `find /var/log/net -name "*${YEST}-*.log" -printf "%h\n"|uniq`;do
      arch=/var/log/arch/`echo ${s}|cut -d'/' -f5-6`
      #tar&remove or move?
      if ! grep -q `echo ${s}|cut -d'/' -f6` ${exl};then
        cd ${s}; tar -czf /var/log/arch/`echo ${s}|cut -d'/' -f5-6|tr '/' '_'`.tar.gz *${YEST}*
      fi
      echo "${YEST} `du -sh ${s}/*${YEST}*`" >> ${his}
      rm -f ${s}/*${YEST}*
      #[ ! -d ${arch} ]&& mkdir -p ${arch}; mv ${s} ${arch}
    done
    for r in `find /var/log/arch -name "*${DAY2}-*"`;do
      #tar before remove?
      #cd `echo ${r}|cut -d'/' -f-6`; tar -czf /var/log/arch/`echo ${r}|cut -d'/' -f5,6|tr '/' '_'`.tar.gz *
      echo "${YEST} `du -sh ${r}`" >> ${his}
      rm -f ${r}
    done
    exit 0
  ;;
  * )
    echo "Unknown argument! Terminating..."
    usg_ext
  ;;
esac
