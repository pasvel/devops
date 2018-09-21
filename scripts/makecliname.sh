#!/bin/bash

cat pci_list|tr 'A-Z' 'a-z'|while read str;do
  #echo $str
  host=`echo $str|cut -d";" -f4`
  f3=`echo $str|cut -d";" -f2`
  f4=`echo $str|cut -d";" -f3`
  f5=`echo $str|cut -d";" -f1`
  #r1
  case ${host:0:3} in
    sbk|sec|vir|ore|ckp ) r1=${host:0:3};;
    skp ) r1=sbk;;
    djc ) r1=vir;;
    ldp ) r1=ldn;;
    hkp ) r1=hk;;
    * )
      case ${host:0:2} in
        sb ) r1=sbk;;
        sc ) r1=sec;;
        * ) r1=UNKNOWN;;
      esac
  esac
  #r2
  r2=prod
  #r3 - BU
  case $f3 in 
    "customer experience" ) r3=djcm;;
    "finance" ) r3=djfin;;
    *"enterprise"* ) r3=djis;;
    "new york post"|"nyp" ) r3=nypnyp;;
    "print" ) r3=djprt;;
    "professional information business"|"pib" ) r3=djin;;
    "consumer" ) r3=djcs;;
    "facility" ) r3=djfc;;
    "shared services"|"shared technology services" ) r3=djif;;
    * ) r3=UNKNOWN;;
  esac
  #r4 - Technical service
  case $f4 in
    factiva|commerce|graphics|blogs ) r4=$f4;;
    advertising|enterprise|publishing|security ) r4=${f4:0:3};;
    circulation ) r4=circ;;
    "financial enterprise" ) r4=finent;;
    "shared platform" ) r4=sp;;
    *"identity"* ) r4=idt;;
    "messaging" ) r4=msg;;
    "wsj.com" ) r4=wsj;;
    "technical"* ) r4=tsvc;;
    "pipeline and syndication" ) r4=pipeline;;
    *"premise"* ) r4=onprem;;
    *"content"* ) r4=content;;
    *"collaboration"* ) r4=collab;;
    * ) r4=UNKNOWN;;
  esac
  #r5 - Application
  case "$f5" in
    *"ciboodle"* ) r5=ciboodle;;
    *"nyp-dti"* ) r5=nyp-dti;;
    *"peoplesoft"* ) r5=peoplesoft;;
    "nyp- vest" ) r5=nyp;;
    *"factiva"* ) r5=factiva;;
    "e2 web application"* ) r5=e2web;;
    "dj adbase client server apps"* ) r5=djctx;;
    "dj corporate credit card processor"* ) r5=djcccp;;
    "commerce front end"* ) r5=commfrontend;;
    "commerce back end"* ) r5=commbackend;;
    "circulation data entry"* ) r5=circdata;;
    "remittance processing system"* ) r5=rps;;
    "on-line fulfillment system"* ) r5=olf;;
    *"citrix"* ) r5=citrix;;
    *"exchange"* ) r5=exchange;;
    *"active directory"* ) r5=ad;;
    *"identity"* ) r5=idt;;
    "content service"*|*"contentsvc"* ) r5=contsvc;;
    *"email"*|*"e-mail"* ) r5=email;;
    *"wsj"*|*"wsl"* ) r5=wsj;;
    *"cyberark"* ) r5=cyberark;;
    "single sign on"*|*"sso"* ) r5=sso;;
    *"methode"* ) r5=methode;;
    *"google"* ) r5=google;;
    *" "* ) r5=UNKNOWN;;
    * ) r5=$f5
  esac  
  #r6
  case $host in
    *"webapp"* ) r6=webapp;;
    *"app"* ) r6=app;;
    *"web"* ) r6=web;;
    *"db"* ) r6=db;;
    *"mq"* ) r6=mq ;;
    *"feed"* ) r6=feed ;;
    *"core"* ) r6=core ;;
    *"api"* ) r6=api;;
    *"log"* ) r6=log;;
    * ) r6=srv ##Is it OK as std option??
  esac
 echo "$r1/$r2/$r3/$r4/$r5/$r6 : $host : $str" 
done
