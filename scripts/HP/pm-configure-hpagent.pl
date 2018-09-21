#!/usr/bin/perl 
################################################################################
# TITLE            : pm-configure-hpagent.pl
# VERSION          : 1.1
# FUNCTION         : Attempts to activate an already installed HPO agent and 
#                    bind it to the correct network interface by:
#
#                    - Letting the user specify the interfface to bind to and
#                      which manager (OMU) to use
#
#                    The program is supposed to execute locally on the server 
#                    where the agent is installed.
#
#                    The IP address, manager_id and domain of the manager must
#		     be configured in the global variables section of this
#                    program as a hash (%manager) that has the FQN of the manager
#
#                    The program indicates complete success by a return code of
#                    0.  Any error is indicated by a return code of 1, and the
#                    user should consult the log file for further information.
#
#
# PARAMETERS IN    : -i <ip-address> -m <manager name> [-f]
#
# PARAMETERS OUT   : 
#                    
# PROGRAMMED BY    : Henning Tranberg
# DATE             : 16.12.2008
################################################################################
use IO::Socket;
use Net::Domain qw(hostname hostdomain);

################################################################################
#                            Global variables
# $debug          : Debug level (0 = no debug) 
# $maxlogsize     : Max logfile size
# $http_port      : TCP port for testing manager communication 
# $http_url       : Maps Powermon Domain to HTTP url for status feedback
# %ip_addr        : Maps MANAGER server name in profile to manager IP address
# %http_server    : Maps Powermon Domain to HTTP server for status feedback
# %reporter_server: Maps Powermon Domain to HP Reporter server (OMW)
# %manager	  : Name - Address hash for all managers
# $force          : force agent to bind to $bind_address
################################################################################
$maxlogsize = 10240;
$debug = 1;
$force = 0;

$http_port = "383";
$http_url = "/scripts/powertool/nph-powertool-proxy.pl";

@managers =("ihpmgm01.mgmt.oper.no", "ihpmgm02.mgmt.oper.no", "ihpmgm03.mgmt.oper.no", "ihpmgm05.mgmt.oper.no", "ihpmgm41.mgmt.oper.no", "ihpmgm42.mgmt.oper.no", "ihpmgm43.mgmt.oper.no");

$ip_addr{"imp-p02-mgm-003.mgmt.oper.no"} = "146.192.79.211";
$ip_addr{"uxovtest.mgmt.oper.no"} = "146.192.79.192";
$ip_addr{"ihpmgm01.mgmt.oper.no"} = "146.192.79.248";
$ip_addr{"ihpmgm05.mgmt.oper.no"} = "146.192.79.251";
$ip_addr{"ihpmgm03.mgmt.oper.no"} = "134.47.99.197";
$ip_addr{"ihpmgm02.mgmt.oper.no"} = "10.219.35.23";
$ip_addr{"imp-p02-omw-001.mgmt.oper.no"} = "146.192.79.150";
$ip_addr{"cgswr162n"} = "10.219.35.14";
$ip_addr{"tns-fbu-22-914"} = "134.47.99.203";
$ip_addr{"ihpmgm41.mgmt.oper.no"} = "146.192.79.174";
$ip_addr{"ihpmgm42.mgmt.oper.no"} = "146.192.79.175";
$ip_addr{"ihpmgm43.mgmt.oper.no"} = "146.192.79.177";

$http_server{"EDB"} = "146.192.79.197";
$http_server{"NOR"} = "194.248.6.245";
$http_server{"TEL"} = "134.47.108.20";

$manager_id{"ihpmgm01.mgmt.oper.no"} = "264fbf16-fefc-7535-0fc3-810f9606a291";
$manager_id{"ihpmgm02.mgmt.oper.no"} = "d39fa442-d100-7537-18c4-c38f5654d1f5";
$manager_id{"ihpmgm03.mgmt.oper.no"} = "9325c734-062f-7538-1a37-96049e7353f8";
$manager_id{"ihpmgm05.mgmt.oper.no"} = "841bf198-83d5-753f-0274-c4ec907b6cb6";
$manager_id{"ihpmgm41.mgmt.oper.no"} = "542eb846-f417-7553-0f2d-a323a2ada02a";
$manager_id{"ihpmgm42.mgmt.oper.no"} = "413071f6-fcd9-7553-0404-da609c940d42";
$manager_id{"ihpmgm43.mgmt.oper.no"} = "08c89ab2-4b2b-7556-192c-f4267432f2c5";

$cert_server{"ihpmgm01.mgmt.oper.no"} = "ihpmgm01.mgmt.oper.no";
$cert_server{"ihpmgm02.mgmt.oper.no"} = "ihpmgm02.mgmt.oper.no";
$cert_server{"ihpmgm03.mgmt.oper.no"} = "ihpmgm03.mgmt.oper.no";
$cert_server{"ihpmgm05.mgmt.oper.no"} = "ihpmgm05.mgmt.oper.no";
$cert_server{"ihpmgm41.mgmt.oper.no"} = "ihpmgm41.mgmt.oper.no";
$cert_server{"ihpmgm42.mgmt.oper.no"} = "ihpmgm42.mgmt.oper.no";
$cert_server{"ihpmgm43.mgmt.oper.no"} = "ihpmgm43.mgmt.oper.no";

$pm_domain{"ihpmgm01.mgmt.oper.no"} = "EDB";
$pm_domain{"ihpmgm02.mgmt.oper.no"} = "NOR";
$pm_domain{"ihpmgm03.mgmt.oper.no"} = "TEL";
$pm_domain{"ihpmgm05.mgmt.oper.no"} = "EDB2";
$pm_domain{"ihpmgm41.mgmt.oper.no"} = "EDB3";
$pm_domain{"ihpmgm42.mgmt.oper.no"} = "EDB4";
$pm_domain{"ihpmgm43.mgmt.oper.no"} = "EDB5";
#-------------------------------------------------------------------------------
# Make sure that these map to a server defined in %ip_addr hash
#-------------------------------------------------------------------------------
$reporter_server{"EDB"} = "imp-p02-omw-001.mgmt.oper.no";
$reporter_server{"EDB2"} = "imp-p02-omw-001.mgmt.oper.no";
$reporter_server{"EDB3"} = "imp-p02-omw-001.mgmt.oper.no";
$reporter_server{"EDB4"} = "imp-p02-omw-001.mgmt.oper.no";
$reporter_server{"EDB5"} = "imp-p02-omw-001.mgmt.oper.no";
$reporter_server{"NOR"} = "cgswr162n";
$reporter_server{"TEL"} = "tns-fbu-22-914";

