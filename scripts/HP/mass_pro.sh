#!/usr/bin/sh

areyousure () {
  cat PRCS/${node}|sed 's/^/  /'
  echo "-------------------------------------------------------------------------------"
  echo "Upload config \"as is\" to ${node}? [Y/r(eread)/s(kip)/d(elete)]"

  read answer1
  [[ -z $answer1 ]]&& answer1='y'
  if [ $answer1 = 'y' ];then
###    echo "  Doing something important..."
    sh pasvel.sh -q -h ${node} -u PRCS/${node} procmon_local.cfg /var/opt/OV/conf/osspi
    mv PRCS/${node} PRCS/uploaded/${node}
    echo ${node} >> tmp/donelst
  fi
}

touch tmp/donelst tmp/skiplst tmp/emptlst tmp/excllst tmp/errolst tmp/canclst
pattern1=`cat tmp/donelst|tr '\n' '|'`; [[ -z $pattern1 ]]&& pattern1=YAYAYA
pattern2=`cat tmp/skiplst|tr '\n' '|'`; [[ -z $pattern2 ]]&& pattern2=YAYAYA
pattern3=`cat tmp/emptlst|tr '\n' '|'`; [[ -z $pattern3 ]]&& pattern3=YAYAYA
pattern4=`cat tmp/excllst|tr '\n' '|'`; [[ -z $pattern4 ]]&& pattern4=YAYAYA
pattern5=`cat tmp/errolst|tr '\n' '|'`; [[ -z $pattern5 ]]&& pattern5=YAYAYA
pattern6=`cat tmp/canclst|tr '\n' '|'`; [[ -z $pattern6 ]]&& pattern6=YAYAYA
#egrep -v "${pattern1}${pattern2}${pattern3}${pattern4}${pattern5}`echo ${pattern6%'|'}`" tmp/deploy > tmp/prcslst
ls -l PRCS|awk '{print $9}' > tmp/templst
egrep -v "${pattern1}${pattern2}${pattern3}${pattern4}${pattern5}`echo ${pattern6%'|'}`" tmp/templst > tmp/prcslst

for node in `<tmp/prcslst`;do
  nnode1=$(sed -n "/${node}/,\$p" tmp/prcslst|head -2|tail -1)
  nnode2=$(sed -n "/${nnode1}/,\$p" tmp/prcslst|head -2|tail -1)
  echo;echo "Working with ${node}, TNDB:`perl mssql.pl ${node}|grep ${node}|cut -d: -f3` (next ones: $nnode1,$nnode2):"
  echo "################################################################################"
  if [ -a PRCS/${node} ];then
    areyousure
    case $answer1 in 
      's' )
        echo "  Skipping..."
        echo ${node} >> tmp/skiplst
        continue
      ;;
      'r' )
        areyousure
      ;;
      'd' )
        echo "Deleting config..."
        echo ${node} >> tmp/canclst
        rm -f PRCS/${node}
      ;;
    esac
  else
    echo "  No config found"
    echo ${node} >> tmp/emptlst    
  fi
done
