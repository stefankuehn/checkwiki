#!/usr/bin/perl -w

#################################################################
# Program:	checkwiki.cgi
# Descrition:	show all errors of Wikipedia-Project "Check Wikipedia"
# Author:	Stefan Kühn
# Licence: GPL
#################################################################

our $VERSION = '2013-02-09';


use strict;
use warnings;
use CGI qw(param);
use CGI::Carp qw(fatalsToBrowser);
use CGI::Carp qw(fatalsToBrowser set_message); 	# CGI-Error
use URI::Escape;
use Encode;
use LWP::UserAgent;
use DBI;

set_message('There is a problem in the script. 
Send me a mail to (<a href="mailto:kuehn-s@gmx.net">kuehn-s@gmx.net</a>), 
giving this error message and the time and date of the error.');



###########
# Error-Log
###########
# Errors
# wolfsbane.toolserver.org
# cat /var/log/http/cgi_errors|grep new_checkwiki>/home/sk/error_grep.txt
#
#
# local
# sudo cat /var/log/apache2/access.log
# sudo cat /var/log/apache2/error.log




###################################
# Connect to database u_sk
###################################

sub connect_database{
	my $dbh ;
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
	#print $hostname ."\n";
	if ( $hostname =~ 'kunopc'){
		$dbh = DBI->connect( 'DBI:mysql:u_sk_yarrow',							# local 
							'sk',
							$password ,
							{
							  RaiseError => 1,
							  AutoCommit => 1
							} 
						  ) or die "Database connection not made: $DBI::errstr" . DBI->errstr;
	} else {					  
		$dbh = DBI->connect( 'DBI:mysql:u_sk_yarrow:host=sql',				    # Toolserver
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

	# to-do: no disconnect 
	# not necessary http://stackoverflow.com/questions/5325036/dbi-disconnect-question?rq=1
	#END {
 	#   $dbh->disconnect or die $DBI::errstr if $dbh;
	#	}

}





########################################################
# get environment-variables
########################################################

#foreach my $p (sort keys %ENV) { 
#	print $p=$ENV{$p}."<br />\n"; 
#}
our $script_name = 'checkwiki.cgi';
#print "<br />\n"; 
$script_name = $ENV{'SCRIPT_FILENAME'};
$script_name = '' unless defined $script_name;
$script_name =~ s/^.+\///g;
#print 'Skriptname:'.$script_name."<br />\n"; 



###########################################################
# get parameter from cgi
###########################################################
our $param_view   		= param('view');		# list, high, middle, low, only, detail
our $param_project		= param('project');		# project
our $param_id 	  		= param('id');			# id of improvment
our $param_pageid 		= param('pageid');	
our $param_offset 		= param('offset');
our $param_limit  		= param('limit');
our $param_orderby 		= param('orderby');
our $param_sort  		= param('sort');
our $param_statistic  	= param('statistic');


$param_view = '' 		unless defined $param_view;
$param_project = '' 	unless defined $param_project;
$param_id = '' 			unless defined $param_id;
$param_pageid = '' 		unless defined $param_pageid;
$param_offset = '' 		unless defined $param_offset;
$param_limit  = '' 		unless defined $param_limit;
$param_orderby = '' 	unless defined $param_orderby;
$param_sort = '' 		unless defined $param_sort;
$param_statistic  = '' 	unless defined $param_statistic;

if ($param_offset =~ /^[0-9]+$/) {} else {
	$param_offset = 0;
}

if ($param_limit =~ /^[0-9]+$/) {} else {
	$param_limit = 25;
}
$param_limit = 500 if ($param_limit > 500);
our $offset_lower = $param_offset - $param_limit;
our $offset_higher = $param_offset + $param_limit;
	$offset_lower = 0 if ($offset_lower < 0);
our  $offset_end =  $param_offset + $param_limit;


# Sorting
our $column_orderby = '';
our $column_sort = '';
if ($param_orderby ne ''){
	if (   $param_orderby ne 'article'
		and $param_orderby ne 'notice'
		and $param_orderby ne 'found'
		and $param_orderby ne 'more') {
		$param_orderby = '';
	}
}

if ($param_sort ne '') {
	if (   $param_sort ne 'asc'
		and $param_sort ne 'desc') {
		$column_sort = 'asc' 
	} else {
		$column_sort = 'asc'  if ($param_sort eq 'asc');
		$column_sort = 'desc'  if ($param_sort eq 'desc');
	}
}





###########################################################
# Begin HTML
###########################################################


	
print "Content-type: text/html\n\n";
print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'."\n";
print '<html xmlns="http://www.w3.org/1999/xhtml">'."\n";
print '<head>'."\n";
print '<title>Check Wikipedia</title>'."\n";
print '<meta http-equiv="content-type" content="text/html;charset=utf-8" />'."\n";
print get_style();
print '</head>'."\n";

print '<body>'."\n";
print '<h1>Check Wikipedia</h1>'."\n" if ($param_view ne 'bots') ; 


our $lang = '';
$lang = get_lang();








###########################################################
# show startpage with overview of all projects 
###########################################################

if (     $param_project 	eq ''
	 and $param_view    	eq ''
	 and $param_id      	eq ''
	 and $param_pageid  	eq ''
	 and $param_statistic  	eq ''
	 ) {


	 # Homepage
	print '<p>→ Homepage</p>'."\n";	
	print '<p>More information at the <a href="de.wikipedia.org/wiki/Benutzer:Stefan_Kühn/Check_Wikipedia">projectpage</a>.</p>'."\n";
	
#	print '<p>Current <b>'.get_number_all_errors_over_all().'</b> ideas for improvement known. <b>'.get_number_of_ok_over_all().'</b> are done. </p>'."\n";

	#print '<p>Attention: At the moment an update run in the database !</p>'."\n";
		
	print '<p>Choose your project!</p>'."\n";
	print '<p><span style="font-size:10px;">This table will updated every 15 minutes.</span></p>'."\n";
	print get_projects();
	

}




###########################################################
# show page for one project (language or commons)
###########################################################

if ( 	 $param_project ne ''
	 and $param_view    eq 'project'
	 and $param_id      eq ''
	 and $param_pageid  eq ''
	 ) {
	#print '<h2>'.$param_project.'</h2>'."\n";
	print '<p>→ <a href="'.$script_name.'">Homepage</a> → '.$param_project.'</p>'."\n";	

	#print 'Current <b>'.get_number_all_errors().'</b> ideas for improvement in  <b>'.get_number_all_article().'</b> articles are known. <br />'."\n";

	
	# local page, dump etc.
	print project_info($param_project);   

	print '<p><span style="font-size:10px;">This table will updated every 15 minutes.</span></p>'."\n";
	print '<table class="table">';
	print '<tr><th class="table">&nbsp;</th><th class="table">To-do</th><th class="table">Done</th></tr>'."\n";
	print get_number_of_prio();
	print '</table>';
	print '<p>A list with <a href="'.$script_name.'?project='.$param_project.'&amp;view=list">all article</a> order by number of ideas.</p>'."\n";

	#print '<p>Since the last update <b>'.get_number_of_ok().'</b> ideas for improvement were implemented. </p>'."\n";
	
	
}



###########################################################
# Show all errors of one/all priorities
###########################################################

if (   $param_project ne ''
	and ($param_view eq 'high'
	or $param_view eq 'middle'
	or $param_view eq 'low'
	or $param_view eq 'all')
	) {
	
	my $prio = 0;
	my $headline = '';
	my $html_page = '';
	if ($param_view eq 'high') {
		$prio = 1;
		$headline = 'High priority';
		$html_page = 'priority_high.htm';
	}

	if ($param_view eq 'middle') {
		$prio = 2;
		$headline = 'Middle priority';
		$html_page = 'priority_middle.htm';
	}
	
	if ($param_view eq 'low') {
		$prio = 3;
		$headline = 'Low priority';
		$html_page = 'priority_low.htm';
	}

	if ($param_view eq 'all') {
		$prio = 0;
		$headline = 'all priorities';
		$html_page = 'priority_all.htm';
	}
	
	#print '<h2>'.$param_project.' - '.$headline.'</h2>'."\n";
	
	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → '.$headline.'</p>'."\n";	
	print '<p><span style="font-size:10px;">This table will updated every 15 minutes.</span></p>'."\n";
	
	print get_number_error_and_desc_by_prio($prio);


	
	
}
###########################################################################
# a list of all articles with errors sort by name or number of errors
###########################################################################

if (    $param_project ne ''
	and $param_view eq 'list') {

	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → List of articles</p>'."\n";	

	#print '<h2>'.$param_project.' - List of articles</h2>'."\n";
	
	print '<p>At the moment this list is deactivated.</p>'."\n";
	#print get_list();	

}	




################################################################
# set article as done
################################################################
if (    $param_project ne ''
	and $param_view =~ /^(detail|only)$/
	and	$param_pageid =~ /^[0-9]+$/
	and $param_id =~ /^[0-9]+$/ ) {
	my $dbh = connect_database();
	my $sql_text = "update cw_error set ok=1 where error_id=".$param_pageid." and error=".$param_id." and project = '".$param_project."';";
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB	
}





#################################################################
# show one error with all articles
#################################################################
if (	$param_project ne ''
	and $param_view =~ /^only(done)?$/
	and $param_id =~ /^[0-9]+$/) {
	
	my $headline = '';
	$headline = get_headline($param_id);
	
	#print '<h2>'.$param_project.' - '.$headline.'</h2>'."\n";
	my $prio = get_prio_of_error($param_id);

	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=high">high priority</a>' if ($prio eq '1');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=middle">middle priority</a>' if ($prio eq '2');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=low">low priority</a>' if ($prio eq '3');


	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → '.$prio.' → '.$headline.'</p>'."\n";	
	
	
	print '<p>'.get_description($param_id).'</p>'."\n";
	print '<p>To do: <b>'.get_number_of_error($param_id).'</b>, ';
	print 'Done: <b>'.get_number_of_ok_of_error($param_id).'</b> article(s) - ';
	print 'ID: '.$param_id.' - ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=bots&amp;id='.$param_id.'&amp;offset='.$offset_lower.'&amp;limit='.$param_limit.'">List for bots</a> - ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=alldone&amp;id='.$param_id.'">Set all articles as done!</a>';
	print '</p>'."\n";
	
	# show only one error with all articles
	if ($param_view =~ /^only$/ ) {
	    print '<p><a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'">Show all done articles</a></p>';
		print get_article_of_error($param_id);
	}

	# show only one error with all articles set done
	if ($param_view =~ /^onlydone$/ ) {
	    print '<p><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">Show to-do-list</a></p>';
		print get_done_article_of_error($param_id);
	}

}





#################################################################
# show one error with all articles for bots
#################################################################
if (	$param_project ne ''
	and $param_view =~ /^bots$/   
	and $param_id =~ /^[0-9]+$/) {
	# one error with all articles
	print get_article_of_error_for_bots($param_id);

}





################################################################
if (    $param_project ne ''
	and $param_view =~ /^alldone$/   
	and $param_id =~ /^[0-9]+$/ ) {
	# All article of an error set ok = 1
	my $headline = '';
	$headline = get_headline($param_id);
	
	#print '<h2>'.$param_project.' - '.$headline.'</h2>'."\n";
	my $prio = get_prio_of_error($param_id);

	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=high">high priority</a>' if ($prio eq '1');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=middle">middle priority</a>' if ($prio eq '2');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=low">low priority</a>' if ($prio eq '3');


	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → '.$prio.' → '.$headline.'</p>'."\n";	
	
	print '<p>You work with a bot or a tool like "AWB" or "WikiCleaner".</p><p>And now you want set all <b>'.get_number_of_error($param_id).'</b> article(s) of id <b>'.$param_id.'</b> as <b>done</b>.</p>';
	
	print '<ul>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">No, I will back!</a></li>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">No, I want only try this link!</a></li>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">No, I am not sure. I will go back.</a></li>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=alldone2&amp;id='.$param_id.'">Yes, I will set all <b>'.get_number_of_error($param_id).'</b> article(s) as done.</a></li>'."\n";
	print '</ul>'."\n";	
	print '';
}
################################################################
if (    $param_project ne ''
	and $param_view =~ /^alldone2$/   
	and $param_id =~ /^[0-9]+$/ ) {
	# All article of an error set ok = 1
	my $headline = '';
	$headline = get_headline($param_id);
	
	#print '<h2>'.$param_project.' - '.$headline.'</h2>'."\n";
	my $prio = get_prio_of_error($param_id);

	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=high">high priority</a>' if ($prio eq '1');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=middle">middle priority</a>' if ($prio eq '2');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=low">low priority</a>' if ($prio eq '3');


	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → '.$prio.' → '.$headline.'</p>'."\n";	

	
	print '<p>You work with a bot or a tool like "AWB" or "WikiCleaner".</p><p>And now you want set all <b>'.get_number_of_error($param_id).'</b> article(s) of id <b>'.$param_id.'</b>. as <b>done</b>.</p>';
	
	print '<p>If you set all articles as done, then only in the database the article will set as done. With the next scan all this articles will be scanned again. If the script found this idea for improvment again, then this article is again in this list.</p>';
	
	print '<p>If you want stop this listing, then this is not the way. Please contact the author at the <a href=""bilder/de.wikipedia.org/wiki/Benutzer:Stefan_Kühn/Check_Wikipedia">projectpage</a> and discuss the problem there.</p>';
	
	
	print '<ul>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">No, I will back!</a></li>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">No, I want only try this link!</a></li>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'">No, I am not sure. I will go back.</a></li>'."\n";
	print '<li><a href="'.$script_name.'?project='.$param_project.'&amp;view=alldone3&amp;id='.$param_id.'">Yes, I will set all <b>'.get_number_of_error($param_id).'</b> article(s) as done.</a></li>'."\n";
	print '</ul>'."\n";	
	print '';
}

################################################################
if (    $param_project ne ''
	and $param_view =~ /^alldone3$/   
	and $param_id =~ /^[0-9]+$/ ) {
	# All article of an error set ok = 1
	my $headline = '';
	$headline = get_headline($param_id);
	
	#print '<h2>'.$param_project.' - '.$headline.'</h2>'."\n";
	my $prio = get_prio_of_error($param_id);

	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=high">high priority</a>' if ($prio eq '1');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=middle">middle priority</a>' if ($prio eq '2');
	$prio = '<a href="'.$script_name.'?project='.$param_project.'&amp;view=low">low priority</a>' if ($prio eq '3');


	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → '.$prio.' → '.$headline.'</p>'."\n";	

	print '<p>All <b>'.get_number_of_error($param_id).'</b> article(s) of id <b>'.$param_id.'</b>. were set as <b>done</b></p>';

	my $dbh = connect_database();
	my $sql_text = "update cw_error set ok = 1 where error=".$param_id." and project = '".$param_project."';";
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	$sth->execute or die $sth->errstr; 	

	
	print 'Back to '.$prio."\n";
}

################################################################
if (    $param_project ne ''
	and $param_view eq 'detail'
	and $param_pageid =~ /^[0-9]+$/ ) {
	# Details zu einem Artikel anzeigen
	#print '<h2>'.$param_project.' - Details</h2>'."\n";
	print '<p>→ <a href="'.$script_name.'">Homepage</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=project">'.$param_project.'</a> → ';
	print '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list">List</a> → Details</p>'."\n";	

	my $dbh = connect_database();
	my $sql_text = "select title from cw_error where error_id=".$param_pageid." and project = '".$param_project."' limit 1;";
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	$sth->execute or die $sth->errstr; 	
		while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			my $result = $_;
			$result = '' unless defined $result;
			if ($result ne '') {
				print '<p>Artikel: <a target "_blank" href="'.get_homepage($lang).'/wiki/'.$result.'">'.$result.'</a> - 
						<a href="'.get_homepage($lang).'/w/index.php?title='.$result.'&amp;action=edit">edit</a></p>';
			}
		}
	}

	print get_all_error_of_article($param_pageid);
	

}


##############################################################

if ($param_project eq ''
	and $param_statistic eq 'run') {
	print '<p>→ <a href="'.$script_name.'">Homepage</a> → Statistic';
	get_statistic_starter();
	# to-do:?
}






##############################################################
if ($param_view ne 'bots') {
	# Signatur
	print '<p><span style="font-size:10px;">Author: <a href="en.wikipedia.org/wiki/User:Stefan_Kühn" >Stefan Kühn</a> · 
	<a href="de.wikipedia.org/wiki/Benutzer:Stefan_Kühn/Check_Wikipedia">projectpage</a> · 
	<a href="de.wikipedia.org/w/index.php?title=Benutzer_Diskussion:Stefan_K%C3%BChn/Check_Wikipedia&amp;action=edit&amp;section=new">comments and bugs</a><br />
	Version '.$VERSION.' · license: <a href="www.gnu.org/copyleft/gpl.html">GPL</a> · Powered by <a href="tools.wikimedia.de/">Wikimedia Toolserver</a> </span></p>'."\n";
}






print '</body>';
print '</html>';



####################################################################################################################
####################################################################################################################
####################################################################################################################
####################################################################################################################
####################################################################################################################










sub get_number_all_errors_over_all{
	my $dbh = connect_database();
	my $sql_text = "select count(*) from cw_error where ok=0 ;";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}

sub get_number_of_ok_over_all{
	my $dbh = connect_database();
	my $sql_text = "select count(*) from cw_error where ok=1;";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}


sub get_projects{
	# List all projects at homepage
	my $dbh = connect_database();
	my $sql_text = " select id, project, errors, done, lang, project_page, translation_page, last_update, date(last_dump) , diff_1, diff_7 from cw_overview order by project; ";
	my $sth = $dbh->prepare( $sql_text )  ||  die "Problem with statement: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # here the SQL will execute at the database
	my $result = '';
	
	$result .= '<table class="table">';
	$result .= '<tr>'."\n";
	$result .= '<th class="table">#</th>'."\n";
	$result .= '<th class="table">Project</th>'."\n";
	$result .= '<th class="table">To-do</th>'."\n";
	$result .= '<th class="table">Done</th>'."\n";
	$result .= '<th class="table">Change to<br />yesterday</th>'."\n";
	$result .= '<th class="table">Change to<br />last week</th>'."\n";
	$result .= '<th class="table">Last dump</th>'."\n";
	$result .= '<th class="table">Last update</th>'."\n";
	$result .= '<th class="table">Page at Wikipedia</th>'."\n";
	$result .= '<th class="table">Translation</th>'."\n";
	$result .= '</tr>'."\n";	
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 11) {
				$j= 0;
				$i ++;
			}
		}
		

		$result .= '<tr>'."\n";
		$result .= '<td class="table">'.$output[0][0].'</td>'."\n";
		$result .= '<td class="table"><a href="'.$script_name.'?project='.$output[0][1].'&amp;view=project" rel="nofollow">'.$output[0][1].'</td>'."\n";
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][2].'</td>'."\n";
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][3].'</td>'."\n";
		#change
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][9].'</td>'."\n";
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][10].'</td>'."\n";
		#last dump
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][8].'</td>'."\n";
		$result .= '<td class="table">'.time_string($output[0][7]).'</td>';
		$result .= '<td class="table" align="center"  valign="middle"><a href="'.$output[0][4].'.wikipedia.org/wiki/'.$output[0][5].'">here</a></td>'."\n";
		$result .= '<td class="table" align="center"  valign="middle"><a href="'.$output[0][4].'.wikipedia.org/wiki/'.$output[0][6].'">here</a></td>'."\n";
		$result .= '</tr>'."\n";	

	}
	$result .= '</table>';
	return ($result);
}

