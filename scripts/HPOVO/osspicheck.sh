#!/usr/bin/sh
#$1 - hostname of local node
#
### Checks osspi_fsmon-hash.cfg file immediately and goes sleep. If it's not updated within specified time interval or still missed - IM will be generated
### Written by pasvel, et4956@evry.com

spipath=/var/opt/OV/conf/osspi
hash=osspi_fsmon-hash.cfg
bpath="/opt/OV/bin"
ovrg="-ovrg server"
node=$1

dbg=0 ## 0 - turn on debugging, 1 - turn off

debug () {
  [ $dbg -eq 0 ] && echo " -DEBUG: $1"
}

rediscover () {
  debug "Beginning discovery..."
  ## Remove all files in /var/opt/OV/conf/osspi except *local
  $bpath/ovdeploy -node $node -cmd "[ -d /var/opt/OV/conf/osspi/ ] && find /var/opt/OV/conf/osspi ! -name \"*local\" -exec rm -f {} \;" $ovrg > /dev/null
  ## Rediscovering
  CMD="osspi_perl.sh SPI_DiscClient.pl -n `hostname` -s UNIXOSSPI -f \"/var/opt/OV/bin/instrumentation/osspi_discreg.cfg\" > /dev/null"
  $bpath/ovdeploy -node $node -cmd "$CMD" $ovrg > /dev/null || debug "Discovering is failed"
  debug "Discovery is done"
}

ftcheck () {
  if [ $ftimetr -eq 0 ];then
    ## Trying to rediscover hash if it's check func first execution
    rediscover
    ftimetr=1
  else
    debug "OSSPI HASH file	[$1], creating IM..."
    case $1 in
      ## Make msg_txt according to situation
      error ) msg_txt="File $hash has not changed within the last ${difft}";;
      missed ) msg_txt="File $hash does not exist";;
    esac
    case `hostname` in
      ihpmgm11|ihpmgm14 ) mgm=ihpmgm01;;
      ihpmgm17|ihpmgm18 ) mgm=ihpmgm05;;
      ihpmgm21 ) mgm=ihpmgm02;;
      ihpmgm31 ) mgm=ihpmgm03;;
    esac
    ## If hash still is not OK after discovering we made - create IM
#    $bpath/opcmsg a=HPOM node=$node o=$node msg_grp=PM_SCR severity=critical msg_text="$msg_txt" -option Problem_Host=${mgm}.mgmt.oper.no
    debug "Message to IM creation has been sent"
  fi
}

check () {
  if [ $ftimetr -eq 0 ];then
    ## Upload lhashcheck.sh if it's first execution and do nothing if second
    $bpath/ovdeploy -upload -file "lhashcheck.sh" -sd "/home/et4956" -node $node -td "/tmp" $ovrg > /dev/null || exit 1
    debug "lhashcheck.sh has been uploaded successfully"
  fi
  
  tmp=`$bpath/ovdeploy -node $node -cmd "sh /tmp/lhashcheck.sh" $ovrg`
  difft=`echo $tmp|cut -d: -f2|cut -d] -f1`
  case `echo $tmp|cut -d[ -f2|tr ']' ':'|cut -d: -f1` in
    ## lhashcheck.sh runned locally via ovdeploy can return 3 statuses: UPDATED,ERROR,MISSED
    UPDATED )
      debug "OSSPI HASH file	[UPDATED:${difft}]"
      exit 0 ## Uppiiii, everything is OK, exiting
    ;;
    ERROR )
      debug "OSSPI HASH file	[ERROR:${difft}]"
      ftcheck error
      return 1
    ;;
    MISSED )
      debug "OSSPI HASH file	[MISSED]"
      ftcheck missed
      return 1
    ;; 
  esac
}

### BODY

ftimetr=0 ## First_Time_Trigger. Boolean. Equals 0 in begin, after check func execution will change value to 1
if ! check $ftimetr;then
  ## If status of hash file was ERROR or MISSED, sleep for 15 min and run checking again
  ## On the second iterration we work with ftimetr=1
  debug "Sleeping for 15 min..."
  sleep 900
  check $ftimetr
fi