#-------------------------------------------------------------------------------
# The EDB domain needs two managers to cope with the agent load.  This entry 
# will just see to it that the second manager gets an entry in the hosts file
# in case we need to switch the agent to it later
#-------------------------------------------------------------------------------
$alt_manager{"EDB"} = "ihpmgm05.mgmt.oper.no"; 

################################################################################
#                              Main program
################################################################################
#-------------------------------------------------------------------------------
# Trim path from our process name to clean up messages
#-------------------------------------------------------------------------------
$0 =~ s/(.*[\\\/])(.*)$/$2/;

#-------------------------------------------------------------------------------
# Build full path for log file
#-------------------------------------------------------------------------------
$bindir = $1;
$logdir = $bindir;
$logfile = $logdir . $0 . ".log";

#-------------------------------------------------------------------------------
# Reset logfile if its size exceeds $maxlogsize
#-------------------------------------------------------------------------------
$opencall = (((-s $logfile) > $maxlogsize) ? ">$logfile" : ">>$logfile");

#-------------------------------------------------------------------------------
# Open log file
#-------------------------------------------------------------------------------
open(LOGG,"$opencall") || die "Cannot open $logfile : $!\n";

#-------------------------------------------------------------------------------
# Autoflush output to log file and STDOUT to ensure correct message sequence
#-------------------------------------------------------------------------------
select((select(LOGG), $| = 1 )[0]);
select((select(STDOUT), $| = 1 )[0]);

#-------------------------------------------------------------------------------
# Read command line arguments
#-------------------------------------------------------------------------------
read_arguments(@ARGV);

#-------------------------------------------------------------------------------
# Determine if we are running on Windows or some dialect of Unix
#-------------------------------------------------------------------------------
$win = ($^O =~ /MSWin/);

#-------------------------------------------------------------------------------
# Find the IP addresses configured on this host
#-------------------------------------------------------------------------------
@ip_addresses = get_addresses($win);

#-------------------------------------------------------------------------------
# If $force flag is set, don't try to check if $bind_address is present
#-------------------------------------------------------------------------------
unless ( $force )
{
  unless (grep(/^${bind_address}$/,@ip_addresses))
  {
    	logdie("The IP address $bind_address does not exist on this node");
  }
}

if ($ip_addr = resolve_manager($manager_name)||$ip_addr{$manager_name})
{
	$manager_id = $manager_id{"$manager_name"};
	$cert_server = $cert_server{"$manager_name"};
}
loginfo("Got the following config\nLocal ip-addr:\t$bind_address\nManager name:\t$manager_name\nPm_domain:\t$pm_domain") if ($debug);

loginfo("Configuring the agent to attach to Powermon Domain: $pm_domain");
#-------------------------------------------------------------------------------
# Register the manager in the local hosts file if necessary (edit_hosts will
# check that the name does not already resolve)
#-------------------------------------------------------------------------------
unless (edit_hosts($win,$manager_name,$ip_addr{$manager_name}))
{
  set_status("ACTIVATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
             $manager_name,$http_url,$http_port);
  logdie("Unable to edit hosts file for OMU entry");
}

#-------------------------------------------------------------------------------
# If the domain has an alternative OMU manager, enter it into the hosts file as
# well to make it easier to switch to the alternative manager at some stage.
#-------------------------------------------------------------------------------
if (($alt_name=$alt_manager{$pm_domain}) && ($alt_ip=$ip_addr{$alt_name}))
{
  unless (edit_hosts($win,$alt_name,$alt_ip))
  {
    set_status("ACTIVATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
               $manager_name,$http_url,$http_port);
    logwarn("Unable to edit hosts file for second OMU entry");
  }
}

#-------------------------------------------------------------------------------
# Do the same thing for the OMW manager (for reporting on all platforms and
# policy deployment on Windows).  Make sure that we actually have a name and
# IP address for the OMW manager first..
#-------------------------------------------------------------------------------
if (($omw_name=$reporter_server{$pm_domain}) && ($omw_ip=$ip_addr{$omw_name}))
{
  #-----------------------------------------------------------------------------
  # Note that the script is not failing if we are unable to add the OMW manager
  # to the hosts file.  We will report failure back to the masterlist, but the
  # agent will still function in the OMU realm if we are missing name resolution
  # for the OMW.  This situation will most likely occur if we add a new Powermon
  # domain and either do not have an OMW for it or forget to update the install
  # scripts.
  #-----------------------------------------------------------------------------
  unless (edit_hosts($win,$omw_name,$omw_ip))
  {
    set_status("ACTIVATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
               $manager_name,$http_url,$http_port);
    logwarn("Unable to edit hosts file for OMW entry");
  }
} else {
  logwarn("Unable to find name and IP of OMW server for PM Domain $pm_domain");
} 

#-----------------------------------------------------------------------------
# Stop the agent, if running
#-----------------------------------------------------------------------------
loginfo("Stopping the HP Operations Agent (if it's running), please wait..");
unless (stop_agent($win))
{
   set_status("ACTIVATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
              $manager_name,$http_url,$http_port);
   logdie("HPO agent status NOT OK. Check System.txt for errors");
}

#-------------------------------------------------------------------------------
# If we have a bind address by now, we will try to configure the agent.  Yes, I
# know that the current logic will prevent us from getting here if we do not 
# have a bind address already, but this is a good place to make the check if 
# someone (like me) changes the preceeeding code.
#-------------------------------------------------------------------------------
if ($bind_address)
{
  #-----------------------------------------------------------------------------
  # Configure the agent to bind to this address
  #-----------------------------------------------------------------------------
  loginfo("Configuring the HP Operations Agent");
  unless (configure_agent($win,$bind_address,$manager_name,$manager_id))
  {
    set_status("ACTIVATE_FAILED","BAD_ADDRESS",$pm_domain,$bind_address,
                $manager_name,$http_url,$http_port);
    logdie("Unable to bind HPO agent to $bind_address");
  }
  #----------------------------------------------------------------------------
  # Activate the already installed agent
  #----------------------------------------------------------------------------
  unless (activate_agent($win,$manager_name,$cert_server))
  {
    set_status("ACTIVATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
             $manager_name,$http_url,$http_port);
    logdie("Unable to activate agent");
  }

  #-----------------------------------------------------------------------------
  # Check status of the agent
  #-----------------------------------------------------------------------------
  loginfo("Check the HP Operations Agent status, please wait..");
  unless (agent_status($win))
  {
    set_status("ACTIVATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
               $manager_name,$http_url,$http_port);
    logdie("HPO agent status NOT OK. Check System.txt for errors");
  }

  #-----------------------------------------------------------------------------
  # Remove existing certificate 
  #-----------------------------------------------------------------------------
  loginfo("Remove any old certificates");
  unless (remove_certificate($win))
  {
    set_status("CERTIFICATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
               $manager_name,$http_url,$http_port);
    logdie("Unable to remove old certificate");
  }
  #-----------------------------------------------------------------------------
  # Issue a certificate request
  #-----------------------------------------------------------------------------
  unless (request_certificate($win))
  {
    set_status("CERTIFICATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
               $manager_name,$http_url,$http_port);
    logdie("Unable to issue certificate request");
  }
  #-----------------------------------------------------------------------------
  # check certificate status
  #-----------------------------------------------------------------------------
  unless (check_certificate($win))
  {
    set_status("CERTIFICATE_FAILED","UNKNOWN",$pm_domain,$bind_address,
               $manager_name,$http_url,$http_port);
    logdie("New certificate is not granted");
  }
} else {
  #-----------------------------------------------------------------------------
  # We have to give up on this one
  #-----------------------------------------------------------------------------
  set_status("ACTIVATE_FAILED","BAD_ADDRESS",$pm_domain,$bind_address,
             $manager_name,$http_url,$http_port);
  logdie("Unable to configure HPO agent. Manual intervention required!");
}

