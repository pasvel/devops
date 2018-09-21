#!/usr/bin/perl -w

use strict;
use DBI;

$ENV{'ODBCSYSINI'} = "/usr/local/unixODBC/etc";
$ENV{'ODBCINI'} = "/usr/local/unixODBC/etc/odbc.ini";

my $data_source = q/dbi:ODBC:TNDB/;
my $user = q/sa/;
my $password = q/Faktumest100/;

my $dbh = DBI->connect($data_source, $user, $password)
          or die "Can't connect to $data_source: $DBI::errstr";

print "\n$ARGV[0]:" if ($dbh);

&do_query;

$dbh->disconnect;

sub do_query {
  my @data;
  my $sql_str = "SELECT * FROM tndb.dbo.hosts WHERE (hostname = '$ARGV[0]' )";
  my $sth = $dbh->prepare($sql_str);
  my $rv = $sth->execute || 
           die "Can't execute statement: $DBI::errstr\n";
                   
#  print "Query will return $sth->{NUM_OF_FIELDS} fields.\n\n";
#  print "Field names: @{ $sth->{NAME} }\n";

  while (@data=$sth->fetchrow_array())
  { 
    my $x1=$data[2];
    my $x2=$data[3];
    print "$x1:$x2";
  }

#    while (($field_3, $field_4) = $sth->fetchrow_array) {
#        print "$field_3: $field_4\n";
#    }

  $sth->finish();
}
