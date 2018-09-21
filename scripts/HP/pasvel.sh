#!/usr/bin/sh
#s/cut -d\(.\)/cut -d \'\1\'/g

logo () {
  echo "################################################################################"
#  echo "##          Script for checking, removing and deploying HP policies           ##"
  echo "##     (c) pasvel, 2012 (pasvel@gmail.com). The first steps of SkyNet! :)     ##"
  echo "################################################################################"
}

upexec () {
#echo "DEBUG upexec start `date '+%M:%S'`"
  $bpath/ovdeploy $cmdt -upload -file remote.${rnum}${dot}sh -sd ${HOME}/tmp -node $mgm -td ${HOME}/tmp $ovrg > /dev/null 
  $bpath/ovdeploy $cmdt -node $mgm -cmd "sh $remote_sh" $ovrg > $remote_log #2>>${nodefile}.log
  logapp dbg; logapp log
  [ -s $remote_sh ]&& cat $remote_sh >> ${nodefile}.dbg
  [ -s $remote_log ]&& cat $remote_log >> ${nodefile}.log
  [ `wc -l < $remote_bat` -gt 1 ]&& cat $remote_bat >> ${nodefile}.dbg
#echo "DEBUG upexec stop `date '+%M:%S'`"
}

laststep () {
  if [[ $be -eq 0 || $br -eq 0 ]];then
    bosu=0
    if [ $osval = WIN ];then
      echo "sh ${PASD}/perase.sh $label" >> $remote_sh
      bosw=0
    fi
#    echo "if [ \$? -eq 0 ];then echo \"  Removing policies\t[REMOVED]\"; else echo \"  Removing policies\t[$msg2]\"; fi" >> $remote_sh
  fi

  if [ $bosw -eq 0 ];then
    if [ $bd -eq 0 ];then
      echo "sh ${PASD}/perase.sh $label" >> $remote_sh
      bosu=0
    fi
    ### \b spriymaetsia yak backspace, pravilno lyshe(?) z '*' + pereminna piznishe, za lapkamy!
    echo 'cscript c:\\Powermon\\Utilities\\Powertool\\bin\\powertool-deploy.vbs' $node >> $remote_bat
    echo "IF \"%ERRORLEVEL%\" == \"0\" (\nECHO   Win Distributing...\t[$msg1]\n) ELSE (\nECHO ! Win Distributing...\t[$msg2w]\n)" >> $remote_bat
    ### Old script
    #echo 'cscript c:\\Powermon\\Utilities\\Powertool\\bin\\DeploymentVerifyNode.vbs' $node >> $remote_bat
  fi

  if [ $bosu -eq 0 ];then
##    echo "$bpath/OpC/opcragt -distrib -templates -actions -monitors -commands -force $label" >> $remote_sh
    echo "$bpath/OpC/opcragt -distrib $label -force" >> $remote_sh
    echo "if [ \$? -eq 0 ];then echo \"  Unix Distributing...\t[$msg1]\"; else echo \"! Unix Distributing...\t[$msg2]\"; fi" >> $remote_sh
  fi
}

remote () {
  k=1; [ -a $remote_sh ]&& rm -f $remote_sh
  wman=1; echo "@echo off" > $remote_bat

  echo "if $bpath/OpC/opcragt $node >${HOME}/tmp/opcragt.tmp 2>&1;then" >> $remote_sh
  if [ bsub -eq 0 ];then
    echo "tmp=\`grep \"isn't running\" ${HOME}/tmp/opcragt.tmp|sed \"s/ *isn't running//;s/^.* \\([a-z]*\\)$/\\1/\"|tr '\\\n' ','\`" >> $remote_sh
#    echo "if grep -q \"isn't running\" ${HOME}/tmp/opcragt.tmp;then echo \"! Sub-agents status\t[ERROR:\${tmp%,}]\"; fi" >> $remote_sh
    echo "if [[ ! -z \$tmp ]];then echo \"! Sub-agents status\t[ERROR:\${tmp%,}]\"; fi" >> $remote_sh
    bsub=1
  fi

  until [ $k -gt $i ];do
    case $1 in
      deploy ) msg1="DONE"; ext=a;;
      erase ) msg1="REMOVED"; ext=dea;;
      * ) echo "Exception, debug required (remote [deploy|erase])"
    esac
    msg2="ERROR:\$?"; msg2w="ERROR:%ERRORLEVEL%"

    case $k in
      $i ) 
        case $1 in
          deploy )
##            [ $bd -eq 0 ]&& bosu=0
##            [ $osval = WIN ]&& bosw=0
            [ $bpn -eq 0 ]&& laststep
          ;;
          erase )
            if [ $bpn -eq 0 ];then
#              if [ $bR -eq 0 ];then
#                echo "$bpath/ovpolicy -remove -all -host $label $ovrg" >> $remote_sh
#              else echo "sh ${PASD}/perase.sh $label" >> $remote_sh
#              fi
#              echo "if [ \$? -eq 0 ];then echo \"  Removing policies\t[$msg1]\"; else echo \"  Removing policies\t[$msg2]\"; fi" >> $remote_sh

              if [[ $bE -eq 0 || $bR -eq 0 ]];then
                msg1="DONE"; bosu=0; [ $osval = WIN ]&& bosw=0
                echo "sh ${PASD}/perase.sh $label" >> $remote_sh
                [ $bR -eq 0 ]&& laststep
              fi

              ### Dvoyaka situaciya z logichnymy operaciyamy, nestacha duzhok... Scho dyvno - pracyue yak zadumano...
              if [[ $bd -eq 0 && $bn -ne 0 || $br -eq 0 ]];then
#                if [[ $bE -eq 0 || $bR -eq 0 ]];then
#                  bosu=0; [ $osval = WIN ]&& bosw=0
#                  echo "sh ${PASD}/perase.sh $label" >> $remote_sh
#                fi
                msg1="DONE"
                laststep
              fi
            fi
          ;;
        esac;;
      * )
