#!/bin/bash
# Automated installation and configuration Splunk UF
# 20170823 edition, pavlo.velychko@dowjones.com

col_out () {
#$1 - color, $2 - Text, $3 - Additional text
  case ${1} in
    red ) col=31;;
    green ) col=32;;
    yellow ) col=33;;
  esac
  echo -e "[ \e[0;${col}m${2}\e[m ]${3}"
echo
}

err_ext () {
#  [[ ! -z ${1} ]]&& echo -e "${1}"
  echo -e "Something went wrong, please send ${log} to pavlo.velychko@dowjones.com. I'll try to catch error and help you proceed with installation\t\c"
  col_out red "ERROR"
  [ -f ${0}.tmp ]&& rm -f ${0}.tmp
  exit 1
}

chk_tag () {
#echo "DEBUG tag: $1"
  if [[ ! ${1} == "`hostname`:"*/*/*/* ]];then
    echo "tag = ${tag}" >> ${0}.log
    [ -f ${0}.tmp ]&& cat ${0}.tmp >> ${0}.log
    #Not my code. This section from splunk_install.sh script as is. Just replaced if by case command, it looks better :)
    case ${1} in
      'Error:Code1' ) col_out red "[ERROR]\t" 'IAM Role Exception:\n  1.Check if the IAM role "splunk_automation" is created in the account where this script is running\n  2.Check if the role "djif-splunk-automation" in InfraProd account has permissions to assume the role "splunk_automation" referred above';;
      'Error:Code2' ) col_out red "[ERROR]\t" 'EC2 Instance Not Found: Check if the ACCOUNT_ID you provided is same as the account on which this EC2 is running';;
      'Error:Code3' ) col_out red "[ERROR]\t" 'Improper Tags Exception: Check if this EC2 instance has proper tags : Name, bu, prod, component and environment';;
      * ) col_out red "[ERROR]\t" 'Your clientName does not fit accepted template';;
    esac
    err_ext
  fi
}

#Check current version and compare it with the latest one
ver_gte () { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

#RPM installation
ins_rpm () {
  #if rpm ${1} ${s3l} >${log} 2>&1;then
  if rpm ${1} ${s3l} >> ${log} 2>&1;then
    col_out green "OK"
  else
    col_out red "ERROR"
    err_ext
  fi
}

che_out () {
  if [ ${?} -eq 0 ];then
    col_out green "OK"
    #col_out green "[OK]"
  else
    col_out red "ERROR"
    #col_out red "[ERROR]"
#    err_ext
  fi
}

chk_reg () {
  case ${1} in
    'us-east-1' ) sre="vir";;
    'us-east-2' ) sre="ohi";;
    'us-west-1' ) sre="cal";;
    'us-west-2' ) sre="ore";;
    'ca-central-1' ) sre="cen";;
    'ap-south-1' ) sre="mum";;
    'ap-northeast-2' ) sre="seo";;
    'ap-southeast-1' ) sre="sin";;
    'ap-southeast-2' ) sre="sin";;
    'ap-northeast-1' ) sre="tok";;
    'eu-central-1' ) sre="fft";;
    'eu-west-1' ) sre="ire";;
    'eu-west-2' ) sre="ldn";;
    'sa-east-1' ) sre="sao";;
    * ) echo "Undescribed region!";;
  esac
}

log_out () {
  echo -e "${1}\t\c"
  echo "##### ${1} ##############################" >> ${log}
}

#Checking input
#if [ $# -ne 0 ];then
#  col_out red "[ERROR]\t" "\n  Usage: $0. No arguments are needed!"
#  exit 1
#fi

log=${0}.log; [ -f ${0}.log ]&& rm -f ${0}.log
shome=/opt/splunkforwarder

case $# in
  0 ) echo "No arguments have been specified" >> ${log};;
  1 ) echo "clientName has been specified: ${1}" >> ${log}};;
  * ) echo -e "Usage: $0. No arguments are needed!\t\c"; col_out red "ERROR"; exit 1;;
esac

#Check if instance is amazon/Google/on-premise
bios=`dmidecode -s bios-version`
echo "bios = ${bios}" >> ${log}
case ${bios} in
  *"amazon"* )
    curl -s http://169.254.169.254/latest/dynamic/instance-identity/document > ${0}.tmp
    api="x-api-key : 9yq8phEYN66Oq1WyPvbXeoRtkUA7Au26oeOGm8e6"
    echo -e "Getting Instance_id...\t\c"
    iid=`grep instanceId ${0}.tmp|awk -F'"' {'print $4'}`; che_out
    echo -e "Getting Region...\t\c"
    reg=`grep region ${0}.tmp|awk -F'"' {'print $4'}`; che_out
    echo -e "Getting Account...\t\c"
    acc=`grep accountId ${0}.tmp|awk -F'"' {'print $4'}`; che_out
    rol=djif-splunk-automation #?

    echo -e "Getting Amazon tag...\t\c"
    #echo "DEBUG: instance_id=${iid}&account_id=${acc}&region=${reg}&role_name=${rol}"
    #echo "curl -H \"${api}\" \"https://or7u1sxcdj.execute-api.us-east-1.amazonaws.com/SplunkAutomationStage/splunkresource?instance_id=${iid}&account_id=${acc}&region=${reg}&role_name=${rol}\""
    #curl -H "${api}" "https://or7u1sxcdj.execute-api.us-east-1.amazonaws.com/SplunkAutomationStage/splunkresource?instance_id=${iid}&account_id=${acc}&region=${reg}&role_name=${rol}"
    #tag=$(curl -s -H "${api}" "https://or7u1sxcdj.execute-api.us-east-1.amazonaws.com/SplunkAutomationStage/splunkresource?instance_id=${iid}&account_id=${acc}&region=${reg}&role_name=${rol}"|tr -d '"')
    tag=`curl -s -H "${api}" "https://or7u1sxcdj.execute-api.us-east-1.amazonaws.com/SplunkAutomationStage/splunkresource?instance_id=${iid}&account_id=${acc}&region=${reg}&role_name=${rol}"`
    che_out
    tag=`echo ${tag}|tr -d '"'`
