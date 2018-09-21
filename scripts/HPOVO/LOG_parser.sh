#!/usr/bin/sh

HOME=/home/et4956
rm -f LOG/* parser.lst

for fl in `ls LOG_org`;do
  [[ ! -s LOG_org/$fl ]]&& continue
  echo "Working with $fl --------------------------------------------------"
  ### Fucking echo transforms symbols like \t or \c, sed using is required
  cat $HOME/LOG_org/$fl|sed 's/\\t/\\\\t/g;s/\\c/\\\\c/g;s/\\b/\\\\b/g;s/\\a/\\\\a/g;s/\\f/\\\\f/g;s/\\v/\\\\v/g;s/\\n/\\\\n/g;s/\\r/\\\\r/g'|while read -r str;do
    pro=$(echo $str|tr -d '['|tr -d ']'|tr -d '\r')
#    if [[ "$pro" = "LOGMON" || "$pro" = "LOGFILE" || "$pro" = "FILEMON" ]];then
#      echo "  Directive, add new line, $pro"
#      [[ $n -gt 3 ]]&& echo >> LOG/$fl
#      echo "$str" >> LOG/$fl
#    else
      if [[ -z $pro ]];then
        echo "  Removing blank line"
        echo "$fl" >> parser.lst
        continue
      fi
      if [[ `echo "$pro"|cut -d'=' -f1` = "MessageGroup" ]];then
        echo "  MSG_GRP duplicate, removing"
        continue
      fi
      echo "$str" >> LOG/$fl
      if [[ `echo "$pro"|cut -d'=' -f1` = "ShortName" ]];then
        echo "  Adding MSG_GRP $pro"
        echo "$fl" >> parser.lst
        echo "MessageGroup=\"PM_CUST\"" >> LOG/$fl
      fi
#   fi
  done
done