###        [[ $1 = deploy && `echo ${keys[$k]}|cut -d_ -f2` = OS && `echo ${keys[$k]}|cut -d_ -f3` != WIN-SEC && $br -ne 0 && $bs -ne 0 ]]&& preinstall

        templ=`grep ${keys[$k]} ${PASD}/templates`
        case `echo $templ|awk {'print $1'}` in
          W )
            wman=0; bosw=0
            cmd[$k]="$OVOWNODEUTIL -${ext}ssign_node -node_name $node -group_path `echo $templ|awk {'print $3'}`\\`echo $templ|awk {'print $2'}`\"";;
          U )
            wman=1; bosu=0
            cmd[$k]="$bpath/OpC/utils/opcnode -${ext}ssign_node node_name=$node group_name=`echo $templ|awk {'print $2'}` net_type=NETWORK_IP";;
	  * ) echo "Exception, debug required (remote [W|U])"
        esac

        if [ $wman -eq 0 ];then
          echo ${cmd[$k]} >> $remote_bat
          echo "IF \"%ERRORLEVEL%\" == \"0\" (\nECHO   ${keys[$k]}\t[$msg1]\n) ELSE (\nECHO   ${keys[$k]}\t[$msg2w]\n)" >> $remote_bat
        else
          echo ${cmd[$k]} >> $remote_sh
          echo "if [ \$? -eq 0 ];then echo \"  ${keys[$k]}\t[$msg1]\"; else echo \"  ${keys[$k]}\t[$msg2]\"; fi" >> $remote_sh
        fi;;
    esac
    let k+=1
  done

  if [ `wc -l < $remote_bat` -gt 1 ];then
    case $mgm in
      ihpmgm01|ihpmgm05|ihpmgm41|ihpmgm42 ) winmgm=146.192.79.150;;
      ihpmgm02 ) winmgm=10.219.35.14;;
      ihpmgm03 ) winmgm=134.47.99.203;;
    esac
    echo "$bpath/ovdeploy $cmdt -upload -file remote.${rnum}${dot}bat -sd ${HOME}/tmp -node $winmgm -td \"C:\\TEMP\" $ovrg > /dev/null" >> $remote_sh
    echo "$bpath/ovdeploy $cmdt -node $winmgm -td \"C:\\TEMP\" -cmd \"remote.${rnum}${dot}bat\" $ovrg" >> $remote_sh
#    echo "$bpath/ovdeploy $cmdt -node $winmgm -td \"C:\\TEMP\" -cmd \"del $remote_bat\" $ovrg" >> $remote_sh
    $bpath/ovdeploy $cmdt -upload -file remote.${rnum}${dot}bat -sd ${HOME}/tmp -node $mgm -td ${HOME}/tmp $ovrg > /dev/null
#    if ! grep -q "Agents status" $remote_sh;then
#      [ $1 = deploy ]&& echo "else echo \"  Agents status\t[ERROR:\$?]\"; exit; fi\nrm -f ${HOME}/tmp/opcragt.tmp" >> $remote_sh
#    fi
  fi
  echo "else echo \"! opcragt status\t[ERROR:\$?]\"; exit; fi\nrm -f ${HOME}/tmp/opcragt.tmp" >> $remote_sh
}

mancheck () {
  ### Manual check, just to be sure first time
  echo "$1 $remote_sh:"; cat $remote_sh
  if [ `wc -l < $remote_bat` -gt 1 ];then echo "$1 $remote_bat:"; cat $remote_bat; fi
  echo "Continue? [y/n]"
  read answer
  [[ -z $answer ]]&& answer='y'
}

### Ostatocho zagubyvsia u ciy funkcii, krasche ne chipaty ii vzagali.. :)
prepare () {
#echo "DEBUG prepare start `date '+%M:%S'`"
  j=1; k=1; [ -a $remote_log ]&& >$remote_log
  unset cmd; unset keys; i=$b1i
  [ $1 = delete ]&& i=$b2i
  while [ $j -ne $i ];do
    case $1 in
      check )
        if ! grep -q ${b1keys[$j]} $remote_tmp;then
          echo "${b1keys[$j]}\t[NOT_EXIST]" >> $remote_log
          keys[$k]=${b1keys[$j]}
          let k+=1
        else echo "  ${b1keys[$j]}\t[EXIST]" >> $remote_log
        fi
      ;;
      erase )
        keys[$j]=${b1keys[$j]}
      ;;
      delete )
        if grep -q ${b2keys[$j]} $remote_tmp;then
          keys[$k]=${b2keys[$j]}
          let k+=1
        ### SKIPPED because  current NodeGroup is not assigned
        else echo "  ${b2keys[$j]}\t[SKIPPED]" >> $remote_log
        fi
      ;;
      * ) echo "Exception, debug required (prepare [check|erase])"
    esac
    let j+=1
  done
  [ $1 != erase ]&& i=$k
#echo "DEBUG prepare stop `date '+%M:%S'`"
}

nglist () {
  i=1
  for str in `cat $remote_tmp|grep "PM[UW_]"`;do
    keys[$i]=$str
    [ $bR -eq 0 ]&& b1keys[$i]=$str
    let i+=1
  done; 
  [ $bR -eq 0 ]&& b1i=$i
}

preinstall () {
  logapp log
  case $osval in
    WIN )
      premsg="Node syncronized."; echo "  Node syncronizing"|tr '\n' '\t'
      $bpath/ovdeploy $cmdt -node $mgm -cmd "/opt/OV/edb/bin/syncNode.sh $node" $ovrg >> ${nodefile}.log
      if tail ${nodefile}.log|grep -q "$premsg"; then
        echo "[DONE]"; else echo "[ERROR]"
      fi
    ;;
    UNIX )
     ### Precheck of hash file before discovery

     tmp=`$bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/uplfile.sh $node lhashcheck.sh" $ovrg|sed /^$/d`; echo "$tmp"
     if [[ `echo $tmp|cut -d[ -f2|tr ']' ':'|cut -d: -f1` != UPDATED || bS -eq 0 ]];then
#       CMD="$bpath/ovdeploy $cmdt -node $label -cmd \"[ -d /var/opt/OV/conf/osspi/ ]&& find /var/opt/OV/conf/osspi ! -name \"*local\" -exec rm -f {} \\;\" $ovrg"
#       $bpath/ovdeploy $cmdt -node $mgm -cmd "$CMD" $ovrg >> ${nodefile}.log

       CMD="[ -d /var/opt/OV/conf/osspi/ ]&& find /var/opt/OV/conf/osspi ! -name \"*local\" -exec rm -f {} \\;"
       if $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovdeploy $cmdt -node $label -cmd \"$CMD\" $ovrg" $ovrg >> ${nodefile}.log;then
         echo "  OSSPI HASH files\t[REMOVED]"
       else
         echo "  OSSPI HASH file\t[ERROR]"
       fi
       
       premsg="....Completed"; echo "  OSSPI discovering"|tr '\n' '\t'

#       CMD="/opt/OV/lbin/SPISvcDisc/SPI_DiscServ.sh -v -f /opt/OV/lib/osspi/UnixOSSPI_Disc.conf -n $node" 
#       $bpath/ovdeploy $cmdt -node $mgm -cmd "$CMD" $ovrg >> ${nodefile}.log

       CMD="osspi_perl.sh SPI_DiscClient.pl -n \`hostname\` -s UNIXOSSPI -f \"/var/opt/OV/bin/instrumentation/osspi_discreg.cfg\""
       $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovdeploy $cmdt -node $label -cmd \"$CMD\" $ovrg" $ovrg >> ${nodefile}.log

       if tail ${nodefile}.log|grep -q "$premsg"; then
         echo "[DONE]"
       else
         echo "[TIMEOUT...]"
         $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/uplfile.sh $label lhashcheck.sh" $ovrg|sed /^$/d 2>>${nodefile}.log
       fi
     fi
      ;;
    * ) echo "Exception, debug required (preinstall [WIN|UNIX])"
  esac
}
  
