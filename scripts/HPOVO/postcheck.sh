#!/usr/bin/sh
#$1 - hostname

#cut -d' ' -f2 templates > pols

#/opt/OV/bin/ovpolicy -ovrg server -list -host $1|egrep "enabled|disabled"|egrep -v "OVO settings|OVO authorization|opcmsg\(1|3\)"|cut -d\" -f2 > tempo1
excl="PM[UW]_HW"
#echo "pasvel" > tempo2

while [ TRUE ];do
  egrep -v "$excl" tempo1 > tempo2; bf=1
  [[ ! -s tempo2 ]]&& break

#  for str in `<tempo2|sed 's/-/_/g'`;do 
  for str in `sed 's/-/_/g' tempo2`;do
    cou=`echo $str | tr -cd "_" | wc -c`; k=$cou
echo "DEBUG cou=$cou"
echo "DEBUG str=$str"
    while [ $k -ne 2 ];do
      pol=`echo $str | cut -d_ -f1-$k`
echo "DEBUG pol=$pol"
      if grep -q "^${pol}$" pols;then 
        if [[ -z $list ]];then list=$pol; else list="$list\n$pol"; fi
echo "DEBUG list=$list"
        excl="$excl|$pol"
echo "DEBUG excl1=$excl"
        bf=0; break
      else 
        let k-=1
        if [ $k -eq 2 ];then
          excl="$excl|$pol"
echo "DEBUG excl2=$excl"
          bf=0; break
        fi
      fi
    done
    [ $bf -eq 0 ]&& break
  done
#  [[ ! -s tempo2 ]]&& break
done

#[ -a tempo* ]&& rm -f tempo*
echo $list
