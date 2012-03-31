#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use 5.010;
 
use wikimedia;

#####################################################
print '#' x 60 ."\n";
print 'Test 1 - load sitmatrix from API'."\n\n";
my $wm_agent = eval { new wikimedia(); }  or die ($@);	# create new object
$wm_agent->load_sitematrix_from_api();					# load sitmatrix from API


#####################################################
print '#' x 60 ."\n";
print 'Test 2 - List with all languages'."\n\n";

my @languages =  $wm_agent->get_all_languages;
print @languages .' languages in sitematrix'."\n";

foreach my $code (@languages){
	if ($code =~ /^(de|fr|en|yi|ru)/) {			# output limit only for test 
		printf "%-10s %-20s %-20s\n", $code, $wm_agent->get_language_name_en($code), $wm_agent->get_language_name($code);
	}
}


#####################################################
print '#' x 60 ."\n";
print 'Test 3 - get languages names'."\n\n";

#print $wm_agent->get_language_name_en() ."\n";
#print $wm_agent->get_language_name() ."\n";
#print $wm_agent->is_language_code_ok()."\n";

printf "%-10s %-20s \n", 'check fr',   $wm_agent->is_language_code_ok('fr') ;
printf "%-10s %-20s \n", 'check fxy',  $wm_agent->is_language_code_ok('fxy');



#####################################################
print '#' x 60 ."\n";
print 'Test 4 - get all projects'."\n\n";

my @projects =  $wm_agent->get_all_projects();
print scalar @projects.' Project (all, including closed projects)'."\n";


print "\n";
print 'projects of de'."\n";
@projects =  $wm_agent->get_all_projects('de');
foreach my $project_code (@projects){
	print $project_code."\n";
}

print "\n";
print 'projects of fr'."\n";
@projects =  $wm_agent->get_all_projects ('fr');
foreach my $project_code (@projects){
	print $project_code."\n";
}



#####################################################
print '#' x 60 ."\n";
print 'Test 5 - get url from project'."\n\n";

my %all_projects = %{$wm_agent->project()};		# get hash of all projects

foreach my $code ( sort keys %all_projects) {
	if ($code =~ /^(de|en|yi)/) {		
		my $project = $all_projects{$code};
		printf "%-20s %-20s \n", $code , $project->url;
	}
}


#####################################################
print '#' x 60 ."\n";
print 'Test 6 - get some articles from project'."\n\n";


my $my_project = 'dewiki';
my $curr_project = $all_projects{$my_project};
#print $curr_project->url."\n";
$curr_project->load_metadata();			#todo


my @page_list = ('Eduard Imhof', 'Kjelfossen2','Kjelfossen','R&B','Extensible_3D','Kühnheit');
my %pages = %{ $curr_project->load_pages_api( @page_list ) };

foreach my $page_name ( @page_list) {
	if (exists $pages{$page_name}) {
		my $curr_page = ${$pages{$page_name}}; 	
		print '-' x 20 ."\n"; 
		printf "%-20s %-20s \n", 'project',   $curr_page->project ;
		printf "%-20s %-20s \n", 'Namespace', $curr_page->namespace ;
		printf "%-20s %-20s \n", 'pageid',    $curr_page->pageid;
		printf "%-20s %-20s \n", 'title',     $curr_page->title;
		printf "%-20s %-20s \n", 'timestamp', $curr_page->timestamp;
		printf "%-20s %-20s \n", 'row_text',  "\n".substr($curr_page->row_text,0,100).'...';
	}
}

#my $test = $page_list[0];
#print $pages{$page_list[0]}."\n";
#my $ref_page = $pages{'R&B'};
#my $curr_page = $$ref_page;


#####################################################
print '#' x 60 ."\n";
print 'todo'."\n";
print '----'."\n";
print "\n";
print '- load metadata for project'."\n";
print '- Pushdown automaton (de: Kellerautomat)'."\n";
print '- eliminate comments etc.'."\n";

print 'Finish'."\n\n";