postcheck () {
  logcou=15
  if [ $bV -eq 0 ];then
    echo "  System.txt log on $node [$logcou]:"
    case $osval in
      WIN ) CMD="sh ${HOME}/winpath.sh $label \"log\\System.txt\"";;
      UNIX ) CMD="$bpath/ovdeploy -node $label -cmd \"cat /var/opt/OV/log/System.txt\" $ovrg";;
    esac
#    CMD="$bpath/ovdeploy -node $label -cmd \"cat /var/opt/OV/log/System.txt\" $ovrg;echo"
  else
#    echo "  System.txt errors for\t[`date '+%a %b %e'`], [20]:"
    echo "  System.txt log on $mgm [$logcou]:"
#    CMD="grep -i $label /var/opt/OV/log/System.txt|grep \"`date '+%a %b %e'`\"|grep ERR;echo"
    CMD="grep -i $label /var/opt/OV/log/System.txt"
  fi
  $bpath/ovdeploy $cmdt -node $mgm -cmd "$CMD" $ovrg|sed /^$/d > ${HOME}/tmp/System.txt 2>/dev/null
    ###|sed "s/ERR: `date '+%a %b %e'` //;s/`date '+%Y'`: //" > ${HOME}/tmp/System.txt

  if [ -s ${HOME}/tmp/System.txt ];then
    tail -$logcou ${HOME}/tmp/System.txt|sed "s/^/    /"
    [ `wc -l < ${HOME}/tmp/System.txt` -gt $logcou ]&& echo "! Whole log saved to ${HOME}/tmp/System.txt"
#    $bpath/ovdeploy $cmdt -node $mgm -cmd "`echo $CMD|sed 's/"/\\"/g'`" $ovrg|sed /^$/d > System.txt2
#    if ! diff System.txt1 System.txt2 >/dev/null;then
#      echo "  Local System.txt errors:"
#      diff -C0 System.txt1 System.txt2|egrep -v "\*\*\*|---"
#    fi
#   rm -f ${HOME}/tmp/System.txt
  fi
#  echo "  Local policies \t[`$bpath/ovdeploy $cmdt -node $mgm -cmd \"$bpath/ovpolicy -list -host $label\" $ovrg|egrep \"PMW|PMU\"|wc -l`]"
}

geti () {
#  CMD="egrep -i \"[ |	]${label}[ |	|\.]|${label}$\" /etc/hosts; if [ \$? -ne 0 ];then exit; fi"
  CMD="egrep -i \"[ |	]${label}[ |	|\.]|${label}$\" /etc/hosts"

  if [ $bit -eq 0 ];then
    tval=`perl ${PASD}/mssql.pl $label|grep $label`
    tndb=`echo $tval|cut -d: -f3`
    fqdn=`echo $tval|cut -d: -f2|tr 'A-Z' 'a-z'`
    host=`echo $tval|cut -d: -f1|tr 'A-Z' 'a-z'`
    
    if [[ ! -z $tndb ]];then
      zo=' '
      case $tndb in
        0 ) tndb="NONE";;
        1 ) tndb="HP";;
        2 ) tndb="CA";;
        3 ) tndb="CA+HP";;
        4 ) tndb="B/S";;
        5 ) tndb="B/S+HP";;
        6 ) tndb="B/S+CA";;
        7 ) tndb="B/S+CA+HP";;
        8 ) tndb="MF";;
        * ) zo='!';;
      esac
#      if [ $node != $fqdn ];then
#        echo "! Checking TNDB record:";
#        echo "    $fqdn\t[$tndb]"
#        echo "$node $fqdn" >> ${HOME}/tmp/tndb.lst
#      else echo "$zo TNDB server status\t[$tndb]"
#      fi

    if [[ $node = $fqdn || $node = $host ]];then
      echo "$zo TNDB server status\t[$tndb]"
    else
      echo "! Checking TNDB record:"
      echo "    $fqdn - $host\t[$tndb]"
      echo "$node $fqdn $host" >> ${HOME}/tmp/tndb.lst
    fi

    else echo "! Checking TNDB record\t[MISSED]"
    fi

    if ! tmp=`$bpath/ovdeploy $cmdt -node $mgm -cmd "$CMD" $ovrg 2>/dev/null`;then
#    if [[ -z $tmp ]];then
      echo "! Checking /etc/hosts\t[MISSED]"
    else
      [ $nodeip != `echo $tmp|awk {'print $1'}` ]&& echo "! Checking /etc/hosts\t[`echo $tmp|awk '{print $1}'`]"
#      [ $node != `echo $tmp|awk {'print $2'}` ]&& echo "! Checking /etc/hosts\t[`echo $tmp|awk '{print $2}'`]"
      [[ $node = `echo $tmp|awk {'print $2'}` || $node = `echo $tmp|awk {'print $3'}` ]]|| echo "! Checking /etc/hosts\t[`echo $tmp|awk '{print $2}'`]"
#      [[ $nodeip != `echo $tmp|awk {'print $1'}` || $node != `echo $tmp|awk {'print $2'}` ]]&& echo
    fi
  fi
  
  if [ $bil -eq 0 ];then  
    lgroup=`$bpath/ovdeploy $cmdt -node $mgm -cmd "sh $bpath/OpC/call_sqlplus.sh sel_laygrp $node" $ovrg|sed /^$/d` 
    if [[ ! -z $lgroup && $lgroup = "HoldingArea" ]];then echo "!"|tr -d '\n'; else echo " "|tr -d '\n'; fi
    echo " Layout group name\t[$lgroup]"
  fi

  if [ $bI -eq 0 ];then
    if $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/OpC/opcragt $node" $ovrg > $remote_tmp 2>&1;then
      if grep -q "Message Agent buffering" $remote_tmp;then
        tmp="buffering,"
        echo "$mgm $node" >> ${HOME}/tmp/buffering.lst
      else tmp=''
      fi

      if grep -q "isn't running" $remote_tmp;then
        tmp=${tmp}`grep "isn't running" $remote_tmp|sed "s/ *isn't running//;s/^.* \([a-z]*\)$/\1/"|tr '\n' ','`
      fi
      [[ -n $tmp ]]&& echo "! Sub-agents status\t[ERROR:${tmp%,}]"
   
      case $osval in
##        WIN )
##          echo "  WIN message\t[:)]"
##        ;;
        UNIX )
          $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/uplfile.sh $label lhashcheck.sh" $ovrg|sed /^$/d 2>>${nodefile}.log
        ;;
##        * ) echo "Exception, debug required (geti [WIN|UNIX])"
      esac
    else
      echo "! Agents running status\t[ERROR]"
      if [ $bii -eq 0 ];then
        echo "  NodeGroups:"
