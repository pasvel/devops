if [ $# -eq 0 ];then echo "Usage: $0 id"; exit; fi
echo "@/home/et4956/sel_nodeswithid.sql $1"|/opt/OV/bin/OpC/opcdbpwd -exe sqlplus -s|sed -n '/------------------------------------ /,$p'|sed '/^$/d'