#-------------------------------------------------------------------------------
# Return success to master list
#-------------------------------------------------------------------------------
set_status("ACTIVATE_OK","NOT_APPLICABLE",$pm_domain,$bind_address,
           $manager_name,$http_url,$http_port);

#-------------------------------------------------------------------------------
# Close down
#-------------------------------------------------------------------------------
loginfo("Finished") if ($debug);

close LOGG;

exit 0;

################################################################################
#                               Subroutines
################################################################################

sub read_arguments
{
  my(@arguments) = @_;

  #----------------------------------------------------------------------------
  # Read command line arguments
  #   -v  Verbose (turns on debug info)
  #   -f  force (force Agant to use bind_address
  #   -i <ipaddress>
  #   -d <Powermon domain>
  #   -m <manager name>
  #----------------------------------------------------------------------------
  while (@arguments)
  {
    $arg = shift(@arguments);
    SWITCH:
    {
      if ($arg eq "-i")    { $bind_address = shift(@arguments); last SWITCH; }
      if ($arg eq "-m")    { $manager_name = shift(@arguments); last SWITCH; }
      if ($arg eq "-d")    { $pm_domain = shift(@arguments); last SWITCH; }
      if ($arg eq "-f")    { $force = 1; last SWITCH; }
      if ($arg eq "-v")    { $debug = 1; last SWITCH; }

      logwarn("Unknown argument: $arg");
    }
  }
  logdie("Usage: $0 -i <ip-address> -m <manager_name> [-f] [-v]") unless ($bind_address && $manager_name);
  unless ($bind_address =~ /^\d+\.\d+\.\d+\.\d+/)
  {
	logdie("Invalid ip-address: $bind_address (Not an IP address)");
  }
  @octs = split(/\./, $bind_address);
  foreach $oct (@octs)
  {
	if  ( $oct < 0 || $oct > 255 )
	{
     		logdie("Invalid ip-address: $bind_address (Not an IP address)");
	}
  }
  unless ($pm_domain = $pm_domain{"$manager_name"})
  {
	loginfo ("Error: Unknown HP Operations manager: $manager_name");
	logdie("Valid HP managers are: @managers");
  }
}