#echo "DEBUG nglist.sh"
        $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/nglist.sh $node $osval" $ovrg|sed /^$/d|sed "s/^/    /"
      fi
      return 1
    fi
  fi

   
  if [[ $bii -eq 0 || $biv -eq 0 || $bv -eq 0 ]];then
    if $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovdeploy $cmdt -node $label -cmd ovconfget $ovrg" $ovrg > $remote_tmp;then
 
      if [[ $biv -eq 0 || $bii -eq 0 ]];then
        echo "  Agent's versions\t[`grep OPC_INSTALLED_VERSION $remote_tmp|cut -d= -f2`-`grep BUNDLE_VERSION $remote_tmp|cut -d= -f2`]"
      fi

      if [[ `grep ihpmgm $remote_tmp|grep -v $mgm|wc -l` -gt 0 || `grep OPC_PRIMARY_MGR $remote_tmp|cut -d= -f1` = OPC_PRIMARY_MGR ]];then
        echo "  Managers records:"; tmp=''

        for hpval in `grep ihpmgm $remote_tmp`;do
          if [[ `echo $hpval|cut -d= -f2|cut -d. -f1` != $mgm || `echo $hpval|cut -d= -f1` = OPC_PRIMARY_MGR ]];then
            echo "!   $hpval"
            chap=`sed -e '/./{H;$!d;}' -e "x;/$hpval/!d" $remote_tmp|grep "\[.*\]"|tr -d []`
            if [ `echo $hpval|cut -d= -f1` = OPC_PRIMARY_MGR ];then
              CMD="ovconfchg -ns $chap -clear OPC_PRIMARY_MGR"
            else
              CMD="ovconfchg -ns $chap -set `echo $hpval|cut -d= -f1` ${mgm}.mgmt.oper.no"
            fi
            tmp="${tmp}$hpval|"
            echo "echo \"$label:\"" >> ${HOME}/fixmgm.sh
            echo "$bpath/ovdeploy -node $mgm -cmd \"$bpath/ovdeploy -node $label -cmd \\\"$CMD\\\" $ovrg\" $ovrg >> $HOME/log/fixmgm.log 2>&1" >> ${HOME}/fixmgm.sh
            echo "if [ \$? -eq 0 ];then echo \"  ${CMD}\t[DONE]\"; else echo \"  ${CMD}\t[ERROR]\"; fi" >> ${HOME}/fixmgm.sh
          fi
        done
        grep ihpmgm $remote_tmp|egrep -v "${tmp%\|}"|sed 's/^/    /'

        case $mgm in
          ihpmgm01 ) mgmid=264fbf16-fefc-7535-0fc3-810f9606a291;;
          ihpmgm02 ) mgmid=d39fa442-d100-7537-18c4-c38f5654d1f5;;
          ihpmgm03 ) mgmid=9325c734-062f-7538-1a37-96049e7353f8;;
          ihpmgm05 ) mgmid=841bf198-83d5-753f-0274-c4ec907b6cb6;;
          ihpmgm41 ) mgmid=542eb846-f417-7553-0f2d-a323a2ada02a;;
          ihpmgm42 ) mgmid=413071f6-fcd9-7553-0404-da609c940d42;;
        esac
        if [ `grep MANAGER_ID $remote_tmp|cut -d= -f2` != $mgmid ];then
          echo "!   `grep MANAGER_ID $remote_tmp` (${mgm}_ID=$mgmid)"
          CMD="ovconfchg -ns sec.core.auth -set MANAGER_ID $mgmid"
          echo "echo \"$label:\"" >> ${HOME}/fixmgm.sh
          echo "$bpath/ovdeploy -node $mgm -cmd \"$bpath/ovdeploy -node $label -cmd \\\"$CMD\\\" $ovrg\" $ovrg >> $HOME/log/fixmgm.log 2>&1" >> ${HOME}/fixmgm.sh
          echo "if [ \$? -eq 0 ];then echo \"  ${CMD}\t[DONE]\"; else echo \"  ${CMD}\t[ERROR]\"; fi" >> ${HOME}/fixmgm.sh
        fi

      else
        if [ $bv -eq 0 ];then
          echo "  Config's nodename\t[`grep OPC_NODENAME $remote_tmp|cut -d= -f2`]"
          echo "  Managers records:"
          egrep "ihpmgm|ID" $remote_tmp|sed 's/^/    /'
        fi
      fi
    else
      echo "! ovdeploy status\t[ERROR]"
      ovd=1
    fi
  fi

  if [[ $bii -eq 0 || $bia -eq 0 || $bip -eq 0 || bid -eq 0 || $bin -eq 0 ]];then
##  if $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovpolicy -list -host $label $ovrg" $ovrg|egrep "PMW|PMU|OVO|opcmsg"|sed /^$/d > $remote_tmp;then
    if $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovpolicy -list -host $label $ovrg" $ovrg|sed -n '/---*/,$p'|sed '/---*/d;/^$/d' > $remote_tmp;then
      polscou=`wc -l < $remote_tmp`; ##rdate=''

      if [ $polscou -gt 3 ];then
        if [[ $bii -eq 0 || $bid -eq 0 || $bia -eq 0 ]];then
          [[ $ovd -eq 0 ]]&& rdate="\t[`$bpath/ovdeploy $cmdt -node $mgm -cmd \"sh ${PASD}/lrefdate.sh $label $osval\" $ovrg 2>/dev/null|sed '/^$/d;s/ *$//g'`]"
        fi
      fi

      if [[ $bii -eq 0 || $bia -eq 0 ]];then
        echo "  NodeGroups/LocalPols"|tr '\n' '\t'
        if [ $mgm = ihpmgm43 ];then
          echo "[Skip for $mgm]"
        else
          $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/nglist.sh $node $osval" $ovrg|sed 's/^\\.*\\//;/^$/d' > ${HOME}/tmp/chkpols.tmp
          sh ${PASD}/chkpols.sh ${HOME}/tmp/chkpols.tmp $remote_tmp "$rdate"
        fi
      fi

#      [[ $bii -ne 0 ]]&& echo "  Local policies\t[$polscou]$rdate"
      [[ $bip -eq 0 || $bid -eq 0 ]]&& echo "  Local policies\t[$polscou]$rdate"
      [[ $bip -eq 0 && $polscou -gt 3 ]]&& sh ${PASD}/showpols.sh $remote_tmp

      if [ $bin -eq 0 ];then
        echo "  NodeGroups:"
        $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/nglist.sh $node $osval" $ovrg|sed /^$/d|sed "s/^/    /"
      fi

      [ ! -a ${HOME}/tmp/chkpols.tmp0 ]&& touch ${HOME}/tmp/chkpols.tmp0
      [[ $biii -eq 0 ]]&& if egrep -q "PMW_OS_WIN_BASE|PMW_APP_CUST_services|OS_LIN_.*_BASE|OS_AIX_BASE|OS_SOL_BASE|OS_HPUX_BASE" ${HOME}/tmp/chkpols.tmp0;then
        [ $ovd -eq 0 ]&& $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/getlocals.sh $label $osval" $ovrg|sed '/^ *\*/d;/^$/d'
      fi

      [[ $biii -eq 0 ]]&& if egrep -q "PMU_DB_ORA_BASE|PMW_DB_MSSQL_BASE|PMU_DB_DB2_BASE|PMU_DB_SYBASE_BASE" ${HOME}/tmp/chkpols.tmp0;then
        $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/ldbspi.sh $osval $label" $ovrg|sed "/^[ |      ]*$/d" > tmp/ldbspi.tmp 2>&1
        cat tmp/ldbspi.tmp|sed '/local.cfg present/d'
      fi

    fi
  fi
