#!/usr/bin/perl -w

# Test von Modulen, hier Modul Arithmetic.pm
# Quelle http://www.slideshare.net/Skud/test-driven-development-tutorial
# t/arithmetic.t
# Folie 78+79
# Siehe auch http://search.cpan.org/~mschwern/Test-Simple-0.98/lib/Test/More.pm
# Aufruf mit prove -v wikimedia.t


use Test::More;
use lib '/home/sk/daten/programmierung/perl/project/wp';
use wikimedia;

use_ok ("wikimedia");
require_ok( 'wikimedia' );

can_ok ("wikimedia", "get_all_languages");
can_ok ("wikimedia", "get_all_project_for_language");
can_ok ("wikimedia", "get_language_name");
can_ok ("wikimedia", "get_language_name_en");

my $wm_agent = wikimedia::new();
$wm_agent -> wikimedia::load_sitematrix_from_api();


#ok(is_numeric(1.23), "1.23 is numeric");
is($wm_agent -> wikimedia::get_language_name('de'), 'Deutsch', "local name of language");
is($wm_agent -> wikimedia::get_language_name_en('de'), 'German', "english name of language");
is($wm_agent -> wikimedia::get_language_name_en('fr'), 'French', "french name of language");
#ok( int( ${$wm_agent -> wikimedia::get_all_languages()}) > 200, "many languages");


ok( 1 + 1 == 2, "One and one is two!" );
ok( "Steve" =~ /steve/i, "Steve matches steve" );
ok( defined( `hostname` ), "Hostname produced .. something" );


done_testing();