sub get_number_all_article{
	my $dbh = connect_database();
	my $sql_text = "select count(a.error_id) from (select error_id from cw_error where ok=0 and project = '".$param_project."' group by error_id) a;";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}

sub get_number_of_ok{
	my $dbh = connect_database();
	my $sql_text = "select IFNULL(sum(done),0) from cw_overview_errors where project = '".$param_project."';";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}


sub get_number_all_errors{
	my $dbh = connect_database();
	my $sql_text = "select IFNULL(sum(errors),0) from cw_overview_errors where project = '".$param_project."';";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}

sub get_number_of_error{
	# Anzahl gefundenen Vorkommen eines Fehlers
	my $error = shift;
	my $dbh = connect_database();
	my $sql_text = "select count(*) from cw_error where ok=0 and error = ".$error." and project = '".$param_project."';";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}

sub get_number_of_ok_of_error{
	# Anzahl gefundenen Vorkommen eines Fehlers
	my $error = shift;
	my $dbh = connect_database();
	my $sql_text = "select count(*) from cw_error where ok=1 and error = ".$error." and project = '".$param_project."';";
	my $result = 0;
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}




#############################################################
# Get all projectinfos for project-startpage
#############################################################

sub project_info{
	my $param_project = shift;
	my $dbh = connect_database();
	my $sql_text = "
	select project, 
	lang, 
	if(length(ifnull(wikipage,''))!=0,wikipage, 'no data') wikipage,
	if(length(ifnull(translation_page,''))!=0,translation_page, 'no data') translation_page,
	date_format(last_dump,'%Y-%m-%d') last_dump, 
	date_format(next_dump ,'%Y-%m-%d') next_dump,
	ifnull(DATEDIFF(curdate(),last_dump),''),
	ifnull(DATEDIFF(curdate(),next_dump),''),
	ifnull(DATEDIFF(next_dump,last_dump),'')
	from cw_project 
	where project='".$param_project."' limit 1;";	


	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	
	my @info;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			@info = @$arrayref; # only one line possible, last line win
		}
	}
	my $result = '';
	$result .= '<ul>'."\n";
    $result .= '<li>local page: '.'<a href="'.get_homepage($info[1]).'/wiki/'.$info[2].'">'.$info[2].'</a></li>'."\n";
    $result .= '<li>translation page: '.'<a href="'.get_homepage($info[1]).'/wiki/'.$info[3].'">here</a></li>'."\n";
    $result .= '<li>dump '.$info[4].' ('.$info[6].' days old), status: last scanned</li>'."\n";
    $result .= '<li>dump '.$info[5].' ('.$info[7].' days old), status: new available dump</li>'."\n";
    $result .= '<li>diff: '.$info[8].' days</li>'."\n";
    #to-do: print '<li>statistic (be available soon)</li>'."\n";
    #to-do: print '<li>top 100 (be available soon)</li>'."\n";
    $result .= '</ul>';
    return ($result);
	
}


