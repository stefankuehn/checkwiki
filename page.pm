package page;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.01';


sub new
{
   
	# create wikipage
    my ($class) = @_;
    my $self = {};
    $self->{_project}   	= undef;		# dewiki
	$self->{_pageid}  		= undef;		# 12345
    $self->{_search_title}  = undef;		# Eduard_Imhof  (not normalized)
	$self->{_title}  		= undef;		# Eduard Imhof
    $self->{_row_page}     	= undef;		# <page .. </page>
    $self->{_row_text}     	= undef;		# '''Eduard Imhof'' is cartograher ...
	$self->{_namespace} 	= undef;		# 0
	$self->{_timestamp}		= undef;		# 2012-02-14T15:22:02Z
 	#$self->{_interwiki}     = undef;		# de:Edu  fr:Edu
    bless ($self, $class);
    return $self;
}


#accessor method for project
sub project {
    my ( $self, $project ) = @_;
    $self->{_project} = $project if defined($project);
    return ( $self->{_project} );
}

#accessor method for pageid
sub pageid {
    my ( $self, $pageid ) = @_;
    $self->{_pageid} = $pageid if defined($pageid);
    return ( $self->{_pageid} );
}

#accessor method for title
sub search_title {
    my ( $self, $search_title ) = @_;
    $self->{_search_title} = $search_title if defined($search_title);
    return ( $self->{_search_title} );
}

#accessor method for title
sub title {
    my ( $self, $title ) = @_;
    $self->{_title} = $title if defined($title);
    return ( $self->{_title} );
}

#accessor method for row_page
sub row_page {
    my ( $self, $row_page ) = @_;
    $self->{_row_page} = $row_page if defined($row_page);
    return ( $self->{_row_page} );
}

#accessor method for row_text
sub row_text {
    my ( $self, $row_text ) = @_;
    $self->{_row_text} = $row_text if defined($row_text);
    return ( $self->{_row_text} );
}

#accessor method for namespace
sub namespace {
    my ( $self, $namespace ) = @_;
    $self->{_namespace} = $namespace if defined($namespace);
    return ( $self->{_namespace} );
}

#accessor method for timestamp
sub timestamp {
    my ( $self, $timestamp ) = @_;
    $self->{_timestamp} = $timestamp if defined($timestamp);
    return ( $self->{_timestamp} );
}


1;

