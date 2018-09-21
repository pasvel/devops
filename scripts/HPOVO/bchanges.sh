#!/usr/bin/sh
#$1 - NEWER date, $2 - OLDER!!!

if [ $# -lt 2 ];then
  echo "Usage: $0 NEWER_Date OLDER_Date"
  exit 2
fi

for mgm in ihpmgm01 ihpmgm02 ihpmgm03 ihpmgm05 ihpmgm41 ihpmgm42;do
  if [[ -a banks/$1_$mgm && -a banks/$2_$mgm ]];then
    echo "$mgm\t[`wc -l < banks/$1_$mgm` <- `wc -l < banks/$2_$mgm`]"
    diff banks/$1_$mgm banks/$2_$mgm|sed -n "s/</NEW	/p;s/>/OLD	/p"|sort -k2 -u|sed 's/^/  /'
  else echo "ERROR: File(s) not found!"; exit 1
  fi
done