#  else
#    echo "! Agents running status\t[ERROR]"
#    if [ $bii -eq 0 ];then
#      echo "  NodeGroups:"
#      $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/nglist.sh $node" $ovrg|sed /^$/d|sed "s/^/    /"
#    fi
#  fi
}

logapp () {
  echo "$node $os [$nodeip],$mgm:" >> ${nodefile}.$1
  echo "######################################################## `date '+%b %d %Y %H:%M'` #####" >> ${nodefile}.$1
}

body () {
  bosw=1; bosu=1; bsub=0; ovd=0

  fl="$node [$nodeip] $os,$mgm"
  let cou=80-${#fl}-1
  echo "$fl `expr substr ${sep} 1 $cou`"

  [ $bi -eq 0 ]&& geti ###|tee -a $HOME/log/pasvel.log

  if [ $bg -eq 0 ];then
    $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/getlocals.sh $label $osval" $ovrg|sed '/^ *\*/d;/^$/d'
  fi

  if [ $bb -eq 0 ];then
#    $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/ldbspi.sh $osval $label" $ovrg|sed "/^[ |	]*$/d;/ERROR/d" > tmp/ldbspi.tmp
    $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/ldbspi.sh $osval $label" $ovrg|sed "/^[ |      ]*$/d" > tmp/ldbspi.tmp 2>&1
    cat tmp/ldbspi.tmp|sed '/local.cfg present/d'
  fi

  if [ $ba -eq 0 ];then
    $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovdeploy $cmdt -node $label -cmd \"ovcodautil -obj\" $ovrg" $ovrg > tmp/adspi.tmp
    echo "  ADSPI NumMetrics\t[`sed -n '/Data source: ADSPI/,/NumMetrics/p' tmp/adspi.tmp|tail -1|sed 's/NumMetrics = //'`]"
  fi

  if [ $bm -eq 0 ];then
    echo "  Running \"${mcommand}\"..."
    $bpath/ovdeploy $cmdt -node $mgm -cmd "$mcommand $node" $ovrg|sed '/^$/d;s/^/    /'
  fi

  if [ $bc -eq 0 ];then
#    logapp log; echo "  \"$command\":" >> ${nodefile}.log
    echo "  Running \"${command}\"..."
#    $bpath/ovdeploy -node $mgm -cmd "$bpath/ovdeploy -node $label -cmd \"$command\" $cmdt $ovrg" $cmdt $ovrg|sed '/^$/d;s/^/    /'
    $bpath/ovdeploy -node $mgm -cmd "$bpath/ovdeploy -node $label -cmd \"$command\" $ovrg" $ovrg|sed '/^$/d;s/^/    /' ###|tee -a ${nodefile}.log
  fi

  if [[ $bu -eq 0 || $bw -eq 0 ]];then
    case $upath in
      'powermon' )
         case $osval in
           WIN ) upath='C:\Documents and Settings\All Users\Application Data\HP\HP BTO Software\conf\powermon' ;;
           UNIX ) upath='/var/opt/OV/conf/powermon/' ;;
         esac
      ;;
      'instrum' )
         case $osval in
           WIN ) upath='C:\Documents and Settings\All Users\Application Data\HP\HP BTO Software\bin\instrumentation' ;;
           UNIX ) upath='/var/opt/OV/bin/instrumentation' ;;
         esac
      ;;
      'osspi' ) upath='/var/opt/OV/conf/osspi';;
    esac

    logapp log
    if [ $bu -eq 0 ];then
      echo "  Uploading $ufile to $upath..."|tr '\n' '\t'
      [ ! -a ${HOME}/tmp/$ufile ]&& cp $usrc ${HOME}/tmp/$ufile
      $bpath/ovdeploy $cmdt -node $mgm -upload -file $ufile -sd ${HOME}/tmp -td ${HOME}/tmp $ovrg >> ${nodefile}.log
      $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovdeploy $cmdt -node $node -upload -file $ufile -sd ${HOME}/tmp -td \"$upath\" $ovrg" $ovrg>>${nodefile}.log
      if [ $? -eq 0 ];then echo "[DONE]"; else echo "[ERROR]"; fi
    fi

    if [ $bw -eq 0 ];then
      echo "  Downloading $ufile from $upath..."|tr '\n' '\t'
      $bpath/ovdeploy $cmdt -node $mgm -cmd "$bpath/ovdeploy $cmdt -node $node -download -file $ufile -td ${HOME}/tmp -sd \"$upath\" $ovrg" $ovrg>>${nodefile}.log
      $bpath/ovdeploy $cmdt -node $mgm -download -file $ufile -sd ${HOME}/tmp -td ${HOME}/tmp $ovrg >> ${nodefile}.log
#      if [ $? -eq 0 ];then echo "[DONE]"; else echo "[ERROR]"; fi
      if [ -a ${HOME}/tmp/$ufile ];then
        [ "tmp/$ufile" != "$usrc" ]&& mv -f ${HOME}/tmp/$ufile $usrc
        echo "[DONE]"
      else echo "[ERROR]"
      fi
    fi
    $bpath/ovdeploy $cmdt -node $mgm -cmd "rm -f ${HOME}/tmp/$ufile" $ovrg >> ${nodefile}.log || echo "! Removing tmp file\t[ERROR]"
  fi

  if [[ $bn -eq 0 || $bd -eq 0 || $bE -eq 0 ]];then
#echo "DEBUG nglist.sh"
    $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/nglist.sh $node $osval" $ovrg|sed 's/^.*\\//g;/^$/d' > $remote_tmp
    if [[ $bR -eq 0 && `wc -l < $remote_tmp` -eq 0 ]];then
      echo "  There are no assigned policies\t[ERROR]"
      return 1
    fi
    logapp log
    cat $remote_tmp >> ${nodefile}.log
  fi

  if [ $bs -eq 0 ];then
      preinstall
      bs=0
  fi

  ### Erase!
  if [ $bE -eq 0 ];then
    if grep -q "PM[UW_]" $remote_tmp;then
      nglist
      remote erase
      [ $bx -eq 0 ]&& mancheck erase
      upexec
      cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
      if grep -q "opcragt status" $remote_log;then
        if [ $bh -eq 0 ];then exit; else break; fi
      fi
    else 
      echo "  No NodeGroups are assigned"
    fi
    
    ### Deploy after erase
    prepare erase
    remote deploy
    [ $bx -eq 0 ]&& mancheck deploy
    upexec
    cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
  else

    ### Delete node groups
    if [ $bd -eq 0 ];then
      prepare delete
      [ -a $remote_log ]&& cat $remote_log|grep "SKIPPED"|sed /^$/d
      if [[ `grep -q "SKIPPED" $remote_log` -eq 0 && $k -eq 1 ]];then
        echo "  No policy remove required"
      else
        remote erase
        [ $bx -eq 0 ]&& mancheck erase
        upexec
        cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
      fi
      if grep -q "opcragt agents status" $remote_log;then if [ $bh -eq 0 ];then exit; else break; fi; fi
    fi

    ### Check and deploy
    if [ $bn -eq 0 ];then
      [[ $bR -eq 0 || $bd -eq 0 ]]&& $bpath/ovdeploy $cmdt -node $mgm -cmd "sh ${PASD}/nglist.sh $node $osval" $ovrg|sed 's/^.*\\//g;/^$/d' > $remote_tmp
      prepare check
      if grep -q NOT_EXIST $remote_log;then
        cat $remote_log|grep -v "NOT_EXIST"|sed /^$/d
        remote deploy
        [ $bx -eq 0 ]&& mancheck deploy
        upexec
        cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
      else
        echo "  No policy update required"
        if [ $bd -eq 0 ];then
          remote deploy
          [ $bx -eq 0 ]&& mancheck deploy
          upexec
          cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
        fi
      fi
      if grep -q "opcragt agents status" $remote_log;then if [ $bh -eq 0 ];then exit; else break; fi; fi

      ### Make sync always, even if it's not required