#############################################################
# Show priority table (high, medium, low) + Number of errors
#############################################################

sub get_number_of_prio{

	my $dbh = connect_database();
	my $sql_text = "
	select  IFNULL(sum(errors),0) ,prio , IFNULL(sum(done),0) 
	from cw_overview_errors 
	where project = '".$param_project."' 
	group by prio 
	having prio > 0 order by prio;";	
	
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	
	my $sum_of_all = 0;
	my $sum_of_all_ok = 0;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 3) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}
		my $number_of_error = $i;
		$result .= '<tr><td class="table" align="right"><a href="'.$script_name.'?project='.$param_project.'&amp;view=';
		$result .= 'nothing" rel="nofollow">deactivated' if ($output[0][1] == 0);
		$result .= 'high" rel="nofollow">high priority' if ($output[0][1] == 1);
		$result .= 'middle" rel="nofollow">middle priority' if ($output[0][1] == 2);
		$result .= 'low" rel="nofollow">low priority' if ($output[0][1] == 3);
		$result .= '</a></td><td class="table" align="right"  valign="middle">'.$output[0][0].'</td><td class="table" align="right"  valign="middle">'.$output[0][2].'</td></tr>'."\n";
		$sum_of_all = $sum_of_all + $output[0][0];
		$sum_of_all_ok = $sum_of_all_ok + $output[0][2];
		if ($output[0][1] == 3) {
			# summe -> all priorities
			my $result2 .= '<tr><td class="table" align="right"><a href="'.$script_name.'?project='.$param_project.'&amp;view=';
			$result2 .= 'all">all priorities';
			$result2 .= '</a></td><td class="table" align="right"  valign="middle">'.$sum_of_all.'</td><td class="table" align="right"  valign="middle">'.$sum_of_all_ok.'</td></tr>'."\n";
			#$result2 .= '<tr><td class="table" align="right">&nbsp;</td><td class="table" align="right"  valign="middle">&nbsp;</td><td class="table" align="right"  valign="middle">&nbsp;</td></tr>'."\n";
			$result = $result2.$result;
		}
		
	}
	return ($result);
}







