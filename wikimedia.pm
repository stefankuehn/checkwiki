
package wikimedia;


use strict;

use wiki;
use LWP;
use Data::Dumper;


=head1 NAME

WWW::wikimedia_wikiproject - Interface to find Wikimedia Wikiprojects (Wikipedia, Commons, Wikibooks).

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';







################################################################
# constructor
################################################################

sub new
{

    my ($class) = @_;
    my $self = {
		_sitematrix	      	=> undef,	# all_data_from_api
		_languages      	=> undef,	# array (de,fr,fi,ar,...)
		_languages_name 	=> undef,	# hash de--> Deutsch, fr-->
		_languages_name_en 	=> undef,	# hash de--> German, fr--> French
		_project 			=> undef 	# hash de--> German, fr--> French
	};
    bless $self, $class;
    return $self;
}




#accessor method for _sitematrix
sub sitematrix {
    my ( $self, $sitematrix ) = @_;									#object + neuer Wert
    $self->{_sitematrix} = $sitematrix if defined($sitematrix);		#zuweisung falls neuer wert
    return ( $self->{_sitematrix} );								#rückgabe des werts	
}

#accessor method for _languages
sub languages {
    my ( $self, $languages ) = @_;
	
#	if ( defined($languages) ) {
#		print 'Accessor languages'."\n";		
#		print substr(Dumper($languages), 1, 100);
#		print "\n";
#	};
    $self->{_languages} = $languages if defined($languages);
    return ( $self->{_languages} );
}

#accessor method for _languages_name
sub languages_name {
    my ( $self, $languages_name ) = @_;
    $self->{_languages_name} = $languages_name if defined($languages_name);
    return ( $self->{_languages_name} );
}

#accessor method for _languages_name_en
sub languages_name_en {
    my ( $self, $languages_name_en ) = @_;
    $self->{_languages_name_en} = $languages_name_en if defined($languages_name_en);
    return ( $self->{_languages_name_en} );
}

#accessor method for _project
sub project {
    my ( $self, $project ) = @_;
    $self->{_project} = $project if defined($project);
    return ( $self->{_project} );
}

################################################################
# Methods
################################################################

sub load_sitematrix_from_api {
	my ($self) = @_;

	#print 'Load data from API'."\n";	

	# Load data from API
	# http://de.wikipedia.org/w/api.php?action=sitematrix
	# http://en.wikipedia.org/w/api.php?action=query&meta=siteinfo

	my @failover_url = ( 'en', 'de', 'fr', 'ru', 'ja');
#'ftp://gibt-es-nicht.example.com/',
#	'http://en.wikipedia.org/w/api.php?action=sitematrix&format=xml',
#	'http://de.wikipedia.org/w/api.php?action=sitematrix&format=xml',
#	'http://fr.wikipedia.org/w/api.php?action=sitematrix&format=xml';

	my $url = 'http://de.wikipedia.org/w/api.php?action=sitematrix&format=xml';
	$url = 'ftp://gibt-es-nicht.example.com/';

	my $ua = LWP::UserAgent->new;			# http://search.cpan.org/~gaas/libwww-perl-6.03/lib/LWP/UserAgent.pm
	$ua->timeout(10);						# timeout for request
	my $response = '';

	
	$response = $ua->get( $url );	
	my $result  = '';
	if ($response -> is_success) {			# maybe no internet
		my $content = $response->content;	# http://search.cpan.org/~gaas/HTTP-Message-6.02/lib/HTTP/Response.pm
	
		$result = $content if ($content) ;
		# find 
		#print %$response."\n";
		#print $result."\n";
		print 'Load data sucessfull'."\n";
#		sitematrix ($self, $result);

	}
	 else {
		
		 # die $response->status_line;
		warn( 'Problem with API-Connection, maybe no internet');
		
		# "\t".$response->status_line."\n".
		# 'Load sitematrix from old file');		

		$self->sitematrix( load_sitematrix_from_old_file() ); # unless defined $self->{_sitematrix};	# old data from en...API
	 }


    if ( $self->sitematrix ) {
		print 'analyze sitematrix'."\n";
        
        # get all languages
        my $text = $self->sitematrix;
        my @all_languages;
        my %all_language_name;
        my %all_language_name_en;
		my %all_projects;
        while ( $text =~ m/((<language .*?<\/language>))/g) {     # get   <language ... >
          my $language_xml = $&;
          my $language_code = $language_xml;
          #print $language_xml."\n";
          
          #####################
          # get code
          $language_code =~ s/(.*?) code="(.*?)".*/$2/;      # get   code="de"
          #print 'Code: '.$language_code ."\n";
          push (@all_languages, $language_code);

          #####################
          # get localname 
          # <language code="av" name="Авар" localname="Avaric">
          my $localname = '';
          if ( $language_xml =~ m/(.*?) localname="(.*?)"/) {
              $localname = $2;
          }
          #printf "%-15s %-15s\n", $code , $localname;
          %all_language_name_en = (%all_language_name_en, ( $language_code, $localname));       

          #####################
          # get name 
          # <language code="av" name="Авар" localname="Avaric">
          my $name = '';
          if ( $language_xml =~ m/(.*?) name="(.*?)"/) {
              $name = $2;
          }
          %all_language_name = (%all_language_name, ( $language_code, $name));       
  
          #####################
          # get projects
          #<language code="nds" name="Plattdüütsch" localname="Low German">
          #  <site>
          #    <site url="http://nds.wikipedia.org" dbname="ndswiki" code="wiki" />
          #    <site url="http://nds.wiktionary.org" dbname="ndswiktionary" code="wiktionary" />
          #    <site url="http://nds.wikibooks.org" dbname="ndswikibooks" code="wikibooks" closed="" />
          #    <site url="http://nds.wikiquote.org" dbname="ndswikiquote" code="wikiquote" closed="" />
          #  </site>
          #</language>  
          my $string = $language_xml;

          while ($string =~ m/(<site .*? \/>)/g) {
              #found site
              my $site = $&;
              #print $site."\n";
              
              # get url
              my $url = '';
              $url = $2 if ( $site =~ m/(.*?) url="(.*?)"/);
              #print 'URL: '.$url."\n";
              
              # get dbname
              my $dbname = '';
              $dbname = $2 if ( $site =~ m/(.*?) dbname="(.*?)"/);
              #print 'DBname: '.$dbname."\n";
              
              # get sitecode
              my $sitecode = '';
              $sitecode = $2 if ( $site =~ m/(.*?) code="(.*?)"/);
              #print 'sitecode: '.$sitecode."\n";

              # get close
              my $close = 0;
              $close = 1 if ( $site =~ m/ closed=""/);
              #print 'close: '.$close."\n";             

              my $private = 0;
              $private = 1 if ( $site =~ m/ private=""/);
              #print 'private: '.$private."\n";  
              
			  my $project_hash_ref = new wiki( );
			  $project_hash_ref->project($dbname);
			  $project_hash_ref->language($language_code);
			  $project_hash_ref->url($url);
			  $project_hash_ref->name($localname);
			  $project_hash_ref->name_en($name);
			  $project_hash_ref->site_code($sitecode);
			  $project_hash_ref->site_close($close);
			  $project_hash_ref->private($private);
			  $project_hash_ref->api($project_hash_ref->url.'/w/api.php');	# create api with url

			  %all_projects = (%all_projects, ( $dbname, $project_hash_ref));       
				
			  if ($dbname eq 'aawikibooks') {
#				print 'DBname:'.$dbname."\n";
#				print 'Project:'.$project_hash_ref."\n";
#				my %kurz_neu = %$project_hash_ref;
#				print 'URL:'.$kurz_neu{'url'}."\n";
#				print Dumper(\$project_hash_ref);
			  }
			
          }
          #print "\n";

          
          
          
        }

        languages ($self, \@all_languages);
        languages_name ($self, \%all_language_name);
        languages_name_en ($self, \%all_language_name_en);
        project ($self, \%all_projects);
      	#print Dumper(\%all_projects);
    }

	

	return $self;
}









################################################################

sub get_all_languages {         # de,ar,fi,fr,got,...
	# get all languages_codes as array    
	my ($self) = @_;
	my @result = @{$self->languages};
    
	#my $ref_array = $self->languages;
	#my @result = @{$ref_array};
	#foreach my $key (@result) {
	#     printf "Key: %-10s ", $key;
	#}
	return @result;
}

################################################################

sub is_language_code_ok {         # de --> 1		# fxys -->0
    my ($self, $language) = @_;
	if (defined ($language)) {
	
		my @all = $self->get_all_languages;
		#print $language ."\n";
		#print join (', ', @all)."\n";
		foreach my $key (@all) {
			#print $key.' '.$language."\n";		
			return 1 if ($key eq $language );
		}
		return 0;
	}
	return undef;
}


################################################################

sub get_language_name {      # de --> Deutsch
    my ($self, $code) = @_;
	if (defined ($code)) {
		my $languageref = $self->{_languages_name};
		my %language = %{$languageref};
		return $language{$code};
	}
    return undef;
}


################################################################

sub get_language_name_en {      # de --> German
    my ($self, $code) = @_;
    if (defined ($code)) {
		#print 'Self: '.$self."\n";
		#print 'Code: '.$code."\n";
		my $languageref = $self->{_languages_name_en};
		my %language = %{$languageref};
		return $language{$code};
	}
    return undef;
}


################################################################

sub get_all_projects { # all,  de --> dewiki, dewiktionary, dewikibooks, dewikinews, dewikiquote, ...
    my ($self, $language_code) = @_;
	my @result;
	
	if ($self->is_language_code_ok ($language_code) or not defined ($language_code) ) {
		#printf "%-20s %-20s\n", 'Language code:', $language_code;

		my $all_projectsref = $self->project;				# gibt Ref auf Hash mit Wiki-Projekten zurück
		#printf "%-20s %-20s\n", 'Projectref:', $all_projectsref;

		my %all_projects = %{$all_projectsref};					# hash mit Ref holen
		#printf "%-20s %-20s\n", 'Hash mit Ref:', %all_projects."\n";  

		my @keys_all_projects = keys %all_projects;
		#print join( ', ', @keys)."\n";					# alle Keys des Hash (dewiki, dewikibooks, ...)



		foreach my $current_projectcode (sort @keys_all_projects) {
			 #printf "%-20s %-20s\n", 'Projectcode', $current_projectcode;

			 my $curr_project_hash_ref = $all_projects{$current_projectcode}; #ref auf hash von jedem einzelnen Projekt holen
#			 printf "%-20s %-20s\n", 'Projecthash', $curr_project_hash_ref."\n";
			 
			 my %current_project = %$curr_project_hash_ref;

			 #foreach my $key (sort keys %current_project) {
			 #	 printf "Key: %-10s Wert: %-10s\n", $key, $current_project{$key};
			 #}

			 if ( defined ($language_code) ) {
				if ( $current_project{_language} eq $language_code) {
					# all projects of one language
					push (@result , $current_project{_project} );
					#print 'Found de'.$current_project{_project}."\n";
				}
			 } else {
				push (@result , $current_project{_project} );
				#print 'Found all'.$current_project{_project}."\n";
			 }
		}		
	}

    return @result;
}


################################################################

sub is_project_code_ok {      # dewiki --> 1, deiswiki-->0
    my ($self, $project_code) = @_;
	if (defined ($project_code)) {
	
		my @all = $self->get_all_projects;
		foreach my $current_code (@all) {
			#print $current_code.' '.$project_code."\n";		
			return 1 if ($project_code eq $current_code );
		}
		return 0;
	}
	return undef;
	
}
################################################################

sub load_sitematrix_from_old_file
{
    local($_);
    my @data = <DATA>;
    close(DATA);
	chomp(@data);                       # delete alle newlines
	my $data = join ('', @data);        # all lines in one line
	$data =~ s/[ ]+</</g;
	return ($data);
}


1;



################################################################
# old data from 2011-01-24
# source: http://en.wikipedia.org/w/api.php?action=sitematrix