#      remote deploy
#      [ $bx -eq 0 ]&& mancheck deploy
#      upexec
#      cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
    fi
  fi

  if [ $br -eq 0 ];then
    i=1
    remote erase
    [ $bx -eq 0 ]&& mancheck erase
    upexec
    cat $remote_log|egrep "DONE|ERROR|REMOVED|FAILED"|sed /^$/d
  fi

  [ $bv -eq 0 ]&& postcheck
}

chglayout () {
  if [ $bl -eq 0 ];then
    ### Threshould is 30 servers per time
    thr=30; cmd="if [ \$? -eq 0 ];then echo \"Moving to $layout group\t[DONE]\"; else echo \"Moving to $layout group\t[ERROR:\$?]\"; fi"
    echo "@echo off" > $remote_bat; [ -a $remote_sh ]&& rm -f $remote_sh

    if [ $bh -eq 0 ];then
      echo "$bpath/OpC/utils/opcnode -move_nodes node_list=$node layout_group=PM_PRES_NO${layout}" > $remote_sh
      echo $cmd|sed 's/Moving/  &/g' >> $remote_sh
      [ $bx -eq 0 ]&& mancheck layout
      upexec
      cat $remote_log|egrep "DONE|ERROR"|sed /^$/d
    else
      cd ${HOME}/tmp
      for mgm in `ls ihpmgm*`;do
        all=`wc -l < $mgm`
        if [ $all -le $thr ];then
          lst=`tr '\n' ' ' < $mgm`
          ### Zabyraemo probil v samomu kinci, sed, paskuda taka, ne hoche!
          echo "$bpath/OpC/utils/opcnode -move_nodes node_list=\"`echo ${lst% }`\" layout_group=PM_PRES_NO${layout}" > $remote_sh
          echo $cmd|sed 's/Moving/  &/g' >> $remote_sh
        else
          ### opcnode returns error when server's amount is big... I've choosen 30 per time
          f=1; l=$thr
          until [ $f -ge $all ];do
            lst=`sed -n "${f},${l}p" $mgm|tr '\n' ' '`
            echo "$bpath/OpC/utils/opcnode -move_nodes node_list=\"`echo ${lst% }`\" layout_group=PM_PRES_NO${layout}" >> $remote_sh
            echo $cmd|sed 's/Moving/  &/g' >> $remote_sh
            let f=$l+1; let l+=$thr
          done
        fi
        [ $bx -eq 0 ]&& mancheck layout
        upexec
        echo "$mgm:"; cat $remote_log|egrep "DONE|ERROR"|sed /^$/d
      done
      cd ${HOME}
    fi
  fi
}

usage () {
  echo "Usage: $0 {OPTION(S)} [nodegroup[1] ... nodegroup[n]]"
  echo "\t-f FILE\t\tFile with servers list. Can't be used with -h key"
  echo "\t-h HOST(1) HOST(2) .. HOST(N)\t\tHost(s) mode. Separated by spaces. Can't be used with -f key"
  echo "\t-l LAYOUTGROUP\tMove server(s) to specific layout group. Format: only 5 customer's digits"
#  echo "\t-p PM_RESPGROUP\tAssign server to one of the PM_RESP group. Format: WIN_DOM"
  echo "\t-n NODEGROUP[S]\tAssign server to NodeGroups[s]. NodeGroups should be separated by space"
  echo "\t-d NODEGROUP[S]\tUnassign server from NodeGroups[s]. NodeGroups should be separated by space. Can't be used with -e key"
  echo "\t-e\t\tErase local policies before deploying. Using with -n key"
  echo "\t-E\t\tErase ALL assigned NodeGroups and local policies before deploying. Can't be used with -d key"
  echo "\t-r\t\tRedeploy assigned policies. Can't be used with -e, -d, -n keys"
  echo "\t-R\t\tRemove NodeGroups assignment and ALL local policies, make distributing. Assign everything again"
  echo "\t-s\t\tCheck and discover if it's necessary OS-SPI for Unix and Synchronize for Windows"
  echo "\t-S\t\tForce discovering OS-SPI for Unix and Synchronize for Windows"
  echo "\t-c\t\tExecute command on node"
  echo "\t-m\t\tExecute command on mgm. \$node value will be appanded to command automatically"
  echo "\t-i\t\tInformation"
  echo "\t-ii\t\tExtended information"
  echo "\t-v\t\tVerify System.txt for today + check managers string"
  echo "\t-V\t\tVerify System.txt for current node + check managers string"
  echo "\t-b\t\tCheck DB-SPI"
  echo "\t-g\t\tDownload and show all local configs"
  echo "\t-u SRC_FILE DST_FILE {DST_PATH|powermon|instrum|osspi}\t\tUpload SRC_FILE to DST_PATH/DST_FILE"
  echo "\t-w DST_FILE SRC_FILE {SRC_PATH|powermon|instrum|osspi}\t\tDownload DST_PATH/SRC_FILE to DST_FILE"
#  echo "\t-q\t\tQuiet mode. Suppress blank printing"
  echo "\t-x\t\tDebug mode. Ask confirmation after each step"
  echo;echo "\tExample:\tsh pasvel.sh -f STB.lst -l 10418 -d PMU_OS_LIN_RH_BASE -n PMW_OS_WIN_BASE PMW_APP_DDMI_BASE"
  exit 1
}

### BODY! ######################################################################