####################################################################
# Show table with todo, description of errors (all,high,middle,low)
####################################################################


sub get_number_error_and_desc_by_prio{
	my $prio = shift;
	my $dbh = connect_database();
	my $sql_text ="select IFNULL(errors, '') todo, IFNULL(done, '') ok, name, name_trans, id from cw_overview_errors where prio = ".$prio." and project = '".$param_project."' order by name_trans, name;";
 
	if ($prio == 0) {
		# show all priorities
	  $sql_text ="select IFNULL(errors, '') todo, IFNULL(done, '') ok, name, name_trans, id from cw_overview_errors where project = '".$param_project."' order by name_trans, name;";
 
	}
	
	if ($prio == 0 and $param_project eq 'all') {
		# show all priorities
		  $sql_text ="select IFNULL(errors, '') todo, IFNULL(done, '') ok, name, name_trans, id from cw_overview_errors order by name_trans, name;";

	}
  
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	my $result = '';
	$result .= '<table class="table">';
	$result .= '<tr>';
	$result .= '<th class="table">To-do</th>';
	$result .= '<th class="table">Done</th>';
	$result .= '<th class="table">Description</th>';
	$result .= '<th class="table">ID</th>';
	$result .= '</tr>'."\n";
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 5) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}
		
		my $headline = $output[0][2];
		$headline = $output[0][3] if ($output[0][3] ne '');
		

		$result .= '<tr>';
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][0].'</td>';
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][1].'</td>';
		$result .= '<td class="table"><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$output[0][4].'" rel="nofollow">'.$headline.'</a></td>';
		$result .= '<td class="table" align="right"  valign="middle">'.$output[0][4].'</td>';
		$result .= '</tr>'."\n";	

	}
	$result .= '</table>';
	return ($result);
}