#echo "TAG: $tag"
#chk_reg ${reg}
#echo "REG: $reg, SRE: $sre"
    chk_tag "${sre}/${tag}"
    hst=`echo ${tag}|cut -d: -f1`
    cln=`echo ${tag}|cut -d: -f2`
    srv="splunkdeploy.services.dowjones.net"
    echo "cln=${cln}, srv=${srv}, hst=${hst}, iid=${iid}, reg=${reg}, sre=${sre}, acc=${acc}, rol=${rol}, tag=${tag}" >> ${log}
  ;;
  *"Google"* )
    echo "Google"
    exit 1
  ;;
  * )
    if [ -z ${1} ];then
      echo -e "It's on-premises server, please run script again and specify correct clientName as argument! Terminating...\t\c"
      col_out red "ERROR"
      exit 1
      #echo "Please specify clientName:"
      #read cln
    else
      cln=${1}
      srv="awssplunkdeploy2.dowjones.net"
      hst=`hostname`
      echo "cln=${cln}, srv=${srv}, hst=${hst}" >> ${log}
    fi
  ;;
esac

#Get latest version of UF
[ -n ${ver} ]&& ver=`curl -s https://s3.amazonaws.com/pasvel-web/splunkforwarder-latest`
if [[ -z ${ver} ]];then
  col_out red "[ERROR]\t" "Can't get the newest version, please check your Internet connection"|tee -a ${log}
  exit 1
fi

pkg="splunkforwarder-${ver}-`uname -i`.rpm"
s3l=https://s3.amazonaws.com/pasvel-web/${pkg}
ins=`rpm -qa splunkforwarder|cut -d- -f2`

echo "Installed ver=${ins}, Planned ver=${ver}" >> ${log}
log_out "Executing"

#Installation
if [[ ! -z ${ins} ]];then
  if ver_gte ${ver} ${ins};then
  #Current version is older than latest. Updating
  #Do we need forced update or choosable?
    log_out "Stopping Splunk..."
    ${shome}/bin/splunk stop >> ${log} 2>&1; che_out
    #echo -e "splunkforwarder-${ins} will be updated to newer ${ver}...\t\c"
    log_out "Upgrading splunkforwarder-${ins} to ${ver}..."
    ins_rpm "-Uvh"
  else
  #Nothing to do, latest version is installed
    log_out 
    echo -e "You have latest version of splunkforwarder-${ins} installed, great!\t\c"
    col_out green "OK"
  fi
else
  #No splunkforwarder in the system, starting fresh installation
  #echo -e "Installing ${pkg}...\t\c"
  log_out "Installing ${pkg}..."
  ins_rpm "-ivh"
fi

#Create deploymentclient.conf file
deplf="/opt/splunkforwarder/etc/system/local/deploymentclient.conf"
/bin/cat << EOM >${deplf}
[target-broker:deploymentServer]
targetUri = ${srv}:8089

[deployment-client]
phoneHomeIntervalInSecs = 60
clientName=${cln}
EOM
log_out "File deployment.conf has been created successfully"
col_out green "OK"
echo "**************************************************"
ls -la ${deplf} >> ${log}
cat ${deplf}|tee -a ${log}
echo "**************************************************"

if [[ -z ${ins} ]];then
  pass="admin:changeme"
  #echo -e "Accepting license...\t\c"
  #${shome}/bin/splunk start --answer-yes --no-prompt --accept-license >> ${log} 2>&1; che_out
else
  pass="admin:da66jZR6"
fi

#echo -e "Accepting license...\t\c"
log_out "Accepting license..."
${shome}/bin/splunk status --answer-yes --no-prompt --accept-license >> ${log} 2>&1
col_out green "OK"

log_out "Setting Splunk servername..."
${shome}/bin/splunk set servername $hst -auth ${pass} >> ${log} 2>&1; che_out
log_out "Enabling auto-start..."
${shome}/bin/splunk enable boot-start -user splunk >> ${log} 2>&1; che_out
log_out "Restarting Splunk..."
${shome}/bin/splunk restart >> ${log} 2>&1; che_out

echo -e "Installation completed!"; echo #\t\c"; col_out green "OK"