if [ $# -eq 0 ];then usage; exit; fi

bpath="/opt/OV/bin"
DATE=$(date '+%Y%m%d')
ovrg="-ovrg server"
cmdt="-cmd_timeout 180000"
PASD="/home/et4956"
rnum=''; dot=''
OVOWNODEUTIL="\"C:\\Program Files\\HP\\HP BTO Software\\lbin\\OvOW\\en\\ovownodeutil.wsf\""
sep="-------------------------------------------------------------------------------"

for mgm in 01 02 03 05 41 42 43;do
  [ ! -a ${PASD}/banks/${DATE}_ihpmgm${mgm} ]&& tmp="${tmp}${mgm} "
done
if [[ ! -z $tmp ]];then
  echo "!${sep}"; echo "Update NodeBank files for [${tmp% }] (${PASD}/banks.sh ${tmp% })"; echo "${sep}!"
  exit 1
fi

### Generate random 4-digits number (1000-9999)
#rnum=0; dot='.'
#while [ $rnum -le 1000 ];do
#  rnum=$RANDOM
#  let rnum%=9999
#done
###


cons=$(ps -ef|grep "$$ *$PPID"|awk {'print $6'})
euser=$(w|grep "$cons"|awk {'print $1'})

#tmp=$(ps -ef|egrep -v "egrep|$$|tee"|grep "$PPID")
#euser=$(echo "$tmp"|awk {'print $1'})
#echo "$tmp"; #echo "DEBUG euser=>${euser}<"
#euser=$(ps -ef|egrep -v "egrep|$$"|grep "$PPID"|awk {'print $1'})

case $euser in
#  et4956 ) rnum=${euser}; dot='.'; HOME=/var/opt/OV/tmp; cd $HOME;;
  root ) if [ $(pwd) != "/home/et4956" ];then usage; else HOME=${PASD}; fi;;
#  et4956 ) HOME=${PASD}; cd ${HOME};;
  et4956|et5468|et5634|et3539|et1948|et2210 )
    rnum=${euser}; dot='.'
    if ps -ef|egrep -v "egrep|$$|tee"|grep "pasvel.sh -";then
      echo "!${sep}"; echo "Another copy of pasvel.sh is running by ${euser}! Terminating..."; echo ">$tmp<"; echo "${sep}!"
      exit 1
    else
      HOME="/home/${euser}"
      cd ${HOME}
      [[ ${euser} != 'et4956' ]]&& echo "${DATE}\t${euser}\t$0 $@" >> ${PASD}/log/count.log
    fi
  ;;
  * ) echo "Exception, debug required euser=>$euser< , >$cons<"; exit 1 ;;
esac

[ -a ${HOME}/tmp/ihpmgm* ]&& rm -f ${HOME}/tmp/ihpmgm*
[ -a ${HOME}/tmp/buffering.lst ]&& rm -f ${HOME}/tmp/buffering.lst
[ -a ${HOME}/tmp/fewmgm.lst ]&& rm -f ${HOME}/tmp/fewmgm.lst
[ -a ${HOME}/tmp/tndb.lst ]&& rm -f ${HOME}/tmp/tndb.lst
[ -a ${HOME}/fixmgm.sh ]&& rm -f ${HOME}/fixmgm.sh
[ -a ${HOME}/log/fixmgm.log ]&& rm -f ${HOME}/log/fixmgm.log
[ -a ${HOME}/log/pasvel.log ]&& rm -f ${HOME}/log/pasvel.log

remote_sh=${HOME}/tmp/remote.${rnum}${dot}sh
remote_log=${HOME}/log/remote.${rnum}${dot}log
remote_tmp=${HOME}/tmp/remote.${rnum}${dot}tmp
remote_bat=${HOME}/tmp/remote.${rnum}${dot}bat

bf=1; bl=1; be=1; bE=1; bx=1; bd=1; bn=1; bq=1; bh=1; bp=1; br=1; bR=1; bs=1; bS=1; bv=1; bi=1; bii=1; biii=1; 
bip=1; bb=1; bc=1; bu=1; ba=1; biv=1; bin=1; bpn=1; bw=1; bg=1; bm=1; bil=1; bit=1; bid=1; bis=1; bia=1; bI=1; bV=1;

while [ $# -ne 0 ];do
  case $1 in
    -f ) ### file
      bf=0
      nodelist=$2
      nodefile="${HOME}/log/`echo $nodelist|sed 's/^.*\///'|cut -d. -f1`"
      shift
    ;;
    -l ) ### layout group
      bl=0
      layout=$2
      shift
    ;;
    -n|-d ) ### add node groups|delete node groups
      nd=$1; unset bkeys; j=1; ###[ $nd = -n ]&& j=2
      [[ $bp -ne 0 && $nd = -n ]]&& j=2

      while [[ ${#2} -ge 3 && `expr substr $2 1 1` != '-' ]];do
        case $2 in
          'WIN' ) pol="PMW_OS_WIN_BASE";;
          'SEC' ) pol="PMW_OS_WIN-SEC_BASE";;
          'RHEL' ) pol="PMU_OS_LIN_RH_BASE";;
          'SUSE' ) pol="PMU_OS_LIN_SUSE_BASE";;
          'AIX' ) pol="PMU_OS_AIX_BASE";;
          'SOL' ) pol="PMU_OS_SOL_BASE";;
          'SOL10' ) pol="PMU_OS_SOL-10_BASE";;
          'HPUX' ) pol="PMU_OS_HPUX_BASE";;
          'ORA' ) pol="PMU_DB_ORA_BASE";;
          'SQL'|'MSSQL' ) pol="PMW_DB_MSSQL_BASE";;
          'DDMI' ) pol="PMW_APP_DDMI_BASE";;
          'XEN' ) pol="PMW_APP_CITRIX_BASE_XenApp";;
          'TREND' ) pol="PMW_APP_TREND_BASE_TMOS-client";;
          'DPC' ) pol="PMW_APP_DPCLIENT_BASE";;
          'IIS' ) pol="PMW_APP_IIS_BASE";;
          'CL8' ) pol="PMW_CL_WIN2008_BASE";;
          'CL3' ) pol="PMW_CL_WIN2003_BASE";;
          'PRINT' ) pol="PMW_OS_WIN_PRINT";;
          'CUST' ) pol="PMW_APP_CUST_services";;

          'DELL' ) pol="PMW_HW_DELL_BASE";;
          'IBM' ) pol="PMW_HW_IBM-DIR_BASE";;
          'HPSIM' ) pol="PMW_HW_HPSIM_BASE";;
          'TRAPS' ) pol="PMW_HW_HPSIM-Traps_BASE";;
          * )
            if ! grep -q $2 ${PASD}/templates;then
              echo "!${sep}"; echo "Unknown template! Terminating..."; echo "${sep}!"
              exit 1
            else pol=$2
            fi
        esac

        [ $nd = -n ]&& b1keys[$j]=$pol
        [ $nd = -d ]&& b2keys[$j]=$pol

        if [[ `expr substr $pol 1 8` != 'PM_RESP_' ]];then
          bpn=0
          tmp=`grep $pol ${PASD}/templates|awk {'print $2'}|cut -d_ -f1`
          [ $tmp = PMW ]&& osval=WIN; [ $tmp = PMU ]&& osval=UNIX
#          [ $tmp = PM ]&& osval=`grep $pol ${PASD}/templates|awk {'print $2'}|cut -d_ -f3`
        else osval=`echo $pol|cut -d_ -f3`
        fi

        let j+=1
        shift
      done
      
      case $nd in
        -n ) bn=0; b1i=$j; [ $bp -ne 0 ]&& b1keys[1]=PM_RESP_${osval}_DOM;;
        -d ) bd=0; b2i=$j;;
        * ) echo "Exception, debug required (read args [-n|-d])"
      esac
    ;;
    -p ) ### PM_RESP nodegroup
      bp=0
