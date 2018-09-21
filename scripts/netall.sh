#!/bin/bash

NET=/var/log/net
case $# in
  0 ) par=`ls ${NET}/all` ;;
  * )
    all=`echo $@|tr ' ' '|'`
    par=`ls ${NET}/all|egrep -w "${all}"`
  ;;
esac

for str in ${par};do
  if [ ! `ls -A ${NET}/all/${str}` ];then
    echo -e "[EMPTY]\t${NET}/all/${str}"
    #continue
  else
    lst=`find "${NET}" -name ${str} -not -path "${NET}/all/*"|tr '\n' ','|sed -e "s/,$//"`
    if [[ -n ${lst} ]];then
      let k=`echo ${lst}|tr -dc ','|wc -c`+1
      echo -e "[FOUND]\t`du -sh ${NET}/all/${str}` : (${k}) : ${lst}"
      #echo -e "[FOUND]\t`du -sh ${NET}/all/${str}|cut -f1`\t${str} : (${k}) : ${lst}"
    else
      echo -e "[UNIQ]\t`du -sh ${NET}/all/${str}`"
      #echo -e "[UNIQ]\t`du -sh ${NET}/all/${str}|cut -f1`\t${str}"
    fi
  fi
done
