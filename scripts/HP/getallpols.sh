#!/usr/bin/sh

ugetpols () {
  [ -a $HOME/tmp/getallpols.tmp ]&& rm -f $HOME/tmp/getallpols.tmp
  $bpath/OpC/opctmplrpt $1|grep MEMBER|sed 's/"//g'|while read pol;do
    if [ `echo $pol|awk '{print $1}'` != MEMBER_TEMPLATE_GROUP ];then
      echo "$polgrp:`echo $pol|awk '{print $2}'`" >> $HOME/policies
      echo "  `echo $pol|awk '{print $2}'`"
    else
      echo $pol|awk '{print $2}' >> $HOME/tmp/getallpols.tmp
    fi
  done

  if [ -s $HOME/tmp/getallpols.tmp ];then
    cat $HOME/tmp/getallpols.tmp|while read pol;do
      ugetpols $pol
    done
  fi
}

wgetpols () {
  [ -a $HOME/tmp/getallpols.tmp ]&& rm -f $HOME/tmp/getallpols.tmp

  val="C:\\TEMP\\sel_polsbypg.bat $@" 
  $bpath/ovdeploy -node 146.192.79.150 -cmd "$val" $ovrg|sed /^$/d > $HOME/tmp/getallpols.req

  if egrep -iq "^Msg [0-9]|error|fail|warn|crit" $HOME/tmp/getallpols.req;then
    echo "  [WARNING!]\t>> $HOME/tmp/getallpols.err"
    echo "  $@:" >> $HOME/tmp/getallpols.err
    cat $HOME/tmp/getallpols.req|sed 's/^/    /'|tee -a $HOME/tmp/getallpols.err
  else
    if ! grep -q "[A-Z0-9]-.*-.*-.*-.*" $HOME/tmp/getallpols.req;then
      sqlcmd="select Name from openview.dbo.OV_PM_PolicyGroup where ParentGroupId=(select GroupId from openview.dbo.OV_PM_PolicyGroup where Name=\'$@\');"
      $bpath/ovdeploy -node 146.192.79.150 -cmd "$osql \"$sqlcmd\"" $ovrg|grep "PM[UW]" >> $HOME/tmp/getallpols.tmp
    else
      cat $HOME/tmp/getallpols.req|grep "[A-Z0-9]-.*-.*-.*-.*"|while read pol;do
        sqlcmd="select Name from openview.dbo.OV_PM_Policy WHERE PolicyId = \'$pol\'"
        $bpath/ovdeploy -node 146.192.79.150 -cmd "$osql \"$sqlcmd\"" $ovrg|grep "PM[UW]"|while read str;do
          echo "$polgrp:$str" >> $HOME/policies
          echo "  $str"
        done
      done
    fi
  fi

  if [ -s $HOME/tmp/getallpols.tmp ];then
    cat $HOME/tmp/getallpols.tmp|while read pol;do
      wgetpols $pol
    done
  fi
}

bpath=/opt/OV/bin
HOME=/home/et4956
ovrg="-ovrg server"
osql="osql -E -S \"IMP-P02-OMW-001\OVOPS\" -d openview -Q"
[ -a $HOME/tmp/getallpols.* ]&& rm -f $HOME/tmp/getallpols.*

if [ $# -eq 0 ];then
  ### Windows policies groups. osql only
  for polgrp in `grep "^W " templates|awk '{print $2}'`;do
    echo "$polgrp:"
    wgetpols $polgrp
  done

  ### Unix policies groups. Built-in script,I'm going to replace by sql request - it will be faster
  for polgrp in `grep "^U " templates|egrep -v "RESP|AppHeart"|awk '{print $2}'`;do
    echo "$polgrp:"
    ugetpols $polgrp
  done
else
  while [ $# -ne 0 ];do
    echo "$1:"
    case `grep $1 templates|awk '{print $1}'` in
      W ) polgrp=$1; wgetpols $1;;
      U ) polgrp=$1; ugetpols $1;;
    esac
    shift
  done
fi

if [ -a $HOME/tmp/getallpols.err ];then
  echo; echo "Issues:"
  cat $HOME/tmp/getallpols.err
fi