sub get_headline{
	my $error = shift;
	my $dbh = connect_database();
	my $sql_text = " select name, name_trans from cw_error_desc where id = ".$error." and project = '".$param_project."';";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		#old
		#foreach(@$arrayref) {
		#	$result = $_;
		#}
		
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print '<p class="smalltext"/>xxx'.$_."</p>\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 2) {
				$j= 0;
				$i ++;
			}
		}
		if ($output[0][1] ne '') {
			# translated text
			$result = $output[0][1] ;
		} else {
			# english text
			$result = $output[0][0];
		}
	}
	return ($result);
}



sub get_description{
	my $error = shift;
	my $dbh = connect_database();
	my $sql_text = " select text, text_trans from cw_error_desc where id = ".$error." and project = '".$param_project."';";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		# old
		#foreach(@$arrayref) {
		#	$result = $_;
		#}
		
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			#print $_."\n";
		}
		if ($output[0][1] ne '') {
			# translated text
			$result = $output[0][1] ;
		} else {
			# english text
			$result = $output[0][0];
		}
		
	}
	return ($result);
}



sub get_prio_of_error{
	my $error = shift;
	my $dbh = connect_database();
	my $sql_text = " select prio from cw_error_desc where id = ".$error." and project = '".$param_project."';";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}





############################################################
# show table for only one error
############################################################

