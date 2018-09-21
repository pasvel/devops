#!/usr/bin/sh

rotate () {
  cd $HOME/$2
  [ -a *.bak ]&& mv *.bak $HOME/tmp/rotate
  tar -cf ${2}.${YEAR}${1}.tar ${YEAR}${1}*_ihpmgm*
  gzip ${2}.${YEAR}${1}.tar
  mv $HOME/$2/${2}.${YEAR}${1}.tar.gz $HOME/backup
  mv $HOME/${2}/${YEAR}${1}*_ihpmgm* $HOME/tmp/rotate
#  echo "rm -f ${2}/${YEAR}${1}*_ihpmgm*"
}

if [ $# -eq 0 ];then
  echo "Usage: $0 month(s), f.e. 01 ... 04 05"
  exit 2
fi

HOME=/home/et4956
YEAR=`date '+%Y'`
[ ! -d $HOME/tmp/rotate ]&& mkdir /home/et4956/tmp/rotate

case $1 in
 01 ) m=Jan;;
 02 ) m=Feb;;
 03 ) m=Mar;;
 04 ) m=Apr;;
 05 ) m=May;;
 06 ) m=Jun;;
 07 ) m=Jul;;
 08 ) m=Aug;;
 09 ) m=Sep;;
 10 ) m=Oct;;
 11 ) m=Nov;;
 12 ) m=Dec;;
esac

echo "Working with log, $1"
cd $HOME/log
lst=$(ls -l|grep ${m}|egrep -v "tar|gz"|awk '{print $9}')
tar -cf log.${YEAR}${1}.tar $lst
gzip log.${YEAR}${1}.tar
mv $HOME/log/log.${YEAR}${1}.tar.gz $HOME/backup
mv $(echo $lst|tr '\n' ' ') $HOME/tmp/rotate
#echo "rm -f $(echo $lst|tr '\n' ' ')"

for str in banks hosts;do
  while [ $# -ne 0 ];do
    echo "Working with $str, $1"
    rotate $1 $str
    shift
  done
done

echo "Don't forget about $HOME/tmp/rotate"
