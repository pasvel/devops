#!/usr/bin/perl
use Socket;

$iaddr = inet_aton("$ARGV[0]");
$name  = gethostbyaddr($iaddr, AF_INET);
print "Host name is $name\n";
