#!/usr/bin/sh

for str in `<$1`;do
  perl mssql.pl $str
done
echo;echo
