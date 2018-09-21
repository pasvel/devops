#!/usr/bin/sh
#$1 - logname, $2 - pattern

HOME=`pwd`
if [ $# -eq 0 ];then
  logfile=${HOME}/log/pasvel.log
else logfile=$1
fi

if [[ -z $2 ]];then
  sed 's/^[a-z]/#&/' $logfile|tr '#' '\n'|sed -e '/./{H;$!d;}' -e 'x;/\[ERROR\]/b' -e '/\[MISSED\]/b' -e '/!/b' -e d|sed '/^ *$/d' > ${HOME}/tmp/analizer.tmp
else
  sed 's/^[a-z]/#&/' $logfile|tr '#' '\n'|sed -e '/./{H;$!d;}' -e "x;/$2/!d"|sed '/^ *$/d' > ${HOME}/tmp/analizer.tmp
fi

if [ -s ${HOME}/tmp/analizer.tmp ];then
  grep "^[a-z]" ${HOME}/tmp/analizer.tmp|awk '{print $1'}|cut -d. -f1|tr 'a-z' 'A-Z' > ${HOME}/tmp/errors
  less ${HOME}/tmp/analizer.tmp

  echo 
  echo "Servers with ERRORS: [${HOME}/tmp/errors]"
  cat ${HOME}/tmp/errors|sed 's/^/  /'

  echo
  echo "Do you want to save analized log? [y/N]"
  read answer1

  [[ -z $answer1 ]]&& answer1='n'
  if [[ $answer1 = 'y' ]];then
    cp ${HOME}/tmp/analizer.tmp ${logfile}.err
    echo "Analized log is saved on ${logfile}.err"
  fi
fi
