#!/usr/bin/sh
#$1 - logname

sed 's/^[a-z]/@&/' $1|tr '@' '\n'|sed -e '/./{H;$!d;}' -e 'x;/ERROR/b' -e '/MISSED/b' -e d|sed /^$/d > tmp/loganalizer.tmp
grep "^[a-z]" tmp/loganalizer.tmp|awk '{print $1}'|cut -d. -f1|tr 'a-z' 'A-Z' > tmp/errors
more tmp/loganalizer.tmp

echo
echo "Servers with ERRORS: [tmp/errors]"
cat tmp/errors|sed 's/^/  /'

echo
echo "Do you want to save analized log? [y/N]"
read answer1

[[ -z $answer1 ]]&& answer1='n'
if [[ $answer1 = 'y' ]];then
  cp tmp/loganalizer.tmp $1.err
  echo "Analized log is located on $1.err"
fi