sub get_article_of_error{
	my $error = shift;
	my $dbh = connect_database();

	$column_orderby = '' if ( $column_orderby eq '');	
	$column_orderby = 'order by a.title' if ($param_orderby eq 'article');
	$column_orderby = 'order by a.notice' if ($param_orderby eq 'notice');
	$column_orderby = 'order by more' if ($param_orderby eq 'more');
	$column_orderby = 'order by a.found' if ($param_orderby eq 'found');	
	$column_sort    = 'asc'   if ( $column_sort  eq '');
	$column_orderby = $column_orderby.' '.$column_sort if ( $column_orderby  ne '');
	
	

	


	# my $sql_text =	 "
	# 	select a.title, a.notice , a.error_id, count(*) more, a.found, a.project from (	
	# 	select title, notice, error_id, found, project from cw_error where error=".$error." and ok=0 and project = '".$param_project."') a
	# 	join cw_error b
	# 	on (a.title = b.title)
	# 	where b.ok = 0
	# 	and b.project = '".$param_project."'
	# 	group by a.title, a.notice, a.error_id
	# 	".' '.$column_orderby.' '." 
	# 	limit ".$param_offset.",".$param_limit.";";

	# if ($param_project eq 'all') {
	# 	$sql_text =	 "
	# 		select a.title, a.notice , a.error_id, count(*) more, a.found, a.project from (	
	# 		select title, notice, error_id, found, project from cw_error where error=".$error." and ok=0 ) a
	# 		join cw_error b
	# 		on (a.title = b.title)
	# 		where b.ok = 0
	# 		group by a.title, a.notice, a.error_id
	# 		".' '.$column_orderby.' '." 
	# 		limit ".$param_offset.",".$param_limit.";";
	# }



	$column_orderby = '' if ( $column_orderby eq '');	
	$column_orderby = 'order by title' if ($param_orderby eq 'article');
	$column_orderby = 'order by notice' if ($param_orderby eq 'notice');
	$column_orderby = 'order by more' if ($param_orderby eq 'more');
	$column_orderby = 'order by found' if ($param_orderby eq 'found');	
	$column_sort    = 'asc'   if ( $column_sort  eq '');
	$column_orderby = $column_orderby.' '.$column_sort if ( $column_orderby  ne '');
		
	my $sql_text = " select title, notice, error_id, 'more' more, found, project 
	from cw_error 
	where error = ".$error." 
	and ok=0 
	and project = '".$param_project."' 
	".' '.$column_orderby.' '." 
	limit ".$param_offset.",".$param_limit.";";







	#print $sql_text."\n";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	
	$result .= '<p>';
	$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$offset_lower.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">←</a>';
	$result .= ' '.$param_offset.' bis '.$offset_end.' ';
	$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$offset_higher.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">→</a>';
	$result .= '</p>';
	
	$result .= '<table class="table">';
	$result .= '<tr>';
	$result .= '<th class="table">Article';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=article&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=article&amp;sort=desc">↓</a>';
		$result .= '</th>';
	$result .= '<th class="table">Edit</th>';
	$result .= '<th class="table">Notice';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=notice&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=notice&amp;sort=desc">↓</a>';
		$result .= '</th>';	
	$result .= '<th class="table">More';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=more&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=more&amp;sort=desc">↓</a>';
		$result .= '</th>';	
	$result .= '<th class="table">Found';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=found&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=found&amp;sort=desc">↓</a>';
		$result .= '</th>';	
	$result .= '<th class="table">Done</th>';
	$result .= '</tr>'."\n";
	my $row_style = '';
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 6) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}

		my $article_project = $param_project;
		if ($param_project eq 'all') {
			$article_project = $output[0][5];
			$lang = $article_project;
			$lang =~ s/wiki$//;
		}
		
		if ($row_style eq '' ) {
			$row_style = 'style="background-color:#D0F5A9"';
		} else {
			$row_style = '';
		}	
			
		$result .= '<tr>';
		$result .= '<td class="table" '.$row_style.'><a href="'.get_homepage($lang).'/wiki/'.$output[0][0].'">'.$output[0][0].'</a></td>';
		$result .= '<td class="table" '.$row_style.'><a href="'.get_homepage($lang).'/w/index.php?title='.$output[0][0].'&amp;action=edit">edit</a></td>';

		$result .= '<td class="table" '.$row_style.'>'.$output[0][1].'</td>';
		$result .= '<td class="table" '.$row_style.' align="center"  valign="middle">';
		#if ($output[0][3] == 1) {
			# only one error
		#} else {
			# more other errors
			
			$result .= '<a href="'.$script_name.'?project='.$article_project.'&amp;view=detail&amp;pageid='.$output[0][2].'">'.$output[0][3].'</a>';
		#}
		$result .= '</td>';
		$result .= '<td class="table" '.$row_style.'>'.time_string($output[0][4]).'</td>';
		$result .= '<td class="table" '.$row_style.' align="center"  valign="middle">';
		$result .= '<a href="'.$script_name.'?project='.$article_project.'&amp;view=only&amp;id='.$error.'&amp;pageid='.$output[0][2].'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'" rel="nofollow">Done</a>';
		$result .= '</td></tr>'."\n";	

	}
	$result .= '</table>';
	return ($result);
}

