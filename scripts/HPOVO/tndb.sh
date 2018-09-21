#!/usr/bin/sh

DATE=`date '+%Y%m%d'`*
[ -a tmp/tndb.tmp ]&& rm -f tmp/tndb.tmp

for str in `<$1`;do
  tmp=`grep -i $str banks/$DATE`
  node=`echo $tmp | awk {'print $1'} | cut -d: -f2`
  echo $node >> tmp/tndb.tmp
done
