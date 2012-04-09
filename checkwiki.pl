#!/usr/local/bin/perl -w

#################################################################
# Program:		checkwiki.pl
# Descrition:	Scan all pages of a Wikipedia-Project (dump or live) for errors
# Author:		Stefan Kühn
# Version:		2012-04-02
# Licence: 		GPL
# WWW:			http://toolserver.org/~sk/cw/index.htm
#################################################################

#################################################################
# Syntax
# perl -w checkwiki.pl -p=enwiki m=live
#################################################################

# Error exception
$SIG{__DIE__} = \&die_error;
$SIG{__WARN__} = \&warn_error;


use strict;
use warnings;
use diagnostics;
use URI::Escape;
use LWP::UserAgent;	
use wikimedia;

# wget -q -c http://dumps.wikimedia.org/dewiki/20120317/dewiki-20120317-pages-articles.xml.bz2


print "\n";
print '#' x 60 ."\n";
print '#' x 23 . ' checkwiki.pl ' . '#' x 23 ."\n";
print '#' x 60 ."\n";

##################################################################
my %parameter = %{ load_input_arguments() };

print '#' x 60 ."\n";
$parameter{'start_time'} = time;
printf "%20s\t%-30s\n", 'Starttime:', get_time_string($parameter{'start_time'});

my $wm_agent = eval { new wikimedia(); }  or die ($@);	# create new object
$wm_agent->load_sitematrix_from_api();					# load sitmatrix from API

if ($wm_agent->is_project_code_ok($parameter{'project'}) == 0 ) {
	finish_script_with_problem ('Unkown project'); 
}





##################################################################
#finish
$parameter{'end_time'} = time;
printf "%20s\t%-30s\n", 'Endtime:',  get_time_string($parameter{'end_time'});
printf "%20s\t%-30s\n", 'Duration:', get_time_min($parameter{'end_time'} - $parameter{'start_time'});

print '#' x 60 ."\n";
print ' Finish checkwiki'."\n";
print '#' x 60 ."\n";




sub load_input_arguments {
	my %parameter;
	$parameter{'project'} = '';
	$parameter{'modus'}   = '';
	$parameter{'only'}    = '';
	$parameter{'silent'}  = 'no';
	$parameter{'load'}    = 'new,done,dumpscan,lastchange,old';
	$parameter{'test'}    = 'no';


	#################################################################
	# Declaration of parameter via commandline
	#################################################################
	if ( @ARGV ) {
		###################
		#check argument value for project
		foreach my $current_argv (@ARGV) {
			if ( $current_argv =~ m/^p=(.*)/ ) {
				$parameter{'project'} = $1;
			}
			if ( $current_argv =~ m/^m=(dump|live)/ ) {
				$parameter{'modus'} = $1;
			}
			if ( $current_argv =~ m/^silent=(yes|no)/ ) {
				$parameter{'silent'} = $1;
			}
			if ( $current_argv =~ m/^test=(yes|no)/ ) {
				$parameter{'test'} = $1;
			}
			if ( $current_argv =~ m/^load=((new|done|dumpscan|old),?)+/ ) {		# load=new/done/dumpscan/lastchange/old
				$parameter{'load'} = $1;
			}
		}
	}

	#################################################################
	# Declaration of parameter via parameterfile
	#################################################################
	# TODO


	check_input_arguments( \%parameter);

	return \%parameter;
}



#################################################
sub check_input_arguments {
	my %parameter = %{ shift() } ;
	my $quit_reason = '';

	# All parameter available and correct
	# extract parameter 

			

	

	# project
	my $project = '';
	$project = $parameter{'project'} if (exists $parameter{'project'} );		
	$quit_reason = $quit_reason.'Unknown project!'."\n" if ($project eq '') ;
	printf "%20s\t%-30s\n",'Project:', $project;


	# scan modus
	my $scan_modus = '';
	$scan_modus .= $parameter{'modus'}.' (scan a dumpfile)'                if ($parameter{'modus'} eq 'dump');
	$scan_modus .= $parameter{'modus'}.' (scan live pages of the project)' if ($parameter{'modus'} eq 'live');
	printf "%20s\t%-30s\n",'Scan-Modus:', $scan_modus;
    if (not $parameter{'modus'} =~ m/(dump|live)/ ) {
		$quit_reason = $quit_reason.'Unknown scan-modus!'."\n";
	}

	# test modus
	printf "%20s\t%-30s\n",'Test-Modus:', $parameter{'test'};
	if (not $parameter{'test'} =~ m/(yes|no)/ ) {			#modus only for test
		$quit_reason = $quit_reason.'Unknown test-modus!'."\n";
	}

	# silent modus
	printf "%20s\t%-30s\n",'Silent-Modus:', $parameter{'silent'};
	if (not $parameter{'silent'} =~ m/(yes|no)/ ) {			
		$quit_reason = $quit_reason.'Unknown silent-modus!'."\n";
	}


	if ($quit_reason ne '') {
		finish_script_with_problem ($quit_reason);
	}

}


##########################################################################################
sub get_time_string{
	my $time = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	$mon  = $mon + 1;
	$year += 1900;
	$mon  = "0".$mon  if ($mon <10);
	$mday = "0".$mday if ($mday<10);
	$hour = "0".$hour if ($hour<10);
	$min  = "0".$min  if ($min <10);
	$sec  = "0".$sec  if ($sec <10);
	my $time_string = $year.'-'.$mon.'-'.$mday.' '.$hour.':'.$min.':'.$sec;
	return ($time_string);
}

sub get_time_min{
	# transform timediff in min 
	my $sec = shift;
	my $min = int($sec/60);
	$sec = $sec - ($min*60);
	$sec = "0".$sec if ($sec<10);
	my $time_string = $min.':'.$sec.' min';
	return ($time_string);
}
##########################################################################################
sub finish_script_with_problem {
	#End of Script, because no correct parameter
	my $quit_reason = shift;
	$quit_reason = '#' x 60 ."\n".'Stop checkwiki because problem:'."\n".$quit_reason."\n";
	$quit_reason = $quit_reason.'Use for scan a dump'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=dewiki m=dump'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=nds_nlwiki m=dump'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=nds_nlwiki m=dump silent'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=nds_nlwiki m=dump silent test'."\n\n";
	$quit_reason = $quit_reason.'Use for scan a list of pages live'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=dewiki m=live'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=dewiki m=live silent'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=dewiki m=live silent test'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=dewiki m=live silent update_error_desc'."\n";
	$quit_reason = $quit_reason.'perl -w checkwiki.pl p=dewiki m=live load=new/done/dumpscan/lastchange/old limit=500'."\n"; 	#starter modus
	$quit_reason = $quit_reason."\n";
	die ($quit_reason);
}