sub get_done_article_of_error{
	my $error = shift;
	my $dbh = connect_database();
	# show all done articles of one error

	$column_orderby = 'a.title' if ( $column_orderby eq '');	
	$column_orderby = 'a.title' if ($param_orderby eq 'article');
	$column_orderby = 'a.notice' if ($param_orderby eq 'notice');
	$column_orderby = 'more' if ($param_orderby eq 'more');
	$column_orderby = 'a.found' if ($param_orderby eq 'found');	
	$column_sort    = 'asc'   if ( $column_sort  eq '');
	
	
	#my $sql_text = " select title, hinweis, id from pd_error where error = ".$error." and ok=0 order by title limit 25;";
	my $sql_text =	 "
		select a.title, a.notice , a.error_id, count(*) more, a.found, a.project from (	
		select title, notice, error_id, found, project from cw_error where error=".$error." and ok=1 and project = '".$param_project."') a
		join cw_error b
		on (a.title = b.title)
		and b.project = '".$param_project."'
		group by a.title, a.notice, a.error_id
		order by ".$column_orderby." ".$column_sort." 
		limit ".$param_offset.",".$param_limit.";";

	if ($param_project eq 'all') {
		$sql_text =	 "
			select a.title, a.notice , a.error_id, count(*) more, a.found, a.project from (	
			select title, notice, error_id, found, project from cw_error where error=".$error." and ok=1 ) a
			join cw_error b
			on (a.title = b.title)
			where b.ok = 1
			group by a.title, a.notice, a.error_id
			order by ".$column_orderby." ".$column_sort." 
			limit ".$param_offset.",".$param_limit.";";
	}
		
	#print $sql_text."\n";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	
	$result .= '<p>';
	$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$offset_lower.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">←</a>';
	$result .= ' '.$param_offset.' bis '.$offset_end.' ';
	$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$offset_higher.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">→</a>';
	$result .= '</p>';
	
	$result .= '<table class="table">';
	$result .= '<tr>';
	$result .= '<th class="table">Article';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=article&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=article&amp;sort=desc">↓</a>';
		$result .= '</th>';
	$result .= '<th class="table">Version</th>';
	$result .= '<th class="table">Notice';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=notice&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=notice&amp;sort=desc">↓</a>';
		$result .= '</th>';	
	$result .= '<th class="table">More';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=more&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=more&amp;sort=desc">↓</a>';
		$result .= '</th>';	
	$result .= '<th class="table">Found';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=found&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=onlydone&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=found&amp;sort=desc">↓</a>';
		$result .= '</th>';	
	$result .= '<th class="table">Done</th>';
	$result .= '</tr>'."\n";
	my $row_style = '';
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 6) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}

		my $article_project = $param_project;
		if ($param_project eq 'all') {
			$article_project = $output[0][5];
			$lang = $article_project;
			$lang =~ s/wiki$//;
		}
		
		if ($row_style eq '' ) {
			$row_style = 'style="background-color:#D0F5A9"';
		} else {
			$row_style = '';
		}	
			
		$result .= '<tr>';
		$result .= '<td class="table" '.$row_style.'><a href="'.get_homepage($lang).'/wiki/'.$output[0][0].'">'.$output[0][0].'</a></td>';
		$result .= '<td class="table" '.$row_style.'><a href="'.get_homepage($lang).'/w/index.php?title='.$output[0][0].'&amp;action=history">history</a></td>';

		$result .= '<td class="table" '.$row_style.'>'.$output[0][1].'</td>';
		$result .= '<td class="table" '.$row_style.' align="center"  valign="middle">';
		if ($output[0][3] == 1) {
			# only one error
		} else {
			# more other errors
			
			$result .= '<a href="'.$script_name.'?project='.$article_project.'&amp;view=detail&amp;pageid='.$output[0][2].'">'.$output[0][3].'</a>'
		}
		$result .= '</td>';
		$result .= '<td class="table" '.$row_style.'>'.time_string($output[0][4]).'</td>';
		$result .= '<td class="table" '.$row_style.' align="center"  valign="middle">';
		#$result .= '<a href="'.$script_name.'?project='.$article_project.'&amp;view=only&amp;id='.$error.'&amp;pageid='.$output[0][2].'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">Done</a>';
		$result .= 'ok';	
		$result .= '</td></tr>'."\n";	

	}
	$result .= '</table>';
	return ($result);
}




sub get_article_of_error_for_bots{
	my $error = shift;
	my $dbh = connect_database();
	#my $sql_text = " select title, hinweis, id from pd_error where error = ".$error." and ok=0 order by title limit 25;";
	my $sql_text =	 "
		select a.title, a.notice , a.error_id, count(*) from (	select title, notice, error_id from cw_error where error=".$error." and ok=0 and project = '".$param_project."') a
		join cw_error b
		on (a.title = b.title)
		where b.ok = 0
		and b.project = '".$param_project."'
		group by a.title, a.notice, a.error_id
		limit ".$param_offset.",".$param_limit.";";
	
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	
	$result .= '<pre>'."\n";
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 4) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}

		$result .= $output[0][0]."\n";
	}
	$result .= '</pre>';
	return ($result);
}

sub get_list{
	my $dbh = connect_database();
	$column_orderby = 'more' if ( $column_orderby eq '');	
	$column_orderby = 'title'    if ($param_orderby eq 'article');
	$column_orderby = 'more' if ($param_orderby eq 'more');
	$column_sort    = 'desc'     if ( $column_sort  eq '');
	

	my $sql_text = "select title, count(*) more, error_id from cw_error where ok=0 and project = '".$param_project."' 
	group by title order by ".$column_orderby." ".$column_sort.", title 
	limit ".$param_offset.",".$param_limit.";";
	
	#print $sql_text."\n";
	
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	my $result = '';
	
	$result .= '<p>';
	$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list&amp;offset='.$offset_lower.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">←</a>';
	$result .= ' '.$param_offset.' bis '.$offset_end.' ';
	$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list&amp;offset='.$offset_higher.'&amp;limit='.$param_limit.'&amp;orderby='.$param_orderby.'&amp;sort='.$param_sort.'">→</a>';
	$result .= '</p>';
	
	$result .= '<table class="table">';
	$result .= '<tr>';
	$result .= '<th class="table">Number';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=more&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=more&amp;sort=desc">↓</a>';
		$result .= '</th>';
	$result .= '<th class="table">Article';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=article&amp;sort=asc">↑</a>';
		$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=list&amp;id='.$param_id.'&amp;offset='.$param_offset.'&amp;limit='.$param_limit.'&amp;orderby=article&amp;sort=desc">↓</a>';
		$result .= '</th>';
	$result .= '<th class="table">Details</th>';
	$result .= '</tr>'."\n";
	
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 3) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}

		$result .= '<tr><td class="table" align="right"  valign="middle">'.$output[0][1].'</td>';
		$result .= '<td class="table"><a href="'.get_homepage($lang).'/wiki/'.$output[0][0].'">'.$output[0][0].'</a></td>';
		$result .= '<td class="table" align="center"  valign="middle"><a href="'.$script_name.'?project='.$param_project.'&amp;view=detail&amp;pageid='.$output[0][2].'">Details</a></td>';
		$result .= '</tr>'."\n";	

	}
	$result .= '</table>';
	return ($result);
}




