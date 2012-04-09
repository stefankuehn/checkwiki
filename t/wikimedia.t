#!/usr/bin/perl -w

# Test von Modulen, hier Modul Arithmetic.pm
# Quelle http://www.slideshare.net/Skud/test-driven-development-tutorial
# t/arithmetic.t
# Folie 78+79
# Siehe auch http://search.cpan.org/~mschwern/Test-Simple-0.98/lib/Test/More.pm
# Aufruf mit prove -v wikimedia.t


use Test::More;
use lib '/home/sk/daten/programmierung/perl/project/git/checkwiki';
use wikimedia;

use_ok ("wikimedia");
require_ok( 'wikimedia' );

can_ok ("wikimedia", "new");
##accessor method
can_ok ("wikimedia", "sitematrix");
can_ok ("wikimedia", "languages");
can_ok ("wikimedia", "languages_name");
can_ok ("wikimedia", "languages_name_en");
can_ok ("wikimedia", "project");

##############################
# methods
##############################

# sitematrix
can_ok ("wikimedia", "load_sitematrix_from_api");
can_ok ("wikimedia", "load_sitematrix_from_old_file");
my $wm_agent = eval { new wikimedia(); }  or die ($@);	# create new object
$wm_agent -> load_sitematrix_from_api();				# load sitmatrix from API
ok(defined($wm_agent -> load_sitematrix_from_api()), 'Load via API ok');


# get_all_languages
can_ok ("wikimedia", "get_all_languages");
ok(defined($wm_agent -> get_all_languages), 'get all languages produced .. something' );
my @all_languages = $wm_agent -> get_all_languages;
my $counter_l = @all_languages;
ok( $counter_l > 280, "many languages");


# get_language_name
can_ok ("wikimedia", "get_language_name");
can_ok ("wikimedia", "get_language_name_en");
is($wm_agent -> get_language_name('de'), 'Deutsch', "local name of language");
is($wm_agent -> get_language_name_en('de'), 'German', "english name of language");
is($wm_agent -> get_language_name_en('fr'), 'French', "french name of language");


# is_language_code_ok
can_ok ("wikimedia", "is_language_code_ok");
is($wm_agent -> is_language_code_ok('fr'), 1, "correct languagecode");
is($wm_agent -> is_language_code_ok('def'), 0, "incorrect languagecode");


# is_project_code_ok
can_ok ("wikimedia", "is_project_code_ok");
is($wm_agent -> is_project_code_ok('dewiki'), 1, "correct projectcode dewiki");
is($wm_agent -> is_project_code_ok('dewikibooks'), 1, "correct projectcode dewikibooks");
is($wm_agent -> is_project_code_ok('dewikixyz'), 0, "incorrect projectcode dewikixyz");


# get_all_projects
can_ok ("wikimedia", "get_all_projects");
my @projects =  $wm_agent->get_all_projects('de');
my $counter_p = @projects;
ok( $counter_p > 4, "many languages");




# examples
# ok(is_numeric(1.23), "1.23 is numeric");
# ok( 1 + 1 == 2, "One and one is two!" );
# ok( "Steve" =~ /steve/i, "Steve matches steve" );
# ok( defined( `hostname` ), "Hostname produced .. something" );


done_testing();
