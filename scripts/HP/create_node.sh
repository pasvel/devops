#!/bin/ksh

# Script to create HP Operation Manages, needed for flexible management
# Author: Alf & Henning, Sept 2011
#
# Note! 3 steps to complete, before you run this script
#
# First:
# Create the default node group, where all nodes will be members, including HP Operations Managers creatde here
# The node group name will be "PMA_BASE", however temporary we will use the old "roolout_test".
# Change the "Default_node_group" variable when we want to use the new group name by "switching" the next two lines

# Second:
# Add the new HP Operations Manager (current node?) to the "here document" at the bottom of this script

# Third
# The nodes in the "here document", have to be resolvable (present in DNS or /etc/hosts), befor you run this script.
######################################################################

# select which node group name to use by add/delet comment character (#) i 1. position of the 2 next lines
my_local_host=`hostname`
#default_node_group_name="PMA_BASE"
default_node_group_name="rollout_test"

# Functions
in_file=$1
tmp=/tmp/tmp_$$
get_answer()
{
  read answer
  if [ "${answer}" = "yes" -o "${answer}" = "" -o "${answer}" = "y" ] ; then
    return 0
  else
    return 1
  fi
}

if [ -f $in_file ]
then
	echo "OK, creating nodes from $infile"
else
	echo "Usage: $0 infile"
	exit 2
fi
#continue_script
while [ 1 ]
do
	printf "\nNOTE! Before you continue running this script, there are 3 steps you should complete:\n\n"
	printf "1: Check that the defult node group name are correctly configured\n"
        printf "   Activate correct definition name by add/remove comment character \"#\"\n"
        printf "   in the default_node group definition in the beginning of this script\n"
        printf "   #defult_node_group_name=\"PMA_BASE\"\n"
        printf "   default_node_group_name=\"rollout_test\"\n"
	printf "\n\n"
	printf "2: Make sure the hostname of node is resolvable.\n"
	printf "   Add the new node's ip-address and hostname to DNS or hosts file\n"
	printf "   Make sure both hostname and FQN are defined\n\n"
        printf "   Are these 2 steps completed? answer [yes] "
    get_answer
    if [ $? -eq 0 ] ;  then
	break
    else
	exit 1
    fi
done

# Create default node group
echo "Create default node group: $default_node_group_name if it's missing"
opcnode -add_group group_name=$default_node_group_name group_label=$default_node_group_name >/dev/null 2 >&1

# Create nodes, set coreid, and turn off heartbeat 
while read ip_addr node_name coreid mach_type
do
	echo "Creating node: $ip_addr $node_name $coreid $mach_type"
	node_label=`expr $node_name | cut -d. -f1`
        opcnode -add_node node_name=$node_name node_label=$node_label net_type=NETWORK_IP  mach_type=$mach_type group_name=$default_node_group_name ip_addr=$ip_addr
        opcnode -chg_id node_name=$node_name id=$coreid net_type=NETWORK_IP
done < $in_file

