#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use 5.010;
 
use wikimedia;

print "###########################\n";
print 'Teil 1'."\n";
my $wm_agent = eval { new wikimedia(); }  or die ($@);	# neues Object anlegen
$wm_agent->load_sitematrix_from_api();					# laden der API

print "###########################\n";
print "\n".'Teil 2'."\n";
# List with all languages
my @languages =  $wm_agent->get_all_languages;

foreach my $code (@languages){
	if ($code =~ /^(de|fr|en)/) {
		printf "%-10s %-20s %-20s\n", $code, $wm_agent->get_language_name_en($code), $wm_agent->get_language_name($code);
	}
}
print @languages .' Sprachen'."\n";


print "###########################\n";
print 'Teil 3'."\n";
#print $wm_agent->get_language_name_en() ."\n";
#print $wm_agent->get_language_name() ."\n";
#print $wm_agent->is_language_code_ok()."\n";

print $wm_agent->get_language_name_en('de') ."\n";
print $wm_agent->get_language_name('de') ."\n";
print $wm_agent->get_language_name_en('fr') ."\n";
print $wm_agent->get_language_name('fr') ."\n";

print $wm_agent->is_language_code_ok('fr')."\n";
print $wm_agent->is_language_code_ok('fxy')."\n";

print "#######s####################\n";
print 'Teil 4'."\n";


my @projects =  $wm_agent->get_all_projects();

print scalar @projects.' Project (all)'."\n";

print 'Project of de'."\n";
@projects =  $wm_agent->get_all_projects('de');
foreach my $test (@projects){
	print $test."\n";
}

print "\n";
print 'Project of fr'."\n";
@projects =  $wm_agent->get_all_projects ('fr');
foreach my $test (@projects){
	print $test."\n";
}



print "###########################\n";
print 'Teil 5 - Article'."\n";



my $ref_all_project = $wm_agent->project();

#print  $ref_all_project."\n";
my %all_projects = %$ref_all_project;

foreach my $code ( sort keys %all_projects) {
	#print $code."\n";
	my $project = $all_projects{$code};
	#print $project->url."\n";
}

my $my_project = 'ruwiki';
my $curr_project = $all_projects{$my_project};
#print $curr_project->url."\n";
$curr_project->load_metadata();

#my @page_list = ('Eduard Imhof', 'Kjelfossen2','Kjelfossen','R&B','Extensible_3D','Kühnheit');
my @page_list = ('Вильена (микрорегион)');
my $ref_pages = $curr_project->load_pages_api( @page_list);
my %pages = %$ref_pages;
print 'All'."\n";
print %pages;
print "\n";

my $test = $page_list[0];
print $pages{$test}."\n";
#my $ref_page = $pages{'R&B'};
#my $curr_page = $$ref_page;

my $curr_page = ${$pages{$test}}; 

printf "%-20s %-20s \n", 'project',   $curr_page->project ;
printf "%-20s %-20s \n", 'Namespace', $curr_page->namespace ;
printf "%-20s %-20s \n", 'pageid',    $curr_page->pageid;
printf "%-20s %-20s \n", 'title',     $curr_page->title;
printf "%-20s %-20s \n", 'timestamp', $curr_page->timestamp;
printf "%-20s %-20s \n", 'row_text',  $curr_page->row_text;

print '################################'."\n";
print $curr_page->row_page;

#print %curr_page;










