#!/usr/bin/sh

spipath=/var/opt/OV/conf/osspi
hash=osspi_fsmon-hash.cfg

res=`find ${spipath} -name ${hash}|wc -l`
if [ "${res}" -eq "1" ];then

  ltime=`perl -e "use Time::localtime; print time();"`
  ftime=`perl -e "use File::stat; print stat(@ARGV[0])->mtime;" ${spipath}/${hash}`
  difft=`perl -e "use integer; print ((${ltime} - ${ftime})/60);"`

  if [ "${difft}" -lt "15" ];then
    echo "  OSSPI HASH file	[UPDATED:${difft}min]"
  else
    echo "! OSSPI HASH file	[ERROR:${difft}min]"
  fi
else
  echo "! OSSPI HASH file	[MISSED]"
fi