sub get_all_error_of_article{
	# Detailansicht
	my $id = shift;
	my $dbh = connect_database();
	my $sql_text = "select a.error, b.name, a.notice, a.error_id, a.ok, b.name_trans
					from cw_error a join cw_error_desc b 
					on ( a.error = b.id) 
					where (a.error_id = ".$id." and a.project = '".$param_project."' )
					and b.project = '".$param_project."'
					order by b.name;";
					
					
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	my $result = '';
	$result .= '<table class="table">';
	$result .= '<tr>';
	$result .= '<th class="table">ideas for improvement</th>';
	$result .= '<th class="table">Notice</th>';
	$result .= '<th class="table">Done</th>';
	$result .= '</tr>'."\n";
	
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		my @output;
		my $i = 0;
		my $j = 0;
		foreach(@$arrayref) {
			#print $_."\n";
			$output[$i][$j] = $_;
			$output[$i][$j] = '' unless defined $output[$i][$j];
			$j = $j +1;
			if ($j == 6) {
				$j= 0;
				$i ++;
			}
			#print $_."\n";
		}

	
		$result .= '<tr>';
		$result .= '<td class="table"><a href="'.$script_name.'?project='.$param_project.'&amp;view=only&amp;id='.$output[0][0].'">';
		if ($output[0][5] ne ''){
			$result .= $output[0][5];
		} else {
			$result .= $output[0][1];
		}
		$result .= '</a></td>';
		$result .= '<td class="table">'.$output[0][2].'</td>';
		$result .= '<td class="table" align="center"  valign="middle">';
		if ($output[0][4] eq '0') {
			$result .= '<a href="'.$script_name.'?project='.$param_project.'&amp;view=detail&amp;id='.$output[0][0].'&amp;pageid='.$output[0][3].'" rel="nofollow">Done</a>';
		} else {
			$result .= 'ok';
		}
		$result .= '</td>';
		$result .= '</tr>'."\n";		

	}
	$result .= '</table>';
	return ($result);
}


sub get_lang{
	my $dbh = connect_database();
	my $sql_text = " select lang from cw_project where project = '".$param_project."';";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text )  ||  die "Kann Statement nicht vorbereiten: $DBI::errstr\n";
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute or die $sth->errstr; # hier geschieht die Anfrage an die DB
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
			$result = '' unless defined $result;
		}
	}
	return ($result);
}

sub time_string{
	my $timestring = $_[0];
	my $result = '';
	if ($timestring ne '') {
		$result = $timestring.'---';
		$result = $timestring;
		$result =~ s/ /&nbsp;/g;   #/ Syntaxhiglighting

		#$result = $result.substr($timestring,0,4).'-'.substr($timestring,4,2).'-'.substr($timestring,6,2).'&nbsp;'.substr($timestring,9,2).':'.substr($timestring,11,2).':'.substr($timestring,13,2);
	}
	return ($result);
}

sub get_homepage {
	my $lang = $_[0];
	my $result = '';
	if ($lang eq 'commons') {
		$result = $lang.'.wikimedia.org';
	} else {
		$result = $lang.'.wikipedia.org';
	}
	if ($param_project =~/wikisource$/) {
		$result = $lang.'.wikisource.org';
	}
	
	
	return($result);
}

sub get_style{
my $result= '<style type="text/css">
body { 
	
	font-family: Verdana, Tahoma, Arial, Helvetica, sans-serif;
	font-size:14px;
	font-style:normal;
	
	/* color:#9A91ff; */
	
	/* background-color:#00077A; */
	/* background-image:url(back.jpg); */
	/* background:url(back_new.jpg) no-repeat fixed top center; */
	/* background:url(../images/back_new.jpg) no-repeat fixed top center; */
	/* background:url(../images/back_schaf2.jpg) no-repeat fixed bottom left; */
	/* background:url(../images/back_schaf3.jpg) no-repeat fixed bottom left; */
	
	background-color:white;
	color:#555555;
	text-decoration:none; 
	line-height:normal; 
	font-weight:normal; 
	font-variant:normal; 
	text-transform:none; 
	margin-left:5%;
	margin-right:5%;
	}
	
h1	{
	/*color:red; */
	font-size:20px;
	}

h2	{
	/*color:red; */
	font-size:16px;
	}
	
a 	{  

	/*only blue */
	/* color:#80BFBF; */ 
	/* color:#4889c5; */ 
	/* color:#326a9e; */  
	
	color:#4889c5;
	font-weight:bold;
	/*nettes grün */
	/*color:#7CFC00;*/
	
	/* nice combinatione */
	/*color:#00077A; */
	/*background-color:#eee8fd;*/
	
	
	/* without underline */
	text-decoration:none; 
	
	/*Außenabstand*/
	/*padding:2px;*/
	}

a:hover {  
	background-color:#ffdeff;
	color:red;
	}
	
.nocolor{  
	background-color:white;
	color:white;
	} 
	
a:hover.nocolor{  
	background-color:white;
	color:white;
	}
	
.table{
	font-size:12px; 

	vertical-align:top;

	border-width:thin;
  	border-style:solid;
  	border-color:blue;
  	background-color:#EEEEEE;
  	
  	/*Innenabstand*/
	padding-top:2px;
	padding-bottom:2px;
	padding-left:5px;
	padding-right:5px;
  	
  	/* small border */
  	border-collapse:collapse; 
	
	/* no wrap
	white-space:nowrap;*/
  	
  	}
	
</style>';
return ($result);
}

###############################
sub get_statistic_starter{

}


