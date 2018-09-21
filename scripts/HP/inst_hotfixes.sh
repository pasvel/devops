#!/bin/ksh
tmp=/tmp/tmp_$$
log=install_hofixes.log
select_cmd=/opt/OV/bin/OpC/agtinstall/select_hotfix.sh
install_cmd=/opt/OV/bin/OpC/agtinstall/install_hotfix.sh
conf_aix=/var/opt/OV/conf/eaagt/aix_powerpc_08.60.501.conf
conf_hpux_ipf=/var/opt/OV/conf/eaagt/hp-ux_ipf32_08.60.501.conf
conf_hpux_risc=/var/opt/OV/conf/eaagt/hp-ux_pa-risc_08.60.501.conf
conf_linux_x86=/var/opt/OV/conf/eaagt/linux_x86_08.60.501.conf
conf_linux_x64=/var/opt/OV/conf/eaagt/linux_x64_08.60.501.conf
conf_solaris_sparc=/var/opt/OV/conf/eaagt/solaris_sparc_08.60.501.conf


select_hotfixes()
{
	rm -f ${tmp}0
	$select_cmd $agent | tee -a ${tmp}0
	grep  "Selection tool finished" ${tmp}0 >/dev/null 2>&1
	if [ $? = 0 ]
	then
		RC=0
	else
		RC=1
	fi
	cat ${tmp}0 >>$log
	return $RC
}

install_hotfixes()
{
	rm -f ${tmp}1
	$install_cmd $agent | tee -a ${tmp}1
	grep  "Bundle successfully installed" ${tmp}1 >/dev/null 2>&1
	if [ $? = 0 ]
	then
		RC=0
	else
		RC=1
	fi
	cat ${tmp}1 >>$log
	return $RC
}
# Main
# Main
set -- `getopt f:m:n:d $*`

if [ $? -ne 0 ]
then
        echo $USAGE
        exit 2
fi

while [ $# -gt 0 ]
do
        case $1 in
        -f)     # Input file
                in_file=$2
                if [ -f $in_file ]
                then
                        Ok=true
                else
                        echo "No such file $in_file"
                        exit 2
                fi
                if [ -n "$node" ]
                then
                        echo "Error: Options -f file and -n node are mutually exclusive, use only one of the options"
                        echo "$USAGE"
                        exit 2
                fi
                shift 2
                ;;
        -n)     # Node name
                node=$2
                if [ -n "$in_file" ]
                then
                        echo "Error: Options -f file and -n node are mutually exclusive, use only one of the options"
                        echo "$USAGE"
                        exit 2
                fi
                in_file=${tmp}2
                echo $node >$in_file
                shift 2
                ;;
	--)
		shift
		break
		;;
	esac
done

if [ -f $in_file ]
then
	echo "OK, install hotfixes on nodes in $in_file"
else
	echo "Usage: $0 infile"
	exit 2
fi
if [ -f $log ]
then
	cp $log ${log}.old
fi
echo "`date` Install hotfixes" >>$log
for agent in `cat $in_file`
do
	select_hotfixes
	if [ $? = 0 ]
	then
		install_hotfixes
	fi
done
rm -f ${tmp}?