#      b1keys[1]=PM_RESP_$2
#      osval=`echo $2|cut -d_ -f3`
#      shift
    ;;
    -e ) ### erase local polciies only
      be=0
    ;;
    -E ) ### erase ALL
      bE=0
    ;;
    -x ) ### debug. Turns on mancheck func
      bx=0
    ;;
    -q ) ### silence mode
      bq=0
    ;;
    -h ) ### host(s)
      nodelist=${HOME}/tmp/servers
      if [[ ${#3} -ge 3 && `expr substr $3 1 1` != '-' ]];then
        bf=0
        nodefile=${HOME}/log/servers
        [ -a $nodelist ]&& rm -f $nodelist
        while [[ ${#2} -ge 3 && `expr substr $2 1 1` != '-' ]];do
          echo $2 >> $nodelist
          shift
        done
      else
        bh=0
        echo $2 > $nodelist
        nodefile=${HOME}/log/`echo $2|tr [A-Z] [a-z]`
        shift
      fi
    ;;
    -r ) ### refresh policies
      br=0; bpn=0
    ;;
    -R ) ### deassign and assign node groups
      bR=0; bE=0; bpn=0
    ;;
    -s ) ### SPI and SYNC
      bs=0
    ;;
    -S ) ### force SPI and SYNC
      bs=0; bS=0
    ;;
    -v ) ### grep $node System.txt for today
      bi=0; bv=0
    ;;
    -V ) ### grep $node System.txt
      bi=0; bV=0; bv=0
    ;;
    -c* ) ### execute command on node
      bc=0
      tmp=`echo ${1#-c}`
      if [[ -z $tmp ]];then
        command="$2"
        shift
      else
        for cl in ${tmp};do
          case $cl in
            ti ) command="opcmsg application=TEST_IM object=TEST_IM msg_text=TEST_IM msg_grp=PM_OPC severity=critical";;
          esac
        done
      fi
    ;;
    -m* ) ### execute command on mgm
      bm=0
      tmp=`echo ${1#-m}`
      if [[ -z $tmp ]];then
        mcommand="$2"
        shift
      else
        for ml in ${tmp};do
          case $ml in
            cs ) mcommand="$bpath/OpC/opcragt -cleanstart";;
            d ) mcommand="$bpath/OpC/opcragt -distrib";;
            df ) mcommand="$bpath/OpC/opcragt -distrib -force";;
          esac
        done
      fi
    ;;
#    -mc ) ### execute opcragt -cleanstart on mgm
#      bm=0
#      mcommand="$bpath/OpC/opcragt -cleanstart"
#    ;;
#    -md ) ### execute opcragt -distrib on mgm
#      bm=0
#      mcommand="$bpath/OpC/opcragt -distrib"
#    ;;
#    -mdf ) ###execute opcragt -distrib -force on mgm
#      bm=0
#      mcommand="$bpath/OpC/opcragt -distrib -force"
#    ;;
    -u|-w ) ### upload|wget(download) file
       bq=0
       [ $1 = '-u' ]&& bu=0
       [ $1 = '-w' ]&& bw=0
#       case $1 in
#         -u ) bu=0;;
#         -w ) bw=0;;
#       esac
       usrc=$2
       ufile=$3
       upath=$4
       shift 3
     ;;
    -iii ) ### all options
      bi=0; bit=0; bil=0; bI=0
      bii=0
      biii=0
#      bv=0
#      ba=0
    ;;
    -i* ) ### information + option(s)
      bi=0
      tmp=`echo ${1#-i}|sed 's/[a-z]/& /g'`
      if [[ -z $tmp ]];then
        bit=0; bil=0; bid=0; bI=0
      else
        for il in ${tmp};do
          case $il in
            i ) bii=0; bit=0; bil=0; bI=0;; ### extended info
            a ) bia=0; bq=0;; ### analyze
            t ) bit=0; bq=0;; ### TNDB
            l ) bil=0; bq=0;; ### layout group
            v ) biv=0; bq=0;; ### agent's version
            s ) bis=0; bq=0; bI=0;; ### osspi
            d ) bid=0; bq=0;; ### instrumentations upload date
            p ) bip=0; bq=0;; ### policies list
            n ) bin=0; bq=0;; ### nodegroups
          esac
        done
      fi
    ;;
    -b ) ### dbspi
      bb=0
    ;;
    -g ) ### get locals configs
      bg=0
    ;;
    -a ) ### adspi
      ba=0
    ;;
    -t ) ### cmd_timeot
      cmdt="-cmd_timeout $2"
      shift
    ;;
    * )
      echo "!${sep}"; echo "Unknown key: $1, RTFM!"; echo "${sep}!"
      exit 1
  esac
  shift
done

[ $bq -ne 0 ]&& logo ###|tee -a ${HOME}/log/pasvel.log

if [[ $bf -ne 0 && $bh -ne 0 ]];then
  nodelist=${HOME}/tmp/deploy
  nodefile=${HOME}/log/servers
#  [ -a ${nodefile}.log ]&& rm -f ${nodefile}.log
#  [ -a ${nodefile}.dbg ]&& rm -f ${nodefile}.dbg
fi

cat $nodelist|while read str;do
  CMD="^${str}[ |	|\.]"
  tmp=$(grep -i "$CMD" ${PASD}/banks/${DATE}_ihpmgm[04][1235])
  if [[ ! -z $tmp ]];then
    if [ $(echo "$tmp"|wc -l) -gt 1 ];then
      tmp=$(echo "$tmp"|sed 's/.*_ihpmgm/ihpmgm/'|cut -d: -f1|tr '\n' ',')
      echo "!${sep}"; echo "$str\t- is located on [${tmp%,}] managers"; echo "${sep}!"
      echo "$str:${tmp%,}" >> ${HOME}/tmp/fewmgm.lst
      continue
    else
      mgm=$(echo $tmp|cut -d: -f1|cut -d_ -f2)
      node=$(echo $tmp|awk {'print $1'}|cut -d: -f2)
      label=$(echo $node|cut -d. -f1)
      nodeip=$(echo $tmp|awk {'print $2'})
      os=$(echo $tmp|awk {'print $3'})
      echo $node >> ${HOME}/tmp/$mgm

      case $os in
        WINNT ) osval=WIN ;;
        LX26RPM|LX24RPM|AIX|SOL|HPUX ) osval=UNIX ;;
        * ) echo "!${sep}"; echo "Unknown OS=$os!"; echo "${sep}!" ;;
      esac

      body ###|tee -a ${HOME}/log/pasvel.log
    fi
  else
    echo "!${sep}"; echo "$str\t\t- IS NOT in NodeBank [perl pm-configure-hpagent.pl -i IP-ADDRESS -m MANAGER]"; echo "${sep}!"
    continue
  fi
done

[ $bl -eq 0 ]&& chglayout ###|tee -a ${HOME}/log/pasvel.log
[ $bq -ne 0 ]&& echo
