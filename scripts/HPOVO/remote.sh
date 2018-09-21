/opt/OV/bin/OpC/utils/opcnode -list_groups|grep Name|grep "PM[UW_]"|cut -d= -f2|sed "s/^ /U /"
/opt/OV/bin/ovdeploy -node 146.192.79.150 -cmd "ovownodeutil -list_groups|find \"PM_Managed_Nodes\"" -ovrg server|sed /^$/d
