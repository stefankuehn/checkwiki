package wiki;


use strict;
use warnings;
use 5.010;
use Data::Dumper;

our $VERSION = '0.01';

use page;
use URI::Escape;
use HTML::Entities;

sub new
{
   
	# create wikiproject
    my ($class) = @_;
    my $self = {};
    $self->{_project}   	= undef;		# dewiki
	$self->{_language}  	= undef;		# de
    $self->{_url}       	= undef;		# http://de.wikipedia.org
	$self->{_name}  		= undef;		# Deutsch
 	$self->{_name_en}       = undef;		# German
 	$self->{_site_code}     = undef;		# wiki, wiktionary, ...
 	$self->{_site_close}	= undef;		# closed="" 0/1
 	$self->{_private}  	    = undef;		# private=""
	$self->{_api}			= undef;		# http://de.wikipedia.org/w/api.php
	$self->{_mainpage}		= undef;		# http://de.wikipedia.org/wiki/Wikipedia:Hauptseite
    bless ($self, $class);
    return $self;
}


#accessor method for _project
sub project {
    my ( $self, $project ) = @_;
    $self->{_project} = $project if defined($project);
    return ( $self->{_project} );
}


#accessor method for _language
sub language {
    my ( $self, $language ) = @_;
    $self->{_language} = $language if defined($language);
    return ( $self->{_language} );
}

#accessor method for _url
sub url {
    my ( $self, $url ) = @_;
    $self->{_url} = $url if defined($url);
    return ( $self->{_url} );
}

#accessor method for _name
sub name {
    my ( $self, $name ) = @_;
    $self->{_name} = $name if defined($name);
    return ( $self->{_name} );
}

#accessor method for _name_en
sub name_en {
    my ( $self, $name_en ) = @_;
    $self->{_name_en} = $name_en if defined($name_en);
    return ( $self->{_name_en} );
}

#accessor method for site_code
sub site_code {
    my ( $self, $site_code ) = @_;
    $self->{_site_code} = $site_code if defined($site_code);
    return ( $self->{_site_code} );
}

#accessor method for site_close
sub site_close {
    my ( $self, $site_close ) = @_;
    $self->{_site_close} = $site_close if defined($site_close);
    return ( $self->{_site_close} );
}

#accessor method for private
sub private {
    my ( $self, $private ) = @_;
    $self->{_private} = $private if defined($private);
    return ( $self->{_private} );
}

#accessor method for api
sub api {
    my ( $self, $api ) = @_;
    $self->{_api} = $api if defined($api);
    return ( $self->{_api} );
}

#accessor method for mainpage
sub mainpage {
    my ( $self, $mainpage ) = @_;
    $self->{_mainpage} = $mainpage if defined($mainpage);
    return ( $self->{_mainpage} );
}



####################################################################
# More methods
####################################################################

sub print_project_info {
    my( $self ) = @_;
	print 'Project:'."\t";
	print $self->project if defined($self->project);
	print "\n";

	print 'Language:'."\t";
	print $self->language if defined($self->language);
	print "\n";


	return $self;
}



sub load_metadata{
	#http://de.wikipedia.org/w/api.php?action=query&meta=siteinfo&siprop=general|namespaces|namespacealiases|statistics|magicwords
	my( $self ) = @_;
	my $url = $self->api.'?&action=query&meta=siteinfo&siprop=general|namespaces|namespacealiases|statistics|magicwords&format=xml';
	print $url."\n";
}



sub load_pages_api{
	my( $self, @page_list ) = @_;


	# generate URL
	#http://de.wikipedia.org/w/api.php?action=query&prop=revisions&titles=Eduard%20Imhof|Kjelfossen&rvprop=timestamp|content	
	my $titles = join('|', @page_list);
	print $titles."\n";
	my $encode_titles = uri_escape($titles);	# URL ' ' -> %20 
	#print $encode_titles."\n";
	my $url = $self->api.'?action=query&prop=revisions&titles='.$encode_titles.'&rvprop=timestamp|content&format=xml';
	print $url."\n";
	

	# get XML via API
	my $ua = LWP::UserAgent->new;			# http://search.cpan.org/~gaas/libwww-perl-6.03/lib/LWP/UserAgent.pm
	$ua->timeout(60);						# timeout for request
	my $response = '';
	$response = $ua->get( $url );	
	my $result  = '';
	
	my %page_hash;	
	if ($response -> is_success) {			# maybe no internet
		my $content = $response->content;	# http://search.cpan.org/~gaas/HTTP-Message-6.02/lib/HTTP/Response.pm
		$result = $content if ($content) ;	

		#print $result."\n";
		print 'Gesamtlänge:'.length($result)."\n";

		$result =~ s/^.*<pages>//;
		$result =~ s/<\/pages>.*//;
		my @all_pages = split (/<page /, $result);
		shift(@all_pages);
		foreach my $text_result (@all_pages) {
			$text_result = '<page '.$text_result;
			print 'text:'.length($text_result)."\n";

						
			#get title			
			$text_result =~ /title="(.*?)"/;
			my $title = $1;
			decode_entities($title);		# with HTML::Entities 
			print 'result: '.$title."\n";

			#get pageid
			my $pageid = 0;			
			if ($text_result =~ /pageid="(.*?)"/ ) {
				$pageid = $1;
			}

			#get namespace
			$text_result =~ /ns="(.*?)"/;
			my $namespace = $1;

			#get timestamp of revision			
			my $timestamp = '';			
			if ($text_result =~ /<rev timestamp="(.*?)"/ ) {
				$timestamp = $1;
			}

			#get text 		
			my $text = '';			
			if ($text_result =~ /<rev (?:.)*?>((.|\n)*?)<\/rev>/ ) {
				$text = decode_entities($1);
				#$text = $1;
				
			}
			
			#print substr($text, 100)."\n";
			my $new_page = page->new();
			$new_page->project($self->project);
			$new_page->pageid($pageid);
			$new_page->title($title);
			$new_page->row_page($text_result);
			$new_page->namespace($namespace);
			$new_page->timestamp($timestamp);	# ref_timestamp, evt. noch einen load_timestamp
			$new_page->row_text($text);

			$page_hash{$title} = \$new_page;
		}
	}
	return(\%page_hash)
}

