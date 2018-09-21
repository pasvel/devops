#!/usr/bin/sh

HOME=/home/et4956
rm -f CFG/* parser.lst

for fl in `ls CFG_org`;do
  n=0
  echo "Working with $fl --------------------------------------------------"
  cat $HOME/CFG_org/$fl|while read str;do
    let n+=1
    tmp=${#str}
    if [[ $(expr substr "$str" 1 1 2>/dev/null) = '[' && $(expr substr "$str" "$tmp" 1 2>/dev/null) = ']' ]];then
      pro=$(echo $str|tr -d '['|tr -d ']')
      if [[ "$pro" = "PM_[A-Z]*" ]];then
        echo "Directive, add new line, $pro"
        [[ $n -gt 3 ]]&& echo >> CFG/$fl
        echo "$str" >> CFG/$fl
      else
        let tmp=$n+2
        user=$(sed -n ${tmp}p $HOME/CFG_org/$fl)
        if [[ ! -z $user && $(expr substr "$user" 1 5 2>/dev/null) = '@user' ]];then
          echo "  Fixing $pro"
          echo "$fl" >> parser.lst
          [[ $n -gt 3 ]]&& echo >> CFG/$fl
          echo "[PM_APP ${pro}_$(echo $user|sed 's/@user=//g')]" >> CFG/$fl
        else
          echo "  No user, do not touch $pro"
          [[ $n -gt 3 ]]&& echo >> CFG/$fl
          echo "$str" >> CFG/$fl
        fi
      fi
    else 
      echo "  Original str:$str"
      echo "$str" >> CFG/$fl
    fi
  done
done