sub remove_certificate
{
  my ($win) = @_;
  my ($cmd,$arg,@res);
  my ($path);
  my ($cert_line);

  #----------------------------------------------------------------------------
  # Determine correct path for the ovcert command
  #----------------------------------------------------------------------------
  unless ($path = get_path($win,"ovcert"))
  {
    logwarn("Unable to find command ovcert.  Agent not installed?");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  $cmd = $path ."/ovcert";
  $cmd =~ s%/%\\%g if ($win);

  #----------------------------------------------------------------------------
  # Remove any existing certificate and request a new one
  #----------------------------------------------------------------------------
  $arg = "-status ";
  @res = `\"$cmd\" $arg 2>&1`;
  $rc = $? >> 8;
  if (grep(/Certificate is installed/,@res))
  {
        #----------------------------------------------------------------
   	# We have an certifcate, and will remove this one
        #----------------------------------------------------------------
  	$arg = "-list";
 	@res = `\"$cmd\" $arg 2>&1`;
  	$rc = $? >> 8;
	unless ($cert_line = grep(/\(\*\)/,@res))
	{
	    logwarn("Error from $cmd $arg:");
	    foreach (@res)
	    {
	      chomp;
	      logwarn("$_\n");
	    }
	    return 0;  
        } else {
		foreach (@res)
		{
			chomp;
			if ( /\(\*\)/ )
			{
				$cert_line = $_;
				last;
			}
		}
	}
        ($old_certificate = $cert_line) =~ s/^\|\s+(.*?)\s\(\*\).*/$1/;
  	$arg = "-remove $old_certificate -f";
 	@res = `\"$cmd\" $arg 2>&1`;
  	$rc = $? >> 8;
  	if (grep(/Certificate has been successfully removed/,@res))
        {
             # OK
             loginfo("Old certificate has been successfully removed.");
        } else {
	    logwarn("Error from $cmd:");
	    foreach (@res)
	    {
	      chomp;
	      logwarn("$_\n");
	    }
	    return 0;  
       }
  }
  return 1;
}

sub get_addresses
{
  my ($win) = @_;
  my ($cmd,@res,$rc);
  my (@addresses,$aw_address);
  my (@slan_addresses,$slan_address);
  my ($osname);

  #----------------------------------------------------------------------------
  # Windows used to be easy, but it turns out that ipconfig might confuse us by
  # returning virtual IP addresses for cluster packages along with the physical
  # NICs.  Hence, we will use the netsh command whenever possible (which
  # basically means Windows 2003 and above and Windows 2000 servers with the
  # resource kit installed).
  #----------------------------------------------------------------------------
  if ($win)
  {
    if (which("netsh"))
    {
      $cmd = "netsh interface ip show address";
    }
    else
    {
      logwarn("Reverting to ipconfig command as netsh is not available");
      logwarn("This may cause the agent to bind to a virtual package IP on cluster nodes");
      $cmd = "ipconfig";
    }
  }
  else
  {
    #--------------------------------------------------------------------------
    # We need to distinguish between the different dialects of Unix, mostly
    # because the path differs (We need the path, as it not always included in
    # our PATH environment variable).
    # NOTE: I have tried on several occasions to find a way to enumerate the
    # IP adresses using perl only.  This would make the code more portable and
    # less error prone.  Any help is appreciated! :-)
    #--------------------------------------------------------------------------
    $osname = $^O;

    SWITCH:
    {
      if ($osname =~ /sunos|solaris/)
      {
        #----------------------------------------------------------------------
        # Sun is not that difficult either
        #----------------------------------------------------------------------
        $cmd = "/usr/sbin/ifconfig -a";
        last SWITCH;
      }

      if ($osname =~ /linux/)
      {
        #----------------------------------------------------------------------
        # Neither is Linux, as long as we get the path right
        #----------------------------------------------------------------------
        $cmd = "/sbin/ifconfig -a";
        last SWITCH;
      }

      if ($osname =~ /aix/)
      {
        #----------------------------------------------------------------------
        # AIX keeps the ifconfig command in a really strange place
        #----------------------------------------------------------------------
        $cmd = "/etc/ifconfig -a";
        last SWITCH;
      }

      if ($osname =~ /hpux/)
      {
        #----------------------------------------------------------------------
        # HP-UX is the only major Unix vendor that lacks ifconfig -a
        #----------------------------------------------------------------------
        foreach my $interface (get_nics())
        {
          #--------------------------------------------------------------------
          # Build a string of ifconfig commands instead
          #--------------------------------------------------------------------
          $cmd .= "ifconfig $interface;";
        }

        last SWITCH;
      }

      #------------------------------------------------------------------------
      # Assuming ifconfig -a is a good default, hoping it will be in our path
      #------------------------------------------------------------------------
      $cmd = "ifconfig -a";
    }
  }

  #----------------------------------------------------------------------------
  # Execute the command and capture the result
  #----------------------------------------------------------------------------
  @res = `$cmd 2>&1`;
  $rc = $? >> 8;

  #----------------------------------------------------------------------------
  # Remove the local loop address from the result set
  #----------------------------------------------------------------------------
  @res = grep {!/\Q127.0.0.1\E/} @res;
  #-----------------------------------------------------------------------------
  # We assume that the command always returns 0 on success
  #-----------------------------------------------------------------------------
  if ($rc)
  {
    logwarn("Error from $cmd:");
    foreach (@res)
    {
      chomp;
      logwarn("$_\n");
    }
    return "";  
  }

  #-----------------------------------------------------------------------------
  # Parse command output looking for IP addresses, avoiding those 0.0.0.0 
  # addresses sometimes associated with unconfigured NICs.
  #-----------------------------------------------------------------------------
  if ($win)
  {
    grep { push(@addresses,$1) if /IP[v4]* Address.*:\s*([1-2][\d\.]+)/ } @res;

    #---------------------------------------------------------------------------
    # Remove any 169.254 (APIPA) addresses from the list of local NICs  
    #---------------------------------------------------------------------------
    (@addresses) = grep(!/^169\.254/,@addresses); 

  }
  else
  {
    SWITCH:
    {
      if ($osname =~ /sunos|solaris|aix|hpux/)
      {
        grep { push(@addresses,$1) if /inet\s*([1-2][\d\.]+)/ } @res;
        last SWITCH;
      }

      if ($osname =~ /linux/)
      {
        grep { push(@addresses,$1) if /inet addr:\s*([1-2][\d\.]+)/ } @res;
        last SWITCH;
      }

      #-------------------------------------------------------------------------
      # Guess this is a good default
      #-------------------------------------------------------------------------
      grep { push(@addresses,$1) if /inet\s*([1-2][\d\.]+)/ } @res;
    }
  }
  return @addresses;
}

sub get_nics
{
  my ($cmd,@res,$rc);
  my ($skipped_header);
  my (@interfaces);

  #----------------------------------------------------------------------------
  # NOTE: We only use this on HP-UX for the moment.  Check if the -w option is
  # available before expanding usage to any other Unix dialect!
  #----------------------------------------------------------------------------
  $cmd = "netstat -iw";

  #----------------------------------------------------------------------------
  # Execute the command and capture the result
  #----------------------------------------------------------------------------
  @res = `$cmd 2>&1`;
  $rc = $? >> 8;

  #-----------------------------------------------------------------------------
  # We assume that the command always returns 0 on success
  #-----------------------------------------------------------------------------
  if ($rc)
  {
    logwarn("Error from $cmd:");
    foreach (@res)
    {
      chomp;
      logwarn("$_\n");
    }
    return "";  
  }

  #-----------------------------------------------------------------------------
  # Build the list of interface names, omitting the loopback interface 
  #-----------------------------------------------------------------------------
  foreach (@res)
  {
    #---------------------------------------------------------------------------
    # The first line of output always contains the column headers
    #---------------------------------------------------------------------------
    next unless $skipped_header++;

    #---------------------------------------------------------------------------
    # Skip loopback
    #---------------------------------------------------------------------------
    next if (/^lo0/);

    #---------------------------------------------------------------------------
    # Collect the remaining interfaces
    #---------------------------------------------------------------------------
    push(@interfaces,$1) if (/^([^\s]+)/);
  }

  #-----------------------------------------------------------------------------
  # Return the interface list 
  #-----------------------------------------------------------------------------
  return @interfaces;
}

sub edit_hosts
{
  my ($win,$manager_name,$manager_ip) = @_;
  my ($hostsfile,$alias);
  my (@hosts);

  #----------------------------------------------------------------------------
  # No need to do anything if the name already resolves
  #----------------------------------------------------------------------------
  return 1 if (resolve_manager($manager_name));

  #----------------------------------------------------------------------------
  # Determine name of hosts file
  #----------------------------------------------------------------------------
  $hostsfile=(($win) ? $ENV{SystemRoot}."/System32/Drivers" : "")."/etc/hosts";

  #----------------------------------------------------------------------------
  # Open hosts file for reading
  #----------------------------------------------------------------------------
  unless (open(HOST,"<$hostsfile"))
  {
    logwarn("Unable to open hosts file $hostsfile for read: $!");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Read the entire file (usually not good practice, but most efficient here)
  #----------------------------------------------------------------------------
  @hosts = (<HOST>);
  close HOST;

  #----------------------------------------------------------------------------
  # If the host is present in the hosts file and still does not resolve, host
  # lookups probably do not consult the hosts file on this node
  #----------------------------------------------------------------------------
  if (grep(/$manager_name/,@hosts))
  {
    logwarn("Host $manager_name exists in $hostsfile, but does not resolve");
    logwarn("Check /etc/nsswitch.conf!") unless ($win);
    return 0;
  }

  #----------------------------------------------------------------------------
  # Open hosts file for append
  #----------------------------------------------------------------------------
  unless (open(HOST,">>$hostsfile"))
  {
    logwarn("Unable to open hosts file $hostsfile for append: $!");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Get the hostname part of the FQN (Note the shortest match modifier (?) )
  #----------------------------------------------------------------------------
  ($alias = $manager_name) =~ s/^(.*?)\..*/$1/;

  #----------------------------------------------------------------------------
  # Autoflush output to hosts file to avoid race condition when checking that
  # the name resolves immediately
  #----------------------------------------------------------------------------
  select((select(HOST), $| = 1 )[0]);

  #----------------------------------------------------------------------------
  # Write new entry to hosts file and close it
  #----------------------------------------------------------------------------
  printf(HOST "# Added by HPO Agent install.  Do Not Remove!\n");
  printf(HOST "$manager_ip\t$manager_name ");
  printf(HOST "$alias") unless ($alias eq $manager_name);
  printf(HOST "\n");
  close HOST;

  #----------------------------------------------------------------------------
  # Wait a few seconds to allow for disc controller caching, VMWare latency, 
  # and other delaying factors out of our control...
  #----------------------------------------------------------------------------
  sleep 5;

  #----------------------------------------------------------------------------
  # Check name resolution again
  #----------------------------------------------------------------------------
  unless (resolve_manager($manager_name))
  {
    logwarn("Host $manager_name written to $hostsfile, but does not resolve");
    logwarn("Check /etc/nsswitch.conf") unless ($win);
    return 0;
  }

  #----------------------------------------------------------------------------
  # Guess we're OK, then...
  #----------------------------------------------------------------------------
  return 1;
}

sub resolve_manager
{
  my ($hostname) = @_;
  my ($hostaddr);

  #----------------------------------------------------------------------------
  # Attempt to resolve the manger hostname into its IP address
  #----------------------------------------------------------------------------
  unless ($hostaddr = gethostbyname($hostname))
  {
    loginfo("Unable to resolve $hostname into IP address") if ($debug > 2);
    return "";
  }

  #----------------------------------------------------------------------------
  # Convert address from binary to dot separated format
  #----------------------------------------------------------------------------
  return ($hostaddr = join('.',unpack('C4',$hostaddr)));
}


sub activate_agent
{
  my ($win,$manager_name,$cert_server) = @_;
  my ($cmd,$arg,@res);
  my ($script);

  loginfo("Activating the HP Operations agent") if ($debug);
  #----------------------------------------------------------------------------
  # Find out which command we will be dealing with
  #----------------------------------------------------------------------------
  $script = ($win) ? "opcactivate.vbs" : "opcactivate";

  #----------------------------------------------------------------------------
  # Round up the usual suspects, being careful not to trust the OvInstallDir 
  # unless it actually contains a bin/OpC/install subdir
  #----------------------------------------------------------------------------
  foreach ("$ENV{OvInstallDir}/bin/OpC/install",
           "$ENV{OvInstallDir}/bin/win64/OpC/install",
           "$ENV{SystemDrive}/Program Files/HP/HP BTO Software/bin/OpC/install",
           "$ENV{SystemDrive}/Program Files/HP/HP BTO Software/bin/win64/OpC/install",
           "$ENV{SystemDrive}/Program Files (x86)/HP/HP BTO Software/bin/win64/OpC/install",
           "/opt/OV/bin/OpC/install",
           "/usr/lpp/OV/bin/OpC/install")
  {
    #--------------------------------------------------------------------------
    # Build full path to the directory where we locate the script
    #--------------------------------------------------------------------------
    if (-f $_.'/'.$script)
    {
      $cmd = $_ .'/'.$script;
      last;
    }
  }

  #----------------------------------------------------------------------------
  # Not much we can do if we are unable to find the script
  #----------------------------------------------------------------------------
  unless ($cmd)
  {
    logwarn("Unable to locate $script");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  ($cmd = "cscript \"$cmd\"") =~ s%/%\\%g if ($win);

  #----------------------------------------------------------------------------
  # Configure agent with the chosen profile
  #----------------------------------------------------------------------------
  $arg = "-srv $manager_name -cert_srv $cert_server -f";

  #----------------------------------------------------------------------------
  # Execute the command and capture the result
  #----------------------------------------------------------------------------
  @res = `$cmd $arg 2>&1`;
  $rc = $? >> 8;

  #-----------------------------------------------------------------------------
  # We assume that the command always returns 0 on success
  #-----------------------------------------------------------------------------
  if ($rc)
  {
    logwarn("Error from $cmd:");
    foreach (@res)
    {
      chomp;
      logwarn("$_\n");
    }
    return 0;  
  }

  #-----------------------------------------------------------------------------
  # Sadly, this is not always the case...
  #-----------------------------------------------------------------------------
  if (grep(/Error in one of the target prerequisites/,@res))
  {
    logwarn("Error from $cmd:");
    foreach (@res)
    {
      chomp;
      logwarn("$_\n");
    }
    return 0;  
  }

  #-----------------------------------------------------------------------------
  # We, on the other hand, return true on success
  #-----------------------------------------------------------------------------
  return 1;
}

sub stop_agent
{
  my ($win) = @_;
  my ($cmd,@res);
  my ($path);

  #----------------------------------------------------------------------------
  # Determine correct path for the ovc command
  #----------------------------------------------------------------------------
  unless ($path = get_path($win,"ovc"))
  {
    logwarn("Unable to find command ovc.  Agent not installed?");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  $cmd = $path ."/ovc";
  $cmd =~ s%/%\\%g if ($win);
  $arg="-kill";
  #---------------------------------------------------------------------
  # Stop the Agent 
  #---------------------------------------------------------------------
  @res = `\"$cmd\" $arg 2>&1`;
  $rc = $? >> 8;
  if ( $rc )
  {
	#--------------------------------------------------------------
	# We have run into some sort of problem
	#-------------------------------------------------------------
	logwarn("Error from $cmd $arg:");
	foreach (@res)
	{
	  chomp;
	  logwarn("$_\n");
	}
        return 0;  
  }
  return 1;
}

sub agent_status
{
  my ($win) = @_;
  my ($cmd,@res);
  my ($path,$retries);

  #----------------------------------------------------------------------------
  # Determine correct path for the ovc command
  #----------------------------------------------------------------------------
  unless ($path = get_path($win,"ovc"))
  {
    logwarn("Unable to find command ovc.  Agent not installed?");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  $cmd = $path ."/ovc";
  $cmd =~ s%/%\\%g if ($win);
  $arg = "-status";
 #---------------------------------------------------------------------
  # Agent status
  # The agent may take some time to stabilize...
  #---------------------------------------------------------------------
  while ($retries++ < 10)
  {
    #-------------------------------------------------------------------
    # Execute the command and capture the result
    #-------------------------------------------------------------------
    @res = `\"$cmd\" $arg 2>&1`;
    $rc = $? >> 8;

    #-------------------------------------------------------------------
    # The agent is not really ready until the communication broker is up
    #-------------------------------------------------------------------
    last if (grep(/ovbbccb.*Running/,@res));
    #-------------------------------------------------------------------
    # If the agent is still initializing, we will give it some more time
    # to complete. We assume the command always returns 0 on success
    #-------------------------------------------------------------------
    if ($rc)
    {
      if (grep(/being initialized|not yet started/,@res))
      {
	sleep 30;
	next;
      } else {
	#--------------------------------------------------------
	# We have run into some sort of problem
	#--------------------------------------------------------
	logwarn("Error from $cmd $arg:");
	foreach (@res)
	{
	   chomp;
	   logwarn("$_\n");
	}
	return 0;  
      }
    }
  }
  #---------------------------------------------------------------------
  # Return true on success
  #---------------------------------------------------------------------
  return 1;
}

sub configure_agent
{
  my ($win,$bind_address,$manager_name,$manager_id) = @_;
  my ($cmd,$arg,@res);
  my ($path);

  #----------------------------------------------------------------------------
  # Determine correct path for the ovconfchg command
  #----------------------------------------------------------------------------
  unless ($path = get_path($win,"ovconfchg"))
  {
    logwarn("Unable to find command ovconfchg.  Agent not installed?");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  $cmd = $path ."/ovconfchg";
  $cmd =~ s%/%\\%g if ($win);

  #----------------------------------------------------------------------------
  # Clear any existing settings and add client and server bind addresses
  #----------------------------------------------------------------------------
  #$arg = "-ns bbc.cb -clear SERVER_BIND_ADDR ";
  #$arg .= "-ns bbc.cb -set SERVER_BIND_ADDR $bind_address ";
  #$arg .= "-ns bbc.http -clear CLIENT_BIND_ADDR ";
  $arg .= "-ns bbc.http -set CLIENT_BIND_ADDR $bind_address ";
  $arg .= "-ns sec.core.auth -set MANAGER $manager_name ";
  $arg .= "-ns sec.core.auth -set MANAGER_ID $manager_id ";

  #----------------------------------------------------------------------------
  # Execute the command and capture the result
  #----------------------------------------------------------------------------
  @res = `\"$cmd\" $arg 2>&1`;
  $rc = $? >> 8;

  #-----------------------------------------------------------------------------
  # We assume that the command always returns 0 on success
  #-----------------------------------------------------------------------------
  if ($rc)
  {
    logwarn("Error from $cmd:");
    foreach (@res)
    {
      chomp;
      logwarn("$_\n");
    }
    return 0;  
  }

  #-----------------------------------------------------------------------------
  # We, on the other hand, return true on success
  #-----------------------------------------------------------------------------
  return 1;
}

sub request_certificate
{
  my ($win) = @_;
  my ($cmd,$arg,@res);
  my ($path);

  #----------------------------------------------------------------------------
  # Determine correct path for the ovcert command
  #----------------------------------------------------------------------------
  unless ($path = get_path($win,"ovcert"))
  {
    logwarn("Unable to find command ovcert.  Agent not installed?");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  $cmd = $path ."/ovcert";
  $cmd =~ s%/%\\%g if ($win);

  #----------------------------------------------------------------------------
  # Clear any existing settings and add client and server bind addresses
  #----------------------------------------------------------------------------
  $arg = "-certreq ";

  loginfo("Requesting a new certificate");
  #----------------------------------------------------------------------------
  # Execute the command and capture the result
  #----------------------------------------------------------------------------
  @res = `\"$cmd\" $arg 2>&1`;
  $rc = $? >> 8;

  #-----------------------------------------------------------------------------
  # We assume that the command always returns 0 on success
  #-----------------------------------------------------------------------------
  if ($rc)
  {
    #---------------------------------------------------------------------------
    # If we have a certificate already, we take a wild guess at it being OK.
    #---------------------------------------------------------------------------
    if (grep(/There is already a valid certificate/,@res))
    {
      loginfo("Certificate is already installed");
      return 1;
    }

    logwarn("Error from $cmd $arg:");
    foreach (@res)
    {
      chomp;
      logwarn("$_\n");
    }
    return 0;  
  }
  #-----------------------------------------------------------------------------
  # Return true on success
  #-----------------------------------------------------------------------------
  return 1;
}

sub check_certificate
{
  my ($win) = @_;
  my ($cmd,$arg,@res);
  my ($retries);
  my ($path);

  #----------------------------------------------------------------------------
  # Determine correct path for the ovcert command
  #----------------------------------------------------------------------------
  unless ($path = get_path($win,"ovcert"))
  {
    logwarn("Unable to find command ovcert.  Agent not installed?");
    return 0;
  }

  #----------------------------------------------------------------------------
  # Build command to execute, making sure all slashes are leaning the right way
  #----------------------------------------------------------------------------
  $cmd = $path ."/ovcert";
  $cmd =~ s%/%\\%g if ($win);
  $arg = "-status ";
  #----------------------------------------------------------------------------
  # Execute the command and capture the result
  #----------------------------------------------------------------------------
  loginfo("Certificate status:");
  while ($retries++ < 7)
  {
    #-------------------------------------------------------------------
    # Execute the command and capture the result
    #-------------------------------------------------------------------
    @res = `\"$cmd\" $arg 2>&1`;
    $rc = $? >> 8;
    #---------------------------------------------------------------------------
    # If we have a certificate, we take a wild guess at it is OK.
    #---------------------------------------------------------------------------
    last if (grep(/Certificate is installed/,@res));
    if ($rc)
    {
      logwarn("Error from $cmd:");
      foreach (@res)
      {
        chomp;
        logwarn("$_\n");
      }
      return 0;
    }
    # The status and check is not always syncron, do a final sleep as well
    sleep 20;
    next;
  }
  #---------------------------------------------------------------------------
  # Show final status, both from "ovcert -status" and from "ovcert -check"
  #---------------------------------------------------------------------------
  foreach (@res)
  {
       chomp;
       loginfo("$_");
  }
  $arg = "-check ";
  @res = `\"$cmd\" $arg 2>&1`;
  $rc = $? >> 8;
  foreach (@res)
  {
       chomp;
       loginfo("$_");
  }
  #-----------------------------------------------------------------------------
  # Return true on success
  #-----------------------------------------------------------------------------
  return 1;
}

sub get_path
{
  my ($win,$cmd) = @_;
  my ($sep,$dir,$ext,@winext,@unixpaths,@winpaths,@searchpath);

  #-----------------------------------------------------------------------------
  # Make a list of valid Windows command extensions (including only those we are
  # likely to encounter in our context)
  #-----------------------------------------------------------------------------
  @winext = ('exe','cmd','bat','vbs','pl');

  #-----------------------------------------------------------------------------
  # Default paths on Unix (AIX differs from the rest)
  #-----------------------------------------------------------------------------
  @unixpaths = ('/opt/OV/bin','/usr/lpp/OV/bin');

  #-----------------------------------------------------------------------------
  # The Windows 2008 binaries will end up in different paths depending on which
  # agent binary version we are installing on which hardware platform:
  #
  # 64 bit on x64: %SystemDrive%\Program Files\HP\HP BTO Software\bin\win64
  # 32 bit on x64: %SystemDrive%\Program Files (x86)\HP\HP BTO Software\bin
  # 32 bit on x86: %SystemDrive%\Program Files\HP\HP BTO Software\bin
  #-----------------------------------------------------------------------------
  @winpaths = ($ENV{SystemDrive}.'/Program Files/HP/HP BTO Software/bin',
               $ENV{SystemDrive}.'/Program Files/HP/HP BTO Software/bin/win64',
               $ENV{SystemDrive}.'/Program Files (x86)/HP/HP BTO Software/bin');

  #-----------------------------------------------------------------------------
  # Determine correct path separator
  #-----------------------------------------------------------------------------
  $sep = ($win) ? ';' : ':';

  #-----------------------------------------------------------------------------
  # Build a search path by adding some alternative locations to the env path.
  # Make sure that our additions go before the env path to avoid any false hits.
  #-----------------------------------------------------------------------------
  @searchpath = split("$sep",$ENV{PATH});

  if ($win)
  {
    #---------------------------------------------------------------------------
    # OvInstallDir should be set if the Windows agent is installed, but it is
    # quite possible that we will not see it without starting a new cmd shell..
    #---------------------------------------------------------------------------
    if ($ENV{OvInstallDir})
    {
      #-------------------------------------------------------------------------
      # Include both the bin and bin\win64 subdirs
      #-------------------------------------------------------------------------
      unshift(@searchpath,$ENV{OvInstallDir}.'/bin/win64');
      unshift(@searchpath,$ENV{OvInstallDir}.'/bin');
    }
    else
    {
      #-------------------------------------------------------------------------
      # ..in which case we will just have to try the default path(s)
      #-------------------------------------------------------------------------
      unshift(@searchpath,@winpaths);
    }
  }
  else
  {
    #---------------------------------------------------------------------------
    # Add the usual suspects for Unix as well
    #---------------------------------------------------------------------------
    unshift(@searchpath,@unixpaths);
    unshift(@searchpath,$ENV{OV_BIN}) if ($ENV{OV_BIN});
  }

  #-----------------------------------------------------------------------------
  # Traverse the path
  #-----------------------------------------------------------------------------
  foreach $dir (@searchpath)
  {
    if ($win)
    {
      foreach $ext (@winext)
      {
        #-----------------------------------------------------------------------
        # Return path if we find an executable with a valid extension
        #-----------------------------------------------------------------------
        return $dir if (-f $dir.'/'.$cmd.'.'.$ext);
      }
    }
    else
    {
      #-------------------------------------------------------------------------
      # Return path if we find an executable (exact match required for Unix)
      #-------------------------------------------------------------------------
      return $dir if (-f $dir.'/'.$cmd);
    }
  }  

  #-----------------------------------------------------------------------------
  # We have searched everywhere without finding the command
  #-----------------------------------------------------------------------------
  return 0;
}

sub connect_manager
{
  my ($manager_ip,$manager_port,$ipaddresses) = @_;
  my ($ip_to_bind,$localaddr,$remoteaddr);
  my ($tcp);
  my ($response);

  #-----------------------------------------------------------------------------
  # Get protocol info
  #-----------------------------------------------------------------------------
  $tcp = getprotobyname('tcp');

  #-----------------------------------------------------------------------------
  # Pack manager address in dot notation and port number into inet format
  #-----------------------------------------------------------------------------
  $remoteaddr = sockaddr_in($manager_port, inet_aton($manager_ip));

  #-----------------------------------------------------------------------------
  # Attempt to connect to manager on each local IP address in turn, making sure
  # to check the preferred bind address first
  #-----------------------------------------------------------------------------
  foreach $ip_to_bind (@$ipaddresses)
  { 
    #---------------------------------------------------------------------------
    # Skip if $bindaddr is empty
    #---------------------------------------------------------------------------
    next unless ($ip_to_bind);
 
    loginfo("Trying $ip_to_bind") if ($debug); 
    #---------------------------------------------------------------------------
    # Translate dot notation local address to inet format, allowing the stack
    # to bind us to any local port
    #---------------------------------------------------------------------------
    $localaddr = sockaddr_in(0, inet_aton($ip_to_bind));

    #---------------------------------------------------------------------------
    # Build a TCP socket handle
    #---------------------------------------------------------------------------
    unless (socket(SOCK,PF_INET,SOCK_STREAM,$tcp))
    {
      logwarn("Cannot create TCP socket: $!");
      return 0;
    }

    #---------------------------------------------------------------------------
    # Bind the TCP socket to the local address
    #---------------------------------------------------------------------------
    unless (bind(SOCK, $localaddr))
    {
      logwarn("Cannot bind TCP socket: $!");
      close (SOCK);
      next;
    }

    #---------------------------------------------------------------------------
    # Attempt to connect to manager 
    #---------------------------------------------------------------------------
    unless (connect(SOCK, $remoteaddr))
    {
      loginfo("Unable to reach $manager_ip from $ip_to_bind: $!") if ($debug);
      close (SOCK);
      next;
    }

    #--------------------------------------------------------------------------
    # Close the socket and return the address we were able to connect from.
    # Do not attempt to read from the socket, as we will not get any response
    # from the manager and risk hanging. 
    #--------------------------------------------------------------------------
    close (SOCK);
    return $ip_to_bind; 
  }

  #----------------------------------------------------------------------------
  # We were unable to connect to the manager from any of our local NICs 
  #----------------------------------------------------------------------------
  loginfo("Unable to connect to $manager_ip from any local NIC") if ($debug);
  return 0;
}

sub set_status
{
  my ($status,$reason,$pm_domain,$ipaddr,$manager,$http_url,$http_port) = @_;
  my ($host,$timeout);

  loginfo("Updating masterlist status") if ($debug);
  #-----------------------------------------------------------------------------
  # Hardcode a few things for now
  #-----------------------------------------------------------------------------
  $timeout = "60";
  $agent = "HPO";

  #-----------------------------------------------------------------------------
  # Find out which http host to report to
  #-----------------------------------------------------------------------------
  $host = $http_server{"$pm_domain"};

  #-----------------------------------------------------------------------------
  # Update status
  #-----------------------------------------------------------------------------
  #unless(update_status($host,$http_port,$timeout,$http_url,$ipaddr,$agent,
  #                     $manager,$status,$reason))
  #{
  #  logwarn("Unable to update masterlist status");
  #}
}

sub update_status
{
  #-----------------------------------------------------------------------------
  # Note that we need local scope for our parameters, as we will refer to some
  # of them by variable expansion ($$param) later.  Note that the expansion
  # causes perl -w to report some of these variables as "used only once", as the
  # interpreter does not see that we are referring to them by expansion.
  #-----------------------------------------------------------------------------
  local ($host,$port,$timeout,$url,$ipaddr,$agent,$manager,$status,$reason)=@_;
  local ($hostname,$domainname);
  my ($sock,$encoded,$complete_url,$param,$buf,$result,$msg);
  my ($size) = 1024;

  #-----------------------------------------------------------------------------
  # Get the local hostname and domainname from Net::Domain
  #-----------------------------------------------------------------------------
  $hostname = hostname();
  $domainname = hostdomain();
 
  #-----------------------------------------------------------------------------
  # Include the necessary modules
  #-----------------------------------------------------------------------------
  
  loginfo("Opening TCP socket for host $host port: $port") if ($debug > 1);

  #-----------------------------------------------------------------------------
  # Open the socket 
  #-----------------------------------------------------------------------------
  $sock = IO::Socket::INET->new(Proto => 'tcp',
                      PeerAddr => $host,
                      PeerPort => $port,
                      Timeout => $timeout);

  #-----------------------------------------------------------------------------
  # Bail out unless we actually managed to establish connection
  #-----------------------------------------------------------------------------
  unless ($sock)
  {
    logwarn("Unable to contact host $host port $port");
    return 0;
  }

  #-----------------------------------------------------------------------------
  # Build the entire URL (GET syntax)
  #-----------------------------------------------------------------------------
  $complete_url = $url .'?' . "hostname=$hostname";

  foreach $param ("domainname","ipaddr","agent","status","reason","manager")
  {
    #---------------------------------------------------------------------------
    # URI encode variable content only
    #---------------------------------------------------------------------------
    ($encoded = $$param) =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;

    #---------------------------------------------------------------------------
    # Add to URL
    #---------------------------------------------------------------------------
    $complete_url .= '&' . "$param=$encoded";
  }     

  loginfo("URL: $complete_url") if ($debug > 1);

  #-----------------------------------------------------------------------------
  # Issue a GET request.  No, I do not have a clue as to why we have to send 
  # this many newlines to make the server respond.  We should really need only
  # two newlines to complete the header... 
  #-----------------------------------------------------------------------------
  $sock->send("GET " .${complete_url}. " HTTP/1.0\n\n\n\n");

  #-----------------------------------------------------------------------------
  # Get server response. 
  #-----------------------------------------------------------------------------
  while ($sock->recv($buf,$size))
  {
    $result .= $buf;
    #---------------------------------------------------------------------------
    # Make sure we don't wait for timeout if the message is complete
    #---------------------------------------------------------------------------
    last if $buf =~ m%</HTML>|Connection: close%;
  }

  #-----------------------------------------------------------------------------
  # Parse server response. Everything between the <BODY> tags will be a status
  # message 
  #-----------------------------------------------------------------------------
  $result = $1 if ($buf =~ m%<BODY>(.*)</BODY>%);

  #-----------------------------------------------------------------------------
  # Anything except "OK" means that the update has failed somehow
  #-----------------------------------------------------------------------------
  if ($result eq "OK")
  {
    loginfo("Status update successful") if ($debug);
    return 1;
  }
  else
  {
    #---------------------------------------------------------------------------
    # Show the error message if the HTML is properly formatted, else dump the
    # entire buffer back to the user (probably a server level problem)
    #---------------------------------------------------------------------------
    $msg = $result || $buf;
    logwarn("Status update FAILED with message: $msg");
    return 0;
  }

  #-----------------------------------------------------------------------------
  # If we end up here, we have not received a valid response from the server
  #-----------------------------------------------------------------------------
  logwarn("No response from status server on $host");
  return 0;
}

sub which
{
  my ($command) = @_;
  my (@path,@content);
  my ($extensions,$directory,$searchpath);

  #----------------------------------------------------------------------------
  # Get the content of the Path environement variable. Make sure to include the
  # current directory (.), as this is searched by default on Windows 
  #----------------------------------------------------------------------------
  @path = (".",split(/;+/,$ENV{"Path"}|$ENV{"PATH"})); 

  #----------------------------------------------------------------------------
  # Get the list of executable file extensions from the PATHEXT environment
  # variable into a subexpression suitable for the grep function
  #----------------------------------------------------------------------------
  $extensions = join("|",(split(/;+/,$ENV{"PATHEXT"})));
  $extensions =~ s/\./\\./g;

  if ($debug > 2)
  {
    loginfo("Looking for $command in Path: " . join("|",@path));
    loginfo("Extensions: $extensions");
  }

  foreach $directory (@path)
  {
    #--------------------------------------------------------------------------
    # Get rid of any trailing backslash, escape spaces, turn the slashes and 
    # add /* to the search path (just the way glob likes it)
    #--------------------------------------------------------------------------
    ($searchpath = $directory) =~ s/\\$//;
    $searchpath =~ s%\\%/%g;
    $searchpath =~ s%\s%\\ %g;
    $searchpath .= "/*";

    #--------------------------------------------------------------------------
    # List the content of the directory
    #--------------------------------------------------------------------------
    @content = glob("$searchpath");

    #--------------------------------------------------------------------------
    # Look for the specified command with any relevant extension
    #--------------------------------------------------------------------------
    if (grep(/$command($extensions)/i,@content))
    {
      loginfo("Found $command in $directory") if ($debug > 2);
      return 1; 
    }

  } 

  #----------------------------------------------------------------------------
  # No luck, it seems
  #----------------------------------------------------------------------------
  return 0; 

}

#-------------------------------------------------------------------------------
# Note that all log functions except logdie are running silent be default, as we
# do not want to disturb the software distribution routines.
#-------------------------------------------------------------------------------

sub logdie
{
  local($message) = @_;

  printf(LOGG "%s FATAL: %s\n",scalar(localtime),$message);
  die "$0: $message\n";
}

sub logerr
{
  local($message) = @_;

  printf(LOGG "%s ERROR: %s\n",scalar(localtime),$message);
  warn "$0: $message\n" if ($debug);
}

sub logwarn
{
  local($message) = @_;

  printf(LOGG "%s WARNING: %s\n",scalar(localtime),$message);
  warn "$0: $message\n" if ($debug);
}

sub loginfo
{
  local($message) = @_;
  printf("%s: %s\n",$0,$message) if ($debug);
  printf(LOGG "%s INFO: %s\n",scalar(localtime),$message);
}     

