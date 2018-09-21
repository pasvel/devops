#!/usr/bin/sh

if [ $(cat lst|tr 'a-z' 'A-Z'|wc -l) -eq $(cat lst|cut -d. -f1|tr 'a-z' 'A-Z'|sort|uniq|wc -l) ];then
  tr '\t| ' '\n'<lst|tr 'a-z' 'A-Z'|cut -d. -f1 > /home/et4956/tmp/nodelist
  exit 0
else 
  echo "Duplicate is found in lst file"
  cat lst|tr 'a-z' 'A-Z'|cut -d. -f1|sort|uniq -d
  exit 1
fi
