#!/usr/bin/perl -w

#################################################################
# Program:	checkwiki_bots.cgi
# Descrition:	features for bots for Wikipedia-Project "Check Wikipedia"
# Author:	Stefan Kühn / Nicolas Vervelle
# Licence:	GPL
#################################################################

our $VERSION = '2013-02-13';

use strict;
use warnings;

use DBI;
use CGI;


# Get parameters from CGI
our $request = CGI->new;

our $param_project = $request->param('project'); # Project
our $param_action  = $request->param('action');  # Action requested: list, mark
our $param_id      = $request->param('id');      # Id of improvement
our $param_offset  = $request->param('offset');  # Offset for the list of articles
our $param_limit   = $request->param('limit');   # Limit to the number of articles in the list
our $param_pageid  = $request->param('pageid');  # PageId of an article

$param_project = '' unless defined $param_project;
$param_action  = '' unless defined $param_action;
$param_id      = '' unless defined $param_id;
$param_offset  = '' unless defined $param_offset;
$param_limit   = '' unless defined $param_limit;
$param_pageid  = '' unless defined $param_pageid;

if ($param_offset =~ /^[0-9]+$/) {} else {
	$param_offset = 0;
}
if ($param_limit =~ /^[0-9]+$/) {} else {
	$param_limit = 25;
}
$param_limit = 500 if ($param_limit > 500);


# Process request
if (    $param_project ne ''
    and $param_action  eq 'list'
    and $param_id      =~ /^[0-9]+$/) {
	# Action : List articles
	print list_articles($request, $param_project, $param_id, $param_offset, $param_limit);

} elsif (    $param_project ne ''
         and $param_action  eq 'mark'
         and $param_id      =~ /^[0-9]+$/
         and $param_pageid  =~ /^[0-9]+$/) {
	# Action : Mark error as fixed
	print mark_article_done($request, $param_project, $param_id, $param_pageid);

} else {
	# Incorrect usage
	print show_usage($request);
}


# List articles
sub list_articles{
	my $request = shift;
	my $project = shift;
	my $error = shift;
	my $offset = shift;
	my $limit = shift;
	my $error = shift;

	# Execute request to retrieve list of articles
	my $dbh = connect_database();
	my $sql_text =	 "
		select a.title, a.notice , a.error_id, count(*)
		from (	select title, notice, error_id from cw_error where error=".$error." and ok=0 and project = '".$project."') a
		join cw_error b
		on (a.title = b.title)
		where b.ok = 0
		and b.project = '".$project."'
		group by a.title, a.notice, a.error_id
		limit ".$offset.",".$limit.";";
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB

	# Send result
	print $request->header(-type => 'text/text');
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 4) {
				$j= 0;
				$i ++;
			}
		}

		print 'pageid='.$output[0][2].'|title='.$output[0][0].'\n';
	}
}


# Mark article as done
sub mark_article_done{
	my $request = shift;
	my $project = shift;
	my $error = shift;
	my $pageid = shift;

	# Execute request to mark article as done
	my $dbh = connect_database();
	my $sql_text = "update cw_error set ok=1 where error_id=".$pageid." and error=".$error." and project = '".$project."';";
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB	

	# Send result
	print $request->header(-type => 'text/text');
	print 'Article with pageid='.$pageid.' has been marked as done.';
}


# Show usage of the script
sub show_usage{
	my $request = shift;
	print $request->header(-type => 'text/text');
	print 'This script can be used with the following parameters:\n';
	print '  project=... : name of the project (enwiki, ...)\n';
	print '  id=... : id of improvement\n';
	print '  action=... : action requested, among the following values:\n';
	print '    list: list articles for the given improvement. The following parameters can also be used:\n';
	print '      offset=... : offset in the list of articles\n';
	print '      limit=... : maximum number of articles in the list\n';
	print '    mark: mark an article as fixed for the given improvement. The following parameters can also be used:\n';
	print '      pageid=... : page identifier of the article that has been fixed\n';
}


# Connect to database
sub connect_database{
	my $dbh;
	# load password for database
	open(PWD, "</home/sk/.mytop");
	my $password = '';
	do {
		my $test = <PWD>;
		if ($test =~ /^pass=/ ) {
			$password = $test;
			$password =~ s/^pass=//g;
			$password =~ s/\n//g;
		}
	}
	while (eof(PWD) != 1);
	close(PWD);

	my $hostname = `hostname`;		# check PC-name
	if ( $hostname =~ 'kunopc') {
		$dbh = DBI->connect('DBI:mysql:u_sk_yarrow',							# local 
							'sk',
							$password ,
							{
							  RaiseError => 1,
							  AutoCommit => 1
							} 
						  ) or die "Database connection not made: $DBI::errstr" . DBI->errstr;
	} else {					  
		$dbh = DBI->connect('DBI:mysql:u_sk_yarrow:host=sql',				    # Toolserver
							'sk',
							$password ,
							{
							  RaiseError => 1,
							  AutoCommit => 1
							} 
						  ) or die "Database connection not made: $DBI::errstr" . DBI->errstr;
	}	

	$password = '';
	return ($dbh);
}