__DATA__
<?xml version="1.0"?>
<api>
  <sitematrix count="846">
    <specials>
      <special url="http://advisory.wikimedia.org" dbname="advisorywiki" code="advisory" closed="" />
      <special url="http://ar.wikimedia.org" dbname="arwikimedia" code="arwikimedia" />
      <special url="http://arbcom.de.wikipedia.org" dbname="arbcom_dewiki" code="arbcom-de" private="" />
      <special url="http://arbcom.en.wikipedia.org" dbname="arbcom_enwiki" code="arbcom-en" private="" />
      <special url="http://arbcom.fi.wikipedia.org" dbname="arbcom_fiwiki" code="arbcom-fi" private="" />
      <special url="http://arbcom.nl.wikipedia.org" dbname="arbcom_nlwiki" code="arbcom-nl" private="" />
      <special url="http://auditcom.wikimedia.org" dbname="auditcomwiki" code="auditcom" private="" />
      <special url="http://bd.wikimedia.org" dbname="bdwikimedia" code="bdwikimedia" />
      <special url="http://beta.wikiversity.org" dbname="betawikiversity" code="betawikiversity" />
      <special url="http://board.wikimedia.org" dbname="boardwiki" code="board" private="" />
      <special url="http://boardgovcom.wikimedia.org" dbname="boardgovcomwiki" code="boardgovcom" private="" />
      <special url="http://br.wikimedia.org" dbname="brwikimedia" code="brwikimedia" />
      <special url="http://www.wikimedia.ch/" dbname="chwikimedia" code="chwikimedia" />
      <special url="http://chair.wikimedia.org" dbname="chairwiki" code="chair" private="" />
      <special url="http://chapcom.wikimedia.org" dbname="chapcomwiki" code="chapcom" private="" />
      <special url="http://checkuser.wikimedia.org" dbname="checkuserwiki" code="checkuser" private="" />
      <special url="http://co.wikimedia.org" dbname="cowikimedia" code="cowikimedia" />
      <special url="http://collab.wikimedia.org" dbname="collabwiki" code="collab" private="" />
      <special url="http://commons.wikimedia.org" dbname="commonswiki" code="commons" />
      <special url="http://de.labs.wikimedia.org" dbname="de_labswikimedia" code="de-labswikimedia" closed="" />
      <special url="http://dk.wikimedia.org" dbname="dkwikimedia" code="dkwikimedia" />
      <special url="http://donate.wikimedia.org" dbname="donatewiki" code="donate" fishbowl="" />
      <special url="http://en.labs.wikimedia.org" dbname="en_labswikimedia" code="en-labswikimedia" closed="" />
      <special url="http://et.wikimedia.org" dbname="etwikimedia" code="etwikimedia" />
      <special url="http://exec.wikimedia.org" dbname="execwiki" code="exec" private="" />
      <special url="http://fi.wikimedia.org" dbname="fiwikimedia" code="fiwikimedia" />
      <special url="http://flaggedrevs.labs.wikimedia.org" dbname="flaggedrevs_labswikimedia" code="flaggedrevs-labswikimedia" closed="" />
      <special url="http://wikimediafoundation.org" dbname="foundationwiki" code="foundation" fishbowl="" />
      <special url="http://grants.wikimedia.org" dbname="grantswiki" code="grants" private="" />
      <special url="http://il.wikimedia.org" dbname="ilwikimedia" code="ilwikimedia" private="" />
      <special url="http://incubator.wikimedia.org" dbname="incubatorwiki" code="incubator" />
      <special url="http://internal.wikimedia.org" dbname="internalwiki" code="internal" private="" />
      <special url="http://www.mediawiki.org" dbname="mediawikiwiki" code="mediawiki" />
      <special url="http://meta.wikimedia.org" dbname="metawiki" code="meta" />
      <special url="http://mk.wikimedia.org" dbname="mkwikimedia" code="mkwikimedia" />
      <special url="http://movementroles.wikimedia.org" dbname="movementroleswiki" code="movementroles" private="" />
      <special url="http://mx.wikimedia.org" dbname="mxwikimedia" code="mxwikimedia" />
      <special url="http://nl.wikimedia.org" dbname="nlwikimedia" code="nlwikimedia" />
      <special url="http://no.wikimedia.org" dbname="nowikimedia" code="nowikimedia" />
      <special url="http://noboard.chapters.wikimedia.org" dbname="noboard_chapterswikimedia" code="noboard-chapterswikimedia" private="" />
      <special url="http://nostalgia.wikipedia.org" dbname="nostalgiawiki" code="nostalgia" fishbowl="" />
      <special url="http://nyc.wikimedia.org" dbname="nycwikimedia" code="nycwikimedia" />
      <special url="http://nz.wikimedia.org" dbname="nzwikimedia" code="nzwikimedia" />
      <special url="http://office.wikimedia.org" dbname="officewiki" code="office" private="" />
      <special url="http://otrs-wiki.wikimedia.org" dbname="otrs_wikiwiki" code="otrs-wiki" private="" />
      <special url="http://outreach.wikimedia.org" dbname="outreachwiki" code="outreach" />
      <special url="http://pa.us.wikimedia.org" dbname="pa_uswikimedia" code="pa-uswikimedia" />
      <special url="http://pl.wikimedia.org" dbname="plwikimedia" code="plwikimedia" />
      <special url="http://pt.wikimedia.org" dbname="ptwikimedia" code="ptwikimedia" />
      <special url="http://quality.wikimedia.org" dbname="qualitywiki" code="quality" closed="" />
      <special url="http://readerfeedback.labs.wikimedia.org" dbname="readerfeedback_labswikimedia" code="readerfeedback-labswikimedia" closed="" />
      <special url="http://rs.wikimedia.org" dbname="rswikimedia" code="rswikimedia" fishbowl="" />
      <special url="http://ru.wikimedia.org" dbname="ruwikimedia" code="ruwikimedia" />
      <special url="http://se.wikimedia.org" dbname="sewikimedia" code="sewikimedia" />
      <special url="http://searchcom.wikimedia.org" dbname="searchcomwiki" code="searchcom" private="" />
      <special url="http://wikisource.org" dbname="sourceswiki" code="sources" />
      <special url="http://spcom.wikimedia.org" dbname="spcomwiki" code="spcom" private="" />
      <special url="http://species.wikimedia.org" dbname="specieswiki" code="species" />
      <special url="http://steward.wikimedia.org" dbname="stewardwiki" code="steward" private="" />
      <special url="http://strategy.wikimedia.org" dbname="strategywiki" code="strategy" />
      <special url="http://ten.wikipedia.org" dbname="tenwiki" code="ten" closed="" />
      <special url="http://test.wikipedia.org" dbname="testwiki" code="test" />
      <special url="http://test2.wikipedia.org" dbname="test2wiki" code="test2" />
      <special url="http://tr.wikimedia.org" dbname="trwikimedia" code="trwikimedia" />
      <special url="http://ua.wikimedia.org" dbname="uawikimedia" code="uawikimedia" />
      <special url="http://uk.wikimedia.org" dbname="ukwikimedia" code="ukwikimedia" />
      <special url="http://usability.wikimedia.org" dbname="usabilitywiki" code="usability" closed="" />
      <special url="http://ve.wikimedia.org" dbname="vewikimedia" code="vewikimedia" closed="" />
      <special url="http://wg.en.wikipedia.org" dbname="wg_enwiki" code="wg-en" private="" />
      <special url="http://wikimania2005.wikimedia.org" dbname="wikimania2005wiki" code="wikimania2005" closed="" />
      <special url="http://wikimania2006.wikimedia.org" dbname="wikimania2006wiki" code="wikimania2006" fishbowl="" closed="" />
      <special url="http://wikimania2007.wikimedia.org" dbname="wikimania2007wiki" code="wikimania2007" fishbowl="" closed="" />
      <special url="http://wikimania2008.wikimedia.org" dbname="wikimania2008wiki" code="wikimania2008" closed="" />
      <special url="http://wikimania2009.wikimedia.org" dbname="wikimania2009wiki" code="wikimania2009" closed="" />
      <special url="http://wikimania2010.wikimedia.org" dbname="wikimania2010wiki" code="wikimania2010" closed="" />
      <special url="http://wikimania2011.wikimedia.org" dbname="wikimania2011wiki" code="wikimania2011" />
      <special url="http://wikimania2012.wikimedia.org" dbname="wikimania2012wiki" code="wikimania2012" />
      <special url="http://wikimaniateam.wikimedia.org" dbname="wikimaniateamwiki" code="wikimaniateam" private="" />
    </specials>
    <language code="aa" name="Qafár af" localname="Afar">
      <site>
        <site url="http://aa.wiktionary.org" dbname="aawiktionary" code="wiktionary" closed="" />
        <site url="http://aa.wikibooks.org" dbname="aawikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="ab" name="Аҧсуа" localname="Abkhazian">
      <site>
        <site url="http://ab.wikipedia.org" dbname="abwiki" code="wiki" />
        <site url="http://ab.wiktionary.org" dbname="abwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="ace" name="Acèh" localname="Achinese">
      <site>
        <site url="http://ace.wikipedia.org" dbname="acewiki" code="wiki" />
      </site>
    </language>
    <language code="af" name="Afrikaans" localname="Afrikaans">
      <site>
        <site url="http://af.wikipedia.org" dbname="afwiki" code="wiki" />
        <site url="http://af.wiktionary.org" dbname="afwiktionary" code="wiktionary" />
        <site url="http://af.wikibooks.org" dbname="afwikibooks" code="wikibooks" />
        <site url="http://af.wikiquote.org" dbname="afwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="ak" name="Akan" localname="Akan">
      <site>
        <site url="http://ak.wikipedia.org" dbname="akwiki" code="wiki" />
        <site url="http://ak.wiktionary.org" dbname="akwiktionary" code="wiktionary" closed="" />
        <site url="http://ak.wikibooks.org" dbname="akwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="als" name="Alemannisch" localname="Alemannisch">
      <site>
        <site url="http://als.wikipedia.org" dbname="alswiki" code="wiki" />
        <site url="http://als.wiktionary.org" dbname="alswiktionary" code="wiktionary" closed="" />
        <site url="http://als.wikibooks.org" dbname="alswikibooks" code="wikibooks" closed="" />
        <site url="http://als.wikiquote.org" dbname="alswikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="am" name="አማርኛ" localname="Amharic">
      <site>
        <site url="http://am.wikipedia.org" dbname="amwiki" code="wiki" />
        <site url="http://am.wiktionary.org" dbname="amwiktionary" code="wiktionary" />
        <site url="http://am.wikiquote.org" dbname="amwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="an" name="Aragonés" localname="Aragonese">
      <site>
        <site url="http://an.wikipedia.org" dbname="anwiki" code="wiki" />
        <site url="http://an.wiktionary.org" dbname="anwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="ang" name="Ænglisc" localname="Old English">
      <site>
        <site url="http://ang.wikipedia.org" dbname="angwiki" code="wiki" />
        <site url="http://ang.wiktionary.org" dbname="angwiktionary" code="wiktionary" />
        <site url="http://ang.wikibooks.org" dbname="angwikibooks" code="wikibooks" />
        <site url="http://ang.wikiquote.org" dbname="angwikiquote" code="wikiquote" closed="" />
        <site url="http://ang.wikisource.org" dbname="angwikisource" code="wikisource" closed="" />
      </site>
    </language>
    <language code="ar" name="العربية" localname="Arabic">
      <site>
        <site url="http://ar.wikipedia.org" dbname="arwiki" code="wiki" />
        <site url="http://ar.wiktionary.org" dbname="arwiktionary" code="wiktionary" />
        <site url="http://ar.wikibooks.org" dbname="arwikibooks" code="wikibooks" />
        <site url="http://ar.wikinews.org" dbname="arwikinews" code="wikinews" />
        <site url="http://ar.wikiquote.org" dbname="arwikiquote" code="wikiquote" />
        <site url="http://ar.wikisource.org" dbname="arwikisource" code="wikisource" />
        <site url="http://ar.wikiversity.org" dbname="arwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="arc" name="ܐܪܡܝܐ" localname="Aramaic">
      <site>
        <site url="http://arc.wikipedia.org" dbname="arcwiki" code="wiki" />
      </site>
    </language>
    <language code="arz" name="مصرى" localname="Egyptian Spoken Arabic">
      <site>
        <site url="http://arz.wikipedia.org" dbname="arzwiki" code="wiki" />
      </site>
    </language>
    <language code="as" name="অসমীয়া" localname="Assamese">
      <site>
        <site url="http://as.wikipedia.org" dbname="aswiki" code="wiki" />
        <site url="http://as.wiktionary.org" dbname="aswiktionary" code="wiktionary" closed="" />
        <site url="http://as.wikibooks.org" dbname="aswikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="ast" name="Asturianu" localname="Asturian">
      <site>
        <site url="http://ast.wikipedia.org" dbname="astwiki" code="wiki" />
        <site url="http://ast.wiktionary.org" dbname="astwiktionary" code="wiktionary" />
        <site url="http://ast.wikibooks.org" dbname="astwikibooks" code="wikibooks" closed="" />
        <site url="http://ast.wikiquote.org" dbname="astwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="av" name="Авар" localname="Avaric">
      <site>
        <site url="http://av.wikipedia.org" dbname="avwiki" code="wiki" />
        <site url="http://av.wiktionary.org" dbname="avwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="ay" name="Aymar aru" localname="Aymara">
      <site>
        <site url="http://ay.wikipedia.org" dbname="aywiki" code="wiki" />
        <site url="http://ay.wiktionary.org" dbname="aywiktionary" code="wiktionary" />
        <site url="http://ay.wikibooks.org" dbname="aywikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="az" name="Azərbaycanca" localname="Azerbaijani">
      <site>
        <site url="http://az.wikipedia.org" dbname="azwiki" code="wiki" />
        <site url="http://az.wiktionary.org" dbname="azwiktionary" code="wiktionary" />
        <site url="http://az.wikibooks.org" dbname="azwikibooks" code="wikibooks" />
        <site url="http://az.wikiquote.org" dbname="azwikiquote" code="wikiquote" />
        <site url="http://az.wikisource.org" dbname="azwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ba" name="Башҡортса" localname="Bashkir">
      <site>
        <site url="http://ba.wikipedia.org" dbname="bawiki" code="wiki" />
        <site url="http://ba.wikibooks.org" dbname="bawikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="bar" name="Boarisch" localname="Bavarian">
      <site>
        <site url="http://bar.wikipedia.org" dbname="barwiki" code="wiki" />
      </site>
    </language>
    <language code="bat-smg" name="Žemaitėška" localname="Samogitian">
      <site>
        <site url="http://bat-smg.wikipedia.org" dbname="bat-smgwiki" code="wiki" />
      </site>
    </language>
    <language code="bcl" name="Bikol Central" localname="Bikol Central">
      <site>
        <site url="http://bcl.wikipedia.org" dbname="bclwiki" code="wiki" />
      </site>
    </language>
    <language code="be" name="Беларуская" localname="Belarusian">
      <site>
        <site url="http://be.wikipedia.org" dbname="bewiki" code="wiki" />
        <site url="http://be.wiktionary.org" dbname="bewiktionary" code="wiktionary" />
        <site url="http://be.wikibooks.org" dbname="bewikibooks" code="wikibooks" />
        <site url="http://be.wikiquote.org" dbname="bewikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="be-x-old" name="‪Беларуская (тарашкевіца)‬" localname="‪Беларуская (тарашкевіца)‬">
      <site>
        <site url="http://be-x-old.wikipedia.org" dbname="be-x-oldwiki" code="wiki" />
      </site>
    </language>
    <language code="bg" name="Български" localname="Bulgarian">
      <site>
        <site url="http://bg.wikipedia.org" dbname="bgwiki" code="wiki" />
        <site url="http://bg.wiktionary.org" dbname="bgwiktionary" code="wiktionary" />
        <site url="http://bg.wikibooks.org" dbname="bgwikibooks" code="wikibooks" />
        <site url="http://bg.wikinews.org" dbname="bgwikinews" code="wikinews" />
        <site url="http://bg.wikiquote.org" dbname="bgwikiquote" code="wikiquote" />
        <site url="http://bg.wikisource.org" dbname="bgwikisource" code="wikisource" />
      </site>
    </language>
    <language code="bh" name="भोजपुरी" localname="Bihari">
      <site>
        <site url="http://bh.wikipedia.org" dbname="bhwiki" code="wiki" />
        <site url="http://bh.wiktionary.org" dbname="bhwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="bi" name="Bislama" localname="Bislama">
      <site>
        <site url="http://bi.wikipedia.org" dbname="biwiki" code="wiki" />
        <site url="http://bi.wiktionary.org" dbname="biwiktionary" code="wiktionary" closed="" />
        <site url="http://bi.wikibooks.org" dbname="biwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="bjn" name="Bahasa Banjar" localname="Bahasa Banjar">
      <site>
        <site url="http://bjn.wikipedia.org" dbname="bjnwiki" code="wiki" />
      </site>
    </language>
    <language code="bm" name="Bamanankan" localname="Bambara">
      <site>
        <site url="http://bm.wikipedia.org" dbname="bmwiki" code="wiki" />
        <site url="http://bm.wiktionary.org" dbname="bmwiktionary" code="wiktionary" closed="" />
        <site url="http://bm.wikibooks.org" dbname="bmwikibooks" code="wikibooks" closed="" />
        <site url="http://bm.wikiquote.org" dbname="bmwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="bn" name="বাংলা" localname="Bengali">
      <site>
        <site url="http://bn.wikipedia.org" dbname="bnwiki" code="wiki" />
        <site url="http://bn.wiktionary.org" dbname="bnwiktionary" code="wiktionary" />
        <site url="http://bn.wikibooks.org" dbname="bnwikibooks" code="wikibooks" />
        <site url="http://bn.wikisource.org" dbname="bnwikisource" code="wikisource" />
      </site>
    </language>
    <language code="bo" name="བོད་ཡིག" localname="Tibetan">
      <site>
        <site url="http://bo.wikipedia.org" dbname="bowiki" code="wiki" />
        <site url="http://bo.wiktionary.org" dbname="bowiktionary" code="wiktionary" closed="" />
        <site url="http://bo.wikibooks.org" dbname="bowikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="bpy" name="ইমার ঠার/বিষ্ণুপ্রিয়া মণিপুরী" localname="Bishnupria Manipuri">
      <site>
        <site url="http://bpy.wikipedia.org" dbname="bpywiki" code="wiki" />
      </site>
    </language>
    <language code="br" name="Brezhoneg" localname="Breton">
      <site>
        <site url="http://br.wikipedia.org" dbname="brwiki" code="wiki" />
        <site url="http://br.wiktionary.org" dbname="brwiktionary" code="wiktionary" />
        <site url="http://br.wikiquote.org" dbname="brwikiquote" code="wikiquote" />
        <site url="http://br.wikisource.org" dbname="brwikisource" code="wikisource" />
      </site>
    </language>
    <language code="bs" name="Bosanski" localname="Bosnian">
      <site>
        <site url="http://bs.wikipedia.org" dbname="bswiki" code="wiki" />
        <site url="http://bs.wiktionary.org" dbname="bswiktionary" code="wiktionary" />
        <site url="http://bs.wikibooks.org" dbname="bswikibooks" code="wikibooks" />
        <site url="http://bs.wikinews.org" dbname="bswikinews" code="wikinews" />
        <site url="http://bs.wikiquote.org" dbname="bswikiquote" code="wikiquote" />
        <site url="http://bs.wikisource.org" dbname="bswikisource" code="wikisource" />
      </site>
    </language>
    <language code="bug" name="ᨅᨔ ᨕᨘᨁᨗ" localname="Buginese">
      <site>
        <site url="http://bug.wikipedia.org" dbname="bugwiki" code="wiki" />
      </site>
    </language>
    <language code="bxr" name="Буряад" localname="Буряад">
      <site>
        <site url="http://bxr.wikipedia.org" dbname="bxrwiki" code="wiki" />
      </site>
    </language>
    <language code="ca" name="Català" localname="Catalan">
      <site>
        <site url="http://ca.wikipedia.org" dbname="cawiki" code="wiki" />
        <site url="http://ca.wiktionary.org" dbname="cawiktionary" code="wiktionary" />
        <site url="http://ca.wikibooks.org" dbname="cawikibooks" code="wikibooks" />
        <site url="http://ca.wikinews.org" dbname="cawikinews" code="wikinews" />
        <site url="http://ca.wikiquote.org" dbname="cawikiquote" code="wikiquote" />
        <site url="http://ca.wikisource.org" dbname="cawikisource" code="wikisource" />
      </site>
    </language>
    <language code="cbk-zam" name="Chavacano de Zamboanga" localname="Chavacano de Zamboanga">
      <site>
        <site url="http://cbk-zam.wikipedia.org" dbname="cbk-zamwiki" code="wiki" />
      </site>
    </language>
    <language code="cdo" name="Mìng-dĕ̤ng-ngṳ̄" localname="Min Dong Chinese">
      <site>
        <site url="http://cdo.wikipedia.org" dbname="cdowiki" code="wiki" />
      </site>
    </language>
    <language code="ce" name="Нохчийн" localname="Chechen">
      <site>
        <site url="http://ce.wikipedia.org" dbname="cewiki" code="wiki" />
      </site>
    </language>
    <language code="ceb" name="Cebuano" localname="Cebuano">
      <site>
        <site url="http://ceb.wikipedia.org" dbname="cebwiki" code="wiki" />
      </site>
    </language>
    <language code="ch" name="Chamoru" localname="Chamorro">
      <site>
        <site url="http://ch.wikipedia.org" dbname="chwiki" code="wiki" />
        <site url="http://ch.wiktionary.org" dbname="chwiktionary" code="wiktionary" closed="" />
        <site url="http://ch.wikibooks.org" dbname="chwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="cho" name="Choctaw" localname="Choctaw">
      <site>
        <site url="http://cho.wikipedia.org" dbname="chowiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="chr" name="ᏣᎳᎩ" localname="Cherokee">
      <site>
        <site url="http://chr.wikipedia.org" dbname="chrwiki" code="wiki" />
        <site url="http://chr.wiktionary.org" dbname="chrwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="chy" name="Tsetsêhestâhese" localname="Cheyenne">
      <site>
        <site url="http://chy.wikipedia.org" dbname="chywiki" code="wiki" />
      </site>
    </language>
    <language code="ckb" name="کوردی" localname="Sorani">
      <site>
        <site url="http://ckb.wikipedia.org" dbname="ckbwiki" code="wiki" />
      </site>
    </language>
    <language code="co" name="Corsu" localname="Corsican">
      <site>
        <site url="http://co.wikipedia.org" dbname="cowiki" code="wiki" />
        <site url="http://co.wiktionary.org" dbname="cowiktionary" code="wiktionary" />
        <site url="http://co.wikibooks.org" dbname="cowikibooks" code="wikibooks" closed="" />
        <site url="http://co.wikiquote.org" dbname="cowikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="cr" name="Nēhiyawēwin / ᓀᐦᐃᔭᐍᐏᐣ" localname="Cree">
      <site>
        <site url="http://cr.wikipedia.org" dbname="crwiki" code="wiki" />
        <site url="http://cr.wiktionary.org" dbname="crwiktionary" code="wiktionary" closed="" />
        <site url="http://cr.wikiquote.org" dbname="crwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="crh" name="Qırımtatarca" localname="Crimean Turkish">
      <site>
        <site url="http://crh.wikipedia.org" dbname="crhwiki" code="wiki" />
      </site>
    </language>
    <language code="cs" name="Česky" localname="Czech">
      <site>
        <site url="http://cs.wikipedia.org" dbname="cswiki" code="wiki" />
        <site url="http://cs.wiktionary.org" dbname="cswiktionary" code="wiktionary" />
        <site url="http://cs.wikibooks.org" dbname="cswikibooks" code="wikibooks" />
        <site url="http://cs.wikinews.org" dbname="cswikinews" code="wikinews" />
        <site url="http://cs.wikiquote.org" dbname="cswikiquote" code="wikiquote" />
        <site url="http://cs.wikisource.org" dbname="cswikisource" code="wikisource" />
        <site url="http://cs.wikiversity.org" dbname="cswikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="csb" name="Kaszëbsczi" localname="Kashubian">
      <site>
        <site url="http://csb.wikipedia.org" dbname="csbwiki" code="wiki" />
        <site url="http://csb.wiktionary.org" dbname="csbwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="cu" name="Словѣ́ньскъ / ⰔⰎⰑⰂⰡⰐⰠⰔⰍⰟ" localname="Church Slavic">
      <site>
        <site url="http://cu.wikipedia.org" dbname="cuwiki" code="wiki" />
      </site>
    </language>
    <language code="cv" name="Чӑвашла" localname="Chuvash">
      <site>
        <site url="http://cv.wikipedia.org" dbname="cvwiki" code="wiki" />
        <site url="http://cv.wikibooks.org" dbname="cvwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="cy" name="Cymraeg" localname="Welsh">
      <site>
        <site url="http://cy.wikipedia.org" dbname="cywiki" code="wiki" />
        <site url="http://cy.wiktionary.org" dbname="cywiktionary" code="wiktionary" />
        <site url="http://cy.wikibooks.org" dbname="cywikibooks" code="wikibooks" />
        <site url="http://cy.wikiquote.org" dbname="cywikiquote" code="wikiquote" />
        <site url="http://cy.wikisource.org" dbname="cywikisource" code="wikisource" />
      </site>
    </language>
    <language code="cz" name="">
      <site />
    </language>
    <language code="da" name="Dansk" localname="Danish">
      <site>
        <site url="http://da.wikipedia.org" dbname="dawiki" code="wiki" />
        <site url="http://da.wiktionary.org" dbname="dawiktionary" code="wiktionary" />
        <site url="http://da.wikibooks.org" dbname="dawikibooks" code="wikibooks" />
        <site url="http://da.wikiquote.org" dbname="dawikiquote" code="wikiquote" />
        <site url="http://da.wikisource.org" dbname="dawikisource" code="wikisource" />
      </site>
    </language>
    <language code="de" name="Deutsch" localname="German">
      <site>
        <site url="http://de.wikipedia.org" dbname="dewiki" code="wiki" />
        <site url="http://de.wiktionary.org" dbname="dewiktionary" code="wiktionary" />
        <site url="http://de.wikibooks.org" dbname="dewikibooks" code="wikibooks" />
        <site url="http://de.wikinews.org" dbname="dewikinews" code="wikinews" />
        <site url="http://de.wikiquote.org" dbname="dewikiquote" code="wikiquote" />
        <site url="http://de.wikisource.org" dbname="dewikisource" code="wikisource" />
        <site url="http://de.wikiversity.org" dbname="dewikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="diq" name="Zazaki" localname="Zazaki">
      <site>
        <site url="http://diq.wikipedia.org" dbname="diqwiki" code="wiki" />
      </site>
    </language>
    <language code="dk" name="">
      <site />
    </language>
    <language code="dsb" name="Dolnoserbski" localname="Lower Sorbian">
      <site>
        <site url="http://dsb.wikipedia.org" dbname="dsbwiki" code="wiki" />
      </site>
    </language>
    <language code="dv" name="ދިވެހިބަސް" localname="Divehi">
      <site>
        <site url="http://dv.wikipedia.org" dbname="dvwiki" code="wiki" />
        <site url="http://dv.wiktionary.org" dbname="dvwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="dz" name="ཇོང་ཁ" localname="Dzongkha">
      <site>
        <site url="http://dz.wikipedia.org" dbname="dzwiki" code="wiki" />
        <site url="http://dz.wiktionary.org" dbname="dzwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="ee" name="Eʋegbe" localname="Ewe">
      <site>
        <site url="http://ee.wikipedia.org" dbname="eewiki" code="wiki" />
      </site>
    </language>
    <language code="el" name="Ελληνικά" localname="Greek">
      <site>
        <site url="http://el.wikipedia.org" dbname="elwiki" code="wiki" />
        <site url="http://el.wiktionary.org" dbname="elwiktionary" code="wiktionary" />
        <site url="http://el.wikibooks.org" dbname="elwikibooks" code="wikibooks" />
        <site url="http://el.wikinews.org" dbname="elwikinews" code="wikinews" />
        <site url="http://el.wikiquote.org" dbname="elwikiquote" code="wikiquote" />
        <site url="http://el.wikisource.org" dbname="elwikisource" code="wikisource" />
        <site url="http://el.wikiversity.org" dbname="elwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="eml" name="Emiliàn e rumagnòl" localname="Emiliano-Romagnolo">
      <site>
        <site url="http://eml.wikipedia.org" dbname="emlwiki" code="wiki" />
      </site>
    </language>
    <language code="en" name="English" localname="English">
      <site>
        <site url="http://en.wikipedia.org" dbname="enwiki" code="wiki" />
        <site url="http://en.wiktionary.org" dbname="enwiktionary" code="wiktionary" />
        <site url="http://en.wikibooks.org" dbname="enwikibooks" code="wikibooks" />
        <site url="http://en.wikinews.org" dbname="enwikinews" code="wikinews" />
        <site url="http://en.wikiquote.org" dbname="enwikiquote" code="wikiquote" />
        <site url="http://en.wikisource.org" dbname="enwikisource" code="wikisource" />
        <site url="http://en.wikiversity.org" dbname="enwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="eo" name="Esperanto" localname="Esperanto">
      <site>
        <site url="http://eo.wikipedia.org" dbname="eowiki" code="wiki" />
        <site url="http://eo.wiktionary.org" dbname="eowiktionary" code="wiktionary" />
        <site url="http://eo.wikibooks.org" dbname="eowikibooks" code="wikibooks" />
        <site url="http://eo.wikinews.org" dbname="eowikinews" code="wikinews" />
        <site url="http://eo.wikiquote.org" dbname="eowikiquote" code="wikiquote" />
        <site url="http://eo.wikisource.org" dbname="eowikisource" code="wikisource" />
      </site>
    </language>
    <language code="epo" name="">
      <site />
    </language>
    <language code="es" name="Español" localname="Spanish">
      <site>
        <site url="http://es.wikipedia.org" dbname="eswiki" code="wiki" />
        <site url="http://es.wiktionary.org" dbname="eswiktionary" code="wiktionary" />
        <site url="http://es.wikibooks.org" dbname="eswikibooks" code="wikibooks" />
        <site url="http://es.wikinews.org" dbname="eswikinews" code="wikinews" />
        <site url="http://es.wikiquote.org" dbname="eswikiquote" code="wikiquote" />
        <site url="http://es.wikisource.org" dbname="eswikisource" code="wikisource" />
        <site url="http://es.wikiversity.org" dbname="eswikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="et" name="Eesti" localname="Estonian">
      <site>
        <site url="http://et.wikipedia.org" dbname="etwiki" code="wiki" />
        <site url="http://et.wiktionary.org" dbname="etwiktionary" code="wiktionary" />
        <site url="http://et.wikibooks.org" dbname="etwikibooks" code="wikibooks" />
        <site url="http://et.wikiquote.org" dbname="etwikiquote" code="wikiquote" />
        <site url="http://et.wikisource.org" dbname="etwikisource" code="wikisource" />
      </site>
    </language>
    <language code="eu" name="Euskara" localname="Basque">
      <site>
        <site url="http://eu.wikipedia.org" dbname="euwiki" code="wiki" />
        <site url="http://eu.wiktionary.org" dbname="euwiktionary" code="wiktionary" />
        <site url="http://eu.wikibooks.org" dbname="euwikibooks" code="wikibooks" />
        <site url="http://eu.wikiquote.org" dbname="euwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="ext" name="Estremeñu" localname="Extremaduran">
      <site>
        <site url="http://ext.wikipedia.org" dbname="extwiki" code="wiki" />
      </site>
    </language>
    <language code="fa" name="فارسی" localname="Persian">
      <site>
        <site url="http://fa.wikipedia.org" dbname="fawiki" code="wiki" />
        <site url="http://fa.wiktionary.org" dbname="fawiktionary" code="wiktionary" />
        <site url="http://fa.wikibooks.org" dbname="fawikibooks" code="wikibooks" />
        <site url="http://fa.wikinews.org" dbname="fawikinews" code="wikinews" />
        <site url="http://fa.wikiquote.org" dbname="fawikiquote" code="wikiquote" />
        <site url="http://fa.wikisource.org" dbname="fawikisource" code="wikisource" />
      </site>
    </language>
    <language code="ff" name="Fulfulde" localname="Fulah">
      <site>
        <site url="http://ff.wikipedia.org" dbname="ffwiki" code="wiki" />
      </site>
    </language>
    <language code="fi" name="Suomi" localname="Finnish">
      <site>
        <site url="http://fi.wikipedia.org" dbname="fiwiki" code="wiki" />
        <site url="http://fi.wiktionary.org" dbname="fiwiktionary" code="wiktionary" />
        <site url="http://fi.wikibooks.org" dbname="fiwikibooks" code="wikibooks" />
        <site url="http://fi.wikinews.org" dbname="fiwikinews" code="wikinews" />
        <site url="http://fi.wikiquote.org" dbname="fiwikiquote" code="wikiquote" />
        <site url="http://fi.wikisource.org" dbname="fiwikisource" code="wikisource" />
        <site url="http://fi.wikiversity.org" dbname="fiwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="fiu-vro" name="Võro" localname="Võro">
      <site>
        <site url="http://fiu-vro.wikipedia.org" dbname="fiu-vrowiki" code="wiki" />
      </site>
    </language>
    <language code="fj" name="Na Vosa Vakaviti" localname="Fijian">
      <site>
        <site url="http://fj.wikipedia.org" dbname="fjwiki" code="wiki" />
        <site url="http://fj.wiktionary.org" dbname="fjwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="fo" name="Føroyskt" localname="Faroese">
      <site>
        <site url="http://fo.wikipedia.org" dbname="fowiki" code="wiki" />
        <site url="http://fo.wiktionary.org" dbname="fowiktionary" code="wiktionary" />
        <site url="http://fo.wikisource.org" dbname="fowikisource" code="wikisource" />
      </site>
    </language>
    <language code="fr" name="Français" localname="French">
      <site>
        <site url="http://fr.wikipedia.org" dbname="frwiki" code="wiki" />
        <site url="http://fr.wiktionary.org" dbname="frwiktionary" code="wiktionary" />
        <site url="http://fr.wikibooks.org" dbname="frwikibooks" code="wikibooks" />
        <site url="http://fr.wikinews.org" dbname="frwikinews" code="wikinews" />
        <site url="http://fr.wikiquote.org" dbname="frwikiquote" code="wikiquote" />
        <site url="http://fr.wikisource.org" dbname="frwikisource" code="wikisource" />
        <site url="http://fr.wikiversity.org" dbname="frwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="frp" name="Arpetan" localname="Franco-Provençal">
      <site>
        <site url="http://frp.wikipedia.org" dbname="frpwiki" code="wiki" />
      </site>
    </language>
    <language code="frr" name="Nordfriisk" localname="Northern Frisian">
      <site>
        <site url="http://frr.wikipedia.org" dbname="frrwiki" code="wiki" />
      </site>
    </language>
    <language code="fur" name="Furlan" localname="Friulian">
      <site>
        <site url="http://fur.wikipedia.org" dbname="furwiki" code="wiki" />
      </site>
    </language>
    <language code="fy" name="Frysk" localname="Western Frisian">
      <site>
        <site url="http://fy.wikipedia.org" dbname="fywiki" code="wiki" />
        <site url="http://fy.wiktionary.org" dbname="fywiktionary" code="wiktionary" />
        <site url="http://fy.wikibooks.org" dbname="fywikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="ga" name="Gaeilge" localname="Irish">
      <site>
        <site url="http://ga.wikipedia.org" dbname="gawiki" code="wiki" />
        <site url="http://ga.wiktionary.org" dbname="gawiktionary" code="wiktionary" />
        <site url="http://ga.wikibooks.org" dbname="gawikibooks" code="wikibooks" closed="" />
        <site url="http://ga.wikiquote.org" dbname="gawikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="gag" name="Gagauz" localname="Gagauz">
      <site>
        <site url="http://gag.wikipedia.org" dbname="gagwiki" code="wiki" />
      </site>
    </language>
    <language code="gan" name="贛語" localname="Gan">
      <site>
        <site url="http://gan.wikipedia.org" dbname="ganwiki" code="wiki" />
      </site>
    </language>
    <language code="gd" name="Gàidhlig" localname="Scottish Gaelic">
      <site>
        <site url="http://gd.wikipedia.org" dbname="gdwiki" code="wiki" />
        <site url="http://gd.wiktionary.org" dbname="gdwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="gl" name="Galego" localname="Galician">
      <site>
        <site url="http://gl.wikipedia.org" dbname="glwiki" code="wiki" />
        <site url="http://gl.wiktionary.org" dbname="glwiktionary" code="wiktionary" />
        <site url="http://gl.wikibooks.org" dbname="glwikibooks" code="wikibooks" />
        <site url="http://gl.wikiquote.org" dbname="glwikiquote" code="wikiquote" />
        <site url="http://gl.wikisource.org" dbname="glwikisource" code="wikisource" />
      </site>
    </language>
    <language code="glk" name="گیلکی" localname="Gilaki">
      <site>
        <site url="http://glk.wikipedia.org" dbname="glkwiki" code="wiki" />
      </site>
    </language>
    <language code="gn" name="Avañe&#039;ẽ" localname="Guarani">
      <site>
        <site url="http://gn.wikipedia.org" dbname="gnwiki" code="wiki" />
        <site url="http://gn.wiktionary.org" dbname="gnwiktionary" code="wiktionary" />
        <site url="http://gn.wikibooks.org" dbname="gnwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="got" name="̲̹̺̿̈́̓" localname="Gothic">
      <site>
        <site url="http://got.wikipedia.org" dbname="gotwiki" code="wiki" />
        <site url="http://got.wikibooks.org" dbname="gotwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="gu" name="ગુજરાતી" localname="Gujarati">
      <site>
        <site url="http://gu.wikipedia.org" dbname="guwiki" code="wiki" />
        <site url="http://gu.wiktionary.org" dbname="guwiktionary" code="wiktionary" />
        <site url="http://gu.wikibooks.org" dbname="guwikibooks" code="wikibooks" closed="" />
        <site url="http://gu.wikiquote.org" dbname="guwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="gv" name="Gaelg" localname="Manx">
      <site>
        <site url="http://gv.wikipedia.org" dbname="gvwiki" code="wiki" />
        <site url="http://gv.wiktionary.org" dbname="gvwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="ha" name="هَوُسَ" localname="Hausa">
      <site>
        <site url="http://ha.wikipedia.org" dbname="hawiki" code="wiki" />
        <site url="http://ha.wiktionary.org" dbname="hawiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="hak" name="Hak-kâ-fa" localname="Hakka">
      <site>
        <site url="http://hak.wikipedia.org" dbname="hakwiki" code="wiki" />
      </site>
    </language>
    <language code="haw" name="Hawai`i" localname="Hawaiian">
      <site>
        <site url="http://haw.wikipedia.org" dbname="hawwiki" code="wiki" />
      </site>
    </language>
    <language code="he" name="עברית" localname="Hebrew">
      <site>
        <site url="http://he.wikipedia.org" dbname="hewiki" code="wiki" />
        <site url="http://he.wiktionary.org" dbname="hewiktionary" code="wiktionary" />
        <site url="http://he.wikibooks.org" dbname="hewikibooks" code="wikibooks" />
        <site url="http://he.wikinews.org" dbname="hewikinews" code="wikinews" />
        <site url="http://he.wikiquote.org" dbname="hewikiquote" code="wikiquote" />
        <site url="http://he.wikisource.org" dbname="hewikisource" code="wikisource" />
      </site>
    </language>
    <language code="hi" name="हिन्दी" localname="Hindi">
      <site>
        <site url="http://hi.wikipedia.org" dbname="hiwiki" code="wiki" />
        <site url="http://hi.wiktionary.org" dbname="hiwiktionary" code="wiktionary" />
        <site url="http://hi.wikibooks.org" dbname="hiwikibooks" code="wikibooks" />
        <site url="http://hi.wikiquote.org" dbname="hiwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="hif" name="Fiji Hindi" localname="Fiji Hindi">
      <site>
        <site url="http://hif.wikipedia.org" dbname="hifwiki" code="wiki" />
      </site>
    </language>
    <language code="ho" name="Hiri Motu" localname="Hiri Motu">
      <site>
        <site url="http://ho.wikipedia.org" dbname="howiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="hr" name="Hrvatski" localname="Croatian">
      <site>
        <site url="http://hr.wikipedia.org" dbname="hrwiki" code="wiki" />
        <site url="http://hr.wiktionary.org" dbname="hrwiktionary" code="wiktionary" />
        <site url="http://hr.wikibooks.org" dbname="hrwikibooks" code="wikibooks" />
        <site url="http://hr.wikiquote.org" dbname="hrwikiquote" code="wikiquote" />
        <site url="http://hr.wikisource.org" dbname="hrwikisource" code="wikisource" />
      </site>
    </language>
    <language code="hsb" name="Hornjoserbsce" localname="Upper Sorbian">
      <site>
        <site url="http://hsb.wikipedia.org" dbname="hsbwiki" code="wiki" />
        <site url="http://hsb.wiktionary.org" dbname="hsbwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="ht" name="Kreyòl ayisyen" localname="Haitian">
      <site>
        <site url="http://ht.wikipedia.org" dbname="htwiki" code="wiki" />
        <site url="http://ht.wikisource.org" dbname="htwikisource" code="wikisource" closed="" />
      </site>
    </language>
    <language code="hu" name="Magyar" localname="Hungarian">
      <site>
        <site url="http://hu.wikipedia.org" dbname="huwiki" code="wiki" />
        <site url="http://hu.wiktionary.org" dbname="huwiktionary" code="wiktionary" />
        <site url="http://hu.wikibooks.org" dbname="huwikibooks" code="wikibooks" />
        <site url="http://hu.wikinews.org" dbname="huwikinews" code="wikinews" closed="" />
        <site url="http://hu.wikiquote.org" dbname="huwikiquote" code="wikiquote" />
        <site url="http://hu.wikisource.org" dbname="huwikisource" code="wikisource" />
      </site>
    </language>
    <language code="hy" name="Հայերեն" localname="Armenian">
      <site>
        <site url="http://hy.wikipedia.org" dbname="hywiki" code="wiki" />
        <site url="http://hy.wiktionary.org" dbname="hywiktionary" code="wiktionary" />
        <site url="http://hy.wikibooks.org" dbname="hywikibooks" code="wikibooks" />
        <site url="http://hy.wikiquote.org" dbname="hywikiquote" code="wikiquote" />
        <site url="http://hy.wikisource.org" dbname="hywikisource" code="wikisource" />
      </site>
    </language>
    <language code="hz" name="Otsiherero" localname="Herero">
      <site>
        <site url="http://hz.wikipedia.org" dbname="hzwiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="ia" name="Interlingua" localname="Interlingua">
      <site>
        <site url="http://ia.wikipedia.org" dbname="iawiki" code="wiki" />
        <site url="http://ia.wiktionary.org" dbname="iawiktionary" code="wiktionary" />
        <site url="http://ia.wikibooks.org" dbname="iawikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="id" name="Bahasa Indonesia" localname="Indonesian">
      <site>
        <site url="http://id.wikipedia.org" dbname="idwiki" code="wiki" />
        <site url="http://id.wiktionary.org" dbname="idwiktionary" code="wiktionary" />
        <site url="http://id.wikibooks.org" dbname="idwikibooks" code="wikibooks" />
        <site url="http://id.wikiquote.org" dbname="idwikiquote" code="wikiquote" />
        <site url="http://id.wikisource.org" dbname="idwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ie" name="Interlingue" localname="Interlingue">
      <site>
        <site url="http://ie.wikipedia.org" dbname="iewiki" code="wiki" />
        <site url="http://ie.wiktionary.org" dbname="iewiktionary" code="wiktionary" />
        <site url="http://ie.wikibooks.org" dbname="iewikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="ig" name="Igbo" localname="Igbo">
      <site>
        <site url="http://ig.wikipedia.org" dbname="igwiki" code="wiki" />
      </site>
    </language>
    <language code="ii" name="ꆇꉙ" localname="Sichuan Yi">
      <site>
        <site url="http://ii.wikipedia.org" dbname="iiwiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="ik" name="Iñupiak" localname="Inupiaq">
      <site>
        <site url="http://ik.wikipedia.org" dbname="ikwiki" code="wiki" />
        <site url="http://ik.wiktionary.org" dbname="ikwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="ilo" name="Ilokano" localname="Iloko">
      <site>
        <site url="http://ilo.wikipedia.org" dbname="ilowiki" code="wiki" />
      </site>
    </language>
    <language code="io" name="Ido" localname="Ido">
      <site>
        <site url="http://io.wikipedia.org" dbname="iowiki" code="wiki" />
        <site url="http://io.wiktionary.org" dbname="iowiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="is" name="Íslenska" localname="Icelandic">
      <site>
        <site url="http://is.wikipedia.org" dbname="iswiki" code="wiki" />
        <site url="http://is.wiktionary.org" dbname="iswiktionary" code="wiktionary" />
        <site url="http://is.wikibooks.org" dbname="iswikibooks" code="wikibooks" />
        <site url="http://is.wikiquote.org" dbname="iswikiquote" code="wikiquote" />
        <site url="http://is.wikisource.org" dbname="iswikisource" code="wikisource" />
      </site>
    </language>
    <language code="it" name="Italiano" localname="Italian">
      <site>
        <site url="http://it.wikipedia.org" dbname="itwiki" code="wiki" />
        <site url="http://it.wiktionary.org" dbname="itwiktionary" code="wiktionary" />
        <site url="http://it.wikibooks.org" dbname="itwikibooks" code="wikibooks" />
        <site url="http://it.wikinews.org" dbname="itwikinews" code="wikinews" />
        <site url="http://it.wikiquote.org" dbname="itwikiquote" code="wikiquote" />
        <site url="http://it.wikisource.org" dbname="itwikisource" code="wikisource" />
        <site url="http://it.wikiversity.org" dbname="itwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="iu" name="ᐃᓄᒃᑎᑐᑦ/inuktitut" localname="Inuktitut">
      <site>
        <site url="http://iu.wikipedia.org" dbname="iuwiki" code="wiki" />
        <site url="http://iu.wiktionary.org" dbname="iuwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="ja" name="日本語" localname="Japanese">
      <site>
        <site url="http://ja.wikipedia.org" dbname="jawiki" code="wiki" />
        <site url="http://ja.wiktionary.org" dbname="jawiktionary" code="wiktionary" />
        <site url="http://ja.wikibooks.org" dbname="jawikibooks" code="wikibooks" />
        <site url="http://ja.wikinews.org" dbname="jawikinews" code="wikinews" />
        <site url="http://ja.wikiquote.org" dbname="jawikiquote" code="wikiquote" />
        <site url="http://ja.wikisource.org" dbname="jawikisource" code="wikisource" />
        <site url="http://ja.wikiversity.org" dbname="jawikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="jbo" name="Lojban" localname="Lojban">
      <site>
        <site url="http://jbo.wikipedia.org" dbname="jbowiki" code="wiki" />
        <site url="http://jbo.wiktionary.org" dbname="jbowiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="jp" name="">
      <site />
    </language>
    <language code="jv" name="Basa Jawa" localname="Javanese">
      <site>
        <site url="http://jv.wikipedia.org" dbname="jvwiki" code="wiki" />
        <site url="http://jv.wiktionary.org" dbname="jvwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="ka" name="ქართული" localname="Georgian">
      <site>
        <site url="http://ka.wikipedia.org" dbname="kawiki" code="wiki" />
        <site url="http://ka.wiktionary.org" dbname="kawiktionary" code="wiktionary" />
        <site url="http://ka.wikibooks.org" dbname="kawikibooks" code="wikibooks" />
        <site url="http://ka.wikiquote.org" dbname="kawikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="kaa" name="Qaraqalpaqsha" localname="Kara-Kalpak">
      <site>
        <site url="http://kaa.wikipedia.org" dbname="kaawiki" code="wiki" />
      </site>
    </language>
    <language code="kab" name="Taqbaylit" localname="Kabyle">
      <site>
        <site url="http://kab.wikipedia.org" dbname="kabwiki" code="wiki" />
      </site>
    </language>
    <language code="kbd" name="Адыгэбзэ" localname="Kabardian">
      <site>
        <site url="http://kbd.wikipedia.org" dbname="kbdwiki" code="wiki" />
      </site>
    </language>
    <language code="kg" name="Kongo" localname="Kongo">
      <site>
        <site url="http://kg.wikipedia.org" dbname="kgwiki" code="wiki" />
      </site>
    </language>
    <language code="ki" name="Gĩkũyũ" localname="Kikuyu">
      <site>
        <site url="http://ki.wikipedia.org" dbname="kiwiki" code="wiki" />
      </site>
    </language>
    <language code="kj" name="Kwanyama" localname="Kuanyama">
      <site>
        <site url="http://kj.wikipedia.org" dbname="kjwiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="kk" name="Қазақша" localname="Kazakh">
      <site>
        <site url="http://kk.wikipedia.org" dbname="kkwiki" code="wiki" />
        <site url="http://kk.wiktionary.org" dbname="kkwiktionary" code="wiktionary" />
        <site url="http://kk.wikibooks.org" dbname="kkwikibooks" code="wikibooks" />
        <site url="http://kk.wikiquote.org" dbname="kkwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="kl" name="Kalaallisut" localname="Kalaallisut">
      <site>
        <site url="http://kl.wikipedia.org" dbname="klwiki" code="wiki" />
        <site url="http://kl.wiktionary.org" dbname="klwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="km" name="ភាសាខ្មែរ" localname="Khmer">
      <site>
        <site url="http://km.wikipedia.org" dbname="kmwiki" code="wiki" />
        <site url="http://km.wiktionary.org" dbname="kmwiktionary" code="wiktionary" />
        <site url="http://km.wikibooks.org" dbname="kmwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="kn" name="ಕನ್ನಡ" localname="Kannada">
      <site>
        <site url="http://kn.wikipedia.org" dbname="knwiki" code="wiki" />
        <site url="http://kn.wiktionary.org" dbname="knwiktionary" code="wiktionary" />
        <site url="http://kn.wikibooks.org" dbname="knwikibooks" code="wikibooks" closed="" />
        <site url="http://kn.wikiquote.org" dbname="knwikiquote" code="wikiquote" />
        <site url="http://kn.wikisource.org" dbname="knwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ko" name="한국어" localname="Korean">
      <site>
        <site url="http://ko.wikipedia.org" dbname="kowiki" code="wiki" />
        <site url="http://ko.wiktionary.org" dbname="kowiktionary" code="wiktionary" />
        <site url="http://ko.wikibooks.org" dbname="kowikibooks" code="wikibooks" />
        <site url="http://ko.wikinews.org" dbname="kowikinews" code="wikinews" />
        <site url="http://ko.wikiquote.org" dbname="kowikiquote" code="wikiquote" />
        <site url="http://ko.wikisource.org" dbname="kowikisource" code="wikisource" />
      </site>
    </language>
    <language code="koi" name="Перем Коми" localname="Komi-Permyak">
      <site>
        <site url="http://koi.wikipedia.org" dbname="koiwiki" code="wiki" />
      </site>
    </language>
    <language code="kr" name="Kanuri" localname="Kanuri">
      <site>
        <site url="http://kr.wikipedia.org" dbname="krwiki" code="wiki" closed="" />
        <site url="http://kr.wikiquote.org" dbname="krwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="krc" name="Къарачай-Малкъар" localname="Karachay-Balkar">
      <site>
        <site url="http://krc.wikipedia.org" dbname="krcwiki" code="wiki" />
      </site>
    </language>
    <language code="ks" name="कॉशुर - کٲشُر" localname="Kashmiri">
      <site>
        <site url="http://ks.wikipedia.org" dbname="kswiki" code="wiki" />
        <site url="http://ks.wiktionary.org" dbname="kswiktionary" code="wiktionary" />
        <site url="http://ks.wikibooks.org" dbname="kswikibooks" code="wikibooks" closed="" />
        <site url="http://ks.wikiquote.org" dbname="kswikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="ksh" name="Ripoarisch" localname="Colognian">
      <site>
        <site url="http://ksh.wikipedia.org" dbname="kshwiki" code="wiki" />
      </site>
    </language>
    <language code="ku" name="Kurdî" localname="Kurdish">
      <site>
        <site url="http://ku.wikipedia.org" dbname="kuwiki" code="wiki" />
        <site url="http://ku.wiktionary.org" dbname="kuwiktionary" code="wiktionary" />
        <site url="http://ku.wikibooks.org" dbname="kuwikibooks" code="wikibooks" />
        <site url="http://ku.wikiquote.org" dbname="kuwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="kv" name="Коми" localname="Komi">
      <site>
        <site url="http://kv.wikipedia.org" dbname="kvwiki" code="wiki" />
      </site>
    </language>
    <language code="kw" name="Kernowek" localname="Cornish">
      <site>
        <site url="http://kw.wikipedia.org" dbname="kwwiki" code="wiki" />
        <site url="http://kw.wiktionary.org" dbname="kwwiktionary" code="wiktionary" />
        <site url="http://kw.wikiquote.org" dbname="kwwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="ky" name="Кыргызча" localname="Kirghiz">
      <site>
        <site url="http://ky.wikipedia.org" dbname="kywiki" code="wiki" />
        <site url="http://ky.wiktionary.org" dbname="kywiktionary" code="wiktionary" />
        <site url="http://ky.wikibooks.org" dbname="kywikibooks" code="wikibooks" />
        <site url="http://ky.wikiquote.org" dbname="kywikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="la" name="Latina" localname="Latin">
      <site>
        <site url="http://la.wikipedia.org" dbname="lawiki" code="wiki" />
        <site url="http://la.wiktionary.org" dbname="lawiktionary" code="wiktionary" />
        <site url="http://la.wikibooks.org" dbname="lawikibooks" code="wikibooks" />
        <site url="http://la.wikiquote.org" dbname="lawikiquote" code="wikiquote" />
        <site url="http://la.wikisource.org" dbname="lawikisource" code="wikisource" />
      </site>
    </language>
    <language code="lad" name="Ladino" localname="Ladino">
      <site>
        <site url="http://lad.wikipedia.org" dbname="ladwiki" code="wiki" />
      </site>
    </language>
    <language code="lb" name="Lëtzebuergesch" localname="Luxembourgish">
      <site>
        <site url="http://lb.wikipedia.org" dbname="lbwiki" code="wiki" />
        <site url="http://lb.wiktionary.org" dbname="lbwiktionary" code="wiktionary" />
        <site url="http://lb.wikibooks.org" dbname="lbwikibooks" code="wikibooks" closed="" />
        <site url="http://lb.wikiquote.org" dbname="lbwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="lbe" name="Лакку" localname="Лакку">
      <site>
        <site url="http://lbe.wikipedia.org" dbname="lbewiki" code="wiki" />
      </site>
    </language>
    <language code="lg" name="Luganda" localname="Ganda">
      <site>
        <site url="http://lg.wikipedia.org" dbname="lgwiki" code="wiki" />
      </site>
    </language>
    <language code="li" name="Limburgs" localname="Limburgish">
      <site>
        <site url="http://li.wikipedia.org" dbname="liwiki" code="wiki" />
        <site url="http://li.wiktionary.org" dbname="liwiktionary" code="wiktionary" />
        <site url="http://li.wikibooks.org" dbname="liwikibooks" code="wikibooks" />
        <site url="http://li.wikiquote.org" dbname="liwikiquote" code="wikiquote" />
        <site url="http://li.wikisource.org" dbname="liwikisource" code="wikisource" />
      </site>
    </language>
    <language code="lij" name="Ligure" localname="Ligure">
      <site>
        <site url="http://lij.wikipedia.org" dbname="lijwiki" code="wiki" />
      </site>
    </language>
    <language code="lmo" name="Lumbaart" localname="Lumbaart">
      <site>
        <site url="http://lmo.wikipedia.org" dbname="lmowiki" code="wiki" />
      </site>
    </language>
    <language code="ln" name="Lingála" localname="Lingala">
      <site>
        <site url="http://ln.wikipedia.org" dbname="lnwiki" code="wiki" />
        <site url="http://ln.wiktionary.org" dbname="lnwiktionary" code="wiktionary" />
        <site url="http://ln.wikibooks.org" dbname="lnwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="lo" name="ລາວ" localname="Lao">
      <site>
        <site url="http://lo.wikipedia.org" dbname="lowiki" code="wiki" />
        <site url="http://lo.wiktionary.org" dbname="lowiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="lt" name="Lietuvių" localname="Lithuanian">
      <site>
        <site url="http://lt.wikipedia.org" dbname="ltwiki" code="wiki" />
        <site url="http://lt.wiktionary.org" dbname="ltwiktionary" code="wiktionary" />
        <site url="http://lt.wikibooks.org" dbname="ltwikibooks" code="wikibooks" />
        <site url="http://lt.wikiquote.org" dbname="ltwikiquote" code="wikiquote" />
        <site url="http://lt.wikisource.org" dbname="ltwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ltg" name="Latgaļu" localname="Latgalian">
      <site>
        <site url="http://ltg.wikipedia.org" dbname="ltgwiki" code="wiki" />
      </site>
    </language>
    <language code="lv" name="Latviešu" localname="Latvian">
      <site>
        <site url="http://lv.wikipedia.org" dbname="lvwiki" code="wiki" />
        <site url="http://lv.wiktionary.org" dbname="lvwiktionary" code="wiktionary" />
        <site url="http://lv.wikibooks.org" dbname="lvwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="map-bms" name="Basa Banyumasan" localname="Basa Banyumasan">
      <site>
        <site url="http://map-bms.wikipedia.org" dbname="map-bmswiki" code="wiki" />
      </site>
    </language>
    <language code="mdf" name="Мокшень" localname="Moksha">
      <site>
        <site url="http://mdf.wikipedia.org" dbname="mdfwiki" code="wiki" />
      </site>
    </language>
    <language code="mg" name="Malagasy" localname="Malagasy">
      <site>
        <site url="http://mg.wikipedia.org" dbname="mgwiki" code="wiki" />
        <site url="http://mg.wiktionary.org" dbname="mgwiktionary" code="wiktionary" />
        <site url="http://mg.wikibooks.org" dbname="mgwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="mh" name="Ebon" localname="Marshallese">
      <site>
        <site url="http://mh.wikipedia.org" dbname="mhwiki" code="wiki" closed="" />
        <site url="http://mh.wiktionary.org" dbname="mhwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="mhr" name="Олык Марий" localname="Eastern Mari">
      <site>
        <site url="http://mhr.wikipedia.org" dbname="mhrwiki" code="wiki" />
      </site>
    </language>
    <language code="mi" name="Māori" localname="Maori">
      <site>
        <site url="http://mi.wikipedia.org" dbname="miwiki" code="wiki" />
        <site url="http://mi.wiktionary.org" dbname="miwiktionary" code="wiktionary" />
        <site url="http://mi.wikibooks.org" dbname="miwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="minnan" name="">
      <site />
    </language>
    <language code="mk" name="Македонски" localname="Macedonian">
      <site>
        <site url="http://mk.wikipedia.org" dbname="mkwiki" code="wiki" />
        <site url="http://mk.wiktionary.org" dbname="mkwiktionary" code="wiktionary" />
        <site url="http://mk.wikibooks.org" dbname="mkwikibooks" code="wikibooks" />
        <site url="http://mk.wikisource.org" dbname="mkwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ml" name="മലയാളം" localname="Malayalam">
      <site>
        <site url="http://ml.wikipedia.org" dbname="mlwiki" code="wiki" />
        <site url="http://ml.wiktionary.org" dbname="mlwiktionary" code="wiktionary" />
        <site url="http://ml.wikibooks.org" dbname="mlwikibooks" code="wikibooks" />
        <site url="http://ml.wikiquote.org" dbname="mlwikiquote" code="wikiquote" />
        <site url="http://ml.wikisource.org" dbname="mlwikisource" code="wikisource" />
      </site>
    </language>
    <language code="mn" name="Монгол" localname="Mongolian">
      <site>
        <site url="http://mn.wikipedia.org" dbname="mnwiki" code="wiki" />
        <site url="http://mn.wiktionary.org" dbname="mnwiktionary" code="wiktionary" />
        <site url="http://mn.wikibooks.org" dbname="mnwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="mo" name="Молдовеняскэ" localname="Moldavian">
      <site>
        <site url="http://mo.wikipedia.org" dbname="mowiki" code="wiki" closed="" />
        <site url="http://mo.wiktionary.org" dbname="mowiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="mr" name="मराठी" localname="Marathi">
      <site>
        <site url="http://mr.wikipedia.org" dbname="mrwiki" code="wiki" />
        <site url="http://mr.wiktionary.org" dbname="mrwiktionary" code="wiktionary" />
        <site url="http://mr.wikibooks.org" dbname="mrwikibooks" code="wikibooks" />
        <site url="http://mr.wikiquote.org" dbname="mrwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="mrj" name="Кырык мары" localname="Hill Mari">
      <site>
        <site url="http://mrj.wikipedia.org" dbname="mrjwiki" code="wiki" />
      </site>
    </language>
    <language code="ms" name="Bahasa Melayu" localname="Malay">
      <site>
        <site url="http://ms.wikipedia.org" dbname="mswiki" code="wiki" />
        <site url="http://ms.wiktionary.org" dbname="mswiktionary" code="wiktionary" />
        <site url="http://ms.wikibooks.org" dbname="mswikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="mt" name="Malti" localname="Maltese">
      <site>
        <site url="http://mt.wikipedia.org" dbname="mtwiki" code="wiki" />
        <site url="http://mt.wiktionary.org" dbname="mtwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="mus" name="Mvskoke" localname="Creek">
      <site>
        <site url="http://mus.wikipedia.org" dbname="muswiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="mwl" name="Mirandés" localname="Mirandese">
      <site>
        <site url="http://mwl.wikipedia.org" dbname="mwlwiki" code="wiki" />
      </site>
    </language>
    <language code="my" name="မြန်မာဘာသာ" localname="Burmese">
      <site>
        <site url="http://my.wikipedia.org" dbname="mywiki" code="wiki" />
        <site url="http://my.wiktionary.org" dbname="mywiktionary" code="wiktionary" />
        <site url="http://my.wikibooks.org" dbname="mywikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="myv" name="Эрзянь" localname="Erzya">
      <site>
        <site url="http://myv.wikipedia.org" dbname="myvwiki" code="wiki" />
      </site>
    </language>
    <language code="mzn" name="مازِرونی" localname="Mazanderani">
      <site>
        <site url="http://mzn.wikipedia.org" dbname="mznwiki" code="wiki" />
      </site>
    </language>
    <language code="na" name="Dorerin Naoero" localname="Nauru">
      <site>
        <site url="http://na.wikipedia.org" dbname="nawiki" code="wiki" />
        <site url="http://na.wiktionary.org" dbname="nawiktionary" code="wiktionary" />
        <site url="http://na.wikibooks.org" dbname="nawikibooks" code="wikibooks" closed="" />
        <site url="http://na.wikiquote.org" dbname="nawikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="nah" name="Nāhuatl" localname="Nahuatl">
      <site>
        <site url="http://nah.wikipedia.org" dbname="nahwiki" code="wiki" />
        <site url="http://nah.wiktionary.org" dbname="nahwiktionary" code="wiktionary" />
        <site url="http://nah.wikibooks.org" dbname="nahwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="nan" name="Bân-lâm-gú" localname="Min Nan Chinese">
      <site />
    </language>
    <language code="nap" name="Nnapulitano" localname="Neapolitan">
      <site>
        <site url="http://nap.wikipedia.org" dbname="napwiki" code="wiki" />
      </site>
    </language>
    <language code="nb" name="‪Norsk (bokmål)‬" localname="Norwegian Bokmål">
      <site />
    </language>
    <language code="nds" name="Plattdüütsch" localname="Low German">
      <site>
        <site url="http://nds.wikipedia.org" dbname="ndswiki" code="wiki" />
        <site url="http://nds.wiktionary.org" dbname="ndswiktionary" code="wiktionary" />
        <site url="http://nds.wikibooks.org" dbname="ndswikibooks" code="wikibooks" closed="" />
        <site url="http://nds.wikiquote.org" dbname="ndswikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="nds-nl" name="Nedersaksisch" localname="Nedersaksisch">
      <site>
        <site url="http://nds-nl.wikipedia.org" dbname="nds-nlwiki" code="wiki" />
      </site>
    </language>
    <language code="ne" name="नेपाली" localname="Nepali">
      <site>
        <site url="http://ne.wikipedia.org" dbname="newiki" code="wiki" />
        <site url="http://ne.wiktionary.org" dbname="newiktionary" code="wiktionary" />
        <site url="http://ne.wikibooks.org" dbname="newikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="new" name="नेपाल भाषा" localname="Newari">
      <site>
        <site url="http://new.wikipedia.org" dbname="newwiki" code="wiki" />
      </site>
    </language>
    <language code="ng" name="Oshiwambo" localname="Ndonga">
      <site>
        <site url="http://ng.wikipedia.org" dbname="ngwiki" code="wiki" closed="" />
      </site>
    </language>
    <language code="nl" name="Nederlands" localname="Dutch">
      <site>
        <site url="http://nl.wikipedia.org" dbname="nlwiki" code="wiki" />
        <site url="http://nl.wiktionary.org" dbname="nlwiktionary" code="wiktionary" />
        <site url="http://nl.wikibooks.org" dbname="nlwikibooks" code="wikibooks" />
        <site url="http://nl.wikinews.org" dbname="nlwikinews" code="wikinews" closed="" />
        <site url="http://nl.wikiquote.org" dbname="nlwikiquote" code="wikiquote" />
        <site url="http://nl.wikisource.org" dbname="nlwikisource" code="wikisource" />
      </site>
    </language>
    <language code="nn" name="‪Norsk (nynorsk)‬" localname="Norwegian Nynorsk">
      <site>
        <site url="http://nn.wikipedia.org" dbname="nnwiki" code="wiki" />
        <site url="http://nn.wiktionary.org" dbname="nnwiktionary" code="wiktionary" />
        <site url="http://nn.wikiquote.org" dbname="nnwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="no" name="‪Norsk (bokmål)‬" localname="Norwegian (bokmål)‬">
      <site>
        <site url="http://no.wikipedia.org" dbname="nowiki" code="wiki" />
        <site url="http://no.wiktionary.org" dbname="nowiktionary" code="wiktionary" />
        <site url="http://no.wikibooks.org" dbname="nowikibooks" code="wikibooks" />
        <site url="http://no.wikinews.org" dbname="nowikinews" code="wikinews" />
        <site url="http://no.wikiquote.org" dbname="nowikiquote" code="wikiquote" />
        <site url="http://no.wikisource.org" dbname="nowikisource" code="wikisource" />
      </site>
    </language>
    <language code="nov" name="Novial" localname="Novial">
      <site>
        <site url="http://nov.wikipedia.org" dbname="novwiki" code="wiki" />
      </site>
    </language>
    <language code="nrm" name="Nouormand" localname="Nouormand">
      <site>
        <site url="http://nrm.wikipedia.org" dbname="nrmwiki" code="wiki" />
      </site>
    </language>
    <language code="nso" name="Sesotho sa Leboa" localname="Northern Sotho">
      <site>
        <site url="http://nso.wikipedia.org" dbname="nsowiki" code="wiki" />
      </site>
    </language>
    <language code="nv" name="Diné bizaad" localname="Navajo">
      <site>
        <site url="http://nv.wikipedia.org" dbname="nvwiki" code="wiki" />
      </site>
    </language>
    <language code="ny" name="Chi-Chewa" localname="Nyanja">
      <site>
        <site url="http://ny.wikipedia.org" dbname="nywiki" code="wiki" />
      </site>
    </language>
    <language code="oc" name="Occitan" localname="Occitan">
      <site>
        <site url="http://oc.wikipedia.org" dbname="ocwiki" code="wiki" />
        <site url="http://oc.wiktionary.org" dbname="ocwiktionary" code="wiktionary" />
        <site url="http://oc.wikibooks.org" dbname="ocwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="om" name="Oromoo" localname="Oromo">
      <site>
        <site url="http://om.wikipedia.org" dbname="omwiki" code="wiki" />
        <site url="http://om.wiktionary.org" dbname="omwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="or" name="ଓଡ଼ିଆ" localname="Oriya">
      <site>
        <site url="http://or.wikipedia.org" dbname="orwiki" code="wiki" />
        <site url="http://or.wiktionary.org" dbname="orwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="os" name="Ирон" localname="Ossetic">
      <site>
        <site url="http://os.wikipedia.org" dbname="oswiki" code="wiki" />
      </site>
    </language>
    <language code="pa" name="ਪੰਜਾਬੀ" localname="Punjabi">
      <site>
        <site url="http://pa.wikipedia.org" dbname="pawiki" code="wiki" />
        <site url="http://pa.wiktionary.org" dbname="pawiktionary" code="wiktionary" />
        <site url="http://pa.wikibooks.org" dbname="pawikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="pag" name="Pangasinan" localname="Pangasinan">
      <site>
        <site url="http://pag.wikipedia.org" dbname="pagwiki" code="wiki" />
      </site>
    </language>
    <language code="pam" name="Kapampangan" localname="Pampanga">
      <site>
        <site url="http://pam.wikipedia.org" dbname="pamwiki" code="wiki" />
      </site>
    </language>
    <language code="pap" name="Papiamentu" localname="Papiamento">
      <site>
        <site url="http://pap.wikipedia.org" dbname="papwiki" code="wiki" />
      </site>
    </language>
    <language code="pcd" name="Picard" localname="Picard">
      <site>
        <site url="http://pcd.wikipedia.org" dbname="pcdwiki" code="wiki" />
      </site>
    </language>
    <language code="pdc" name="Deitsch" localname="Deitsch">
      <site>
        <site url="http://pdc.wikipedia.org" dbname="pdcwiki" code="wiki" />
      </site>
    </language>
    <language code="pfl" name="Pälzisch" localname="Pälzisch">
      <site>
        <site url="http://pfl.wikipedia.org" dbname="pflwiki" code="wiki" />
      </site>
    </language>
    <language code="pi" name="पािऴ" localname="Pali">
      <site>
        <site url="http://pi.wikipedia.org" dbname="piwiki" code="wiki" />
        <site url="http://pi.wiktionary.org" dbname="piwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="pih" name="Norfuk / Pitkern" localname="Norfuk / Pitkern">
      <site>
        <site url="http://pih.wikipedia.org" dbname="pihwiki" code="wiki" />
      </site>
    </language>
    <language code="pl" name="Polski" localname="Polish">
      <site>
        <site url="http://pl.wikipedia.org" dbname="plwiki" code="wiki" />
        <site url="http://pl.wiktionary.org" dbname="plwiktionary" code="wiktionary" />
        <site url="http://pl.wikibooks.org" dbname="plwikibooks" code="wikibooks" />
        <site url="http://pl.wikinews.org" dbname="plwikinews" code="wikinews" />
        <site url="http://pl.wikiquote.org" dbname="plwikiquote" code="wikiquote" />
        <site url="http://pl.wikisource.org" dbname="plwikisource" code="wikisource" />
      </site>
    </language>
    <language code="pms" name="Piemontèis" localname="Piedmontese">
      <site>
        <site url="http://pms.wikipedia.org" dbname="pmswiki" code="wiki" />
      </site>
    </language>
    <language code="pnb" name="پنجابی" localname="Western Punjabi">
      <site>
        <site url="http://pnb.wikipedia.org" dbname="pnbwiki" code="wiki" />
      </site>
    </language>
    <language code="pnt" name="Ποντιακά" localname="Pontic">
      <site>
        <site url="http://pnt.wikipedia.org" dbname="pntwiki" code="wiki" />
      </site>
    </language>
    <language code="ps" name="پښتو" localname="Pashto">
      <site>
        <site url="http://ps.wikipedia.org" dbname="pswiki" code="wiki" />
        <site url="http://ps.wiktionary.org" dbname="pswiktionary" code="wiktionary" />
        <site url="http://ps.wikibooks.org" dbname="pswikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="pt" name="Português" localname="Portuguese">
      <site>
        <site url="http://pt.wikipedia.org" dbname="ptwiki" code="wiki" />
        <site url="http://pt.wiktionary.org" dbname="ptwiktionary" code="wiktionary" />
        <site url="http://pt.wikibooks.org" dbname="ptwikibooks" code="wikibooks" />
        <site url="http://pt.wikinews.org" dbname="ptwikinews" code="wikinews" />
        <site url="http://pt.wikiquote.org" dbname="ptwikiquote" code="wikiquote" />
        <site url="http://pt.wikisource.org" dbname="ptwikisource" code="wikisource" />
        <site url="http://pt.wikiversity.org" dbname="ptwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="qu" name="Runa Simi" localname="Quechua">
      <site>
        <site url="http://qu.wikipedia.org" dbname="quwiki" code="wiki" />
        <site url="http://qu.wiktionary.org" dbname="quwiktionary" code="wiktionary" />
        <site url="http://qu.wikibooks.org" dbname="quwikibooks" code="wikibooks" closed="" />
        <site url="http://qu.wikiquote.org" dbname="quwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="rm" name="Rumantsch" localname="Romansh">
      <site>
        <site url="http://rm.wikipedia.org" dbname="rmwiki" code="wiki" />
        <site url="http://rm.wiktionary.org" dbname="rmwiktionary" code="wiktionary" closed="" />
        <site url="http://rm.wikibooks.org" dbname="rmwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="rmy" name="Romani" localname="Romani">
      <site>
        <site url="http://rmy.wikipedia.org" dbname="rmywiki" code="wiki" />
      </site>
    </language>
    <language code="rn" name="Kirundi" localname="Rundi">
      <site>
        <site url="http://rn.wikipedia.org" dbname="rnwiki" code="wiki" />
        <site url="http://rn.wiktionary.org" dbname="rnwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="ro" name="Română" localname="Romanian">
      <site>
        <site url="http://ro.wikipedia.org" dbname="rowiki" code="wiki" />
        <site url="http://ro.wiktionary.org" dbname="rowiktionary" code="wiktionary" />
        <site url="http://ro.wikibooks.org" dbname="rowikibooks" code="wikibooks" />
        <site url="http://ro.wikinews.org" dbname="rowikinews" code="wikinews" />
        <site url="http://ro.wikiquote.org" dbname="rowikiquote" code="wikiquote" />
        <site url="http://ro.wikisource.org" dbname="rowikisource" code="wikisource" />
      </site>
    </language>
    <language code="roa-rup" name="Armãneashce" localname="Aromanian">
      <site>
        <site url="http://roa-rup.wikipedia.org" dbname="roa-rupwiki" code="wiki" />
        <site url="http://roa-rup.wiktionary.org" dbname="roa-rupwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="roa-tara" name="Tarandíne" localname="Tarandíne">
      <site>
        <site url="http://roa-tara.wikipedia.org" dbname="roa-tarawiki" code="wiki" />
      </site>
    </language>
    <language code="ru" name="Русский" localname="Russian">
      <site>
        <site url="http://ru.wikipedia.org" dbname="ruwiki" code="wiki" />
        <site url="http://ru.wiktionary.org" dbname="ruwiktionary" code="wiktionary" />
        <site url="http://ru.wikibooks.org" dbname="ruwikibooks" code="wikibooks" />
        <site url="http://ru.wikinews.org" dbname="ruwikinews" code="wikinews" />
        <site url="http://ru.wikiquote.org" dbname="ruwikiquote" code="wikiquote" />
        <site url="http://ru.wikisource.org" dbname="ruwikisource" code="wikisource" />
        <site url="http://ru.wikiversity.org" dbname="ruwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="rue" name="Русиньскый" localname="Rusyn">
      <site>
        <site url="http://rue.wikipedia.org" dbname="ruewiki" code="wiki" />
      </site>
    </language>
    <language code="rw" name="Kinyarwanda" localname="Kinyarwanda">
      <site>
        <site url="http://rw.wikipedia.org" dbname="rwwiki" code="wiki" />
        <site url="http://rw.wiktionary.org" dbname="rwwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="sa" name="संस्कृतम्" localname="Sanskrit">
      <site>
        <site url="http://sa.wikipedia.org" dbname="sawiki" code="wiki" />
        <site url="http://sa.wiktionary.org" dbname="sawiktionary" code="wiktionary" />
        <site url="http://sa.wikibooks.org" dbname="sawikibooks" code="wikibooks" />
        <site url="http://sa.wikisource.org" dbname="sawikisource" code="wikisource" />
      </site>
    </language>
    <language code="sah" name="Саха тыла" localname="Yakut">
      <site>
        <site url="http://sah.wikipedia.org" dbname="sahwiki" code="wiki" />
        <site url="http://sah.wikisource.org" dbname="sahwikisource" code="wikisource" />
      </site>
    </language>
    <language code="sc" name="Sardu" localname="Sardinian">
      <site>
        <site url="http://sc.wikipedia.org" dbname="scwiki" code="wiki" />
        <site url="http://sc.wiktionary.org" dbname="scwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="scn" name="Sicilianu" localname="Sicilian">
      <site>
        <site url="http://scn.wikipedia.org" dbname="scnwiki" code="wiki" />
        <site url="http://scn.wiktionary.org" dbname="scnwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="sco" name="Scots" localname="Scots">
      <site>
        <site url="http://sco.wikipedia.org" dbname="scowiki" code="wiki" />
      </site>
    </language>
    <language code="sd" name="سنڌي" localname="Sindhi">
      <site>
        <site url="http://sd.wikipedia.org" dbname="sdwiki" code="wiki" />
        <site url="http://sd.wiktionary.org" dbname="sdwiktionary" code="wiktionary" />
        <site url="http://sd.wikinews.org" dbname="sdwikinews" code="wikinews" closed="" />
      </site>
    </language>
    <language code="se" name="Sámegiella" localname="Northern Sami">
      <site>
        <site url="http://se.wikipedia.org" dbname="sewiki" code="wiki" />
        <site url="http://se.wikibooks.org" dbname="sewikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="sg" name="Sängö" localname="Sango">
      <site>
        <site url="http://sg.wikipedia.org" dbname="sgwiki" code="wiki" />
        <site url="http://sg.wiktionary.org" dbname="sgwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="sh" name="Srpskohrvatski / Српскохрватски" localname="Serbo-Croatian">
      <site>
        <site url="http://sh.wikipedia.org" dbname="shwiki" code="wiki" />
        <site url="http://sh.wiktionary.org" dbname="shwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="si" name="සිංහල" localname="Sinhala">
      <site>
        <site url="http://si.wikipedia.org" dbname="siwiki" code="wiki" />
        <site url="http://si.wiktionary.org" dbname="siwiktionary" code="wiktionary" />
        <site url="http://si.wikibooks.org" dbname="siwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="simple" name="Simple English" localname="Simple English">
      <site>
        <site url="http://simple.wikipedia.org" dbname="simplewiki" code="wiki" />
        <site url="http://simple.wiktionary.org" dbname="simplewiktionary" code="wiktionary" />
        <site url="http://simple.wikibooks.org" dbname="simplewikibooks" code="wikibooks" closed="" />
        <site url="http://simple.wikiquote.org" dbname="simplewikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="sk" name="Slovenčina" localname="Slovak">
      <site>
        <site url="http://sk.wikipedia.org" dbname="skwiki" code="wiki" />
        <site url="http://sk.wiktionary.org" dbname="skwiktionary" code="wiktionary" />
        <site url="http://sk.wikibooks.org" dbname="skwikibooks" code="wikibooks" />
        <site url="http://sk.wikiquote.org" dbname="skwikiquote" code="wikiquote" />
        <site url="http://sk.wikisource.org" dbname="skwikisource" code="wikisource" />
      </site>
    </language>
    <language code="sl" name="Slovenščina" localname="Slovenian">
      <site>
        <site url="http://sl.wikipedia.org" dbname="slwiki" code="wiki" />
        <site url="http://sl.wiktionary.org" dbname="slwiktionary" code="wiktionary" />
        <site url="http://sl.wikibooks.org" dbname="slwikibooks" code="wikibooks" />
        <site url="http://sl.wikiquote.org" dbname="slwikiquote" code="wikiquote" />
        <site url="http://sl.wikisource.org" dbname="slwikisource" code="wikisource" />
      </site>
    </language>
    <language code="sm" name="Gagana Samoa" localname="Samoan">
      <site>
        <site url="http://sm.wikipedia.org" dbname="smwiki" code="wiki" />
        <site url="http://sm.wiktionary.org" dbname="smwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="sn" name="chiShona" localname="Shona">
      <site>
        <site url="http://sn.wikipedia.org" dbname="snwiki" code="wiki" />
        <site url="http://sn.wiktionary.org" dbname="snwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="so" name="Soomaaliga" localname="Somali">
      <site>
        <site url="http://so.wikipedia.org" dbname="sowiki" code="wiki" />
        <site url="http://so.wiktionary.org" dbname="sowiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="sq" name="Shqip" localname="Albanian">
      <site>
        <site url="http://sq.wikipedia.org" dbname="sqwiki" code="wiki" />
        <site url="http://sq.wiktionary.org" dbname="sqwiktionary" code="wiktionary" />
        <site url="http://sq.wikibooks.org" dbname="sqwikibooks" code="wikibooks" />
        <site url="http://sq.wikinews.org" dbname="sqwikinews" code="wikinews" />
        <site url="http://sq.wikiquote.org" dbname="sqwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="sr" name="Српски / Srpski" localname="Serbian">
      <site>
        <site url="http://sr.wikipedia.org" dbname="srwiki" code="wiki" />
        <site url="http://sr.wiktionary.org" dbname="srwiktionary" code="wiktionary" />
        <site url="http://sr.wikibooks.org" dbname="srwikibooks" code="wikibooks" />
        <site url="http://sr.wikinews.org" dbname="srwikinews" code="wikinews" />
        <site url="http://sr.wikiquote.org" dbname="srwikiquote" code="wikiquote" />
        <site url="http://sr.wikisource.org" dbname="srwikisource" code="wikisource" />
      </site>
    </language>
    <language code="srn" name="Sranantongo" localname="Sranan Tongo">
      <site>
        <site url="http://srn.wikipedia.org" dbname="srnwiki" code="wiki" />
      </site>
    </language>
    <language code="ss" name="SiSwati" localname="Swati">
      <site>
        <site url="http://ss.wikipedia.org" dbname="sswiki" code="wiki" />
        <site url="http://ss.wiktionary.org" dbname="sswiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="st" name="Sesotho" localname="Southern Sotho">
      <site>
        <site url="http://st.wikipedia.org" dbname="stwiki" code="wiki" />
        <site url="http://st.wiktionary.org" dbname="stwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="stq" name="Seeltersk" localname="Seeltersk">
      <site>
        <site url="http://stq.wikipedia.org" dbname="stqwiki" code="wiki" />
      </site>
    </language>
    <language code="su" name="Basa Sunda" localname="Sundanese">
      <site>
        <site url="http://su.wikipedia.org" dbname="suwiki" code="wiki" />
        <site url="http://su.wiktionary.org" dbname="suwiktionary" code="wiktionary" />
        <site url="http://su.wikibooks.org" dbname="suwikibooks" code="wikibooks" />
        <site url="http://su.wikiquote.org" dbname="suwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="sv" name="Svenska" localname="Swedish">
      <site>
        <site url="http://sv.wikipedia.org" dbname="svwiki" code="wiki" />
        <site url="http://sv.wiktionary.org" dbname="svwiktionary" code="wiktionary" />
        <site url="http://sv.wikibooks.org" dbname="svwikibooks" code="wikibooks" />
        <site url="http://sv.wikinews.org" dbname="svwikinews" code="wikinews" />
        <site url="http://sv.wikiquote.org" dbname="svwikiquote" code="wikiquote" />
        <site url="http://sv.wikisource.org" dbname="svwikisource" code="wikisource" />
        <site url="http://sv.wikiversity.org" dbname="svwikiversity" code="wikiversity" />
      </site>
    </language>
    <language code="sw" name="Kiswahili" localname="Swahili">
      <site>
        <site url="http://sw.wikipedia.org" dbname="swwiki" code="wiki" />
        <site url="http://sw.wiktionary.org" dbname="swwiktionary" code="wiktionary" />
        <site url="http://sw.wikibooks.org" dbname="swwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="szl" name="Ślůnski" localname="Silesian">
      <site>
        <site url="http://szl.wikipedia.org" dbname="szlwiki" code="wiki" />
      </site>
    </language>
    <language code="ta" name="தமிழ்" localname="Tamil">
      <site>
        <site url="http://ta.wikipedia.org" dbname="tawiki" code="wiki" />
        <site url="http://ta.wiktionary.org" dbname="tawiktionary" code="wiktionary" />
        <site url="http://ta.wikibooks.org" dbname="tawikibooks" code="wikibooks" />
        <site url="http://ta.wikinews.org" dbname="tawikinews" code="wikinews" />
        <site url="http://ta.wikiquote.org" dbname="tawikiquote" code="wikiquote" />
        <site url="http://ta.wikisource.org" dbname="tawikisource" code="wikisource" />
      </site>
    </language>
    <language code="te" name="తెలుగు" localname="Telugu">
      <site>
        <site url="http://te.wikipedia.org" dbname="tewiki" code="wiki" />
        <site url="http://te.wiktionary.org" dbname="tewiktionary" code="wiktionary" />
        <site url="http://te.wikibooks.org" dbname="tewikibooks" code="wikibooks" />
        <site url="http://te.wikiquote.org" dbname="tewikiquote" code="wikiquote" />
        <site url="http://te.wikisource.org" dbname="tewikisource" code="wikisource" />
      </site>
    </language>
    <language code="tet" name="Tetun" localname="Tetum">
      <site>
        <site url="http://tet.wikipedia.org" dbname="tetwiki" code="wiki" />
      </site>
    </language>
    <language code="tg" name="Тоҷикӣ" localname="Tajik">
      <site>
        <site url="http://tg.wikipedia.org" dbname="tgwiki" code="wiki" />
        <site url="http://tg.wiktionary.org" dbname="tgwiktionary" code="wiktionary" />
        <site url="http://tg.wikibooks.org" dbname="tgwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="th" name="ไทย" localname="Thai">
      <site>
        <site url="http://th.wikipedia.org" dbname="thwiki" code="wiki" />
        <site url="http://th.wiktionary.org" dbname="thwiktionary" code="wiktionary" />
        <site url="http://th.wikibooks.org" dbname="thwikibooks" code="wikibooks" />
        <site url="http://th.wikinews.org" dbname="thwikinews" code="wikinews" closed="" />
        <site url="http://th.wikiquote.org" dbname="thwikiquote" code="wikiquote" />
        <site url="http://th.wikisource.org" dbname="thwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ti" name="ትግርኛ" localname="Tigrinya">
      <site>
        <site url="http://ti.wikipedia.org" dbname="tiwiki" code="wiki" />
        <site url="http://ti.wiktionary.org" dbname="tiwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="tk" name="Türkmençe" localname="Turkmen">
      <site>
        <site url="http://tk.wikipedia.org" dbname="tkwiki" code="wiki" />
        <site url="http://tk.wiktionary.org" dbname="tkwiktionary" code="wiktionary" />
        <site url="http://tk.wikibooks.org" dbname="tkwikibooks" code="wikibooks" closed="" />
        <site url="http://tk.wikiquote.org" dbname="tkwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="tl" name="Tagalog" localname="Tagalog">
      <site>
        <site url="http://tl.wikipedia.org" dbname="tlwiki" code="wiki" />
        <site url="http://tl.wiktionary.org" dbname="tlwiktionary" code="wiktionary" />
        <site url="http://tl.wikibooks.org" dbname="tlwikibooks" code="wikibooks" />
      </site>
    </language>
    <language code="tn" name="Setswana" localname="Tswana">
      <site>
        <site url="http://tn.wikipedia.org" dbname="tnwiki" code="wiki" />
        <site url="http://tn.wiktionary.org" dbname="tnwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="to" name="lea faka-Tonga" localname="Tonga">
      <site>
        <site url="http://to.wikipedia.org" dbname="towiki" code="wiki" />
        <site url="http://to.wiktionary.org" dbname="towiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="tpi" name="Tok Pisin" localname="Tok Pisin">
      <site>
        <site url="http://tpi.wikipedia.org" dbname="tpiwiki" code="wiki" />
        <site url="http://tpi.wiktionary.org" dbname="tpiwiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="tr" name="Türkçe" localname="Turkish">
      <site>
        <site url="http://tr.wikipedia.org" dbname="trwiki" code="wiki" />
        <site url="http://tr.wiktionary.org" dbname="trwiktionary" code="wiktionary" />
        <site url="http://tr.wikibooks.org" dbname="trwikibooks" code="wikibooks" />
        <site url="http://tr.wikinews.org" dbname="trwikinews" code="wikinews" />
        <site url="http://tr.wikiquote.org" dbname="trwikiquote" code="wikiquote" />
        <site url="http://tr.wikisource.org" dbname="trwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ts" name="Xitsonga" localname="Tsonga">
      <site>
        <site url="http://ts.wikipedia.org" dbname="tswiki" code="wiki" />
        <site url="http://ts.wiktionary.org" dbname="tswiktionary" code="wiktionary" />
      </site>
    </language>
    <language code="tt" name="Татарча/Tatarça" localname="Tatar">
      <site>
        <site url="http://tt.wikipedia.org" dbname="ttwiki" code="wiki" />
        <site url="http://tt.wiktionary.org" dbname="ttwiktionary" code="wiktionary" />
        <site url="http://tt.wikibooks.org" dbname="ttwikibooks" code="wikibooks" />
        <site url="http://tt.wikiquote.org" dbname="ttwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="tum" name="chiTumbuka" localname="Tumbuka">
      <site>
        <site url="http://tum.wikipedia.org" dbname="tumwiki" code="wiki" />
      </site>
    </language>
    <language code="tw" name="Twi" localname="Twi">
      <site>
        <site url="http://tw.wikipedia.org" dbname="twwiki" code="wiki" />
        <site url="http://tw.wiktionary.org" dbname="twwiktionary" code="wiktionary" closed="" />
      </site>
    </language>
    <language code="ty" name="Reo Mā`ohi" localname="Tahitian">
      <site>
        <site url="http://ty.wikipedia.org" dbname="tywiki" code="wiki" />
      </site>
    </language>
    <language code="udm" name="Удмурт" localname="Udmurt">
      <site>
        <site url="http://udm.wikipedia.org" dbname="udmwiki" code="wiki" />
      </site>
    </language>
    <language code="ug" name="ئۇيغۇرچە / Uyghurche‎" localname="Uighur">
      <site>
        <site url="http://ug.wikipedia.org" dbname="ugwiki" code="wiki" />
        <site url="http://ug.wiktionary.org" dbname="ugwiktionary" code="wiktionary" />
        <site url="http://ug.wikibooks.org" dbname="ugwikibooks" code="wikibooks" closed="" />
        <site url="http://ug.wikiquote.org" dbname="ugwikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="uk" name="Українська" localname="Ukrainian">
      <site>
        <site url="http://uk.wikipedia.org" dbname="ukwiki" code="wiki" />
        <site url="http://uk.wiktionary.org" dbname="ukwiktionary" code="wiktionary" />
        <site url="http://uk.wikibooks.org" dbname="ukwikibooks" code="wikibooks" />
        <site url="http://uk.wikinews.org" dbname="ukwikinews" code="wikinews" />
        <site url="http://uk.wikiquote.org" dbname="ukwikiquote" code="wikiquote" />
        <site url="http://uk.wikisource.org" dbname="ukwikisource" code="wikisource" />
      </site>
    </language>
    <language code="ur" name="اردو" localname="Urdu">
      <site>
        <site url="http://ur.wikipedia.org" dbname="urwiki" code="wiki" />
        <site url="http://ur.wiktionary.org" dbname="urwiktionary" code="wiktionary" />
        <site url="http://ur.wikibooks.org" dbname="urwikibooks" code="wikibooks" />
        <site url="http://ur.wikiquote.org" dbname="urwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="uz" name="O&#039;zbek" localname="Uzbek">
      <site>
        <site url="http://uz.wikipedia.org" dbname="uzwiki" code="wiki" />
        <site url="http://uz.wiktionary.org" dbname="uzwiktionary" code="wiktionary" />
        <site url="http://uz.wikibooks.org" dbname="uzwikibooks" code="wikibooks" />
        <site url="http://uz.wikiquote.org" dbname="uzwikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="ve" name="Tshivenda" localname="Venda">
      <site>
        <site url="http://ve.wikipedia.org" dbname="vewiki" code="wiki" />
      </site>
    </language>
    <language code="vec" name="Vèneto" localname="Vèneto">
      <site>
        <site url="http://vec.wikipedia.org" dbname="vecwiki" code="wiki" />
        <site url="http://vec.wikisource.org" dbname="vecwikisource" code="wikisource" />
      </site>
    </language>
    <language code="vi" name="Tiếng Việt" localname="Vietnamese">
      <site>
        <site url="http://vi.wikipedia.org" dbname="viwiki" code="wiki" />
        <site url="http://vi.wiktionary.org" dbname="viwiktionary" code="wiktionary" />
        <site url="http://vi.wikibooks.org" dbname="viwikibooks" code="wikibooks" />
        <site url="http://vi.wikiquote.org" dbname="viwikiquote" code="wikiquote" />
        <site url="http://vi.wikisource.org" dbname="viwikisource" code="wikisource" />
      </site>
    </language>
    <language code="vls" name="West-Vlams" localname="West-Vlams">
      <site>
        <site url="http://vls.wikipedia.org" dbname="vlswiki" code="wiki" />
      </site>
    </language>
    <language code="vo" name="Volapük" localname="Volapük">
      <site>
        <site url="http://vo.wikipedia.org" dbname="vowiki" code="wiki" />
        <site url="http://vo.wiktionary.org" dbname="vowiktionary" code="wiktionary" />
        <site url="http://vo.wikibooks.org" dbname="vowikibooks" code="wikibooks" />
        <site url="http://vo.wikiquote.org" dbname="vowikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="wa" name="Walon" localname="Walloon">
      <site>
        <site url="http://wa.wikipedia.org" dbname="wawiki" code="wiki" />
        <site url="http://wa.wiktionary.org" dbname="wawiktionary" code="wiktionary" />
        <site url="http://wa.wikibooks.org" dbname="wawikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="war" name="Winaray" localname="Waray">
      <site>
        <site url="http://war.wikipedia.org" dbname="warwiki" code="wiki" />
      </site>
    </language>
    <language code="wo" name="Wolof" localname="Wolof">
      <site>
        <site url="http://wo.wikipedia.org" dbname="wowiki" code="wiki" />
        <site url="http://wo.wiktionary.org" dbname="wowiktionary" code="wiktionary" />
        <site url="http://wo.wikiquote.org" dbname="wowikiquote" code="wikiquote" />
      </site>
    </language>
    <language code="wuu" name="吴语" localname="Wu">
      <site>
        <site url="http://wuu.wikipedia.org" dbname="wuuwiki" code="wiki" />
      </site>
    </language>
    <language code="xal" name="Хальмг" localname="Kalmyk">
      <site>
        <site url="http://xal.wikipedia.org" dbname="xalwiki" code="wiki" />
      </site>
    </language>
    <language code="xh" name="isiXhosa" localname="Xhosa">
      <site>
        <site url="http://xh.wikipedia.org" dbname="xhwiki" code="wiki" />
        <site url="http://xh.wiktionary.org" dbname="xhwiktionary" code="wiktionary" closed="" />
        <site url="http://xh.wikibooks.org" dbname="xhwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="xmf" name="მარგალური" localname="Mingrelian">
      <site>
        <site url="http://xmf.wikipedia.org" dbname="xmfwiki" code="wiki" />
      </site>
    </language>
    <language code="yi" name="ייִדיש" localname="Yiddish">
      <site>
        <site url="http://yi.wikipedia.org" dbname="yiwiki" code="wiki" />
        <site url="http://yi.wiktionary.org" dbname="yiwiktionary" code="wiktionary" />
        <site url="http://yi.wikisource.org" dbname="yiwikisource" code="wikisource" />
      </site>
    </language>
    <language code="yo" name="Yorùbá" localname="Yoruba">
      <site>
        <site url="http://yo.wikipedia.org" dbname="yowiki" code="wiki" />
        <site url="http://yo.wiktionary.org" dbname="yowiktionary" code="wiktionary" closed="" />
        <site url="http://yo.wikibooks.org" dbname="yowikibooks" code="wikibooks" closed="" />
      </site>
    </language>
    <language code="za" name="Vahcuengh" localname="Zhuang">
      <site>
        <site url="http://za.wikipedia.org" dbname="zawiki" code="wiki" />
        <site url="http://za.wiktionary.org" dbname="zawiktionary" code="wiktionary" />
        <site url="http://za.wikibooks.org" dbname="zawikibooks" code="wikibooks" closed="" />
        <site url="http://za.wikiquote.org" dbname="zawikiquote" code="wikiquote" closed="" />
      </site>
    </language>
    <language code="zea" name="Zeêuws" localname="Zeeuws">
      <site>
        <site url="http://zea.wikipedia.org" dbname="zeawiki" code="wiki" />
      </site>
    </language>
    <language code="zh" name="中文" localname="Chinese">
      <site>
        <site url="http://zh.wikipedia.org" dbname="zhwiki" code="wiki" />
        <site url="http://zh.wiktionary.org" dbname="zhwiktionary" code="wiktionary" />
        <site url="http://zh.wikibooks.org" dbname="zhwikibooks" code="wikibooks" />
        <site url="http://zh.wikinews.org" dbname="zhwikinews" code="wikinews" />
        <site url="http://zh.wikiquote.org" dbname="zhwikiquote" code="wikiquote" />
        <site url="http://zh.wikisource.org" dbname="zhwikisource" code="wikisource" />
      </site>
    </language>
    <language code="zh-cfr" name="">
      <site />
    </language>
    <language code="zh-classical" name="文言" localname="Classical Chinese">
      <site>
        <site url="http://zh-classical.wikipedia.org" dbname="zh-classicalwiki" code="wiki" />
      </site>
    </language>
    <language code="zh-min-nan" name="Bân-lâm-gú" localname="Bân-lâm-gú">
      <site>
        <site url="http://zh-min-nan.wikipedia.org" dbname="zh-min-nanwiki" code="wiki" />
        <site url="http://zh-min-nan.wiktionary.org" dbname="zh-min-nanwiktionary" code="wiktionary" />
        <site url="http://zh-min-nan.wikibooks.org" dbname="zh-min-nanwikibooks" code="wikibooks" />
        <site url="http://zh-min-nan.wikiquote.org" dbname="zh-min-nanwikiquote" code="wikiquote" />
        <site url="http://zh-min-nan.wikisource.org" dbname="zh-min-nanwikisource" code="wikisource" />
      </site>
    </language>
    <language code="zh-yue" name="粵語" localname="Cantonese">
      <site>
        <site url="http://zh-yue.wikipedia.org" dbname="zh-yuewiki" code="wiki" />
      </site>
    </language>
    <language code="zu" name="isiZulu" localname="Zulu">
      <site>
        <site url="http://zu.wikipedia.org" dbname="zuwiki" code="wiki" />
        <site url="http://zu.wiktionary.org" dbname="zuwiktionary" code="wiktionary" />
        <site url="http://zu.wikibooks.org" dbname="zuwikibooks" code="wikibooks" closed="" />
      </site>
    </language>
  </sitematrix>
</api>
