#!/usr/local/bin/perl -w

#################################################################
# Program:	checkwiki.pl
# Descrition:	Scan all pages of a Wikipedia-Project (dump or live) for errors
# Author:	Stefan Kühn
# Version:	2011-11-27
# Licence: GPL
#################################################################

#################################################################
# Syntax
# perl -w checkwiki.pl -p=enwiki m=live
#################################################################

# New features, last changes and discussion
# http://de.wikipedia.org/wiki/Benutzer:Stefan_Kühn/Check_Wikipedia

#################################################################

# Error exception
$SIG{__DIE__} = \&die_error;
$SIG{__WARN__} = \&warn_error;
use strict;
use warnings;

#################################################################

# notice
# delete_old_errors_in_db  --> Problem with deleting of errors in loadmodus
# delete_deleted_article_from_db --> Problem old articles

	
	#################################################################
	# Load Module
	#################################################################
	#use lib "C:/perl/lib";
	
	use URI::Escape;
	use LWP::UserAgent;
	
	#use CGI::Carp qw(fatalsToBrowser);

	#use lib '/home/sk/perl/checkwiki';
	#our $file_module_coordinate = 'coordinates.pm';
	#if (-e $file_module_coordinate) {
		#use coordinates ;
	#}
	# use new_coordinates;

	
	#use lib '../module';
	#use wikipedia;
	
	#use URI::Escape;
	#use LWP::UserAgent;

	#################################################################
	# declare_global_directorys
	#################################################################
	our $dump_directory		    = '/mnt/user-store/dumps/';		# toolserver
	# our $dump_directory	= '../../dump/';	# home or usb
	
	our $output_directory		= '/mnt/user-store/sk/data/checkwiki/';
	our $input_directory_new 	= '/mnt/user-store/sk/data/new_article/';
	our $input_directory_change = '/mnt/user-store/sk/data/last_changes/';
	our $output_templatetiger   = '/mnt/user-store/sk/data/templatetiger/';
	our $output_geo				= '/mnt/user-store/sk/data/geo/';
	
	#our $dump_filename  = '/mnt/user-store/dump/dewiki-20080607-pages-articles.xml'; #'Wikipedia-20080502083556.xml';
	our $dump_filename  = '';
	#$dump_filename ='../../dump/dewiki-20071217-pages-articles.xml';

	#################################################################
	# Declaration of variables (global)
	#################################################################
	
	our $quit_program			= 'no';		# quit the program (yes,no), for quit the programm in an emergency
	our $quit_reason			= '';		# quit the program reason
	our $test_programm 			= 'true';	# only for program tests
	
	our $dump_or_live   		= '';		# scan modus (dump, live, only)
	our $silent_modus   		= '';		# silent modus (very low output at screen) for batch 
	our $test_modus   			= '';		# silent modus (very low output at screen) for batch 

	our $starter_modus			= '';		# to update in the loadmodus the cw_starter table
	our $load_modus_done		= 'yes';	# done article from db
	our $load_modus_new			= 'yes';	# new article from db
	our $load_modus_dump		= 'yes';	# new article from db
	our $load_modus_last_change = 'yes';	# last_change article from db
	our $load_modus_old			= 'yes';	# old article from db
	
	
	our $details_for_page		= 'no';		# yes/no 	durring the scan you can get more details for a article scan


	our $time_start				= time();	# start timer in secound
	our $time_end				= time();	# end time in secound
	our $date					= 0;		# date of dump "20060324"

	our $line_number			= 0;		# number of line in dump
	our $project				= '';		# name of the project 'dewiki'
	our $language				= '';		# language of dump 'de', 'en'; 
	our $page_number			= 0;		# number of pages in namesroom 0
	our $base 					= '';		# base of article, 'http://de.wikipedia.org/wiki/Hauptseite'
	our $home					= '';		# base of article, 'http://de.wikipedia.org/wiki/'
	
	our @namespace;							# namespace values
											# 0 number
											# 1 namespace in project language
											# 2 namespace in english language
	our	$namespaces_count		= -1;		# number of namespaces		

	our @namespacealiases;					# namespacealiases values
											# 0 number
											# 1 namespacealias	
	our	$namespacealiases_count= -1;		# number of namespacealiases	
	
	our @namespace_cat;						#all namespaces for categorys
	our @namespace_image;					#all namespaces for images
	our @namespace_templates;				#all namespaces for templates
	
	our @magicword_defaultsort;
	
	our @magicword_img_thumbnail;
	our @magicword_img_manualthumb;
	our @magicword_img_right;
	our @magicword_img_left;
	our @magicword_img_none;
	our @magicword_img_center;
	our @magicword_img_framed;
	our @magicword_img_frameless;
	our @magicword_img_page;
	our @magicword_img_upright;
	our @magicword_img_border;
	our @magicword_img_sub;
	our @magicword_img_super;
	our @magicword_img_link;
	our @magicword_img_alt;
	our @magicword_img_width;
	our @magicword_img_baseline;
	our @magicword_img_top;
	our @magicword_img_text_top;
	our @magicword_img_middle;
	our @magicword_img_bottom;
	our @magicword_img_text_bottom;
	
											
	# Wiki-special variables
	
	our @live_article;						# to-do-list for live (all articles to scan)
	our $current_live_article	= -1;		# line_number_of_current_live_article
	our $number_of_live_tests 	= -1;		# Number of articles for live test

	our $current_live_error_scan = -1;		# for scan every 100 article of an error
	our @live_to_scan ;						# article of one error number which should be scanned
	our $number_article_live_to_scan = -1;	# all article from one error
	our @article_was_scanned;				#if an article was scanned, this will insert here

	our $xml_text_from_api = '';				# the text from more then one articles from the API
	
	our $error_counter 			= -1;		# number of found errors in all article

	our @error_description;					# Error Description
											# 0 priority in script
											# 1 title in English
											# 2 description in English
											# 3 number of found (only live scanned)
											# 4 priority of foreign language
											# 5 title in foreign language
											# 6 description in foreign language
											# 7 number of found in last scan (from statistic file)
											# 8 all known errors (from statistic file + live)
											# 9  XHTML translation title
											# 10 XHTML translation description

	our $number_of_error_description = -1;	# number of error_description		

	
	our $max_error_count = 50;				# maximum of shown article per error
	our $maximum_current_error_scan = -1;	# how much shold be scanned for reach the max_error_count
	our $rest_of_errors_not_scan_yet = '';
	our $number_of_all_errors_in_all_articles = 0;	#all errors
	
	our $for_statistic_new_article = 0;
	our $for_statistic_last_change_article = 0;
	our $for_statistic_geo_article = 0;
	our $for_statistic_number_of_articles_with_error = 0;
	


	###########################
	# files
	###########################
	our $live_filename  				= 'input_for_live.txt';
	our $output_live_wiki   			= 'output_for_wikipedia.txt';
	our $output_dump_wiki   			= 'output_for_wikipedia_dump.txt';
	our $error_list_filename 			= 'error_list.txt';
	our $error_list_filename_only 		= 'error_list_only.txt';
	our $error_list_filename_dump		= 'error_list_dump.txt';				#all errors from the last dump scan
	our $error_list_filename_backup		= 'error_list_dump_backup.txt';
	our $error_statistic_filename 		= 'error_statistic.txt';
	our $error_statistic_filename_only 	= 'error_statistic_only.txt';
	our $error_statistic_filename_list 	= 'error_statistic_list.txt';
	our $translation_file   			= 'translation.txt';
	our $error_list_filename_30 		= 'error_list_error_030.txt';
	our $error_list_filename_every 		= 'error_list_error';			# for all errors

	our $error_geo_list_filename 		= 'error_geo_list.txt';
	our $error_geo_list_filename_only 	= 'error_geo_list_only.txt';
	our $error_geo_list_filename_html	= 'error_geo_list.htm';
	our $error_geo_list_filename_only_html	= 'error_geo_list_only.htm';

	our $log_file						= 'log.txt';
	our $templatetiger_filename			= '';
	
	our @inter_list = ( 'af', 'als', 'an', 'ar',
						'bg', 'bs',
						'ca', 'cs', 'cy',
						'da', 'de',
						'el', 'en', 'eo', 'es', 'et', 'eu',
						'fa', 'fi', 'fr', 'fy',
						'gl', 'gv',
						'he', 'hi', 'hr', 'hu',
						'id', 'is', 'it',
						'ja', 'jv',
						'ka', 'ko',
						'la', 'lb', 'lt',
						'ms', 
						'nds', 'nds_nl', 'nl', 'nn', 'no',
						'pl', 'pt',
						'ro', 'ru',
						'sh', 'simple', 'sk', 'sl', 'sr', 'sv', 'sw',
						'ta', 'th', 'tr',
						'uk', 'ur',
						'vi', 'vo',
						'yi',
						'zh'
					);
	
	our @foundation_projects = ( 'wikibooks', 'b', 
								'wiktionary', 'wikt',
								'wikinews',  'n',
								'wikiquote', 'q',
								'wikisource', 's',
								'wikipedia', 'w',
								'wikispecies', 'species',
								'wikimedia', 'foundation', 'wmf',
								'wikiversity',	'v',
								'commons',
								'meta', 'metawikipedia', 	'm',
								'incubator',
								'mw',
								'quality',
								'bugzilla', 'mediazilla',
								'nost',
								'testwiki'
								);
	
	# current time
	our ($akSekunden, $akMinuten, $akStunden, $akMonatstag, $akMonat,
	    $akJahr, $akWochentag, $akJahrestag, $akSommerzeit) = localtime(time);
	our $CTIME_String = localtime(time);
	$akMonat 	= $akMonat + 1;
	$akJahr 	= $akJahr + 1900;	
	$akMonat   	= "0".$akMonat if ($akMonat<10);
	$akMonatstag = "0".$akMonatstag if ($akMonatstag<10);
	$akStunden 	= "0".$akStunden if ($akStunden<10);
	$akMinuten 	= "0".$akMinuten if ($akMinuten<10);
	
	
	our $translation_page = '';		# name of the page with translation for example in de:  "Wikipedia:WikiProject Check Wikipedia/Übersetzung"
	
	our $start_text = '';
	$start_text = $start_text ."The WikiProject '''Check Wikipedia''' will help to clean up the syntax of Wikipedia and to find some other errors.\n";
	$start_text = $start_text ."\n";
	$start_text = $start_text ."'''Betatest''' - At the moment the script has some bugs and not every error on this page is an actual error. \n";
	$start_text = $start_text ."\n";	
	
	
	our $description_text = '';
	$description_text = $description_text ."== Project description in English == \n";

	$description_text = $description_text ."* '''What is the goal of this project?'''\n";
	$description_text = $description_text ."** This project should help to clean up the data of all articles in many different languages.\n";
	$description_text = $description_text ."** If we have a clear and clean syntax in all articles more projects (for example: Wikipedia-DVD) can use our data more easily.\n";
	$description_text = $description_text ."** The project was inspired by [[:en:Wikipedia:WikiProject Wiki Syntax]].\n";
	$description_text = $description_text ."** In order to use the data of a Wikipedia project without the Mediawiki software you need to write a parser. If many articles include wrong syntax it is difficult to program the parser since it needs to be complex enough to recognize the syntax errors.\n";
	$description_text = $description_text ."** This project helps to find many errors in all kinds of language and will support many languages in the future. \n";
	$description_text = $description_text ."\n";

	$description_text = $description_text ."* '''How does it work?'''\n";
	$description_text = $description_text ."** The script scans every new [http://dumps.wikimedia.org dump] and creates a list of articles with errors.\n";
	$description_text = $description_text ."** The script scans all articles on the list on a daily basis to create a new list for users, omitting already-corrected articles.\n";
	$description_text = $description_text ."** The script is written in Perl by: [[:de:User:Stefan Kühn|Stefan Kühn]] "."\n";
	$description_text = $description_text ."** You can download the script [http://toolserver.org/~sk/checkwiki/checkwiki.pl here]. It is licensed under GPL."."\n";
	$description_text = $description_text ."** [[:de:User:Stefan Kühn/Check Wikipedia|New features, last changes and discussion]]. "."\n";
	$description_text = $description_text ."\n";

	$description_text = $description_text ."* '''What can you do?'''\n";
	$description_text = $description_text ."** The script creates a new error page at the toolserver every day. Please copy and paste the daily updated page at the toolserver (See downloads) to this page here. Attention: That page is a UTF-8 document. In case your browser cannot display the file in UTF-8 you can copy it into a text editor (for example: Notepad++) and convert it to UTF-8. \n";
	$description_text = $description_text ."** You can fix an error in one or more articles. \n";
	$description_text = $description_text ."** You can delete all fixed articles from this list. \n";
	$description_text = $description_text ."** If all articles in one category have been fixed you can delete this category. \n";
	$description_text = $description_text ."** You can suggest a new category of errors to the author of the script. \n";
	$description_text = $description_text ."** You can also inform the author if you want this project to be implemented into your language's Wikipedia. \n";
	$description_text = $description_text ."\n";

	$description_text = $description_text ."* '''Please don't… '''\n";
	$description_text = $description_text ."** insert an article by hand since it will disappear from the list with the next automatic update of this page. \n";
	$description_text = $description_text ."** try to fix spelling mistakes within this page since all manual changes will disappear as well with the next update. Instead, send an e-mail or message to the author so he can fix the spelling in the script. \n";
	$description_text = $description_text ."\n";
	
	
	our $category_text = '';	
	
	our $top_priority_script = 'Top priority';
	our $top_priority_project = '';
	our $middle_priority_script = 'Middle priority';
	our $middle_priority_project = '';
	our $lowest_priority_script = 'Lowest priority';
	our $lowest_priority_project = '';

	
	our $dbh; 	# DatenbaaseHandler
	
	
	
	###############################
	# variables for one article
	###############################
		$page_number 	= $page_number + 1;
	our $title					= '';		# title of the current article
	our $page_id				= -1;		# page id of the current article
	our $revision_id			= -1;		# revision id of the current article
	our $revision_time			= -1;		# revision time of the current article
	our $text					= '';		# text of the current article  (for work)
	our $text_origin			= '';		# text of the current article origin (for save)
	our $text_without_comments  = '';		# text of the current article without_comments (for save)
	

	our	$page_namespace			= -100;		# namespace of page
	our $page_is_redirect   	= 'no';			
	our $page_is_disambiguation = 'no';

	our $page_categories 		= '';
	our $page_interwikis 		= '';

	our $page_has_error 		= 'no';		# yes/no 	error in this page
	our $page_error_number		= -1;		# number of all article for this page

	our @comments;							# 0 pos_start
											# 1 pos_end
											# 2 comment
	our $comment_counter		= -1;		#number of comments in this page 
	
	our @category;							# 0 pos_start
											# 1 pos_end
											# 2 category	Test		
											# 3 linkname	Linkname
											# 4 original	[[Category:Test|Linkname]]
											
	our $category_counter		= -1;
	our $category_all			= '';		# all categries

	our @interwiki;							# 0 pos_start
											# 1 pos_end
											# 2 interwiki	Test		
											# 3 linkname	Linkname
											# 4 original	[[de:Test|Linkname]]
											# 5 language
											
	our $interwiki_counter		= -1;

	our @lines;								# text seperated in lines 
	our @headlines;							# headlines
	our @section;							# text between headlines
	undef(@section);
	
	our @lines_first_blank;					# all lines where the first character is ' '
	
	our @templates_all;						# all templates
	our @template;							# templates with values
											# 0 number of template
											# 1 templatename
											# 2 template_row
											# 3 attribut
											# 4 value
	our $number_of_template_parts = -1;		# number of all template parts													
											
	our @links_all;							# all links
	our @images_all;						# all images
	our @isbn;								# all ibsn of books
	our @ref;								# all ref

	our $page_has_geo_error 	= 'no';		# yes/no 	geo error in this page
	our $page_geo_error_number  = -1;		# number of all article for this page
	
	our $end_of_dump = 'no';				# when last article from dump scan then 'yes', else 'no'
	our $end_of_live = 'no';				# when last article from live scan then 'yes', else 'no'

	
	


	check_input_arguments();
	open_db();
	open_file() 							if ($quit_program eq 'no');			# logfile, dumpfile,  metadata (API, File)
	
	get_error_description()					if ($quit_program eq 'no');			# all errordescription from this script
	load_text_translation() 				if ($quit_program eq 'no');			# load translation from wikipage 
	output_errors_desc_in_db() 				if ($quit_program eq 'no');			# update the database with newest error description
	output_text_translation_wiki()  		if ($quit_program eq 'no');			# output the new wikipage for translation
	
	load_article_for_live_scan()  			if ($quit_program eq 'no');			# only for live
	scan_pages() 							if ($quit_program eq 'no');			# scan all aricle
	close_file();																# close dump or templatetiger-file
	
	update_table_cw_error_from_dump()		if ($quit_program eq 'no');
	delete_deleted_article_from_db()		if ($quit_program eq 'no');			
	delete_article_from_table_cw_new()		if ($quit_program eq 'no');			
	delete_article_from_table_cw_change()	if ($quit_program eq 'no');			
	update_table_cw_starter();
	
	#output_errors() 						if ($quit_program eq 'no');
	output_little_statistic()				if ($quit_program eq 'no');			# print counter of found errors
	output_duration() 						if ($quit_program eq 'no');			# print time at the end

	print $quit_reason 						if ($quit_reason  ne ''); 

	close_db();
	close_logfile();
	print 'finish'."\n";
	

	#################################################################
	#################################################################
	#################################################################
	#################################################################
	#################################################################


sub get_time_string{
	my ($aakSekunden, $aakMinuten, $aakStunden, $aakMonatstag, $aakMonat,
	    $aakJahr, $aakWochentag, $aakJahrestag, $aakSommerzeit) = localtime(time);
	$aakMonat 	= $aakMonat + 1;
	$aakJahr 	= $aakJahr + 1900;	
	$aakMonat   	= "0".$aakMonat if ($aakMonat<10);
	$aakMonatstag = "0".$aakMonatstag if ($aakMonatstag<10);
	$aakStunden 	= "0".$aakStunden if ($aakStunden<10);
	$aakMinuten 	= "0".$aakMinuten if ($aakMinuten<10);
	$aakSekunden    = "0".$aakSekunden if ($aakSekunden<10);
	my $result = $aakJahr.$aakMonat.$aakMonatstag.' '.$aakStunden.$aakMinuten.$aakSekunden;
	return($result);
}

sub check_input_arguments{
	#################################################################
	# Declaration of parameters (extern)
	#################################################################
	if ( @ARGV < 1) {
		# no parameters
		$quit_reason = $quit_reason. 'no parameters'."\n\n";
		$quit_program = 'yes';
	}
	###################
	#check argument value for project
	my $found_argv = 'no';
	foreach (@ARGV) {
		my $current_argv = $_;
		if ( index($current_argv, 'p=') == 0) {
			$found_argv = 'yes';
			$project 	  =	$current_argv;
			$project	  =~ s/^p=//;
			$language	  = $project;
			$language	  =~ s/source$//;
			$language	  =~ s/wiki$//;
			
		}
	}
	if ($found_argv eq 'no'){
		# no project name
		$quit_reason = $quit_reason. 'no project name, for example: "p=dewiki"'."\n\n";
		$quit_program = 'yes';
	}
	
	####################
	#check argument value for scanmodus
	$found_argv = 'no';
	foreach (@ARGV) {
		my $current_argv = $_;
		if (   $current_argv eq 'm=dump'
			or $current_argv eq 'm=live'
			or $current_argv eq 'm=only' ) 
		{
			$found_argv = 'yes';
			$dump_or_live = $current_argv;
			$dump_or_live =~ s/^m=//;
		}
	}
	if ($found_argv eq 'no'){
		#no scan modus
		$quit_reason = $quit_reason. 'modus unknown, for example: "m=dump/live/only"'."\n\n";
		$quit_program = 'yes';
	} 
	
	####################
	#check argument value for silent or test
	$found_argv = 'no';
	foreach (@ARGV) {
		my $current_argv = $_;
		#print $current_argv."\n";
		$silent_modus = 'silent'              if ( $current_argv eq 'silent' );
		$test_modus   = 'test'                if ( $current_argv eq 'test');
		$starter_modus   = 'starter'          if ( $current_argv eq 'starter');
		
		if ( index($current_argv,'load=')==0 and $dump_or_live eq 'live' ) {
			#print 'loadmodus'."\n";
			#print "\t".'Load_modus='.$current_argv."\n";
			$load_modus_done		= 'no' if (index($current_argv, 'done')        == -1) ;		# done article from db
			$load_modus_new			= 'no' if (index($current_argv, 'new')         == -1) ;		# new article from db
			$load_modus_dump		= 'no' if (index($current_argv, 'dump')        == -1) ;		# new article from db
			$load_modus_last_change = 'no' if (index($current_argv, 'last_change') == -1) ;		# last_change article from db
			$load_modus_old			= 'no' if (index($current_argv, 'old')         == -1) ;		# old article from db
			
			

		}
	}
	
	if ($quit_program eq 'yes'){
		#End of Script, because no correct parameter
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
		
	} else {
	
		# All parameters available and correct
		# extract parameters 

		print "\n";
		if ($silent_modus ne 'silent') {
			print '##################################################'."\n";
			print '########    checkwiki.pl - Version 0.21    ########'."\n";
			
		}
			print '##################################################'."\n";
			print 'Start:  '."\t\t".$akJahr.'-'.$akMonat.'-'.$akMonatstag.' '.$akStunden.':'.$akMinuten."\n";
			print 'Project:'."\t\t". $project."\n";
		if ($silent_modus ne 'silent') {
			print 'Modus:  '."\t\t". $dump_or_live. ' (';
			print 'scan a dump' 					if ($dump_or_live eq 'dump');
			print 'scan live'   					if ($dump_or_live eq 'live');
			print 'scan a dump only some errors'	if ($dump_or_live eq 'only');
			print ')'."\n";
		}
		
		if ($test_modus eq 'test') {			#modus only for test
			$project = $project.'_test';
			print "\t\t\t".'Test-Modus --> '.$project.'!!!'."\n";
		}
		
	}
	
	

}

sub open_db{
	#################################################################
	# DB
	#################################################################

	use DBI;
	#load password
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
	#print "-".$password."-\n";

	#Connect to database u_sk
	my $hostname = `hostname`;		# check PC-name
	print $hostname ."\n";
	if ( $hostname =~ 'kunopc'){
		$dbh = DBI->connect( 'DBI:mysql:u_sk_cw_p',							# local
							'sk',
							$password ,
							{
							  RaiseError => 1,
							  AutoCommit => 1
							}
						  ) or die "Database connection not made: $DBI::errstr" . DBI->errstr;
	} else {					  
		$dbh = DBI->connect( 'DBI:mysql:u_sk_yarrow:host=sql',				# Toolserver
							'sk',
							$password ,
							{
							  RaiseError => 1,
							  AutoCommit => 1
							}
						  ) or die "Database connection not made: $DBI::errstr" . DBI->errstr;
	}									  
						  
	$password = '';





}

sub close_db{
	# close database
	$dbh->disconnect();
}

sub close_logfile{
	# close logfile
	close (LOGFILE) if ($starter_modus	ne 'starter');
}

###################################################################################
sub get_error_description{
	# this subroutine check out the error description of all possible errors
	print 'Load all error description'."\n" if ($silent_modus ne 'silent');
	error_list('get_description');

	# count the number of error description
	
	$number_of_error_description = 1;		# first error is error with number 1
	while  (defined($error_description[$number_of_error_description][1]) ) {
		#print $number_of_error_description.' '. $error_description[$number_of_error_description][1]."\n";
		$number_of_error_description = $number_of_error_description + 1;
	}
	
	
	# set all known error description to a basic level
	for (my $i = 1; $i <= $number_of_error_description; $i++) {
		#$error_description[$i][0] = -1;				# set in error
		#$error_description[$i][1] = '';				# set in error
		#$error_description[$i][2] = '';				# set in error
		$error_description[$i][3] = 0;
		$error_description[$i][4] = -1;
		$error_description[$i][5] = '';
		$error_description[$i][6] = '';
		$error_description[$i][7] = 0;
		$error_description[$i][8] = 0;
		$error_description[$i][9] = '';
		$error_description[$i][10] = '';
	
	}
	my $output_number = $number_of_error_description -1;
	print $output_number .' error description in script'."\n" if ($silent_modus ne 'silent');
	

}




###################################################################################

sub open_file{
	# create subdirectory
	#print $output_directory.$project."\n";
	if (not (-e $output_directory.$project )) {
		print 'create directory:'."\t". $output_directory.$project."\n";
		#mkdir($output_directory.$project ,0777);
		system ('mkdir -p '.$output_directory.$project);
	}

	################################
	# open logfile
	my $log_filename = $output_directory.$project.'/'.$project.'_'.$log_file;
	open (LOGFILE, '+>'.$log_filename) if ($starter_modus	ne 'starter');
	
	
	
	################################
	# if new dump is available
	if ($dump_or_live eq 'dump') {
		$dump_filename = search_for_last_dump();
		print 'Dump_filename:'."\t\t".$dump_filename."\n" 	if ($silent_modus ne 'silent');
		
		
		my $last_dump_filename = $output_directory.$project.'/'.$project.'_last_dump_name.txt';
		print $last_dump_filename."\n";
		
		if (not (-e $last_dump_filename)) {
			# create the file if not exist
			system ('touch '.$last_dump_filename);
			print 'create last_dump_file:'."\t".$project.'_last_dump_name.txt'."\n";
			open (LAST_DUMP_NAME_FIRST, '+>'.$last_dump_filename);
			print LAST_DUMP_NAME_FIRST 'x';
			close(LAST_DUMP_NAME_FIRST);
		}
		
		#read the last name
		#print 'check old dumpname'."\n";
		open (LAST_DUMP_NAME, '<'.$last_dump_filename);
		my $last_dump_name_old = '';
		$last_dump_name_old = <LAST_DUMP_NAME>;
		#$last_dump_name_old = '' if not defined;
		$last_dump_name_old =~ s/\n//g;
		
		close(LAST_DUMP_NAME);
		
		#get date from dumpfile
		our $dump_date_for_output = $dump_filename;
		$dump_date_for_output =~ s/^[^\-]-//g;
		$dump_date_for_output =~ s/^[^0-9]+//g;
		$dump_date_for_output =~ s/[^0-9]+$//g;
		$dump_date_for_output = substr($dump_date_for_output,0,4).'-'.substr($dump_date_for_output,4,2).'-'.substr($dump_date_for_output,6,2);
		#print $dump_date_for_output."\n";

		
		if ($dump_filename ne $last_dump_name_old ) {
			# if not the newest dump then start dump scan
			print 'Last:    '."\t\t". $last_dump_name_old."\n";
			print 'Current: '."\t\t". $dump_filename."\n";
			open (LAST_DUMP_NAME, '>'.$last_dump_filename);
			print LAST_DUMP_NAME $dump_filename;
			close(LAST_DUMP_NAME);
			#print 'nice -n 5 perl -w checkwiki.pl p='.$project.' m=dump' ."\n";
	#		if ($dump_or_live eq 'live') {
	#			print "\n\n";
	#			system ('nice -n 5 perl -w checkwiki.pl p='.$project.' m=dump silent') ;
	#			print "\n\n";
	#		}
		}	
		
		#update last_dump time for project in database
		my $sql_text = "update cw_project set last_dump ='".$dump_date_for_output."' where project = '". $project ."';";
		my $sth = $dbh->prepare( $sql_text );
		$sth->execute;

		#delete old list of articles from last dumpscan in table cw_dumpscan
		my $sql_text2 = "delete from cw_dumpscan where project = '". $project ."';";
		$sth = $dbh->prepare( $sql_text2 );
		$sth->execute;
		


		
		
	}
	################################

	
	
	
	if ($dump_or_live eq 'dump' or $dump_or_live eq 'only') {
		

		#print "lsat=x".$dump_filename."x\n";
		

		# check for existens dump
		
		my $full_dump_path_filename = $dump_directory.$project.'/'.$dump_filename;
		#print $full_dump_path_filename."\n";

		if ($dump_filename ne '' and -e $full_dump_path_filename ) {
			#print 'Data:   '."\t\t"."$dump_directory$dump_filename\n"; 
			#open dump
			open(DUMP, "bzip2 -d -q <$full_dump_path_filename |");
			read_and_write_metadata_from_dump();
		} else {
			$quit_program = 'yes';
			$quit_reason = $quit_reason. "file '$full_dump_path_filename'". " don't exist!\n";
		}
		
		# Templatetiger
		$templatetiger_filename = $output_templatetiger.$project.'/'.$project.'_templatetiger.txt';
		if (not (-e $output_templatetiger.$project )) {
			print 'create new subdirectory'."\t".'templatetiger'."\n";
			system ('mkdir -p '.$output_templatetiger.$project);
		}
		if (-e $templatetiger_filename ) {
			print 'Delete '.$templatetiger_filename."\n";
			system ('rm -f '.$templatetiger_filename) ;
		}
		
		open (TEMPLATETIGER, '>>'.$templatetiger_filename);



		
		#GEO Export

		our $geo_export_filename = $output_geo.$project.'/'.$project.'_coordinates.txt';
		if (not (-e $output_geo.$project )) {
			print 'create new subdirectory'."\t".'geo'."\n";
			#mkdir($output_geo.$project ,0777);
			system ('mkdir -p '.$output_geo.$project);
		}
		if (-e $geo_export_filename ) {
			print 'Delete '.$geo_export_filename."\n";
			system ('rm -f '.$geo_export_filename) ;
		}		
	}
	
	# delete old error_list
	if ($quit_program eq 'no' ) {
		read_and_write_metadata_from_dump();
		load_metadata_from_file();

	}
}




sub search_for_last_dump {
	# search in dump_directory for the last XML-file of a project
	my $last_file ='';
	my @xml_files = glob($dump_directory.'/'.$project.'/*-pages-articles.xml.bz2');
	my $count_xml_files = @xml_files;
	
	for (my $i = 0; $i < $count_xml_files; $i++) {
		# List of all xml-files in dump_directory
		my $byte = -s $xml_files[$i];
		#print $xml_files[$i].' '.$byte."\n";
		$xml_files[$i] =~ s/(.)+\///g;
		
		my $project_test = $project;
		$project_test =~ s/_test$//;
		
		if ((   index($xml_files[$i], $project.'-')      == 0	# only this project
			 or index($xml_files[$i], $project_test.'-') == 0 )	#
			and $byte > 0 ) {							# only more then 0 bytes files
			#the last project dump (more then 0 byte)
			if ($xml_files[$i] =~ /^$project(_test)?-[0-9]/)  {
				#print "\t".$xml_files[$i]."\n";
				$last_file = $xml_files[$i];
			}
		}
	}

	if ($last_file eq '' and $dump_or_live ne 'live') {		# stop if dump scan , run if the program will scan live
		# No file found
		$quit_program = 'yes';
		$quit_reason = $quit_reason.$count_xml_files.' XML-files found in folder '.$dump_directory."\n";
		$quit_reason = $quit_reason.'Found no XML-file for project: '.$project."\n";
	}

	@xml_files = ();	# free memory
	return($last_file);
}

######################################################################
sub load_article_for_live_scan{

	if ($dump_or_live eq 'live' ) {
		# open list for live
		print 'Load article for live scan'."\n" if ($silent_modus ne 'silent');
		#print 'Data:   '."\t\t".$output_directory.$project.'/'.$project.'_'.$error_list_filename ."\n";
		if (not (-e $output_directory.$project.'/'.$project.'_'.$error_list_filename )){
			#$quit_program = 'yes';
			#$quit_reason = $quit_reason. "file:" .$output_directory.$project.'/'.$project.'_'.$error_list_filename. " don't exist!\n";
			#print 'file:' .$output_directory.$project.'/'.$project.'_'.$error_list_filename. " don't exist!\n";
			print 'create '.$output_directory.$project.'/'.$project.'_'.$error_list_filename. "\n";
			system ('touch '.$output_directory.$project.'/'.$project.'_'.$error_list_filename);

			
		} else {
			#read articles(live)

			new_article(250) 						if ($load_modus_new  eq 'yes'); 		# get 250 new article last days
			last_change_article(50)					if ($load_modus_last_change eq 'yes');	# get 10 change article last days
			get_done_article_from_database(250)		if ($load_modus_done eq 'yes'); 		# get 250 article which are set as done in the database
																								# which are not scan_live - NEW: with table cw_dumpscan
			get_oldest_article_from_database(250)	if ($load_modus_old eq 'yes');			# get 250 article which are the date of last_scan is very old (dump_scan)

			
			#old 
			#article_last_live_scan();				# get all article from last live scan, where the script found errors				
													# very long in many languages (maybe later)  			
													# replace with done articles
			#article_with_error_from_dump_scan(); 	# get all articles error from the last dump scan		
													# replace with article_with_error_from_dump_scan2
			#article_with_error_from_dump_scan2()	if ($load_modus_dump eq 'yes');			# get 250 articles of each error from the last dump scan, 

			#geo_error_article();					# get all articles with geo errors last days
			

			
			# sort all articles (new + live)
			@live_article = sort(@live_article);
			
			# delet all double/multi input article
			$number_of_live_tests = @live_article;
			#print $number_of_live_tests."\n";
			my @new_live_article;
			my @split_line;
			my @split_line_old;
			
			if ($number_of_live_tests > 0) {
				my $old_title = '';
				my $all_errors_of_this_article = '';
				my $i = -1;
				

				foreach (@live_article) {
					@split_line_old = @split_line;
					@split_line = split(/\t/, $_);
					my $current_title = $split_line[0];
					$split_line[1] =~ s/\n//;
					#print $current_title."\n";
					
					my $number_of_split_line = @split_line;
					if ($number_of_split_line != 2) {
						print 'Problem with input line:'."\n";
						print $_."\n";
						die;
					};
					
					if ($old_title ne $current_title
						and $old_title ne ''){
						#save old
						$i = $i+1;
						$new_live_article[$i] = $old_title."\t".$all_errors_of_this_article;
						$all_errors_of_this_article = '';
						#print "result:".$new_live_article[$i]."\n";
					}
					
					# check new
					if ($old_title eq $current_title) {
						#double
						$all_errors_of_this_article = $all_errors_of_this_article.', '.$split_line[1];
						#print 'double: '.$current_title."\t".$all_errors_of_this_article."\n";
					} else {
						$all_errors_of_this_article = $split_line[1];
						#print 'normal: '.$current_title."\t".$all_errors_of_this_article."\n";
					}
					$old_title = $current_title;
				}
				#save last
				$i = $i+1;
				$new_live_article[$i] = $old_title."\t".$all_errors_of_this_article;

				
				@live_article = @new_live_article;
				$number_of_live_tests = @live_article;
			}
			print "\t".$number_of_live_tests."\t".'all articles without double'."\n";	
			print LOGFILE 'articles without double'."\t".$number_of_live_tests."\n" if ($starter_modus	ne 'starter');
			@new_live_article = ();	# free memory
			@split_line = ();	# free memory
			#foreach (@live_article) {
			#	print LOGFILE $_."\n";
			#}
			#print LOGFILE 'END LIST'."\n\n";
			
			if ($number_of_live_tests == 0) {
				# if after this load in live_modus no article found, then end the scan
				$quit_program = 'yes';
				$quit_reason = $quit_reason. 'no article in scan list for live'."\n";
			}
			

			
		}
	}
}


sub article_last_live_scan{
	my $file_input_live = $output_directory.$project.'/'.$project.'_'.$error_list_filename;
	#print $file_input_live."\n";
	open(LIVE, "<$file_input_live");
	@live_article = <LIVE>;
	close (LIVE);
	$number_of_live_tests = @live_article;
	print "\t".$number_of_live_tests."\t".'articles last scan:'."\n";
	print LOGFILE 'articles last scan:'."\t".$number_of_live_tests."\n" if ($starter_modus	ne 'starter');
}



sub new_article{
	my $new_counter = 0;
	my $limit = $_[0];
	# oldest not scanned article
	# select distinct title from cw_new where scan_live = 0 and project = 'dewiki' and daytime >= (select daytime from cw_new where scan_live = 0 and project = 'dewiki' order by daytime limit 1) order by daytime limit 250;
	
	
	my $sql_text = "select distinct title from cw_new where scan_live = 0 and project = '".$project."'  and daytime >= (select daytime from cw_new where scan_live = 0 and project = '".$project."' order by daytime limit 1) order by daytime limit ".$limit.";";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text );
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
		}
		#print $result."\n";
		push(@live_article, $result."\t".'0' );
		$new_counter ++;
	}
	print "\t".$new_counter."\t".'articles new'."\n";
	print LOGFILE 'articles new:'."\t\t".$new_counter. "\n" if ($starter_modus	ne 'starter');
	$for_statistic_new_article = $new_counter;
}

sub new_article_old{
	# Load new articles
	my $file_new = $project.'_new_article.txt';
	my $file_input_new = $input_directory_new.$project.'/'.$file_new;
	my $limit = 250;
	#print $file_input_new."\n";
	my $new_counter = 0;
	if (-e $file_input_new) {
		#if existing
		open(INPUT_NEW, "<$file_input_new");
		do {
			my $line = <INPUT_NEW>;
			$line =~ s/\n$//g;
			my @split_line = split ( /\t/, $line);
			if ($new_counter < $limit) {
				push(@live_article, $split_line[1]."\t".'0' );
				#print $split_line[1]."\t".'0'."\n";
				$new_counter ++;
			}
		}
		until (eof(INPUT_NEW) == 1);	
		close (INPUT_NEW);
	}
	print "\t".$new_counter."\t".'articles new';
	print ' (no file: '.$file_new.' )' if not (-e $file_input_new);
	print "\n";
	print LOGFILE 'articles new:'."\t\t".$new_counter. "\n" if ($starter_modus	ne 'starter');
	$for_statistic_new_article = $new_counter;
}



sub last_change_article{
	my $change_counter = 0;
	my $limit = $_[0];
	# oldest not scanned article
	# select distinct title from cw_new where scan_live = 0 and project = 'dewiki' and daytime >= (select daytime from cw_new where scan_live = 0 and project = 'dewiki' order by daytime limit 1) order by daytime limit 250;
	
	
	my $sql_text = "select distinct title from cw_change where scan_live = 0 and project = '".$project."'  and daytime >= (select daytime from cw_change where scan_live = 0 and project = '".$project."' order by daytime limit 1) order by daytime limit ".$limit.";";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text );
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
		}
		#print $result."\n";
		push(@live_article, $result."\t".'0' );
		$change_counter ++;
	}
	print "\t".$change_counter."\t".'articles change'."\n";
	print LOGFILE 'articles change:'."\t".$change_counter."\n" if ($starter_modus	ne 'starter');
	our $for_statistic_last_change_article = $change_counter;
}

sub last_change_article_old{
	# Load last change articles
	my $file_last_change = $project.'_last_changes.txt';
	my $file_input_last_change = $input_directory_change.$project.'/'.$file_last_change;
	#print $file_input_new."\n";
	my $limit = 10;
	my $change_counter = 0;
	if (-e $file_input_last_change) {
		#if existing
		#print 'file exist'."\n";
		open(INPUT_NEW, "<$file_input_last_change");
		do {
			my $line = <INPUT_NEW>;
			if ($line) {
				$line =~ s/\n$//g;
				my @split_line = split ( /\t/, $line);
				if ($change_counter < $limit) {
					push(@live_article, $split_line[1]."\t".'0' );
					$change_counter ++;
				}
			}
		}
		until (eof(INPUT_NEW) == 1);	
		close (INPUT_NEW);
	}
	print "\t".$change_counter."\t".'articles change';
	print ' (no file: '.$file_last_change.' )' if not (-e $file_input_last_change);
	print "\n";
	print LOGFILE 'articles change:'."\t".$change_counter."\n" if ($starter_modus	ne 'starter');
	our $for_statistic_last_change_article = $change_counter;
}


sub geo_error_article{
	# get all last_change article last days		
	# Load last change articles
	my $file_geo = $project.'_'.$error_geo_list_filename;
	my $file_input_geo = $output_geo.$project.'/'.$file_geo;
	#print $file_input_new."\n";
	my $geo_counter = 0;
	if (-e $file_input_geo) {
		#if existing
		#print 'file exist'."\n";
		open(INPUT_GEO, "<$file_input_geo");
		do {
			my $line = <INPUT_GEO>;
			if ($line) {
				$line =~ s/\n$//g;
				my @split_line = split ( /\t/, $line);
				my $number_of_parts = @split_line;
				if ( $number_of_parts > 0 ) {
					push(@live_article, $split_line[0]."\t".'0' );
					$geo_counter ++;
				}
			}
		}
		until (eof(INPUT_GEO) == 1);	
		close (INPUT_GEO);
	}
	print "\t".$geo_counter."\t".'articles geo';
	print ' (no file: '.$file_geo.' )' if not (-e $file_input_geo);
	print "\n";
	print LOGFILE 'articles geo:'."\t\t".$geo_counter."\n" if ($starter_modus	ne 'starter');
	$for_statistic_geo_article = $geo_counter;
}

sub article_with_error_from_dump_scan{
	my $database_dump_scan_counter = 0;
	my $limit = 250;
	# oldest not scanned article
	# select distinct title from cw_new where scan_live = 0 and project = 'dewiki' and daytime >= (select daytime from cw_new where scan_live = 0 and project = 'dewiki' order by daytime limit 1) order by daytime limit 250;
	
	
	my $sql_text = "select distinct title from cw_dumpscan where scan_live = 0 and project = '".$project."' limit ".$limit.";";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text );
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
		}
		#print $result."\n";
		push(@live_article, $result."\t".'0' );
		$database_dump_scan_counter ++;
	}
	print "\t".$database_dump_scan_counter."\t".'articles from dump (not scan live) from db'."\n";
	print LOGFILE 'articles from dump (not scan live) from db:'."\t\t".$database_dump_scan_counter."\n" if ($starter_modus	ne 'starter');
}


sub article_with_error_from_dump_scan_old_old{
	if ( $dump_or_live eq 'live') {
		# if a new dump is available
		my $input_dump_errors = $output_directory.$project.'/'.$project.'_'.$error_list_filename_dump;
		#print $file_input_new."\n";
		my $dump_counter = 0;
		if (-e $input_dump_errors) {
			#if existing
			#print 'file exist'."\n";
			open(INPUT_DUMP, "<$input_dump_errors");
			do {
				my $line = <INPUT_DUMP>;
				if ($line) {
					$line =~ s/\n$//g;
					my @split_line = split ( /\t/, $line);
					my $number_of_parts = @split_line;
					if ( $number_of_parts > 0 ) {
						push(@live_article, $split_line[0]."\t".$split_line[1] );
						$dump_counter ++;
					}
				}
			}
			until (eof(INPUT_DUMP) == 1);	
			close (INPUT_DUMP);
			# delete 
			system ('rm '.$input_dump_errors); 
		}
		print "\t".$dump_counter."\t".'articles dump'."\n";
		print LOGFILE 'articles dump:'."\t\t".$dump_counter."\n" if ($starter_modus	ne 'starter');
		
	}
}


sub article_with_error_from_dump_scan_old{
	my $database_dump_scan_counter = 0;
	my $limit = 250;	# number of articles per run
	
	# get all error_id and create new sql_text
	my $sql_text = " select error_id from 	(select * 	from cw_dumpscan 	where project = '".$project."' 	and scan_live = false ) a group by a.error_id limit ".$limit.";";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text );
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute;
	my $union_sql_text = '';
	my $i = 0;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
		}
		$i = $i +1;
		#print $result."\n";
		$union_sql_text .= "union all 
			select title from 
			(select * 
			from cw_dumpscan 
			where project = '".$project."'
			and scan_live = false
			and error_id = '".$result."'
			limit ".$limit.") a".$i."
		";	
	}
	$union_sql_text =~ s/^union all//;
	$union_sql_text = $union_sql_text.';';
	
	#print $union_sql_text."\n";
	
	# use union_select, if one or more error found
	if ($union_sql_text ne ';') {
		
		$sth = $dbh->prepare( $union_sql_text );
		#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
		$sth->execute;
		while (my $arrayref = $sth->fetchrow_arrayref()) {	
			foreach(@$arrayref) {
				$result = $_;
			}
			#print $result."\n";
			push(@live_article, $result."\t".'0' );
			$database_dump_scan_counter ++;
		}
	}
	print "\t".$database_dump_scan_counter."\t".'articles from dump (not scan live) from db'."\n";
	print LOGFILE 'articles from dump (not scan live) from db:'."\t\t".$database_dump_scan_counter."\n" if ($starter_modus	ne 'starter');
}
		
sub get_done_article_from_database{
	my $database_ok_counter = 0;
	my $limit = $_[0];
	my $sql_text = " select title from cw_error where ok = 1 and project = '".$project."' limit ".$limit.";";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text );
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
		}
		#print $result."\n";
		push(@live_article, $result."\t".'0' );
		$database_ok_counter ++;
	}
	print "\t".$database_ok_counter."\t".'done articles from db'."\n";
	print LOGFILE 'done articles from db:'."\t\t".$database_ok_counter."\n" if ($starter_modus	ne 'starter');
}

sub get_oldest_article_from_database{
	my $database_ok_counter = 0;
	my $limit = $_[0];
	my $sql_text = " select title from cw_error where project = '".$project."' and DATEDIFF(now(),found) > 31 order by DATEDIFF(now(),found) desc limit ".$limit.";";
	my $result = '';
	my $sth = $dbh->prepare( $sql_text );
	#print '<p class="smalltext"/>'.$sql_text."</p>\n";					  
	$sth->execute;
	while (my $arrayref = $sth->fetchrow_arrayref()) {	
		foreach(@$arrayref) {
			$result = $_;
		}
		#print $result."\n";
		push(@live_article, $result."\t".'0' );
		$database_ok_counter ++;
	}
	print "\t".$database_ok_counter."\t".'old articles from db'."\n";
	print LOGFILE 'old articles from db:'."\t\t".$database_ok_counter."\n" if ($starter_modus	ne 'starter');
}


############################################################################

sub scan_pages{
	# get the text of the next page
	print 'Start scanning'."\n" 	if ($silent_modus ne 'silent');

	$end_of_dump = 'no';	# when last article from dump scan then 'yes', else 'no'
	$end_of_live = 'no';	# when last article from live scan then 'yes', else 'no'

	do {
		set_variables_for_article();

		if ($dump_or_live eq 'dump' or $dump_or_live eq 'only') {
			get_next_page_from_dump();
		} else {		
			get_next_page_from_live();
		}
		
		if (     $end_of_dump eq 'no' 
			 and $end_of_live eq 'no'
			 and not (   $title =~ /\.js$/
					  or $title =~ /\.css$/
					  )
			 ) 
			 {
			check_article();				#Main check routine
		} else {
			if ( $end_of_dump eq 'yes' 
			 or  $end_of_live eq 'yes' ) {
				print 'articles scan finish'."\n\n"		if ($silent_modus ne 'silent');

			} else {
				print 'no check in article:'."\t\t".$title."\n";
			}
		}
	}
	until (		$end_of_dump eq 'yes' 
			or  $end_of_live eq 'yes'
			#or  $page_number > 20
			#or $page_id  > 7950
			#or  ($error_counter > 10000 and $project ne 'dewiki')
			#or ($error_counter > 40000)
			or ($error_counter > 40000 and $dump_or_live eq 'live')
		   );	
}


sub set_variables_for_article {
	$page_number 	= $page_number + 1;
	$title					= '';		# title of the current article
	$page_id				= -1;		# page id of the current article
	$revision_id			= -1;		# revision id of the current article
	$revision_time			= -1;		# revision time of the current article
	$text					= '';		# text of the current article  (for work)
	$text_origin			= '';		# text of the current article origin (for save)
	$text_without_comments  = '';		# text of the current article without_comments (for save)
	

	$page_namespace			= -100;		# namespace of page
	$page_is_redirect   	= 'no';			
	$page_is_disambiguation = 'no';

	$page_categories 		= '';
	$page_interwikis 		= '';

	$page_has_error 		= 'no';		# yes/no 	error in this page
	$page_error_number		= -1;		# number of all article for this page

	undef(@comments);							# 0 pos_start
											# 1 pos_end
											# 2 comment
	$comment_counter		= -1;		#number of comments in this page 
	
	undef(@category);							# 0 pos_start
											# 1 pos_end
											# 2 category	Test		
											# 3 linkname	Linkname
											# 4 original	[[Category:Test|Linkname]]
											
	$category_counter		= -1;
	$category_all			= '';		# all categries

	undef(@interwiki);							# 0 pos_start
											# 1 pos_end
											# 2 interwiki	Test		
											# 3 linkname	Linkname
											# 4 original	[[de:Test|Linkname]]
											# 5 language
											
	$interwiki_counter		= -1;

	undef(@lines);								# text seperated in lines 
	undef(@headlines);							# headlines
	undef(@section);							# text between headlines

	
	undef(@lines_first_blank);					# all lines where the first character is ' '
	
	undef(@templates_all);						# all templates
	undef(@template);							# templates with values
											# 0 number of template
											# 1 templatename
											# 2 template_row
											# 3 attribut
											# 4 value
	$number_of_template_parts = -1;		# number of all template parts													
											
	undef(@links_all);							# all links
	undef(@images_all);						# all images
	undef(@isbn);								# all ibsn of books
	undef(@ref);							# all ref

	$page_has_geo_error 	= 'no';		# yes/no 	geo error in this page
	$page_geo_error_number  = -1;		# number of all article for this page
	
	

}



sub close_file {
	#close all open files
	close (DUMP);
	close (TEMPLATETIGER);

}


sub update_table_cw_error_from_dump {
	
	if ($dump_or_live eq 'dump') {
		print 'move all article from cw_dumpscan into cw_error'."\n";

		my $sql_text;
		my $sth;
		
		$sql_text = "delete from cw_error where project = '".$project."';";
		$sth = $dbh->prepare( $sql_text );
		$sth->execute;
		
		
		#set @test = 'T%';
		#insert into cw_error (select * from cw_dumpscan where project = 'nlwiki' and title like @test);
		#delete from cw_dumpscan where project = 'nlwiki' and title like @test;
		
		$sql_text = "insert into cw_error (select * from cw_dumpscan where project = '".$project."');";
		$sth = $dbh->prepare( $sql_text );
		$sth->execute;	

		print 'delete all article from this project in cw_dumpscan'."\n";
		$sql_text = "delete from cw_dumpscan where project = '".$project."';";
		$sth = $dbh->prepare( $sql_text );
		$sth->execute;	
	}
}



sub delete_deleted_article_from_db 	{
	#delete all deleted article from database
	my $sql_text2 = "delete from cw_error where ok = 1 and project = '".$project."' and found not like '%".substr(get_time_string(), 0, 7)."%';";
	#print $sql_text2."\n";
	my $sth = $dbh->prepare( $sql_text2 );
	$sth->execute;
}	

sub delete_article_from_table_cw_new 	{
	#delete all scanned or older then 7 days from this project
	my $sql_text2 = "delete from cw_new where project = '".$project."' and (scan_live = 1 or DATEDIFF(now(),daytime) > 7);";
	#print $sql_text2."\n";
	my $sth = $dbh->prepare( $sql_text2 );
	$sth->execute;
	
	#delete all articles from don't scan projects 
	my $sql_text3 = "delete from cw_new where DATEDIFF(now(),daytime) > 8;";
	#print $sql_text2."\n";
	$sth = $dbh->prepare( $sql_text3 );
	$sth->execute;
}

sub delete_article_from_table_cw_change 	{
	#delete all scanned or older then 3 days from this project
	my $sql_text2 = "delete from cw_change where project = '".$project."' and (scan_live = 1 or DATEDIFF(now(),daytime) > 3);";
	#print $sql_text2."\n";
	my $sth = $dbh->prepare( $sql_text2 );
	$sth->execute;
	
	#delete all articles from don't scan projects 
	my $sql_text3 = "delete from cw_change where DATEDIFF(now(),daytime) > 8;";
	$sth = $dbh->prepare( $sql_text3 );
	$sth->execute;
}


sub update_table_cw_starter {
	if ($starter_modus	eq 'starter') {
		print 'update_table_cw_starter'."\n"  if ($silent_modus ne 'silent'); 
		#print "\t".$error_counter."\t".'errors found'."\n";
		if ($error_counter > 0) {
			#print '$page_number= '.$page_number."\n";
			my $sql_text = '';
			# how much was found
			$sql_text = "update cw_starter set errors_done =errors_done +".$error_counter." where project ='".$project."';" if ($load_modus_done eq 'yes') ;
			$sql_text = "update cw_starter set errors_new  =errors_new  +".$error_counter." where project ='".$project."';" if ($load_modus_new eq 'yes') ;
			$sql_text = "update cw_starter set errors_dump =errors_dump +".$error_counter." where project ='".$project."';" if ($load_modus_dump eq 'yes') ;
			$sql_text = "update cw_starter set errors_change =errors_change +".$error_counter." where project ='".$project."';" if ($load_modus_last_change eq 'yes') ;
			$sql_text = "update cw_starter set errors_old =errors_old +".$error_counter." where project ='".$project."';" if ($load_modus_old eq 'yes') ;
			#print $sql_text."\n";
			my $sth = $dbh->prepare( $sql_text);
			$sth->execute;

			# for count of current run
			$sql_text = "update cw_starter set current_run =".$error_counter." where project ='".$project."';";
			#print $sql_text."\n";
			$sth = $dbh->prepare( $sql_text);
			$sth->execute;

		
			if ($load_modus_new ne 'yes' and $load_modus_last_change ne 'yes') {
				# was something change?
				$sql_text = "update cw_starter set last_run_change = 'true' where project ='".$project."';";
				#print $sql_text."\n";
				$sth = $dbh->prepare( $sql_text );
				$sth->execute;
			}
		}
		
	}
}




sub read_and_write_metadata_from_dump {
	# read the metadata from dump (<xml … <siteinfo>…</siteinfo>)
	# write this metadata in file for dump and live-scan
	#print 'Read metadata from dump and write in file'."\n";
	
	#old from dump
	#				my $line ='';
	#				my $end = 'no';
					my $metadata = '';
	#				do {
	#					$line_number = $line_number + 1; 
	#					$line = <DUMP>;
	#					#print $line_number.' '.$line;
	#					$line =~ s/\n//;
	#					$metadata = $metadata.$line."\n";
	#					if (index ($line, '</siteinfo>') > -1) {
	#						$end = 'yes';
	#					}
    #
	#				} 
	#				until ( $end eq 'yes');
	
	#new from web
	# raw_text2
	
	#print 'get Metadaten from :'.$project.' '.$language."\n";
	$language = 'nds-nl' if ($project eq 'nds_nlwiki');
	
	
	my $url = 'http://'.$language.'.wikipedia.org/w/api.php';
	if ($project eq 'commonswiki') {
		$url = 'http://commons.wikimedia.org/w/api.php';
	}
	if ($project =~ /source$/) {
		$url = 'http://'.$language.'.wikisource.org/w/api.php';
	}
	$url = $url.'?action=query&meta=siteinfo&siprop=general|namespaces|namespacealiases|statistics|magicwords&format=xml';
	
	$metadata = raw_text2($url);
	$language = 'nds_nl' if ($project eq 'nds_nlwiki');
	
	
	
	my $file_metadata = $output_directory.$project.'/'.$project.'_metadata.txt';
	print $file_metadata."\n";
	open(METADATA, ">$file_metadata");
	print METADATA $metadata;
	close(METADATA);
	$metadata = '';
	
	
}

sub load_metadata_from_file {
	# load metadata from file for dump and live
	# this file is from the last dump (if live) or current dump (if dump)
	#print 'Read metadata from file'."\n";
	my $file_metadata = $output_directory.$project.'/'.$project.'_metadata.txt';
	open(METADATA, "<$file_metadata");
	my @metadata = <METADATA>;
	close(METADATA);
	
	my $metatext = ''; 
	foreach (@metadata) {
		$metatext = $metatext.$_;
	}
	#print $metatext."\n";

	#Extract metadata
	
	#sitename 
	my $sitename = '';
	my $pos1 = index($metatext,'sitename="') + length('sitename="');
	my $pos2 = index($metatext,'"', $pos1);
	$sitename = substr($metatext, $pos1, $pos2 - $pos1);
	print 'Sitename: '."\t\t".$sitename."\n" 	if ($silent_modus ne 'silent');

	
	
	#get base
	$base = '';
	$pos1 = index($metatext,'base="') + length('base="');
	$pos2 = index($metatext,'"', $pos1 );
	$base = substr($metatext, $pos1, $pos2 -$pos1);
	print 'Base:     '."\t\t".$base."\n" 		if ($silent_modus ne 'silent');
	$home = $base;
	$home =~ s/[^\/]+$//;
	#print 'Home:     '."\t\t".$home."\n";
	
	

	#get namespaces number and name
	# for example: 6 Tabulator image
	my $namespaces = '';
	$pos1 = index($metatext,'<namespaces>') + length('<namespaces>');
	$pos2 = index($metatext,'</namespaces>', $pos1);
	$namespaces = substr($metatext, $pos1, $pos2 -$pos1);
	#print "x".$namespaces."x\n";	
	#$namespaces =~ s/^\n//g;
	$namespaces =~ s/<\/ns>/\n/g;
	$namespaces =~ s/\/>/>\n/g;			# only namespace 0 - articles
	
	# now every namespase in one line
	#print "x".$namespaces."x\n";	
	
	$namespaces =~ s/ case="first-letter"//g;
	$namespaces =~ s/ xml:space="preserve"//g;
	$namespaces =~ s/ subpages=""//g;
	
	#$namespaces =~ s/<ns id="//g;
	#$namespaces =~ s/" canonical="/\t/g;
	#$namespaces =~ s/ canonical="/\t/g;
	#$namespaces =~ s/">/\t/g;
	#$namespaces =~ s/" \/>/\t\n/g;
	#$namespaces =~ s/  //g;
	#print "x".$namespaces."x\n";


	my @namespaces_split = split( /\n/, $namespaces);
	$namespaces_count = @namespaces_split;
	#print $namespaces_count;
	for (my $i = 0; $i < $namespaces_count; $i++) {
	
		#print $i."\t".$namespaces_split[$i]."\n\n";	
		$namespaces_split[$i] =~ s/[ ]+$//g;
		
		#<ns id="-1" canonical="Special">Spezial
		
		#get id
		my $pos1 = index($namespaces_split[$i],'id="') + length('id="');
		my $pos2 = index($namespaces_split[$i],'"', $pos1);
		my $id = substr($namespaces_split[$i], $pos1, $pos2 -$pos1);
		
		
		#get canonical namspace name
		$pos1 = index($namespaces_split[$i],'canonical="') + length('canonical="');
		$pos2 = index($namespaces_split[$i],'"', $pos1);
		my $canonical = substr($namespaces_split[$i], $pos1, $pos2 -$pos1);
		
		#get namespace name
		$pos1 = index($namespaces_split[$i],'>') + length('>');
		my $name = substr($namespaces_split[$i], $pos1);
		
		
		$namespaces_split[$i] = $id."\t".$canonical."\t".$name;
		#print $namespaces_split[$i]."\n";
		
		my @splitter = split( /\t/, $namespaces_split[$i]);
		if ( $namespaces_split[$i] =~ /^0/) {
			$namespace[$i][0] = 0;
		} else {
			$namespace[$i][0] = int($splitter[0]);
		}
		$namespace[$i][1] = $splitter[2];
		$namespace[$i][1] = '' if ($namespace[$i][0] == 0);
		$namespace[$i][2] = $splitter[1];
		$namespace[$i][2] = '' if ($namespace[$i][0] == 0);

		
		if ($namespace[$i][0] == 6) {
			# image
			$namespace_image[0]	= $namespace[$i][1];
			$namespace_image[1] = $namespace[$i][2];	
		}
		if ($namespace[$i][0] == 10) {
			# templates
			$namespace_templates[0] = $namespace[$i][1];
			$namespace_templates[1] = $namespace[$i][2] if ($namespace[$i][1] ne $namespace[$i][2]);
		}
		if ($namespace[$i][0] == 14) {
			#category
			$namespace_cat[0]	= $namespace[$i][1];
			$namespace_cat[1] 	= $namespace[$i][2] if ($namespace[$i][1] ne $namespace[$i][2]);
		}
		#print $i."\t".$namespace[$i][0]."\t".$namespace[$i][1]."\t".$namespace[$i][1]."\n\n"
	}
	
	
	
	# namespacealiases
	
	my $namespacealiases_text = '';
	$pos1 = index($metatext,'<namespacealiases>') + length('<namespacealiases>');
	$pos2 = index($metatext,'</namespacealiases>', $pos1);
	$namespacealiases_text = substr($metatext, $pos1, $pos2 -$pos1);	
	#print $namespacealiases_text. "\n";
	$namespacealiases_text =~ s/<\/ns>/\n/g;
	$namespacealiases_text =~ s/<ns id="//g;
	$namespacealiases_text =~ s/ xml:space="preserve"//g;
	$namespacealiases_text =~ s/">/\t/g;
	#print $namespacealiases_text. "\n";
	
	my @namespacealiases_split = split( /\n/, $namespacealiases_text);
	$namespacealiases_count = @namespacealiases_split;
	
	#print $namespaces_count;
	for (my $i = 0; $i < $namespacealiases_count; $i++) {
		my @splitter = split( /\t/, $namespacealiases_split[$i]);
		if ($splitter[0] eq '6') {
			#aliasname for image
			push(@namespace_image, $splitter[1]);
		}
		if ($splitter[0] eq '10') {
			#aliasname for templates
			push(@namespace_templates, $splitter[1]);
		}
		if ($splitter[0] eq '14') {
			#aliasname for category
			push(@namespace_cat, $splitter[1]);
		}
	
		#save all aliases
		$namespacealiases[$i][0] = $splitter[0];
		$namespacealiases[$i][1] = $splitter[1];
		#print 'Namespacealiases: '.$namespacealiases[$i][0].','.$namespacealiases[$i][1]."\n";
	}
	
	#foreach (@namespace_image) {
	#	print $_."\n";
	#}
	#print "\n";
	#foreach (@namespace_cat) {
	#	print $_."\n";
	#}

	#magicwords 

	@magicword_defaultsort          = get_magicword($metatext, 'defaultsort');
	@magicword_img_thumbnail	= get_magicword($metatext, 'img_thumbnail');
	@magicword_img_manualthumb	= get_magicword($metatext, 'img_manualthumb');
	@magicword_img_right	 	= get_magicword($metatext, 'img_right');
	@magicword_img_left		= get_magicword($metatext, 'img_left');
	@magicword_img_none	 	= get_magicword($metatext, 'img_none');
	@magicword_img_center		= get_magicword($metatext, 'img_center');
	@magicword_img_framed		= get_magicword($metatext, 'img_framed');
	@magicword_img_frameless	= get_magicword($metatext, 'img_frameless');
	@magicword_img_page		= get_magicword($metatext, 'img_page');
	@magicword_img_upright		= get_magicword($metatext, 'img_upright');
	@magicword_img_border		= get_magicword($metatext, 'img_border');
	@magicword_img_sub		= get_magicword($metatext, 'img_sub');
	@magicword_img_super		= get_magicword($metatext, 'img_super');
	@magicword_img_link		= get_magicword($metatext, 'img_link');
	@magicword_img_alt		= get_magicword($metatext, 'img_alt');
	@magicword_img_width		= get_magicword($metatext, 'img_width');
	@magicword_img_baseline		= get_magicword($metatext, 'img_baseline');
	@magicword_img_top		= get_magicword($metatext, 'img_top');
	@magicword_img_text_top		= get_magicword($metatext, 'img_text_top');
	@magicword_img_middle		= get_magicword($metatext, 'img_middle');
	@magicword_img_bottom		= get_magicword($metatext, 'img_bottom');
	@magicword_img_text_bottom	= get_magicword($metatext, 'img_text_bottom');
	
	
	#foreach (@magicword_defaultsort) {
	#	print $_."\n";
	#}

	
}

sub get_magicword {
	my $metatext = $_[0];
	my $key = $_[1];
	my @result;
	
	my $pos1 = index( $metatext, '<magicword name="'.$key );
	if ($pos1 > -1) {
		my $pos2 = index( $metatext, '</magicword>', $pos1 );
		my $part = substr ($metatext, $pos1, $pos2 + length('</magicword>') - $pos1);
		#print $part."\n";
		my @part_split = split ( '<alias>', $part );
		shift (@part_split);
		foreach (@part_split) {
			#print $_."\n"
			my $pos3 = index ($_, '</alias>');
			my $alias = substr ($_, 0, $pos3);
			#print $alias ."\n";
			push (@result, $alias );
		}
		return(@result);
	}
}




sub get_next_page_from_dump{
	#this function scan line after line from dump, 
	#the result is the text from the next article
	
	my $line 				= "";		# one line in dump
	my $article_complete 	= 0;		# all line of article (then 1)
	my $start_recording 	= 0;		# find <page>
	my $revision_start 		= 0;		# find <revision>

	
	#loop for every line
	do {
		$line = <DUMP>;
		$line_number = $line_number +1;
		#$number_of_scan_line = $number_of_scan_line +1;		#Security, maybe the finish is not correct
		#print "$line";
		
		if ($line =~ /<page>/) {
			$start_recording = 1;
		}
		
		if ($start_recording == 1) {
			$text = $text.$line;
		}

		if ($line =~ /<\/page>/) {
			$start_recording = 0;
			$article_complete = 1;
		}
		
		if ($line =~ /<title>/) {
			#extract title
			$title ="$line";
			my @content= split(/>/,$title);
			@content= split(/</,$content[1]);
			$title=$content[0];
			#print "$title\n";
		}

		if ($line =~ /<id>/ and $page_id == -1 ) {
			#extract id
			$page_id ="$line";
			my @content= split(/>/,$page_id);
			@content= split(/</,$content[1]);
			$page_id = $content[0];
			#print "$page_id\t$title\n";
		}		

		if ($line =~ /<revision>/) {
			$revision_start = 1;
		}
		if ($revision_start == 1 and $revision_id == -1 and $line =~ /<id>/) {
			#read revision_id
			$revision_id ="$line";
			my @content= split(/>/,$revision_id);
			@content= split(/</,$content[1]);
			$revision_id=$content[0];
			#print $revision_id,"\n";
		}

		if ($revision_start == 1 and $line =~ /<timestamp>/) {
			#read revision_id
			$revision_time ="$line";
			my @content= split(/>/,$revision_time);
			@content= split(/</,$content[1]);
			$revision_time=$content[0];
			#print $revision_time,"\n";
		}		
		
		$end_of_dump = 'yes' if ($line =~ /<\/mediawiki>/);
		$end_of_dump = 'yes' if (eof(DUMP) == 1);
		
	}
	until ( $article_complete == 1 or $end_of_dump eq 'yes');
	#Extract only edit-text
	my $test = index ($text, '<text xml:space="preserve">');
	$text = substr($text, $test);
	$text =~ s/<text xml:space="preserve">//g;
	$test = index($text,	'</text>');
	$text = substr($text,0,$test);
	
	$text = replace_special_letters($text);
	
	#if (   $title eq 'At-Tabarī'
	#	or $title eq 'Rumänien'
	#	or $title eq 'Liste der Ortsteile im Saarland') {
	
	#	my $output_article_text_file = $output_directory.$project.'/'.$project.'_text_article_'.$title.'.txt';
	#	open(OUTPUT_ARTICLE_TEXT, ">$output_article_text_file");
	#	print OUTPUT_ARTICLE_TEXT $text;
	#	close(OUTPUT_ARTICLE_TEXT);
	
	#}
	#print $text;
}

sub get_next_page_from_live {
	$current_live_article ++;	#next article

	if ( $current_live_error_scan != 0 ) {
		# Error not 0 (new aricles, and last changes...)
		
		if ($current_live_error_scan != 0 and $current_live_article == $maximum_current_error_scan) {
			# set number higher if not all 50 errors  found
			#print 'Nr.'.$current_live_error_scan."\n";
			#print 'Found at moment :'.$error_description[$current_live_error_scan][3]."\n";
			#print 'Max allowed:'.$max_error_count."\n";
			#print 'Max possible:'.$number_article_live_to_scan."\n";

			if ( $error_description[$current_live_error_scan][3]  <  $max_error_count ) {
				# set higer maximum
				$maximum_current_error_scan = $maximum_current_error_scan + ($max_error_count - $error_description[$current_live_error_scan][3]);
				#print 'Set higher maximum: '.$maximum_current_error_scan."\n";
			} else {	
				# stop scan
				save_errors_for_next_scan($current_live_article);	
				#$rest_of_errors_not_scan_yet
				$current_live_article = -1;
			}
		}
		
		# find next error with articles
		if (($current_live_error_scan > 0 and $current_live_article == -1) 
			 or $current_live_article == $number_article_live_to_scan
			 or $current_live_error_scan == -1) {
			#print 'switch from error to error'."\n";
			
			$current_live_error_scan = 0 if ($current_live_error_scan == -1);	#start with error 1
			
			do {
				$current_live_error_scan ++;
				#print $current_live_error_scan."\n";
				@live_to_scan = ();
				if ($error_description[$current_live_error_scan][3] < $max_error_count) {
					# only if not all found with new/change/last 
					get_all_error_with_number($current_live_error_scan);
				} else {
					# if with new /change etc. we found for this error much
					get_all_error_with_number($current_live_error_scan);
					save_errors_for_next_scan(0);
					@live_to_scan = ();
				}
				
				$number_article_live_to_scan = @live_to_scan;
			} until ($current_live_error_scan >= $number_of_error_description
					 or $number_article_live_to_scan > 0);
			
			$maximum_current_error_scan = $max_error_count;
			if ($error_description[$current_live_error_scan][3] > 0) {
				#print 'More errors for error'.$current_live_error_scan."\n";
				#print 'At moment only :'.$error_description[$current_live_error_scan][3]."\n";
				$maximum_current_error_scan = $max_error_count - $error_description[$current_live_error_scan][3];
				#print 'Search now for more :'.$maximum_current_error_scan."\n";
			}
			$current_live_article = 0;
			$xml_text_from_api = '';
			#print '#############################################################'."\n";
			#print 'Error '.$current_live_error_scan.' :'."\t".$number_article_live_to_scan."\n" if ($number_article_live_to_scan > 0);
			#print 'Max='.$maximum_current_error_scan."\n";
			#print 'Available = '.$number_article_live_to_scan."\n";
			
		}
	}

		

	if 	( $current_live_error_scan == 0
		 and $current_live_article >= $number_article_live_to_scan ) {
		# end of live, no more article to scan
		$end_of_live = 'yes';			
	}
	
	if ($current_live_error_scan >= $number_of_error_description) {
		# after check live all errors, then start with check of error 0 (new articles, last changes, ...)
		$current_live_article = 0;
		$xml_text_from_api = '';
		$current_live_error_scan = 0;
		get_all_error_with_number($current_live_error_scan);
		$number_article_live_to_scan = @live_to_scan;
		#print 'Error 0 :'."\t".$number_article_live_to_scan."\n";
		$maximum_current_error_scan = $max_error_count;	
	}	
	
	#$number_article_live_to_scan = @live_to_scan;
	if ( $current_live_article < $number_article_live_to_scan 
		 and $number_article_live_to_scan > 0
		 and $end_of_live ne 'yes'	) {
		# there is an error with articles
		# now we get the next article 


		if ($xml_text_from_api eq '') {
			# if list of xml_text_from_api is empty, then load next ariticles
			#print 'Load next texts from API'."\n"; 
			my $many_titles = '';
			my $i = $current_live_article; 
			my $end_many_title = 'false';
			do {

				my $line = $live_to_scan[$i];
				my @line_split = split( /\t/, $line);
				my $next_title 		= $line_split[0];
				print LOGFILE $next_title."\n" if ($starter_modus	ne 'starter');
				$next_title = replace_special_letters($next_title);
				$many_titles = $many_titles.'|'.uri_escape($next_title);
				$many_titles =~ s/^\|//;
				$i++;
				$end_many_title = 'true' if ($i == $number_article_live_to_scan);
				$end_many_title = 'true' if ($i == $current_live_article + 25);		# not more then 25 articles
				$end_many_title = 'true' if ( length($many_titles) > 2000);			# url length not too long (Problem ruwiki and other no latin letters    ) 
			} 
			until ($end_many_title eq 'true');
			#print 'Many titles ='.$many_titles."\n";
			$xml_text_from_api = raw_text_more_articles( $many_titles );
			$xml_text_from_api =~ s/^<\?xml version="1\.0"\?>//;
			$xml_text_from_api =~ s/^<api>//;
			$xml_text_from_api =~ s/^<query>//;
			$xml_text_from_api =~ s/^<pages>//;
			$xml_text_from_api =~ s/<\/api>$//;
			$xml_text_from_api =~ s/<\/query>$//;
			$xml_text_from_api =~ s/<\/pages>$//; 
			#print $xml_text_from_api."\n";

		}
		
		
		

		# get next title and  text from xml_text_from_api
		if ($xml_text_from_api ne '') {
			
			my $pos_end = index ($xml_text_from_api, '</page>' );
			if ($pos_end > -1 ) {
				# normal page
				$text		       = substr ( $xml_text_from_api, 0, $pos_end + length('</page>') );
				$xml_text_from_api = substr ( $xml_text_from_api,    $pos_end + length('</page>') );
			} else {
				# missing page
				# <page ns="0" title="ZBlu-ray Disc" missing="" />
				#print 'Missing Page'."\n";
				$pos_end = index ($xml_text_from_api, 'missing="" />' );
				$text		       = substr ( $xml_text_from_api, 0, $pos_end + length('missing="" />') );;
				$xml_text_from_api = substr ( $xml_text_from_api,    $pos_end + length('missing="" />') );
				if ($pos_end == -1){
					#BIG PROBLEM 
					print 'WARNING: Big problem with API'."\n";
					print LOGFILE 'WARNING: Big problem with API'."\n" if ($starter_modus	ne 'starter');
					$text		       = '';
					$xml_text_from_api = '';
				}
			}

			my $line = $live_to_scan[$current_live_article];
			my @line_split = split( /\t/, $line);
			$title 		= $line_split[0];
			
			#print $title ."\n";
			#print substr (  $text, 0, 150)."\n";
			
			if (index ( $text, 'title='.'"'.$title.'"') == -1 ) {
				# the result from the api is in a other sort 
				# know get the current title
				# for example <page pageid="2065519" ns="0" title=".380 ACP">
				#print "Old title:".$title ."\n";
				my $pos_title = index ($text, 'title="');
				my $title_text = $text;
				$title_text = substr ( $title_text, $pos_title + length ('title="') );
				$pos_title = index ($title_text, '"');
				$title = substr ( $title_text, 0, $pos_title );
				#print "New title:".$title;
				#print "\n\n";
				#print substr (  $text, 0, 150)."\n";
				#print "\n\n";

			}
				
			
			#print $title."\n";
			push(@article_was_scanned, $title);
			


			# get id
			my $test_id_pos  = index ($text, 'pageid="');
			if ($test_id_pos > -1) {	
				$page_id =  substr($text, $test_id_pos + length( 'pageid="') );
				$test_id_pos = index ($page_id , '"');
				$page_id = substr($page_id, 0, $test_id_pos);
				#print $page_id.' - '.$title."\n";
			}
			
			
			# get  text
			my $test = index ($text, '<rev timestamp="');
			if ($test > -1) {
				my $pos = index ($text,'">', $test );
				$text = substr($text, $pos + 2);
				#$text =~ s/<text xml:space="preserve">//g;
				$test = index($text,'</rev>');
				$text = substr($text,0,$test);		
			}
			

			#revision_id
			#revision_time
			#print $text."\n";
			#print substr($text, 0, 60)."\n";
			$text = replace_special_letters($text);
		}
	}	
}

sub save_errors_for_next_scan {
	my $from_number = $_[0];
	$number_article_live_to_scan = @live_to_scan;
	for (my $i = $from_number; $i < $number_article_live_to_scan; $i++) {
		#print $live_to_scan[$i]."\n";
		
		my $line = $live_to_scan[$i];
		#print '1:'.$line."\n";
		my @line_split = split( /\t/, $line);
		my $rest_title = $line_split[0];
		$rest_of_errors_not_scan_yet = $rest_of_errors_not_scan_yet."\n".$rest_title."\t".$current_live_error_scan;
	}
}

sub get_all_error_with_number {
	# get from array "live_article" with all errors, only this errors with error number X
	my $error_live = $_[0];
	#print 'Error number: '.$error_live."\n";

	my $number_of_article = @live_article;
	#print $number_of_article."\n";
	#print $live_article[0]."\n";

	if ($number_of_article > 0) {
		for (my $i = 0; $i < $number_of_article; $i ++) {
			my $current_live_line = $live_article[$i];
			#print $current_live_line."\n";
			my @line_split = split( /\t/, $current_live_line);
			#print 'alle:'.$line_split[1]."\n" if ($error_live == 0);
			my @split_error =  split( ', ',$line_split[1]);
			my $found = 'no';
			foreach (@split_error) {
				if (  $error_live eq $_   ){
					#found error with number X
					$found = 'yes';
					#print $current_live_line."\n" if ($error_live == 0);
				}
			}
			if ($found eq 'yes') {
				# article has error X
				#print 'found '.$current_live_line."\n"  if ($error_live == 7);
				
				# was this article scanned today ?
				$found = 'no';
				my $number_of_scanned_articles = @article_was_scanned;
				#print 'Scanned: '."\t".$number_of_scanned_articles."\n";
				foreach (@article_was_scanned) {
					#print $_."\n";
					if ( index ($current_live_line, $_."\t") == 0) {
						#article was in this run scanned
						$found = 'yes';
						#print 'Was scanned :'."\t".$current_live_line."\n";
					}
				}
				if ($found eq 'no') {
					push(@live_to_scan, $current_live_line);	#."\t".$i
				}
			}
		}
	}
}

sub get_all_error_with_type {
	#  at the moment not in use
	# get from all error, only this errors with number X
	my $error_type = $_[0];
	my $number_of_article = @live_article;
	for (my $i = 0; $i < $number_of_article; $i ++) {
		my $current_live_line = $live_article[$i];
		my @line_split = split( /\t/, $current_live_line);
		if ( $line_split[1] eq $error_type) {
#			$live_article[$i] =~ s/\tD\t/\tL\t/;
#			$live_article[$i] =~ s/\tO\t/\tL\t/;
			push(@live_to_scan, $current_live_line);	#."\t".$i
		}
	}
}



sub replace_special_letters {	
	my $content = $_[0];
	# only in dump must replace not in live
	# http://de.wikipedia.org/w/index.php?title=Benutzer_Diskussion:Stefan_K%C3%BChn&oldid=48573921#Dump
	$content =~ s/&lt;/</g;
	$content =~ s/&gt;/>/g;
	$content =~ s/&quot;/"/g;
	$content =~ s/&#039;/'/g;
	$content =~ s/&amp;/&/g;
	# &lt; -> <
	# &gt; -> >
	# &quot;  -> "
	# &#039; -> '
	# &amp; -> &
	return ($content);
}

sub raw_text {
	my $title = $_[0];
	
	$title =~ s/&amp;/%26/g;		# Problem with & in title
	$title =~ s/&#039;/'/g;			# Problem with apostroph in title
	$title =~ s/&lt;/</g;
	$title =~ s/&gt;/>/g;
	$title =~ s/&quot;/"/g;


	# http://localhost/~daniel/WikiSense/WikiProxy.php?wiki=$lang.wikipedia.org&title=$article 
		my $url2 = '';
		#$url2 = 'http://localhost/~daniel/WikiSense/WikiProxy.php?wiki=de.wikipedia.org&title='.$title;
		$url2 = $home;
		$url2 =~ s/\/wiki\//\/w\//;
		
		# old  	$url2 = $url2.'index.php?title='.$title.'&action=raw';
		$url2 = $url2.'api.php?action=query&prop=revisions&titles='.$title.'&rvprop=timestamp|content&format=xml';

		#print $url2."\n";
		
	
	my $response2 ;
	#do {
		uri_escape($url2);
	#print $url2."\n";
		#uri_escape( join ' ' => @ARGV );
		my $ua2 = LWP::UserAgent->new;
		$response2 = $ua2->get( $url2 );
	#}
	#until ($response2->is_success);
	my $content2 = $response2->content;
	my  $result2  = '';
	$result2 = $content2 if ($content2) ;
	
	return($result2);
}

sub raw_text2 {
	my $url = $_[0];
	
	$url =~ s/&amp;/%26/g;			# Problem with & in title
	$url =~ s/&#039;/'/g;			# Problem with apostroph in title
	
	my $response2 ;
	uri_escape($url);
	my $ua2 = LWP::UserAgent->new;
	$response2 = $ua2->get( $url );
	
	my $content2 = $response2->content;
	my  $result2  = '';
	$result2 = $content2 if ($content2) ;
	return($result2);
}

sub raw_text_more_articles {
	my $title = $_[0];
	
	#$title =~ s/&amp;/%26/g;		# Problem with & in title
	#$title =~ s/&#039;/'/g;			# Problem with apostroph in title
	#$title =~ s/&lt;/</g;
	#$title =~ s/&gt;/>/g;
	#$title =~ s/&quot;/"/g;
	#$title =~ s/&#039;/'/g;

	my $url2 = '';
	$url2 = $home;
	$url2 =~ s/\/wiki\//\/w\//;
	$url2 = $url2.'api.php?action=query&prop=revisions&titles='.$title.'&rvprop=timestamp|content&format=xml';
	
	print LOGFILE $url2."\n" if ($starter_modus	ne 'starter');
	my $response2 ;
	my $ua2 = LWP::UserAgent->new;
	$response2 = $ua2->get( $url2 );
	my $content2 = $response2->content;
	my  $result2  = '';
	$result2 = $content2 if ($content2) ;
	return($result2);
}



####################################

sub load_text_translation{
	print 'Load tanslation of:'."\t".$project."\n"   if ($silent_modus ne 'silent');
	
	# Input of translation page

	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'  			if ($project eq 'afwiki') ;
	$translation_page = 'ويكيبيديا:فحص_ويكيبيديا/ترجمة'  								if ($project eq 'arwiki') ;
	$translation_page = 'Viquipèdia:WikiProject Check Wikipedia/Translation'  			if ($project eq 'cawiki') ;
	$translation_page = 'Wikipedie:WikiProjekt Check Wikipedia/Translation'  			if ($project eq 'cswiki') ;
	$translation_page = 'Commons:WikiProject Check Wikipedia/Translation'  				if ($project eq 'commonswiki') ;
	$translation_page = 'Wicipedia:WikiProject Check Wikipedia/Translation'  			if ($project eq 'cywiki') ;
	$translation_page = 'Wikipedia:WikiProjekt Check Wikipedia/Oversættelse'			if ($project eq 'dawiki') ;
	$translation_page = 'Wikipedia:WikiProjekt Syntaxkorrektur/Übersetzung'				if ($project eq 'dewiki') ;
	$translation_page = 'Wikipedia:WikiProjekt Syntaxkorrektur/Übersetzung'				if ($project eq 'dewiki_test') ;
	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'  			if ($project eq 'enwiki') ;
	$translation_page = 'Projekto:Kontrolu Vikipedion/Tradukado'  						if ($project eq 'eowiki') ;
	$translation_page = 'Wikiproyecto:Check Wikipedia/Translation'						if ($project eq 'eswiki') ;
	$translation_page = 'Wikipedia:Wikiprojekti Check Wikipedia/Translation'  			if ($project eq 'fiwiki') ;
	$translation_page = 'Projet:Correction syntaxique/Traduction'						if ($project eq 'frwiki') ;
	$translation_page = 'Meidogger:Stefan Kühn/WikiProject Check Wikipedia/Translation' if ($project eq 'fywiki') ;
	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'  			if ($project eq 'hewiki') ;
	$translation_page = 'Wikipédia:Ellenőrzőműhely/Fordítás'  							if ($project eq 'huwiki') ;
	$translation_page = 'Wikipedia:ProyekWiki Cek Wikipedia/Terjemahan'  				if ($project eq 'idwiki') ;
	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'				if ($project eq 'iswiki') ;
	$translation_page = 'Wikipedia:WikiProjekt Check Wikipedia/Translation'				if ($project eq 'itwiki') ;
	$translation_page = 'プロジェクト:ウィキ文法のチェック/Translation'					if ($project eq 'jawiki') ;
	$translation_page = 'Vicipaedia:WikiProject Check Wikipedia/Translation'  			if ($project eq 'lawiki') ;
	$translation_page = 'Wikipedia:Wikiproject Check Wikipedia/Translation'				if ($project eq 'ndswiki') ;
	$translation_page = 'Wikipedie:WikiProject Check Wikipedia/Translation'				if ($project eq 'nds_nlwiki') ;
	$translation_page = 'Wikipedia:Wikiproject/Check Wikipedia/Vertaling'				if ($project eq 'nlwiki') ;
	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'				if ($project eq 'nowiki') ;
	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'				if ($project eq 'pdcwiki') ;
	$translation_page = 'Wikiprojekt:Check Wikipedia/Tłumaczenie'						if ($project eq 'plwiki') ;
	$translation_page = 'Wikipedia:Projetos/Check Wikipedia/Tradução'					if ($project eq 'ptwiki') ;
	$translation_page = 'Википедия:Страницы с ошибками в викитексте/Перевод'			if ($project eq 'ruwiki') ;
	$translation_page = 'Wikipedia:WikiProject Check Wikipedia/Translation'				if ($project eq 'rowiki') ;
	$translation_page = 'Wikipédia:WikiProjekt Check Wikipedia/Translation'				if ($project eq 'skwiki') ;
	$translation_page = 'Wikipedia:Projekt wikifiering/Syntaxfel/Translation'			if ($project eq 'svwiki') ;
	$translation_page = 'Vikipedi:Vikipedi proje kontrolü/Çeviri'  						if ($project eq 'trwiki') ;
	$translation_page = 'Вікіпедія:Проект:Check Wikipedia/Translation'  				if ($project eq 'ukwiki') ;
	$translation_page = 'װיקיפּעדיע:קאנטראלירן_בלעטער/Translation'  					if ($project eq 'yiwiki') ;
	$translation_page = '维基百科:错误检查专题/翻译'  											if ($project eq 'zhwiki') ;

	
	my $translation_input = raw_text($translation_page);
	$translation_input = replace_special_letters($translation_input);
	#print $translation_input."\n";
	#die;

	my $input_text ='';
	# start_text
	$input_text = get_translation_text($translation_input,  'start_text_'.$project.'=',  'END');
	$start_text = $input_text if ($input_text ne '');

	# description_text
	$input_text = get_translation_text($translation_input,  'description_text_'.$project.'=',  'END');
	$description_text = $input_text if ($input_text ne '');

	# category_text
	$input_text = get_translation_text($translation_input,  'category_001=',  'END' );
	$category_text = $input_text if ($input_text ne '');
	
	# priority
	$input_text = get_translation_text($translation_input,  'top_priority_'.$project.'=',  'END' );
	$top_priority_project = $input_text if ($input_text ne '');	
	$input_text = get_translation_text($translation_input,  'middle_priority_'.$project.'=',  'END' );
	$middle_priority_project = $input_text if ($input_text ne '');
	$input_text = get_translation_text($translation_input,  'lowest_priority_'.$project.'=',  'END' );
	$lowest_priority_project = $input_text if ($input_text ne '');	
	



	
	# find error description
	for (my $i = 1; $i < $number_of_error_description; $i++) {
		my $current_error_number = 'error_';
		$current_error_number = $current_error_number.'0'    if ($i < 10);
		$current_error_number = $current_error_number.'0' 	 if ($i < 100);
		$current_error_number = $current_error_number.$i;
		#print $i, $current_error_number."\n";
		
		# Priority
		$error_description[$i][4] = get_translation_text($translation_input,  $current_error_number.'_prio_'.$project.'=',  'END');
		#print "x".$error_description[$i][4]."x"."\n";
		if 	($error_description[$i][4] ne '') {
			# if a translation was found
			$error_description[$i][4] = int ($error_description[$i][4]);
		} else {
			# if no translation was found
			$error_description[$i][4] = $error_description[$i][0];
		}
		if ($error_description[$i][4] == -1 ) {
			# in project unkown then use prio from script
			$error_description[$i][4] = $error_description[$i][0];
		}
		#print $i."\t".$error_description[$i][0]."\t".$error_description[$i][4]."\n";
		
		$error_description[$i][5] = get_translation_text($translation_input,  $current_error_number.'_head_'.$project.'=',  'END');
		$error_description[$i][6] = get_translation_text($translation_input,  $current_error_number.'_desc_'.$project.'=',  'END');
		#$error_description[$i][9]  = get_translation_text_XHTML($error_description[$i][5]);	# don't work
		#$error_description[$i][10] = get_translation_text_XHTML($error_description[$i][6]);	# don't work
	}
	
}

sub get_translation_text {
	my $translation_text = $_[0];
	my $start_tag = $_[1];
	my $end_tag =$_[2];
	my $pos_1 = index($translation_text, $start_tag);
	my $pos_2 = index($translation_text, $end_tag, $pos_1);
	my $result = '';
	if ($pos_1 > -1 and $pos_2 > 0) {
		$result = substr($translation_text, $pos_1, $pos_2 -$pos_1);
		#print $result."\n";
		$result = substr($result, index ($result, '=')+1);
		$result =~ s/^ //g;
		$result =~ s/ $//g;
	}
	return ($result);
}

sub get_translation_text_XHTML{
	# don't work today
	
	# use Wikipedia-API to get XHTML from Wikitext
	# http://www.mediawiki.org/wiki/API:Parsing_wikitext#parse
	# http://en.wikipedia.org/w/api.php?action=parse&text=%5B%5Bfoo%5D%5D%20%5B%5BAPI:Query|bar%5D%5D%20%5Bhttp://www.example.com/%20baz%5D
	
	
	my $translation_text = $_[0];
	my $xhtml_text = '';
	print 'Translation='.$translation_text."\n";
	if ($translation_text ne '') {
		my $url = '';
		$url = $home;
		$url =~ s/\/wiki\//\/w\//;
		$url = $url.'api.php?action=parse&text='.$translation_text;
		
		print 'URL='.$url."\n";
		my $response ;
		my $ua = LWP::UserAgent->new;
		$response = $ua->get( $url );
		my $content = $response->content;
		$xhtml_text  = $content if ($content) ;
		
		# only text, delete all other
		my $pos = index($xhtml_text, 'text xml:space='); 
		$xhtml_text  = substr ($xhtml_text ,$pos);
		$pos = index($xhtml_text, '</span>')+length('</span>'); 
		$xhtml_text  = substr ($xhtml_text ,$pos);
		$pos = index($xhtml_text, '>&lt;/text&gt;</span>'); 
		$xhtml_text  = substr ($xhtml_text ,0, $pos);
		$pos = index($xhtml_text, '<span');
		$xhtml_text  = substr ($xhtml_text ,0, $pos);

		# convert
		$xhtml_text =~ s/&amp;/&/g;
		$xhtml_text =~ s/&lt;/</g;
		$xhtml_text =~ s/&gt;/>/g;
		$xhtml_text =~ s/&quot;/>/g;
		$xhtml_text =~ s/&amp;/&/g;
		$xhtml_text =~ s/&lt;/</g;
		$xhtml_text =~ s/&gt;/>/g;
		$xhtml_text =~ s/&quot;/>/g;
		#$xhtml_text =~ s/&quot;/"/g;
		#$xhtml_text =~ s/&#039;/'/g;
		
		
	}	
	print 'XHTML='.$xhtml_text ."\n";
	return ($xhtml_text);
}

	

sub output_errors_desc_in_db{
	if ($load_modus_done eq 'yes' and $dump_or_live eq 'live') {
		print 'insert new and update old description in the database'."\n"  if ($silent_modus ne 'silent');

	# mysql> desc cw_error_desc;
	# +-----------------+---------------+------+-----+---------+-------+
	# | Field           | Type          | Null | Key | Default | Extra |
	# +-----------------+---------------+------+-----+---------+-------+
	# | project         | varchar(100)  | YES  |     | NULL    |       |
	# | id              | int(8)        | YES  |     | NULL    |       |
	# | prio            | int(4)        | YES  |     | NULL    |       |
	# | name            | varchar(255)  | YES  |     | NULL    |       |
	# | text            | varchar(4000) | YES  |     | NULL    |       |
	# | name_html       | varchar(255)  | YES  |     | NULL    |       |
	# | text_html       | varchar(4000) | YES  |     | NULL    |       |
	# | name_wiki_trans | varchar(255)  | YES  |     | NULL    |       |
	# | text_wiki_trans | varchar(4000) | YES  |     | NULL    |       |
	# | name_html_trans | varchar(255)  | YES  |     | NULL    |       |
	# | text_html_trans | varchar(4000) | YES  |     | NULL    |       |
	# +-----------------+---------------+------+-----+---------+-------+

	


		for (my $i = 1; $i < $number_of_error_description; $i++) {
			my $sql_headline = $error_description[$i][1];
			$sql_headline =~ s/'/\\'/g;
			my $sql_desc = $error_description[$i][2];
			$sql_desc =~ s/'/\\'/g;
			$sql_desc = substr( $sql_desc, 0, 3999);				# max 4000
			my $sql_headline_trans = $error_description[$i][5];
			$sql_headline_trans =~ s/'/\\'/g;
			my $sql_desc_trans     = $error_description[$i][6];
			$sql_desc_trans =~ s/'/\\'/g;
			$sql_desc = substr( $sql_desc_trans, 0, 3999);			# max 4000
			
			
			
			# insert or update error
			my $sql_text2 = "update cw_error_desc 
			set prio=".$error_description[$i][4].", 
			name='".$sql_headline."' ,
			text='".$sql_desc."',
			name_trans='".$sql_headline_trans."' ,
			text_trans='".$sql_desc_trans."' 
			where id = ". $i." 
			and  project = '". $project."'
			;";
			#print $sql_text2."\n" if ($i == 18 or $i ==67 or $i ==91);
			my $sth = $dbh->prepare( $sql_text2 );
			my $x = $sth->execute;
			if ( $x eq '1')  {
				#print 'Update '.$x.' rows'."\n";
			} else {
				print 'new error - description insert into db'."\n";
				$sql_text2 = "insert into cw_error_desc (project, id, prio, name, text, name_trans, text_trans) 
							values ('". $project."', ". $i.", ".$error_description[$i][4].", '".$sql_headline."' ,'".$sql_desc."',
							'".$sql_headline_trans."' ,'".$sql_desc_trans."' );";	
				# print $sql_text2."\n"; 
				$sth = $dbh->prepare( $sql_text2 );
				$sth->execute;
			
			}
			
			
		}	
	}
}

sub output_text_translation_wiki{	
	# Output of translation-file
	my $filename = $output_directory.$project.'/'.$project.'_'.$translation_file;
	print 'Output translation:'."\t".$project.'_'.$translation_file."\n"  if ($silent_modus ne 'silent');
	
	open(TRANSLATION, ">$filename");
	
	#######################################
	print TRANSLATION '<pre>'."\n";
	print TRANSLATION ' new translation text under http://toolserver.org/~sk/checkwiki/'.$project.'/'. " (updated daily) \n";
	
	print TRANSLATION '#########################'."\n";
	print TRANSLATION '# metadata'."\n";
	print TRANSLATION '#########################'."\n";
	
	print TRANSLATION ' project='.$project." END\n";
	print TRANSLATION ' category_001='.$category_text." END  #for example: [[Category:Wikipedia]] \n";
	print TRANSLATION "\n";

	print TRANSLATION '#########################'."\n";
	print TRANSLATION '# start text'."\n";
	print TRANSLATION '#########################'."\n";
	print TRANSLATION "\n";
	print TRANSLATION ' start_text_'.$project.'='.$start_text." END\n";
	
	print TRANSLATION '#########################'."\n";
	print TRANSLATION '# description'."\n";
	print TRANSLATION '#########################'."\n";
	print TRANSLATION "\n";	
	print TRANSLATION ' description_text_'.$project.'='.$description_text." END\n";
	
	print TRANSLATION '#########################'."\n";
	print TRANSLATION '# priority'."\n";
	print TRANSLATION '#########################'."\n";
	print TRANSLATION "\n";

	print TRANSLATION ' top_priority_script='.$top_priority_script." END\n";
	print TRANSLATION ' top_priority_'.$project.'='.$top_priority_project." END\n";
	print TRANSLATION ' middle_priority_script='.$middle_priority_script." END\n";
	print TRANSLATION ' middle_priority_'.$project.'='.$middle_priority_project." END\n";
	print TRANSLATION ' lowest_priority_script='.$lowest_priority_script." END\n";
	print TRANSLATION ' lowest_priority_'.$project.'='.$lowest_priority_project." END\n";
	print TRANSLATION "\n";
	print TRANSLATION " Please only translate the variables with …_".$project." at the end of the name. Not …_script= .\n";
	

	
	########################################
	#my $number_of_error_description = 1;
	#while  ($error_description[$number_of_error_description][1] ne '') {
		#print $number_of_error_description.' '. $error_description[$number_of_error_description][1]."\n";
	#	$number_of_error_description = $number_of_error_description + 1;
	#}
	#until ($error_description[$number_of_error_description][1] ne '');		# english Headline existed
	
	print 'error description:'."\t".$number_of_error_description." (-1) \n"   if ($silent_modus ne 'silent');
	print TRANSLATION '#########################'."\n";
	print TRANSLATION '# error description'."\n";
	print TRANSLATION '#########################'."\n";
	print TRANSLATION '# prio = -1 (unknown)'."\n";
	print TRANSLATION '# prio = 0  (deactivated) '."\n";
	print TRANSLATION '# prio = 1  (top priority)'."\n";
	print TRANSLATION '# prio = 2  (middle priority)'."\n";
	print TRANSLATION '# prio = 3  (lowest priority)'."\n";
	print TRANSLATION "\n";
	
	
	for (my $i = 1; $i < $number_of_error_description; $i++) {
		
		my $current_error_number = 'error_';
		$current_error_number = $current_error_number.'0'    if ($i < 10);
		$current_error_number = $current_error_number.'0'.$i if ($i < 100);
		print TRANSLATION ' '.$current_error_number.'_prio_script='.$error_description[$i][0]." END\n";
		print TRANSLATION ' '.$current_error_number.'_head_script='.$error_description[$i][1]." END\n";
		print TRANSLATION ' '.$current_error_number.'_desc_script='.$error_description[$i][2]." END\n";
		print TRANSLATION ' '.$current_error_number.'_prio_'.$project.'='.$error_description[$i][4]." END\n";
		print TRANSLATION ' '.$current_error_number.'_head_'.$project.'='.$error_description[$i][5]." END\n";
		print TRANSLATION ' '.$current_error_number.'_desc_'.$project.'='.$error_description[$i][6]." END\n";
		print TRANSLATION "\n";
		print TRANSLATION '###########################################################################'."\n";
		print TRANSLATION "\n";
	}	
	
	print TRANSLATION '</pre>'."\n";
	close(TRANSLATION);		
	
}

sub output_little_statistic{
	print 'errors found:'."\t\t".$error_counter." (+1)\n";
}


sub output_duration {
	$time_end = time();
	my $duration = $time_end - $time_start;
	my $duration_minutes = int($duration / 60);
	my $duration_secounds = int(((int(100 * ($duration / 60)) / 100)-$duration_minutes)*60);
	
	print 'Duration:'."\t\t".$duration_minutes.' minutes '.$duration_secounds.' secounds'."\n";
	print $project.' '.$dump_or_live."\n" 		if ($silent_modus ne 'silent');
}

#############################################################################

sub check_article{
	
	my $steps = 500;
	$steps = 1 if ($dump_or_live eq 'live');
    $steps = 5000 if ($silent_modus eq 'silent');


	if (   $title eq 'At-Tabarī'
		or $title eq 'Rumänien'
		or $title eq 'Liste der Ortsteile im Saarland') {
		# $details_for_page = 'yes';
	}
	
	my $text_for_tests = "Hallo
Barnaby, Wendy. The Plague Makers: The Secret World of Biological Warfare, Frog Ltd, 1999. 
in en [[Japanese war crimes]]
<noinclude>
</noinclude>
{{DEFAULTSORT:Role-playing game}}
=== Test ===
<onlyinclude></onlyinclude>
<includeonly></includeonly>
ISBN 1-883319-85-4 ISBN 0-7567-5698-7 ISBN 0-8264-1258-0 ISBN 0-8264-1415-X
* Tulku - ISBN 978 90 04 12766 0 (wrong ISBN)
:-sdfsdf[[http://www.wikipedia.org Wikipedia]] chack tererh
:#sadf
ISBN 3-8304-1007-7  ok
ISBN 3-00-016815-X  ok 
ISBN 978-0-8330-3930-9  ok
ISBN3-00-016815-X
[[Category:abc]] and [[Category:Abc]]&auml
[[1911 př. n. l.|1911]]–[[1897 př. n. l.|1897]] př. n. l.
Rodné jméno = <hiero><--M17-Y5:N35-G17-F4:X1--></hiero> <br />
Trůnní jméno = <hiero>M23-L2-<--N5:S12-D28*D28:D28--></hiero><br />
<references group='Bild' />&Ouml  124345
===This is a headline with reference <ref>A reference with '''bold''' text</ref>===
Nubkaure 
<hiero>-V28-V31:N35-G17-C10-</hiero>
Jméno obou paní = &uuml<hiero>-G16-V28-V31:N35-G17-C10-</hiero><br />
[[Image:logo|thumb| < small> sdfsdf</small>]]
<ref>Abu XY</ref>

im text ISBN 3-8304-1007-7 im text  <-- ok
im text ISBN 3-00-016815-X im text   ok
im text ISBN 978-0-8330-3930-9 im text   ok
[[Image:logo|thumb| Part < small> Part2</small> Part2]]
[[Image:logo|thumb| Part < small> Part</small>]]
ISBN-10 3-8304-1007-7	   bad
ISBN-10: 3-8304-1007-7	   bad
ISBN-13 978-0-8330-3930-9	   bad
ISBN-13: 978-0-8330-3930-9	-->bad
<ref>Abu XY</ref>

ISBN 123451678XXXX 	bad
ISBN 123456789x 	ok
ISBN 3-00-0168X5-X  bad

*ISBN 3-8304-1007-7 121 Test ok
*ISBN 3-8304-1007-7121 Test bad
*ISBN 3 8304 1007 7 121 Test ok
*ISBN 978-0-8330-39 309 Test ok
*ISBN 9 7 8 0 8 3 3 0 3 9 3 0 9 Test bad 10 ok 13

[http://www.dehoniane.it/edb/cat_dettaglio.php?ISBN=24109]	bad
{{test|ISBN=3 8304 1007 7 121 |test=[[text]]}}	bad
[https://www5.cbonline.nl/pls/apexcop/f?p=130:1010:401581703141772 ISBN-bureau] bad

	
ISBN 3-8304-1007-7

<\br>
</br>
[[:hu:A Gibb fivérek által írt dalok listája]] Big Problem
[[en:Supermann]]
testx
=== Liste ===
test
=== 1Acte au sens d'''instrumentum'' ===
<math>tesxter</math>
=== 2Acte au sens d'''instrumentum''' ===

 
	
== 3Acte au sens d''instrumentum'' ==

ISBN 978-88-10-24109-7

* ISBN 0-691-11532-X ok
* ISBN 123451678XXXX bad
* ISBN-10 1234567890 bad
* ISBN-10: 1234567890 bad
* ISBN-13 1234567890123 bad
* ISBN-13: 1234567890123 bad
* ISBN 123456789x Test ok
* ISBN 123456789x x12 Test
* ISBN 123456789012x Test
* ISBN 1234567890 12x Test
* ISBN 123456789X 123 Test
* ISBN 1 2 3 4 5 6 7 8 9 0 Test

[http://www.dehoniane.it/edb/cat_dettaglio.php?ISBN=24109]
[https://www5.cbonline.nl/pls/apexcop/f?p=130:1010:401581703141772 ISBN-bureau]

* Tramlijn_Ede_-_Wageningen - ISBN-nummer
* Tulku - ISBN 978 90 04 12766 0 (wrong ISBN)
* Michel_Schooyans - [http://www.dehoniane.it/edb/cat_dettaglio.php?ISBN=24109]
*VARA_gezinsencyclopedie - [https://www5.cbonline.nl/pls/apexcop/f?p=130:1010:401581703141772 ISBN-bureau]


Testtext hat einen [[|Link]], der nirgendwo hinführt.<ref>Kees Heitink en Gert Jan Koster, De tram rijdt weer!: Bennekomse tramgeschiedenis 1882 - 1937 - 1968 - 2008, 28 bladzijden, geen ISBN-nummer, uitverkocht.</ref>.
=== 4Acte au sens d''instrumentum'' ===
[[abszolútérték-függvény||]] ''f''(''x'') – ''f''(''y'') [[abszolútérték-függvény||]] aus huwiki
 * [[Antwerpen (stad)|Antwerpen]] heeft na de succesvolle <BR>organisatie van de Eurogames XI in [[2007]] voorstellen gedaan om editie IX van de Gay Games in [[2014]] of eventueel de 3e editie van de World OutGames in [[2013]] naar Antwerpen te halen. Het zogeheten '[[bidbook]]' is ingediend en het is afwachten op mogelijke toewijzing door de internationale organisaties. <br>
*a[[B:abc]]<br>
*bas addf< br>
*casfdasdf< br >
*das fdasdf< br / >
[[Che&#322;mno]] and 
sdfsf ISBN 3434462236   
95-98. ISBN 0 7876 5784 0. .
=== UNO MANDAT ===
0-13-110370-9
* [http://www.research.att.com/~bs/3rd.html The C++ Programming Language]: [[Bjarne Stroustrup]], special ed., Addison-Weslye, ISBN 0-201-70073-5, 2000
* The C++ Standard, Incorporating Technical Corrigendum 1, BS ISO/IEC 14882:2003 (2nd ed.), John Wiley & Sons, ISBN 0-470-84674-7
* [[Brian Kernighan|Brian W. Kernighan]], [[Dennis Ritchie|Dennis M. Ritchie]]: ''[[The C Programming Language]]'', Second Edition, Prentice-Hall, ISBN 0-13-110370-9 1988
* [http://kmdec.fjfi.cvut.cz/~virius/publ-list.html#CPP Programování v C++]: Miroslav Virius, [http://www.cvut.cz/cs/uz/ctn Vydavatelství ČVUT], druhé vydání, ISBN 80-01-02978-6 2004
* Naučte se C++ za 21 dní: Jesse Liberty, [http://www.cpress.cz/ Computer Press], ISBN 80-7226-774-4, 2002
* Programovací jazyk C++ pro zelenáče: Petr Šaloun, [http://www.neo.cz Neokortex] s.r.o., ISBN 80-86330-18-4, 2005
* Rozumíme C++: Andrew Koenig, Barbara E. Moo, [http://www.cpress.cz/ Computer Press], ISBN 80-7226-656-X, 2003
* [http://gama.fsv.cvut.cz/~cepek/uvodc++/uvodc++-2004-09-11.pdf Úvod do C++]: Prof. Ing. Aleš Čepek, CSc., Vydavatelství ČVUT, 2004
*eaa[[abc]]< br /  > 
<ref>sdfsdf</ref> .
Verlag LANGEWIESCHE, ISBN-10: 3784551912 und ISBN-13: 9783784551913 
=== Meine Überschrift ABN === ISBN 1234-X-1234
*fdd asaddf&hellip;</br 7> 
{{Zitat|Der Globus ist schön. <ref name='asda'>Buch 27</ref>}}
{{Zitat|Madera=1000 <ref name='asda'>Buch 27</ref>|Kolumbus{{Höhe|name=123}}|kirche=4 }}
==== Саларианцы ====
[[Breslau]] ([[Wroc&#322;aw]])
*gffasfdasdf<\br7>
{{Testvorlage|name=heeft na de succesvolle <BR>organisatie van de [[Eurogames XIa|Eurogames XI]] inheeft na de succesvolle <BR>organisatie van de Eurogames XI inheeft na de succesvolle <BR>organisatie van de Eurogames XI in123<br>|ott]o=kao}}
*hgasfda sdf<br />
<ref>sdfsdf2</ref>!
<br><br> 
===== PPM, PGM, PBM, PNM =====
===== PPM, PGM, PBM, PNM =====

" .'test<br1/><br/1>&ndash;uberlappung<references />3456Ende des Text';
	
#	$text = $text_for_tests;
	
	get_namespace();
	print_article_title_every_x( $steps );
	delete_old_errors_in_db();
	
	get_comments_nowiki_pre();
	
	get_math();			
	get_source();
	get_code();
	get_syntaxhighlight();
	get_isbn();
	get_templates();
	get_links();
	get_images();
	get_tables();
	get_gallery();
	get_hiero();	#problem with <-- and --> (error 056)
	get_ref();
	
	check_for_redirect();
	get_categories();
	get_interwikis();
	
	create_line_array();
	get_line_first_blank();
	get_headlines();
	
	error_check();
	
	
	#get_coordinates() if (-e $file_module_coordinate) ;
	#get_persondata();
	
	set_article_as_scan_live_in_db($title, $page_id) if ($dump_or_live eq 'live');
	
	
}

sub print_article_title_every_x{
	#print in the Loop every x article a short message
	#Output every x articles
	my $steps =$_[0];
	#print "$page_number \t$title\n";
	my $x = int( $page_number / $steps ) * $steps ;
	my $counter_output = '';
	my $project_output = $project;
	$project_output =~ s/wiki//;
	$counter_output .= $project_output.' ';
	$counter_output .= 'p='.$page_number.' ';
	
	if ($dump_or_live eq 'live') {
		my $output_current_live_article = $current_live_article + 1;
		$counter_output .= $current_live_error_scan.'/'.$output_current_live_article.'/'.$number_article_live_to_scan;
	}
	$counter_output .= ' id='.$page_id.' ';
	$counter_output .= $title."\n";
	if (   $page_number == 1 or $page_number == $x ) {
		print $counter_output;
	}
	print LOGFILE $counter_output if ($starter_modus	ne 'starter');

	
}

sub delete_old_errors_in_db{
	# delete article in database
	#print $page_id."\t".$title."\n";
	if ( $dump_or_live eq 'live' 
		 and $page_id 
		 and $title ne '' ) {
		my $sql_text = "delete from cw_error where error_id = ". $page_id." and  project = '". $project."';";
		#print $sql_text."\n\n";
		my $sth = $dbh->prepare( $sql_text );
		$sth->execute;
	}
}

sub get_namespace{
	# check the namespace of an article
	# if here is an error then maybe it is a new namespace in this project; show sub load_metadata_from_file
	if ( index( $title, ':' ) > -1) {
		#print 'Get namespace for: '.$title."\n";
		for (my $i = 0; $i < $namespaces_count; $i++) {
			#print $i." ".$namespace[$i][0]." ".$namespace[$i][1]." ".$namespace[$i][2] ."\n" ;#if ($title eq 'Sjabloon:Gemeente');	
			$page_namespace = $namespace[$i][0] if ( index ($title, $namespace[$i][1].':') == 0);
			$page_namespace = $namespace[$i][0] if ( index ($title, $namespace[$i][2].':') == 0);
		}
		
		#print $page_namespace."\n" ;#if ($title eq 'Sjabloon:Gemeente');
		#print $namespacealiases_count."\n";
		for (my $i = 0; $i < $namespacealiases_count; $i++) {
			#print $i." ".$namespacealiases[$i][0]." ".$namespacealiases[$i][1] ."\n" ;#if ($title eq 'Sjabloon:Gemeente');	
			$page_namespace = $namespacealiases[$i][0] if ( index ($title, $namespacealiases[$i][1].':') == 0);
		}		
		#print $page_namespace."\n" ;#if ($title eq 'Sjabloon:Gemeente');		
		$page_namespace = 0 if ($page_namespace == -100);

	} else {
		$page_namespace = 0;
	}
	
}



sub get_comments_nowiki_pre{
	my $last_pos = -1;
	my $pos_comment = -1;
	my $pos_nowiki  = -1;
	my $pos_pre     = -1;
	my $pos_first = -1;
	my $loop_again = 0;
	do {
		
		# next tag
		$pos_comment = index ($text, '<!--', $last_pos);
		$pos_nowiki  = index ($text, '<nowiki>', $last_pos);
		$pos_pre     = index ($text, '<pre>', $last_pos);
		$pos_pre     = index ($text, '<pre ', $last_pos) if ($pos_pre == -1);
		#print $pos_comment.' '.$pos_nowiki.' '.$pos_pre."\n";
		
		#first tag
		my $tag_first = '';
		$tag_first = 'comment'    if(      $pos_comment > -1 );
		$tag_first = 'nowiki'     if(    ( $pos_nowiki  > -1  and $tag_first eq '')
									   or( $pos_nowiki  > -1  and $tag_first eq 'comment' and  $pos_nowiki < $pos_comment));
		$tag_first = 'pre'     	  if(    ( $pos_pre     > -1  and $tag_first eq '')
									   or( $pos_pre     > -1  and $tag_first eq 'comment' and  $pos_pre < $pos_comment)
									   or( $pos_pre     > -1  and $tag_first eq 'nowiki'  and  $pos_pre < $pos_nowiki));
		#print $tag_first."\n";
									   
 	    #check end tag
		my $pos_comment_end = index ($text, '-->', 			$pos_comment + length('<!--')     );
		my $pos_nowiki_end  = index ($text, '</nowiki>', 	$pos_nowiki  + length('<nowiki>') );
		my $pos_pre_end     = index ($text, '</pre>', 		$pos_pre     + length('<pre')    );			
		
		#comment
		if ($tag_first eq 'comment' and $pos_comment_end > -1) {
			#found <!-- and -->
			$last_pos = get_next_comment($pos_comment + $last_pos);
			$loop_again = 1;
			#print 'comment'.' '.$pos_comment.' '.$last_pos."\n";
		}
		if ($tag_first eq 'comment' and $pos_comment_end == -1) {
			#found <!-- and no -->
			$last_pos = $pos_comment +1;
			$loop_again = 1;
			#print 'comment no end'."\n";
			my $text_output = substr( $text, $pos_comment);
			$text_output   = text_reduce($text_output, 80);
			error_005_Comment_no_correct_end ('check', $text_output );
			#print $text_output."\n";
		}
		
		#nowiki
		if ($tag_first eq 'nowiki' and $pos_nowiki_end > -1) {
			# found <nowiki> and </nowiki>
			$last_pos = get_next_nowiki($pos_nowiki + $last_pos);
			$loop_again = 1;
			#print 'nowiki'.' '.$pos_nowiki.' '.$last_pos."\n";
		}
		if ($tag_first eq 'nowiki' and $pos_nowiki_end == -1) {
			# found <nowiki> and no </nowiki>
			$last_pos = $pos_nowiki +1;
			$loop_again = 1;
			#print 'nowiki no end'."\n";
			my $text_output = substr( $text,$pos_nowiki);
			$text_output   = text_reduce($text_output, 80);
			error_023_nowiki_no_correct_end('check', $text_output  );
		}		
		
		#pre
		if ($tag_first eq 'pre' and $pos_pre_end > -1) {
			# found <pre> and </pre>
			$last_pos = get_next_pre($pos_pre + $last_pos);
			$loop_again = 1;
			#print 'pre'.' '.$pos_pre.' '.$last_pos."\n";
		}
		if ($tag_first eq 'pre' and $pos_pre_end == -1) {
			# found <pre> and no </pre>
			#print $last_pos.' '.$pos_pre."\n";
			$last_pos = $pos_pre +1;
			$loop_again = 1;
			#print 'pre no end'."\n";
			my $text_output = substr( $text,$pos_pre);
			$text_output   = text_reduce($text_output, 80);
			error_024_pre_no_correct_end ('check', $text_output);
		}		
		
		#end 
		if ($pos_comment == -1
		    and $pos_nowiki == -1 
			and $pos_pre == -1) {
			# found no <!-- and no <nowiki> and no <pre>	
			$loop_again = 0;
			
		}
	}
	until ( $loop_again == 0);
	$text_without_comments = $text;

	
}

sub get_next_pre{
		#get position of next comment
	my $pos_start = index ( $text, '<pre');
	my $pos_end   = index ( $text, '</pre>', $pos_start ) ;
	my $result = $pos_start + length('<pre');
	
	if ($pos_start > -1 and $pos_end >-1) {
		#found a comment in current page
		$pos_end = $pos_end + length('</pre>');
		#$comment_counter = $comment_counter +1;
		#$comments[$comment_counter][0] = $pos_start;
		#$comments[$comment_counter][1] = $pos_end;
		#$comments[$comment_counter][2] = substr($text, $pos_start, $pos_end - $pos_start  );

		#print 'Begin='.$comments[$comment_counter][0].' End='.$comments[$comment_counter][1]."\n";
		#print 'Comment='.$comments[$comment_counter][2]."\n";

		#replace comment with space
		my $text_before = substr( $text, 0, $pos_start );
		my $text_after  = substr( $text, $pos_end );
		my $filler = '';
		for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
				$filler = $filler.' ';
		}
		$text = $text_before.$filler.$text_after;
		$result = $pos_end;
	} 
	return ($result );
	
}

sub get_next_nowiki{
		#get position of next comment
	my $pos_start = index ( $text, '<nowiki>' );
	my $pos_end   = index ( $text, '</nowiki>', $pos_start ) ;
	my $result = $pos_start + length('<nowiki>');
		
	if ($pos_start > -1 and $pos_end >-1) {
		#found a comment in current page
		$pos_end = $pos_end + length('</nowiki>');

		#replace comment with space
		my $text_before = substr( $text, 0, $pos_start );
		my $text_after  = substr( $text, $pos_end );
		my $filler = '';
		for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
				$filler = $filler.' ';
		}
		$text = $text_before.$filler.$text_after;
		$result = $pos_end;
	} 
	return ($result );
}
sub get_next_comment{
	my $pos_start = index ( $text, '<!--');
	my $pos_end   = index ( $text, '-->', $pos_start + length('<!--') ) ;
	my $result = $pos_start + length('<!--');	
	if ($pos_start > -1 and $pos_end >-1) {
		#found a comment in current page
		$pos_end = $pos_end + length('-->');
		$comment_counter = $comment_counter +1;
		$comments[$comment_counter][0] = $pos_start;
		$comments[$comment_counter][1] = $pos_end;
		$comments[$comment_counter][2] = substr($text, $pos_start, $pos_end - $pos_start  );
		#print $comments[$comment_counter][2]."\n";
		
		#replace comment with space
		my $text_before = substr( $text, 0, $pos_start );
		my $text_after  = substr( $text, $pos_end );
		my $filler = '';
		for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
				$filler = $filler.' ';
		}
		$text = $text_before.$filler.$text_after;
		$result = $pos_end;
	}
	return ($result );

}


sub get_math {
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';
	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next <math>
		$pos_start =     index ( lc($text), '<math>'        , $pos_start_old);
		my $pos_start2 = index ( lc($text), '<math style='  , $pos_start_old);
		my $pos_start3 = index ( lc($text), '<math title='  , $pos_start_old);
		my $pos_start4 = index ( lc($text), '<math alt='    , $pos_start_old);
		
		#print $pos_start.' '. $pos_end .' '.$pos_start2."\n";
		if ($pos_start == -1 
			or ($pos_start > -1 
				and $pos_start2 > -1 
				and $pos_start > $pos_start2 )){
			 $pos_start	= $pos_start2;
		}
		if ($pos_start == -1 
			or ($pos_start > -1 
				and $pos_start3 > -1 
				and $pos_start > $pos_start3 )){
			 $pos_start	= $pos_start3;
		}
		if ($pos_start == -1 
			or ($pos_start > -1 
				and $pos_start4 > -1 
				and $pos_start > $pos_start4 )){
			 $pos_start	= $pos_start4;
		}	
		$pos_end   = index ( lc($text), '</math>'     , $pos_start + length('<math')) ;
	
		#print $pos_start.' '. $pos_end ."\n";
		if ($pos_start > -1 and $pos_end >-1) {
			#found a math in current page
			$pos_end = $pos_end + length('</math>');
			#print substr($text, $pos_start, $pos_end - $pos_start  )."\n";			

			$end_search = 'no';
			$pos_start_old = $pos_end;

			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			error_013_Math_no_correct_end ('check', substr( $text, $pos_start, 50) );
			#print 'Math:'.substr( $text, $pos_start, 50)."\n";
			$end_search = 'yes';
		}
		
	}
	until ( $end_search eq 'yes') ;	
}

sub get_source {
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';

	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next <math>
		$pos_start = index ( $text, '<source', $pos_start_old); 
		$pos_end   = index ( $text, '</source>', $pos_start + length( '<source')  ) ;
		if ($title eq 'ALTER'){
			print $pos_start."\n";
			print $pos_end."\n";
		}
		
		if ($pos_start > -1 and $pos_end >-1) {
			#found a math in current page
			$pos_end = $pos_end + length('</source>');
			#print substr($text, $pos_start, $pos_end - $pos_start  )."\n";			

			$end_search = 'no';
			$pos_start_old = $pos_end;

			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			error_014_Source_no_correct_end ('check', substr( $text, $pos_start, 50) );
			#print 'Source:'.substr( $text, $pos_start, 50)."\n";
			$end_search = 'yes';
		}
		
	}
	until ( $end_search eq 'yes') ;	

	
	
}

sub get_syntaxhighlight {
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';

	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next <math>
		$pos_start = index ( $text, '<syntaxhighlight', $pos_start_old); 
		$pos_end   = index ( $text, '</syntaxhighlight>', $pos_start + length( '<syntaxhighlight')  ) ;
		if ($title eq 'ALTER'){
			print $pos_start."\n";
			print $pos_end."\n";
		}
		
		if ($pos_start > -1 and $pos_end >-1) {
			#found a math in current page
			$pos_end = $pos_end + length('</syntaxhighlight>');
			#print substr($text, $pos_start, $pos_end - $pos_start  )."\n";			

			$end_search = 'no';
			$pos_start_old = $pos_end;

			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			#error_014_Source_no_correct_end ('check', substr( $text, $pos_start, 50) );
			#print 'Source:'.substr( $text, $pos_start, 50)."\n";
			$end_search = 'yes';
		}
		
	}
	until ( $end_search eq 'yes') ;	

	
	
}

sub get_code {
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';
	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next <math>
		$pos_start = index ( $text, '<code>', $pos_start_old);
		$pos_end   = index ( $text, '</code>', $pos_start ) ;
	
		if ($pos_start > -1 and $pos_end >-1) {
			#found a math in current page
			$pos_end = $pos_end + length('</code>');
			#print substr($text, $pos_start, $pos_end - $pos_start  )."\n";			

			$end_search = 'no';
			$pos_start_old = $pos_end;

			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			error_015_Code_no_correct_end ('check', substr( $text, $pos_start, 50) );
			#print 'Code:'.substr( $text, $pos_start, 50)."\n";
			$end_search = 'yes';
		}
		
	}
	until ( $end_search eq 'yes') ;	
}
##################################################################
sub get_isbn {
	# get all isbn

	if (index ($text, 'ISBN') > 0
		and $title ne 'International Standard Book Number'
		and $title ne 'ISBN'
		and $title ne 'ISBN-10'
		and $title ne 'ISBN-13'
		and $title ne 'Internationaal Standaard Boeknummer'
		and $title ne 'International Standard Book Number'
		and $title ne 'European Article Number'
		and $title ne 'Internationale Standardbuchnummer'
		and $title ne 'Buchland'
		and $title ne 'Codice ISBN'
		and index ($title, 'ISBN') == -1
		# better with show too interwiki !!!
		
		) {
		my $text_test = $text;
		#print "\n\n".'###################################################'."\n";
		while($text_test =~ /ISBN([ ]|[-]|[=])/g) {
			my $pos_start = pos($text_test) - 5;
			#print "\n\n";
			#print $pos_start."\n";
			my $current_isbn = substr($text_test, $pos_start);	
			
			my $output_isbn =  substr ($current_isbn,0,50);
			$output_isbn =~ s/\n/ /g;
			#print $output_isbn."\n";

			my $result_isbn = '';
			my $i = -1;
			my $finish = 'no';
			#print 'isbn: '."\t".$current_isbn."\n";

			# \tab
			$current_isbn =~ s/\t/ /;

			if ( $current_isbn =~ /^([ ]+)?ISBN=([ ]+)?/) {
				#print 'ISBN in Link'."\n";
				# ISBN = 01234566 in templates
				$current_isbn =~ s/^([ ]+)?ISBN([ ]+)?=([ ]+)?/ /;
				#if ( length($current_isbn ) == 10
							
				my $pos_open  = index($current_isbn, '[');
				my $pos_close = index($current_isbn, ']');
				#print $pos_open."\n";
				#print $pos_close."\n";
				if ( ($pos_open == -1 and $pos_close > -1)
					 or ($pos_open > -1 and $pos_close > -1 and $pos_open > $pos_close ) ) {
					# [[nl:Michel_Schooyans]] - [http://www.dehoniane.it/edb/cat_dettaglio.php?ISBN=24109]
					#print "\t".'Get ISBN: ISBN in Link: '."\t"."\n";
					$current_isbn = 'ISBN';
				}
			}


			
			if ( $current_isbn =~ /^([ ]+)?ISBN-[^1]/ ) {
				# text "ISBN-number"
				# text "ISBN-bureau"
				#print "\t".'Get ISBN: ISBN with Minus'."\t"."\n";
				$current_isbn = 'ISBN';
			}	
			
			
			#print "\t".'Get ISBN 2: '."\t".substr($current_isbn, 0, 45)."\n";
			my $pos_next_ISBN = index($current_isbn, 'ISBN', 4);
			if ($pos_next_ISBN > -1) {
				#many ISBN behind the first ISBN
				# "ISBN 1-883319-85-4 ISBN 0-7567-5698-7 ISBN 0-8264-1258-0 ISBN 0-8264-1415-X")
				$current_isbn = substr ( $current_isbn , 0, $pos_next_ISBN);
			}
			$current_isbn =~ s/ISBN//g;
			#print "\t".'Get ISBN 2b: '."\t".substr($current_isbn, 0, 45)."\n";
			
			do 
			{
				$i ++;
				if ( $i <= length($current_isbn) ) {
					my $character = substr($current_isbn, $i, 1 );
					if ($character =~ /[ 0-9Xx\-]/) {
						$result_isbn = $result_isbn .$character;
					} else {
						$finish = 'yes';
					}
				} else {
					$finish = 'yes';
				}
				
				
			}
			until ($finish eq 'yes');
			
			
			
			
			
			if ($result_isbn =~ /[^ ]/
				and $result_isbn =~ /[0-9]/ ) {
				$result_isbn  =~ s/^([ ]+)?//g;
				$result_isbn  =~ s/([ ]+)?$//g;
				#print "\t".'Get ISBN 2: '."\t".$result_isbn."\n";
				push (@isbn, $result_isbn);
				check_isbn( $result_isbn);
			}
		}
	}
	
	

}

sub check_isbn{
	my $current_isbn = $_[0];
	#print 'check: '."\t".$current_isbn."\n";
	# length
	my $test_isbn = $current_isbn;

	$test_isbn =~ s/^([ ]+)?//g;
	$test_isbn =~ s/([ ]+)?$//g;
	$test_isbn =~ s/[ ]//g;
	
	#print "\t".'Check ISBN 1: '."\t_".$test_isbn."_\n";
	my $result = 'yes';

	# length of isbn
	if ($result eq 'yes') {
		if (   index ($test_isbn, '-10') == 0
		    or index ($test_isbn, '-13') == 0) {
			$result = 'no';
			error_069_isbn_wrong_syntax('check', $current_isbn );
		}
	}	

	$test_isbn =~ s/-//g;
	#print "\t".'Check ISBN 2: '."\t_".$test_isbn."_\n";


	# wrong position of X
	if ($result eq 'yes') {
		$test_isbn =~ s/x/X/g;
		if ( index($test_isbn, 'X') >-1 ) {
			# ISBN with X
			#print "\t".'Check ISBN X: '."\t_".$test_isbn."_\n";
			if ( index($test_isbn, 'X') != 9) {
				# ISBN 123456X890
				$result = 'no';
				error_071_isbn_wrong_pos_X('check', $current_isbn );
			}
			if (index($test_isbn, 'X') == 9
				and (length($test_isbn) != 10) ) {
				# ISBN 123451678XXXX b
				$test_isbn = substr($test_isbn, 0, 10);
				#print "\t".'Check ISBN X reduce length: '.$test_isbn."\n";
			}
		}
	}

	my $check_10 = 'no ok';
	my $check_13 = 'no ok';
	my $found_text_10 = '';
	my $found_text_13 = '';
	
	# Check Checksum 13
	if ($result eq 'yes') {
		if (length($test_isbn) >= 13
			and $test_isbn =~/^[0-9]{13}/ 
			) {
			my $checksum = 0;
			$checksum = $checksum + 1 * substr($test_isbn,0,1);
			$checksum = $checksum + 3 * substr($test_isbn,1,1);
			$checksum = $checksum + 1 * substr($test_isbn,2,1);
			$checksum = $checksum + 3 * substr($test_isbn,3,1);
			$checksum = $checksum + 1 * substr($test_isbn,4,1);
			$checksum = $checksum + 3 * substr($test_isbn,5,1);
			$checksum = $checksum + 1 * substr($test_isbn,6,1);
			$checksum = $checksum + 3 * substr($test_isbn,7,1);
			$checksum = $checksum + 1 * substr($test_isbn,8,1);
			$checksum = $checksum + 3 * substr($test_isbn,9,1);
			$checksum = $checksum + 1 * substr($test_isbn,10,1);
			$checksum = $checksum + 3 * substr($test_isbn,11,1);
			
			#print 'Checksum: '."\t".$checksum."\n";
			my $checker = 10 - substr($checksum,length($checksum)-1,1);
			$checker = 0 if ($checker == 10);
			
			#print $checker."\n";
			if ( $checker eq substr($test_isbn,12,1) ){
				$check_13 = 'ok';
			} else {
				$found_text_13 = $current_isbn .'</nowiki> || <nowiki>'. substr($test_isbn,12,1).' vs. '.$checker ;
			}
		}
	}

	# Check Checksum 10
	if ($result eq 'yes') {
		if (length($test_isbn) >= 10
			and $test_isbn =~/^[0-9X]{10}/
			and $check_13 eq  'no ok'
			) {
			my $checksum = 0;
			$checksum = $checksum + 1 * substr($test_isbn,0,1);
			$checksum = $checksum + 2 * substr($test_isbn,1,1);
			$checksum = $checksum + 3 * substr($test_isbn,2,1);
			$checksum = $checksum + 4 * substr($test_isbn,3,1);
			$checksum = $checksum + 5 * substr($test_isbn,4,1);
			$checksum = $checksum + 6 * substr($test_isbn,5,1);
			$checksum = $checksum + 7 * substr($test_isbn,6,1);
			$checksum = $checksum + 8 * substr($test_isbn,7,1);
			$checksum = $checksum + 9 * substr($test_isbn,8,1);
			#print 'Checksum: '."\t".$checksum."\n";
			my $checker = $checksum % 11;
			#print $checker."\n";
			if (    ($checker < 10 and $checker ne substr($test_isbn,9,1) )
				 or ($checker == 10 and 'X' ne substr($test_isbn,9,1) )
				){
				# check wrong and 10 or more characters
				$found_text_10 = $current_isbn .'</nowiki> || <nowiki>'. substr($test_isbn,9,1).' vs. '.$checker.' ('.$checksum.' mod 11)' ;
			} else {
				$check_10 =  'ok' ;
			}
		}
	}


	# length of isbn
	if ($result eq 'yes'
		and not( $check_10 eq 'ok' or $check_13 eq 'ok')
		){
		
		if (     $check_10 eq  'no ok' 
			 and $check_13 eq  'no ok'
			 and length($test_isbn) == 10 
			){
				$result = 'no';
				error_072_isbn_10_wrong_checksum ('check', $found_text_10);
		}
		
		if (     $check_10 eq  'no ok' 
			 and $check_13 eq  'no ok'
			 and length($test_isbn) == 13 
			 ){
				$result = 'no';
				error_073_isbn_13_wrong_checksum ('check', $found_text_13);
		}
		
		if (     $check_10 eq  'no ok' 
			 and $check_13 eq  'no ok'
			 and $result eq 'yes'
			 and length($test_isbn) != 0
			 ) {
				$result = 'no';
				error_070_isbn_wrong_length('check', $current_isbn .'</nowiki> || <nowiki>'. length($test_isbn) );
		}
	}
	
	#if ($result eq 'yes') {
	#	print "\t".'Check ISBN: all ok!'."\n";
	#} else {
	#	print "\t".'Check ISBN: wrong ISBN!'."\n";
	#}
}

##################################################################

sub get_templates{
	# filter all templates
	my $pos_start = 0;
	my $pos_end = 0;

	my $text_test = $text;
	#$text_test = 'abc{{Huhu|name=1|otto=|die=23|wert=as|wertA=[[Dresden|Pesterwitz]] Mein|wertB=1234}}  
	#{{ISD|123}}  {{ESD {{Test|dfgvb}}|123}} {{tzu}} {{poil|ert{{eret|er}}|qwezh}} {{xtesxt} und außerdem 
	#{{Frerd|qwer=0|asd={{mytedfg|poil={{1234|12334}}}}|fgh=123}} und {{mnb|jkl=12|fgh=78|cvb=4567} Ende.';
	
	#print $text_test ."\n\n\n";
	
	$text_test =~ s/\n//g;			# delete all breaks  --> only one line
	$text_test =~ s/\t//g;			# delete all tabulator  --> better for output
	@templates_all = ();
	
	while($text_test =~ /\{\{/g) {
		#Begin of template
		my $pos_start = pos($text_test) - 2;
		my $temp_text = substr ( $text_test, $pos_start);
		my $temp_text_2 = '';
		my $beginn_curly_brackets = 1;
		my $end_curly_brackets = 0;
		while($temp_text =~ /\}\}/g) {
			# Find currect end - number of {{ == }}
			my $pos_end = pos($temp_text);
			$temp_text_2 = substr ( $temp_text, 0, $pos_end);
			$temp_text_2 = ' '.$temp_text_2.' ';
			#print $temp_text_2."\n";

			# test the number of {{ and  }}
			my $temp_text_2_a = $temp_text_2;
			$beginn_curly_brackets = ($temp_text_2_a =~ s/\{\{//g);			
			my $temp_text_2_b = $temp_text_2;
			$end_curly_brackets = ($temp_text_2_b =~ s/\}\}//g);			

			#print $beginn_curly_brackets .' vs. '.$end_curly_brackets."\n";
			last if ($beginn_curly_brackets eq $end_curly_brackets);
		}
		
		if ($beginn_curly_brackets == $end_curly_brackets ) {
			# template is correct 			
			$temp_text_2 = substr ($temp_text_2, 1, length($temp_text_2) -2);
			#print 'Template:'.$temp_text_2."\n" if ($details_for_page eq 'yes');
			push (@templates_all, $temp_text_2);
		} else {
			# template has no correct end
			$temp_text = text_reduce($temp_text, 80);
			error_043_template_no_correct_end('check', $temp_text);
			#print 'Error: '.$title.' '.$temp_text."\n";
		}
	}


	# extract for each template all attributes and values
	my $number_of_templates = -1;
	my $template_part_counter = -1;
	my $output = '';
	foreach (@templates_all) {
		my $current_template = $_;
		#print 'Current templat:_'.$current_template."_\n";
		$current_template =~ s/^\{\{//;
		$current_template =~ s/\}\}$//;	
		$current_template =~ s/^ //g;
		
		foreach (@namespace_templates){
			$current_template =~ s/^$_://i;
		}
		
		$number_of_templates = $number_of_templates + 1;
		my $template_name = '';
		
		my @template_split = split( /\|/ , $current_template);
		my $number_of_splits = @template_split;
		
		
		if (index (  $current_template, '|') == -1 ) {
			# if no pipe; for example {{test}}
			$template_name = $current_template;
			next;
		}
		
		
		if (index (  $current_template, '|') > -1 ) {
			# templates with pipe {{test|attribute=value}}
			
			# get template name
			$template_split[0] =~ s/^ //g;
			$template_name = $template_split[0];
			#print 'Template name: '.$template_name."\n";
			if ( index ($template_name ,'_') > -1) {
				#print $title."\n"; 
				#print 'Template name: '.$template_name."\n";
				$template_name =~ s/_/ /g;
				#print 'Template name: '.$template_name."\n";
			}
			if ( index ($template_name ,'  ') > -1) {
				#print $title."\n";
				#print 'Template name: '.$template_name."\n";
				$template_name =~ s/  / /g;
				#print 'Template name: '.$template_name."\n";
			}	
			
			shift(@template_split);
			
			# get next part of template
			my $template_part = '';
			my @template_part_array;
			undef(@template_part_array);
			
			foreach (@template_split) {
				$template_part = $template_part.$_;
				print "\t".'Test this: '.$template_part."\n" if ($details_for_page eq 'yes');
				
				# check for []
				my $template_part1 = $template_part;
				my $beginn_brackets = ($template_part1 =~ s/\[\[//g);
				#print "\t\t1 ".$beginn_brackets."\n";
				
				my $template_part2 = $template_part;
				my $end_brackets = ($template_part2 =~ s/\]\]//g);
				#print "\t\t2 ".$end_brackets."\n";				
				
				#check for {}
				my $template_part3 = $template_part;
				my $beginn_curly_brackets = ($template_part3 =~ s/\{\{//g);
				#print "\t\t3 ".$beginn_curly_brackets."\n";

				my $template_part4 = $template_part;
				my $end_curly_brackets = ($template_part4 =~ s/\}\}//g);
				#print "\t\t4 ".$end_curly_brackets."\n";				
				
				# templet part complete ?
				if (     $beginn_brackets eq $end_brackets 
					 and $beginn_curly_brackets eq $end_curly_brackets ) {
					
					push (@template_part_array, $template_part);
					$template_part = '';
				} else {
					$template_part = $template_part .'|';
				}
				
			}
			

			
			# OUTPUT If only templates {{{xy|value}}
			my $template_part_number = -1;
			my $template_part_without_attribut = -1;
			
			foreach (@template_part_array) {
				my $template_part = $_;
				#print "\t\t".'Template part: '.$_."\n";
				
				$template_part_number = $template_part_number + 1;
				$template_part_counter = $template_part_counter +1;
				
				$template_name =~ s/^[ ]+//g;
				$template_name =~ s/[ ]+$//g;
				$template[$template_part_counter][0] = $number_of_templates;
				$template[$template_part_counter][1] = $template_name;
				$template[$template_part_counter][2] = $template_part_number;
				
				my $attribut = '';
				my $value = '';
				if (index($template_part, '=') > -1) {
					#template part with "="   {{test|attribut=value}}

					
					my $pos_equal = index($template_part, '=');
					my $pos_lower = index($template_part, '<');
					my $pos_next_temp = index($template_part, '{{');
					my $pos_table = index($template_part, '{|');
					my $pos_bracket = index($template_part, '[');
					
					my $equal_ok = 'true';
					$equal_ok = 'false' if ($pos_lower 		> -1 and $pos_lower 		< $pos_equal);
					$equal_ok = 'false' if ($pos_next_temp 	> -1 and $pos_next_temp 	< $pos_equal);
					$equal_ok = 'false' if ($pos_table 		> -1 and $pos_table 		< $pos_equal);
					$equal_ok = 'false' if ($pos_bracket 	> -1 and $pos_bracket 		< $pos_equal);
					
					if ($equal_ok eq 'true') {
						#template part with "="   {{test|attribut=value}}
						$attribut = substr($template_part, 0, index($template_part, '='));
						$value = substr($template_part, index($template_part, '=') +1);
					} else {
						# problem:  {{test|value<ref name="sdfsdf"> sdfhsdf</ref>}}
						# problem   {{test|value{{test2|name=teste}}|sdfsdf}}
						$template_part_without_attribut = $template_part_without_attribut +1;
						$attribut = $template_part_without_attribut;
						$value = $template_part;					
					}
				} else {
					#template part with no "="   {{test|value}}
					$template_part_without_attribut = $template_part_without_attribut +1;
					$attribut = $template_part_without_attribut;
					$value = $template_part;
				}
				
				
				
				$attribut =~ s/^[ ]+//g;
				$attribut =~ s/[ ]+$//g;
				$value =~ s/^[ ]+//g;
				$value =~ s/[ ]+$//g;
				
				#print 'x'.$attribut."x\tx".$value."x\n" ;#if ($title eq 'Methanol');
				$template[$template_part_counter][3] = $attribut;
				$template[$template_part_counter][4] = $value;
				
				$number_of_template_parts = $number_of_template_parts + 1;
				#print $number_of_template_parts."\n";
				
				$output .= $title."\t";
				$output .= $page_id."\t";
				$output .= $template[$template_part_counter][0]."\t";
				$output .= $template[$template_part_counter][1]."\t";
				$output .= $template[$template_part_counter][2]."\t";
				$output .= $template[$template_part_counter][3]."\t";
				$output .= $template[$template_part_counter][4]."\n";
				
				#print $output."\n"  if ($title eq 'Methanol');
			}			
			
			
		}
		#print "\n";
		# OUTPUT If all templates {{xy}} and {{xy|value}}
		
		
	}
	
	#print $output."\n"  if ($title eq 'Methanol');
	#print $page_namespace."\n"  if ($title eq 'Methanol');
	
	# Output for TemplateTiger 
	if( $dump_or_live eq 'dump'
		and (   $page_namespace == 0 
		     or $page_namespace == 6 
		     or $page_namespace == 104 )
		) {
		
		print $output if ($details_for_page eq 'yes');
		print TEMPLATETIGER $output;

		# new in tt-table of database
		# for (my $i = 0; $i <=$number_of_template_parts; $i++) {
		#	insert_into_db_table_tt ($title, $page_id, $template[$i][0], $template[$i][1], $template[$i][2], $template[$i][3], $template[$i][4], $template[$i][5]);
		#}

	}
	
	#die  if ($title eq 'Methanol');
	
}


##################################################################
sub get_links{
	# filter all templates
	my $pos_start = 0;
	my $pos_end = 0;

	my $text_test = $text;
	#$text_test = 'abc[[Kartographie]], Bild:abd|[[Globus]]]] ohne [[Gradnetz]] weiterer Text 
	#aber hier [[Link234|sdsdlfk]]  [[Test]]';
	
	#print $text_test ."\n\n\n";
	
	$text_test =~ s/\n//g;
	undef (@links_all);
	
	while($text_test =~ /\[\[/g) {
		#Begin of link
		my $pos_start = pos($text_test) - 2;
		my $link_text = substr ( $text_test, $pos_start);
		my $link_text_2 = '';
		my $beginn_square_brackets = 1;
		my $end_square_brackets = 0;
		while($link_text =~ /\]\]/g) {
			# Find currect end - number of [[==]]
			my $pos_end = pos($link_text);
			$link_text_2 = substr ( $link_text, 0, $pos_end);
			$link_text_2 = ' '.$link_text_2.' ';
			#print $link_text_2."\n";

			# test the number of [[and  ]]
			my $link_text_2_a = $link_text_2;
			$beginn_square_brackets = ($link_text_2_a =~ s/\[\[//g);			
			my $link_text_2_b = $link_text_2;
			$end_square_brackets = ($link_text_2_b =~ s/\]\]//g);			

			#print $beginn_square_brackets .' vs. '.$end_square_brackets."\n";
			last if ($beginn_square_brackets eq $end_square_brackets);
		}
		
		if ($beginn_square_brackets == $end_square_brackets ) {
			# link is correct 			
			$link_text_2 = substr ($link_text_2, 1, length($link_text_2) -2);
			#print 'Link:'.$link_text_2."\n";
			push (@links_all, $link_text_2);
		} else {
			# template has no correct end
			$link_text = text_reduce($link_text, 80);
			error_010_count_square_breaks('check', $link_text);
			#print 'Error: '.$title.' '.$link_text."\n";
		}
	}

}

sub get_images {
	# get all images from all links
	undef (@images_all);
	
	my $found_error_text = '';
	foreach(@links_all) {
		my $current_link = $_;
		#print $current_link. "\n";
		
		my $link_is_image = 'no';
		foreach (@namespace_image) {
			my $namespace_image_word = $_;
			$link_is_image = 'yes' if ( $current_link =~ /^\[\[([ ]?)+?$namespace_image_word:/i);
		}
		if ($link_is_image eq 'yes') {
			# link is a image
			my $current_image = $current_link;
			push (@images_all, $current_image);
			#print "\t".'Image:'."\t".$current_image."\n";
			
			my $test_image = $current_image;
			
			#print '1:'."\t".$test_image."\n";
			foreach(@magicword_img_thumbnail) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}
			
			#print '2:'."\t".$test_image."\n";
			foreach(@magicword_img_right) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}
			
			#print '3:'."\t".$test_image."\n";
			foreach(@magicword_img_left) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '4:'."\t".$test_image."\n";
			foreach(@magicword_img_none) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}
			
			#print '5:'."\t".$test_image."\n";
			foreach(@magicword_img_center) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '6:'."\t".$test_image."\n";
			foreach(@magicword_img_framed) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}
			
			#print '7:'."\t".$test_image."\n";
			foreach(@magicword_img_frameless) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '8:'."\t".$test_image."\n";
			foreach(@magicword_img_border) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '9:'."\t".$test_image."\n";
			foreach(@magicword_img_sub) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '10:'."\t".$test_image."\n";
			foreach(@magicword_img_super) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '11:'."\t".$test_image."\n";
			foreach(@magicword_img_baseline) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '12:'."\t".$test_image."\n";
			foreach(@magicword_img_top) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}			

			#print '13:'."\t".$test_image."\n";
			foreach(@magicword_img_text_top) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}

			#print '14:'."\t".$test_image."\n";
			foreach(@magicword_img_middle) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}
			
			#print '15:'."\t".$test_image."\n";
			foreach(@magicword_img_bottom) {
				my $current_magicword = $_;
				#print $current_magicword."\n";
				$test_image =~ s/\|([ ]?)+$current_magicword([ ]?)+(\||\])/$3/i ;
			}
			
			#######
			# special
			
			# 100px
			# 100x100px
			#print '16:'."\t".$test_image."\n";
			#foreach(@magicword_img_width) {
			#	my $current_magicword = $_;
			#	$current_magicword =~ s/$1/[0-9]+/;
			##	print $current_magicword."\n";
			$test_image =~ s/\|([ ]?)+[0-9]+(x[0-9]+)?px([ ]?)+(\||\])/$4/i ;
			#}
			
			#print '17:'."\t".$test_image."\n";
			
			if ($found_error_text eq '') {
				if (index($test_image, '|') == -1) {
					# [[Image:Afriga3.svg]]
					$found_error_text = $current_image;
				} else {
					my $pos_1 = index($test_image, '|');
					my $pos_2 = index($test_image, '|', $pos_1+1);
					#print '1:'."\t".$pos_1."\n";
					#print '2:'."\t".$pos_2."\n";
					if ( $pos_2 == -1 
						 and index($test_image, '|]') > -1  ) {
						 # [[Image:Afriga3.svg|]]
						 $found_error_text = $current_image;
						#print 'Error'."\n";
					}
				}
			}
		}
	}
	
	if ($found_error_text ne '') {
		error_030_image_without_description('check', $found_error_text );
	}

}



##################################################################

sub get_tables {
	# search for comments in this page
	# save comments in Array
	# replace comments with space
	#print 'get comment'."\n";
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';
	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next comment
		$pos_start = index ( $text, '{|', $pos_start_old);
		$pos_end   = index ( $text, '|}', $pos_start ) ;
		#print 'get table: x'.substr ($text, $pos_end, 3 )."x\n";
	
		if ($pos_start > -1 and $pos_end >-1 
			and substr ($text, $pos_end, 3 ) ne '|}}' )
			{
			#found a comment in current page
			$pos_end = $pos_end + length('|}');
			#$comment_counter = $comment_counter +1;
			#$comments[$comment_counter][0] = $pos_start;
			#$comments[$comment_counter][1] = $pos_end;
			#$comments[$comment_counter][2] = substr($text, $pos_start, $pos_end - $pos_start  );

			#print 'Begin='.$comments[$comment_counter][0].' End='.$comments[$comment_counter][1]."\n";
			#print 'Comment='.$comments[$comment_counter][2]."\n";
			
			$end_search = 'no';
			$pos_start_old = $pos_end;

			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			error_028_table_no_correct_end ('check', substr( $text, $pos_start, 50) );
			$end_search = 'yes';
		}
		
	}
	until ( $end_search eq 'yes') ;
}

sub get_gallery {
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';
	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';
		$pos_start = index ( $text, '<gallery', $pos_start_old);
		$pos_end   = index ( $text, '</gallery>', $pos_start ) ;
		if ($pos_start > -1 and $pos_end >-1) {
			$pos_end = $pos_end + length('</gallery>');
			$end_search = 'no';
			$pos_start_old = $pos_end;
			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $text_gallery = substr( $text, $pos_start, $pos_end - $pos_start );
			error_035_gallery_without_description('check', $text_gallery);
			
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
			
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			error_029_gallery_no_correct_end ('check', substr( $text, $pos_start, 50) );
			$end_search = 'yes';
		}
	}
	until ( $end_search eq 'yes') ;
}


sub get_hiero {
	#print 'Get hiero tag'."\n";
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';
	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next <math>
		$pos_start = index ( $text, '<hiero>', $pos_start_old);
		$pos_end   = index ( $text, '</hiero>', $pos_start ) ;
	
		if ($pos_start > -1 and $pos_end >-1) {
			#found a math in current page
			$pos_end = $pos_end + length('</hiero>');
			#print substr($text, $pos_start, $pos_end - $pos_start  )."\n";			

			$end_search = 'no';
			$pos_start_old = $pos_end;

			#replace comment with space
			my $text_before = substr( $text, 0, $pos_start );
			my $text_after  = substr( $text, $pos_end );
			my $filler = '';
			for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
		    		$filler = $filler.' ';
			}
			$text = $text_before.$filler.$text_after;
		} 
		if ($pos_start > -1 and $pos_end == -1) {
			#error_015_Code_no_correct_end ( 'check', substr( $text, $pos_start, 50) );
			#print 'Code:'.substr( $text, $pos_start, 50)."\n";
			$end_search = 'yes';
		}
		
	}
	until ( $end_search eq 'yes') ;	
}


sub get_ref {
	#print 'Get hiero tag'."\n";
	undef (@ref);
	my $pos_start_old = 0;
	my $pos_end_old = 0;
	my $end_search = 'yes';
	do {
		my $pos_start = 0;
		my $pos_end = 0;
		$end_search = 'yes';

		#get position of next <math>
		$pos_start = index ( $text, '<ref>', $pos_start_old);
		$pos_end   = index ( $text, '</ref>', $pos_start ) ;
	
		if ($pos_start > -1 and $pos_end >-1) {
			#found a math in current page
			$pos_end = $pos_end + length('</ref>');
			#print substr($text, $pos_start, $pos_end - $pos_start  )."\n";			

			$end_search = 'no';
			$pos_start_old = $pos_end;
			
			#print $pos_start." ".$pos_end."\n";
			my $new_ref = substr($text, $pos_start, $pos_end - $pos_start);
			#print $new_ref."\n";
			push(@ref, $new_ref );
		} 
		
	}
	until ( $end_search eq 'yes') ;	

}



sub check_for_redirect {
	# is this page a redirect?
	if (index(lc($text), '#redirect') > -1)	 {
		$page_is_redirect = 'yes';
	}
}



sub get_categories {
	# search for categories in this page
	# save comments in Array
	# replace comments with space
	#print 'get categories'."\n";
	
	#$text = 'absc[[ Kategorie:123|Museum]],Kategorie:78]][[     Category:ABC-Waffe| Kreuz ]][[Category:XY-Waffe|Hand ]] [[  category:Schwert| Fuss]] [[Kategorie:Karto]][[kategorie:Karto]]';
	#print $text."\n";
	#foreach (@namespace_cat) {
	#	print $_."\n";
	#}
	foreach (@namespace_cat) {
		
		my $namespace_cat_word = $_;
		#print "namespace_cat_word:".$namespace_cat_word."x\n";
		
		my $pos_start = 0;
		my $pos_end = 0;

		my $text_test = $text;

		my $search_word = $namespace_cat_word;
		while($text_test =~ /\[\[([ ]+)?($search_word:)/ig) {
			my $pos_start = pos($text_test) - length($search_word) - 1;
			#print "search word <b>$search_word</b> gefunden bei Position $pos_start<br>\n";
			
			$pos_end   = index ( $text_test, ']]', $pos_start ) ;

			my $counter_begin = 0;
			do {
				$pos_start = $pos_start -1;
				$counter_begin = $counter_begin + 1 if (substr($text_test, $pos_start, 1) eq '[' );
			} until ($counter_begin == 2);


			#print $namespace_cat."\n";
			#print $pos_start."\n";
			#print $pos_end."\n";
			
			if ($pos_start > -1 and $pos_end >-1) {
				
				#found a comment in current page
				$pos_end = $pos_end + length(']]');
				$category_counter = $category_counter +1;
				$category[$category_counter][0] = $pos_start;
				$category[$category_counter][1] = $pos_end;
				$category[$category_counter][2] = '';
				$category[$category_counter][3] = '';
				$category[$category_counter][4] = substr($text_test, $pos_start, $pos_end - $pos_start);

				#print $category[$category_counter][4]."\n";# if ($title eq 'Alain Delon');
				
				#replace comment with space
				#my $text_before = substr( $text, 0, $pos_start );
				#my $text_after  = substr( $text, $pos_end );
				#my $filler = '';
				#for (my $i = 0; $i < ($pos_end-$pos_start); $i++) {
				# 		$filler = $filler.' ';
				#}
				#$text = $text_before.$filler.$text_after;

				#filter catname 
				$category[$category_counter][2] = $category[$category_counter][4];
				$category[$category_counter][2] =~ s/\[\[//g;		#delete space
				$category[$category_counter][2] =~ s/^([ ]+)?//g;			#delete blank before text
				$category[$category_counter][2] =~ s/\]\]//g;		#delete ]]
				$category[$category_counter][2] =~ s/^$namespace_cat_word//i;		#delete ]]
				$category[$category_counter][2] =~ s/^://;			#delete ]]
				$category[$category_counter][2] =~ s/\|(.)*//g;		#delete |xy 
				#$category[$category_counter][2] =~ s/^(.)*://i;	#delete [[category:
				$category[$category_counter][2] =~ s/^ //g;			#delete blank before text
				$category[$category_counter][2] =~ s/ $//g;			#delete blank after text

				#filter linkname
				$category[$category_counter][3] = $category[$category_counter][4];
				$category[$category_counter][3] = '' if (index ($category[$category_counter][3], '|') == -1); 
				$category[$category_counter][3] =~ s/^(.)*\|//gi;	#delete [[category:xy|
				$category[$category_counter][3] =~ s/\]\]//g;		#delete ]]
				$category[$category_counter][3] =~ s/^ //g;			#delete blank before text
				$category[$category_counter][3] =~ s/ $//g;			#delete blank after text
		
				#if ($title eq 'Alain Delon') {
					#print "\t".'Begin='.$category[$category_counter][0].' End='.$category[$category_counter][1]."\n";
					#print "\t".'catname=' .$category[$category_counter][2]."\n";
					#print "\t".'linkname='.$category[$category_counter][3]."\n";
					#print "\t".'full cat='.$category[$category_counter][4]."\n";
					
				#}
			}
		}
	}

}



sub get_interwikis{
	foreach (@inter_list) {
		
		my $current_lang = $_;
		#print "namespace_cat_word:".$namespace_cat_word."x\n";
		
		my $pos_start = 0;
		my $pos_end = 0;

		my $text_test = $text;

		my $search_word = $current_lang;
		while($text_test =~ /\[\[([ ]+)?($search_word:)/ig) {
			my $pos_start = pos($text_test) - length($search_word) - 1;
			#print "search word <b>$search_word</b> gefunden bei Position $pos_start<br>\n";
			
			$pos_end   = index ( $text_test, ']]', $pos_start ) ;

			my $counter_begin = 0;
			do {
				$pos_start = $pos_start -1;
				$counter_begin = $counter_begin + 1 if (substr($text_test, $pos_start, 1) eq '[' );
			} until ($counter_begin == 2);


			#print $namespace_cat."\n";
			#print $pos_start."\n";
			#print $pos_end."\n";
			
			if ($pos_start > -1 and $pos_end >-1) {
				
				#found a comment in current page
				$pos_end = $pos_end + length(']]');
				$interwiki_counter = $interwiki_counter +1;
				$interwiki[$interwiki_counter][0] = $pos_start;
				$interwiki[$interwiki_counter][1] = $pos_end;
				$interwiki[$interwiki_counter][2] = '';
				$interwiki[$interwiki_counter][3] = '';
				$interwiki[$interwiki_counter][4] = substr($text_test, $pos_start, $pos_end - $pos_start);

	
				$interwiki[$interwiki_counter][2] = $interwiki[$interwiki_counter][4];
				$interwiki[$interwiki_counter][2] =~ s/\]\]//g;		#delete ]]
				$interwiki[$interwiki_counter][2] =~ s/\|(.)*//g;		#delete |xy 
				$interwiki[$interwiki_counter][2] =~ s/^(.)*://gi;	#delete [[category:
				$interwiki[$interwiki_counter][2] =~ s/^ //g;			#delete blank before text
				$interwiki[$interwiki_counter][2] =~ s/ $//g;			#delete blank after text

				#filter linkname
				$interwiki[$interwiki_counter][3] = $interwiki[$interwiki_counter][4];
				$interwiki[$interwiki_counter][3] = '' if (index ($interwiki[$interwiki_counter][3], '|') == -1); 
				$interwiki[$interwiki_counter][3] =~ s/^(.)*\|//gi;	#delete [[category:xy|
				$interwiki[$interwiki_counter][3] =~ s/\]\]//g;		#delete ]]
				$interwiki[$interwiki_counter][3] =~ s/^ //g;			#delete blank before text
				$interwiki[$interwiki_counter][3] =~ s/ $//g;			#delete blank after text
		
				#language
				$interwiki[$interwiki_counter][5] = $current_lang;
				#$interwiki[$interwiki_counter][5] = $interwiki[$interwiki_counter][4];
				#$interwiki[$interwiki_counter][5] =~ s/:(.)*//gi;
				#$interwiki[$interwiki_counter][5] =~ s/\[\[//g;		#delete [[

		
				#if ($title eq 'JPEG') {
					#print "\t".'Begin='.$interwiki[$interwiki_counter][0].' End='.$interwiki[$interwiki_counter][1]."\n";
					#print "\t".'full interwiki='.$interwiki[$interwiki_counter][4]."\n";
					#print "\t".'language='.$interwiki[$interwiki_counter][5]."\n";
					#print "\t".'interwikiname='.$interwiki[$interwiki_counter][2]."\n";
					#print "\t".'linkname='.$interwiki[$interwiki_counter][3]."\n";
				#}
			
			}
		}
	}
}

sub	create_line_array{
	@lines = split (/\n/, $text);
}

sub get_line_first_blank{
	undef(@lines_first_blank);
	#my $yes_blank = 'no';
	
	foreach(@lines) {
		my $current_line = $_;
		if ( $current_line =~ /^ [^ ]/ 
			 and $current_line =~ /^ [^\|]/ 		# no table
			 and $current_line =~ /^ [^\!]/ 		#no table
			 ) {
			push(@lines_first_blank, $current_line);
			#$yes_blank = 'yes';
			
		}
	}
}

sub get_headlines{
	undef(@headlines);

	my $section_text = '';
	#get headlines
	foreach(@lines) {
		my $current_line = $_;
		
		if (substr($current_line ,0 ,1) eq '=') {
			# save section
			push(@section, $section_text);
			$section_text = '';
			# save headline
			push(@headlines, $current_line);
		}
		$section_text = $section_text.$_."\n";
	}
	push(@section, $section_text);

	#foreach(@headlines) {
	#	print $_."\n";
	#}

}

############################################################################

sub error_check {

	print 'Start check error'."\n" if ($details_for_page eq 'yes');

	if ( $dump_or_live eq 'dump'
		or $dump_or_live eq 'live') {
		error_list('check');
	}
	if ( $dump_or_live eq 'only'){
	
		error_030_image_without_description('check','');
	}

	#############
	# next feature
	## comment_very_long;
	
}

sub error_list {

	my $attribut = $_[0];	# check / get_description

	
		error_001_no_bold_title($attribut);									# don´t work - deactivated
		error_002_have_br($attribut); 
		error_003_have_ref($attribut);		
		error_004_have_html_and_no_topic($attribut);
		error_005_Comment_no_correct_end($attribut, '');
		error_006_defaultsort_with_special_letters($attribut);
		error_007_headline_only_three($attribut);
		error_008_headline_start_end($attribut);
		error_009_more_then_one_category_in_a_line($attribut);
		error_010_count_square_breaks($attribut,'');
		error_011_html_names_entities($attribut);							
		error_012_html_list_elements($attribut);
		error_013_Math_no_correct_end($attribut,'');
		error_014_Source_no_correct_end($attribut,'');
		error_015_Code_no_correct_end($attribut,'');
		error_016_unicode_control_characters($attribut);						
		error_017_category_double($attribut);
		error_018_category_first_letter_small($attribut);
		error_019_headline_only_one($attribut);
		error_020_symbol_for_dead($attribut);
		error_021_category_is_english($attribut);							
		error_022_category_with_space($attribut);
		error_023_nowiki_no_correct_end($attribut,'');
		error_024_pre_no_correct_end($attribut,'');
		error_025_headline_hierarchy($attribut);
		error_026_html_text_style_elements($attribut);
		error_027_unicode_syntax($attribut);									
		error_028_table_no_correct_end($attribut,'');
		error_029_gallery_no_correct_end($attribut,'');
		error_030_image_without_description($attribut,'');

		error_031_html_table_elements($attribut);
		error_032_double_pipe_in_link($attribut);
		error_033_html_text_style_elements_underline($attribut);				
		error_034_template_programming_elements($attribut);
		error_035_gallery_without_description($attribut,'');
		error_036_redirect_not_correct($attribut);
		error_037_title_with_special_letters_and_no_defaultsort($attribut);
		
		error_038_html_text_style_elements_italic($attribut);
		error_039_html_text_style_elements_paragraph($attribut);
		error_040_html_text_style_elements_font($attribut);
		error_041_html_text_style_elements_big($attribut);
		error_042_html_text_style_elements_small($attribut);
		error_043_template_no_correct_end($attribut,'');
		error_044_headline_with_bold($attribut);
		error_045_interwiki_double($attribut);
		error_046_count_square_breaks_begin($attribut);
		error_047_template_no_correct_begin($attribut);
		error_048_title_in_text($attribut);
		error_049_headline_with_html($attribut);
		error_050_dash($attribut);
		error_051_interwiki_before_last_headline($attribut);
		error_052_category_before_last_headline($attribut);
		error_053_interwiki_before_category($attribut);
		error_054_break_in_list($attribut);
		error_055_html_text_style_elements_small_double($attribut);
		error_056_arrow_as_ASCII_art($attribut);
		error_057_headline_end_with_colon($attribut);
		error_058_headline_with_capitalization($attribut);
		error_059_template_value_end_with_br($attribut);
		error_060_template_parameter_with_problem($attribut);
		error_061_reference_with_punctuation($attribut);
		error_062_headline_alone($attribut);
		error_063_html_text_style_elements_small_ref_sub_sup($attribut);
		error_064_link_equal_linktext($attribut);
		error_065_image_description_with_break($attribut);
		error_066_image_description_with_full_small($attribut);
		error_067_reference_after_punctuation($attribut);
		error_068_link_to_other_language($attribut);
		error_069_isbn_wrong_syntax($attribut,'');
		error_070_isbn_wrong_length($attribut,'');
		error_071_isbn_wrong_pos_X($attribut,'');
		error_072_isbn_10_wrong_checksum($attribut,'');
		error_073_isbn_13_wrong_checksum($attribut,'');
		error_074_link_with_no_target($attribut);
		error_075_indented_list($attribut);
		error_076_link_with_no_space($attribut);
		error_077_image_description_with_partial_small($attribut);
		error_078_reference_double($attribut);
		error_079_external_link_without_description($attribut);
		error_080_external_link_with_line_break($attribut);
		error_081_ref_double($attribut);
		error_082_link_to_other_wikiproject($attribut);
		error_083_headline_only_three_and_later_level_two($attribut);
		error_084_section_without_text($attribut);
		error_085_tag_without_content($attribut);
		error_086_link_with_two_brackets_to_external_source($attribut);
		error_087_html_names_entities_without_semicolon($attribut);
		error_088_defaultsort_with_first_blank($attribut);
		error_089_defaultsort_with_capitalization_in_the_middle_of_the_word($attribut);
		error_090_defaultsort_with_lowercase_letters($attribut);
		error_091_title_with_lowercase_letters_and_no_defaultsort($attribut);
		error_092_headline_double($attribut);
	
}



###################################
sub error_001_no_bold_title {
	my $error_code = 1;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = -1; 
		$error_description[$error_code][1] = 'No bold title'; 
		$error_description[$error_code][2] = 'This article has no bold title like <nowiki>'."'''Title'''".'</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0  
			and index( $text, "'''" )== -1 
			 and $page_is_redirect eq 'no') {
			error_register($error_code, '');
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_002_have_br{
	my $error_code = 2; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Article with false <nowiki><br/></nowiki>';
		$error_description[$error_code][2] = 'This article contains a <nowiki><br\></nowiki> or <nowiki><\br></nowiki> or <nowiki><br.></nowiki> but a <nowiki><br></br> or <br/></nowiki> tag is necessary in order to be correct XHTML-syntax (see [http://www.w3.org/TR/xhtml1/#h-4.6 1], [http://www.w3.org/TR/2006/REC-xml11-20060816/#sec-starttags 2]).';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		
		if (    $page_namespace == 0 
			 or $page_namespace == 104 ) {
			my $test_text = lc($text);
			if (index($test_text, '<br') > -1
				or index($test_text, 'br>') > -1) {
				my $pos = -1;
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);
					#print $current_line_lc."\n";


					if ($current_line_lc =~ /<br\/[^ ]>/g ){
						# <br/1>
						$pos = pos($current_line_lc) if ( $pos == -1);
					}

					if ($current_line_lc =~ /<br[^ ]\/>/g  ){
						# <br1/>
						$pos = pos($current_line_lc) if ( $pos == -1);
					}
					
					if ($current_line_lc =~ /<br[^ \/]>/g ) {
						# <br7>
						$pos = pos($current_line_lc) if ( $pos == -1);
					}

					if ($current_line_lc =~ /<[^ \/]br>/g ) {
						# <\br>
						$pos = pos($current_line_lc) if ($pos == -1);
					}	

					if ($pos > -1 
						and $test ne 'found'){
						#print $pos."\n";
						$test = 'found';
						if ($test_line eq '') {
							$test_line = substr($current_line, 0, $pos) ;
							$test_line = text_reduce_to_end( $test_line, 50);
							#print $test_line."\n";
						}
					}
				}
			}
		}
		if ($test eq 'found' ) {
			$test_line   = text_reduce($test_line, 80);
			error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
			#print "\t". $error_code."\t".$title."\t".$test_line."\n";
		}
	}
}

sub error_003_have_ref{
	my $error_code = 3; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Article with <nowiki><ref></nowiki> and no <nowiki><references /></nowiki>';
		$error_description[$error_code][2] = 'This article has a <nowiki><ref></nowiki> and not a <nowiki><references /></nowiki>. This is not correct syntax.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
		if ($page_namespace == 0
			or $page_namespace == 104) {
		
			if ( index($text, '<ref>') > -1 
				 or index($text, '<ref name') > -1 
				)
				{
				  
				 my $test = "false";
				 my $test_text = lc($text);
				 $test = "true" if ( $test_text =~ /<[ ]?+references>/ and $test_text =~ /<[ ]?+\/references>/ );
				 $test = "true" if ( $test_text =~ /<[ ]?+references[ ]?+\/>/);
				 $test = "true" if ( $test_text =~ /<[ ]?+references group/);
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+refbegin/);
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+refend/);
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+reflist/);						# in enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+reflink/);						# in enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+reference list/);				# in enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+references-small/);			# in enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+references/);					# in enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+listaref /);					# in enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+reference/);					# in enwiki			 
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+przypisy/);					# in plwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+amaga/);						# in cawiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+referències/);					# in cawiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+viitteet/);					# in fiwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+verwysings/);					# in afwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+references/);					# in itwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+références/);					# in frwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+notes/);						# in frwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+listaref/);					# in nlwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+referenties/);					# in cawiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+ref-section/);					# in ptwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+referências/);					# in ptwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+refs/);						# in nlwiki + enwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+noot/);						# in nlwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+unreferenced/);				# in nlwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+fnb/);							# in nlwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+примечания/);					# in ruwiki	
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+список примечаний/);			# in ruwiki	
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+Примечания/);					# in ruwiki	(Problem with big letters)
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+Список примечаний/);			# in ruwiki	(Problem with big letters)
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+kaynakça/ );					# in trwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+ثبت المراجع/ );				# in arwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+appendix/ );					# in nlwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+примітки/ );					# in ukwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+Примітки/ );					# in ukwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+hide ref/ );					# in zhwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+forrás/ );						# in huwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+註腳/ );							# in zhwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+註腳h/ );						# in zhwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+註腳f/ );						# in zhwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+kayan kaynakça/ );				# in trwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+r/ );							# in itwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+r/ );							# in itwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+הערות שוליים/ );				# in hewiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+הערה/ );						# in hewiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+注脚/ );							# in zhwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+referências/);					# in ptwiki
				 $test = "true" if ( $test_text =~ /\{\{[ ]?+רעפליסטע/);					# in yiwiki

				 
					
				if ($test eq "false") {
					error_register($error_code, ''); 
					#print "\t". $error_code."\t".$title."\n";
				}
			}
		}
	}
}

sub error_004_have_html_and_no_topic{
	my $error_code = 4; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Article with weblink';
		$error_description[$error_code][2] = 'This article has a weblink and not a headline (like "<nowiki>== Weblinks ==</nowiki>"). All weblinks should be in the linklist or list of references.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104)
			 and index($text, 'http://') > -1 
			 and index($text, '==') == -1 
			 and index($text, '{{') == -1  
			 and $project eq 'dewiki'
			 and index($text, '<references') == -1 
			 and index($text, '<ref>') == -1 
			 ) {
			error_register($error_code, ''); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_005_Comment_no_correct_end{
	my $error_code = 5; 
	my $attribut = $_[0];	
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Comment not correct end';
		$error_description[$error_code][2] = 'Found a comment <nowiki>"<!--"</nowiki> with no <nowiki>"-->"</nowiki> end.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
		if ($comment ne ''
			and ( $page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104)
			) {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}



sub error_006_defaultsort_with_special_letters{
	my $error_code = 6; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'DEFAULTSORT with special letters';
		$error_description[$error_code][2] = 'Please don´t use special letters in the DEFAULTSORT (in ca: also in ORDENA).'."\n".
		'* in de: ä → a, ö → o, ü → u, ß → ss '."\n".
		'* in fi: ü → y, é → e, ß → ss, etc.'."\n".
		'* in sv and fi is allowed ÅÄÖåäö'."\n".
		'* in cs is allowed čďěňřšťžČĎŇŘŠŤŽ'."\n".
		'* in da, no, nn is allowed ÆØÅæøå'."\n".
		'* in ro is allowed ăîâşţ'."\n".
		'* in ru: Ё → Е, ё → е'."\n".
		"\n";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
	
		# {{DEFAULTSORT:Mueller, Kai}}
		# {{ORDENA:Alfons I}}
		if ( ($page_namespace == 0 or $page_namespace == 104)
			and $project ne 'arwiki'
			and $project ne 'hewiki'
			and $project ne 'plwiki'
			and $project ne 'jawiki'
			and $project ne 'yiwiki'
			and $project ne 'zhwiki'

			) {
			
			my $pos1 = -1;
			foreach (@magicword_defaultsort) {
				$pos1 = index($text, $_) if ($pos1 == -1);
			}
			
			if ($pos1 > -1 ) {
				my $pos2 = index(substr($text,$pos1), '}}');
				my $testtext = substr($text, $pos1, $pos2);	

				my $testtext_2 = $testtext;
				#my $testtext =~ s/{{DEFAULTSORT\s*:(.*)}}/$1/;
				#print $testtext."\n";
				$testtext =~ s/[-—–:,\.0-9 A-Za-z!\?']//g;
				$testtext =~ s/[&]//g;
				$testtext =~ s/#//g;
				$testtext =~ s/\///g;
				$testtext =~ s/\(//g;
				$testtext =~ s/\)//g;
				$testtext =~ s/\*//g;
				$testtext =~ s/[ÅÄÖåäö]//g  if ($project eq 'svwiki');    # For Swedish, ÅÄÖ should also be allowed
				$testtext =~ s/[ÅÄÖåäö]//g  if ($project eq 'fiwiki');    # For Finnish, ÅÄÖ should also be allowed
				$testtext =~ s/[čďěňřšťžČĎŇŘŠŤŽ]//g if ($project eq 'cswiki'); 
				$testtext =~ s/[ÆØÅæøå]//g  if ($project eq 'dawiki');
				$testtext =~ s/[ÆØÅæøå]//g  if ($project eq 'nowiki');
				$testtext =~ s/[ÆØÅæøå]//g  if ($project eq 'nnwiki');
				$testtext =~ s/[ăîâşţ]//g   if ($project eq 'rowiki');
				$testtext =~ s/[АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдежзийклмнопрстуфхцчшщьыъэюя]//g      if ($project eq 'ruwiki');
				$testtext =~ s/[АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдежзийклмнопрстуфхцчшщьыъэюяіїґ]//g   if ($project eq 'ukwiki');
				$testtext =~ s/[~]//g  		if ($project eq 'huwiki');    # ~ for special letters
				
				#if ($testtext ne '') error_register(…);
				
				
				#print $testtext."\n";
				if (   ( $testtext ne '' )												# normal article
					 #or ($testtext ne '' and $page_namespace != 0 and index($text, '{{DEFAULTSORT') > -1 )		# if not an article then wiht {{ }}
					 ){
					$testtext   = text_reduce($testtext, 80);
					$testtext_2 = text_reduce($testtext_2, 80);
					
					error_register($error_code, '<nowiki>'.$testtext.'</nowiki> || <nowiki>'.$testtext_2.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".$testtext."\n";
				}
			}
		}
	}
}


sub error_007_headline_only_three{
	my $error_code = 7; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Headlines start with three "="';
		$error_description[$error_code][2] = 'The first headline start with <nowiki>"=== XY ==="</nowiki>. It should only be <nowiki>"== XY =="</nowiki>. See also error 083!';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		
		if ( $headlines[0] 
			and ($page_namespace == 0 or $page_namespace == 104)){
			if (  $headlines[0] =~ /===/ 
				 ){
				 
				my $found_level_two = 'no';
				foreach (@headlines) {
					if ($_ =~ /^==[^=]/) {
						$found_level_two = 'yes'; #found level two (error 83)
					}
				}
				if ($found_level_two eq 'no') {
					error_register($error_code, '<nowiki>'.$headlines[0].'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$headlines[0].'</nowiki>'."\n";
				}
			}
		}
	}
}

sub error_008_headline_start_end{
	my $error_code = 8;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Headline should end with "="';
		$error_description[$error_code][2] = 'A headline should end with an "=".';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		foreach (@headlines) {
			my $current_line = $_;
			my $current_line1 = $current_line;
			my $current_line2 = $current_line;

			$current_line2 =~ s/\t//gi;
			$current_line2 =~ s/[ ]+/ /gi;
			$current_line2 =~ s/ $//gi;

			if (         $current_line1 =~ /^==/
				and not ($current_line2 =~ /==$/)
				and index ($current_line ,'<ref') == -1
				and ($page_namespace == 0 or $page_namespace == 104)
			   ) {
				$current_line = text_reduce($current_line, 80);
				error_register($error_code, '<nowiki>'.$current_line.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$current_line.'</nowiki>'."\n";

				#if ($title eq '28 april'){
				#	my $test_length = length($current_line);
				#	for (my $i =0; $i<= $test_length; $i++) {
				#		my $test_text = substr($current_line, $i, 1);
				#		print $test_text."\t".ord($test_text)."\n";
				#	}
				#}


			}		
		}
	}
}


sub error_009_more_then_one_category_in_a_line{
	my $error_code = 9; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Categories more at one line';
		$error_description[$error_code][2] = 'There is more then one category at one line. Please write only one at one line. It is better to read.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
		my $error_line = '';
		print $error_code."\n" if ($details_for_page eq 'yes');
		
		foreach (@lines) {
			my $current_line = $_;
			my $found = 0;
			
			foreach (@namespace_cat) {
				my $namespace_cat_word = $_;
				$found = $found +1 if ( $current_line =~ /\[\[([ ]+)?($namespace_cat_word:)/ig);
			}

			if ($found > 1
				and ($page_namespace == 0 or $page_namespace == 104)
				) {
				$error_line = $current_line;
			}
		}
		
		if ($error_line ne '') {
			error_register($error_code, '<nowiki>'.$error_line.'</nowiki>');
			#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$error_line.'</nowiki>'."\n";
		}
	}
}

sub error_010_count_square_breaks{
	my $error_code = 10; 
	my $attribut = $_[0];
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Square brackets not correct end';
		$error_description[$error_code][2] = 'Different number of <nowiki>[[</nowiki> and <nowiki>]]</nowiki> brackets. If it is sourcecode then use <nowiki><source> or <code></nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne ''
			and ($page_namespace == 0  or $page_namespace == 6 or $page_namespace == 104)
			) {
			$comment = text_reduce($comment, 80);
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}


sub error_011_html_names_entities {
	my $error_code = 11;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML named entities';
		$error_description[$error_code][2] = 'Find <tt>&a<code></code>uml;</tt> or <tt>&o<code></code>uml;</tt> or <tt>&u<code></code>uml;</tt>, <tt>&sz<code></code>lig;</tt> or other. Please use [[Unicode]] characters (äüöÄÜÖßåÅ…).';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0  or $page_namespace == 6 or $page_namespace == 104) {
			my $pos = -1;
			my $test_text = lc($text);
			
			# see http://turner.faculty.swau.edu/webstuff/htmlsymbols.html
			$pos = index( $test_text, '&auml;') if ($pos == -1);			
			$pos = index( $test_text, '&ouml;') if ($pos == -1);
			$pos = index( $test_text, '&uuml;') if ($pos == -1);
			$pos = index( $test_text, '&szlig;') if ($pos == -1);
			$pos = index( $test_text, '&aring;') if ($pos == -1);	# åÅ
			$pos = index( $test_text, '&hellip;') if ($pos == -1);	# …
			#$pos = index( $test_text, '&lt;') if ($pos == -1);						# for example, &lt;em> produces <em> for use in examples
			#$pos = index( $test_text, '&gt;') if ($pos == -1);
			#$pos = index( $test_text, '&amp;') if ($pos == -1);					# For example, in en:Beta (letter), the code: &amp;beta; is used to add "&beta" to the page's display, rather than the unicode character β.
			$pos = index( $test_text, '&quot;') if ($pos == -1);
			$pos = index( $test_text, '&minus;') if ($pos == -1);
			$pos = index( $test_text, '&oline;') if ($pos == -1);
			$pos = index( $test_text, '&cent;') if ($pos == -1);
			$pos = index( $test_text, '&pound;') if ($pos == -1);
			$pos = index( $test_text, '&euro;') if ($pos == -1);
			$pos = index( $test_text, '&sect;') if ($pos == -1);
			$pos = index( $test_text, '&dagger;') if ($pos == -1);

			$pos = index( $test_text, '&lsquo;') if ($pos == -1);
			$pos = index( $test_text, '&rsquo;') if ($pos == -1);
			$pos = index( $test_text, '&middot;') if ($pos == -1);
			$pos = index( $test_text, '&bull;') if ($pos == -1);
			$pos = index( $test_text, '&copy;') if ($pos == -1);
			$pos = index( $test_text, '&reg;') if ($pos == -1);
			$pos = index( $test_text, '&trade;') if ($pos == -1);
			$pos = index( $test_text, '&iquest;') if ($pos == -1);
			$pos = index( $test_text, '&iexcl;') if ($pos == -1);
			$pos = index( $test_text, '&aelig;') if ($pos == -1);
			$pos = index( $test_text, '&ccedil;') if ($pos == -1);
			$pos = index( $test_text, '&ntilde;') if ($pos == -1);
			$pos = index( $test_text, '&acirc;') if ($pos == -1);
			$pos = index( $test_text, '&aacute;') if ($pos == -1);
			$pos = index( $test_text, '&agrave;') if ($pos == -1);
			
			#arrows 
			$pos = index( $test_text, '&darr;') if ($pos == -1);
			$pos = index( $test_text, '&uarr;') if ($pos == -1);
			$pos = index( $test_text, '&crarr;') if ($pos == -1);
			$pos = index( $test_text, '&rarr;') if ($pos == -1);
			$pos = index( $test_text, '&larr;') if ($pos == -1);
			$pos = index( $test_text, '&harr;') if ($pos == -1);

			
			if ($pos > -1) {
				my $found_text = substr ( $text , $pos);
				$found_text = text_reduce($found_text, 80);
				$found_text =~ s/&/&amp;/g;
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}

sub error_012_html_list_elements{
	my $error_code = 12;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML List elements';
		$error_description[$error_code][2] = 'Article contains a <nowiki>"<ol>", "<ul>" or "<li>"</nowiki>. '."In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if (index($test_text, '<ol') > -1
			or index($test_text, '<ul') > -1
			or index($test_text, '<li>') > -1) {
			foreach (@lines) {
				my $current_line = $_;
				my $current_line_lc = lc($current_line);

				#get position of categorie
				
				if ( ($page_namespace == 0 or $page_namespace == 104)
					and index( $text, '<ol start') == -1
					and index( $text, '<ol type') == -1	
					and index( $text, '<ol style="list-style-type:lower-roman">') == -1	
					and index( $text, '<ol style="list-style-type:lower-alpha">') == -1	
					and (
						index( $current_line_lc, '<ol>') > -1
						or index( $current_line_lc, '<ul>') > -1
						or index( $current_line_lc, '<li>') > -1
				)) {
					$test = 'found';
					$test_line = $current_line if ($test_line eq '');
				}
			}
		}
		if ($test eq 'found' ) {
			$test_line = text_reduce($test_line, 80);
			error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
			#print "\t". $error_code."\t".$title."\t".$test_line."\n";
		}
	}
}


sub error_013_Math_no_correct_end{
	my $error_code = 13; 
	my $attribut = $_[0];
	my $comment =  $_[1];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Math not correct end';
		$error_description[$error_code][2] = 'Found a <nowiki>"<math>"</nowiki> but no <nowiki>"</math>"</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne '') {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}
	
sub error_014_Source_no_correct_end{
	my $error_code = 14; 
	my $attribut = $_[0];
	my $comment =  $_[1];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Source not correct end';
		$error_description[$error_code][2] = 'Found a <nowiki>"<source …>"</nowiki> but no <nowiki>"</source>"</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne '') {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_015_Code_no_correct_end{
	my $error_code = 15; 
	my $attribut = $_[0];
	my $comment =  $_[1];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Code not correct end';
		$error_description[$error_code][2] = 'Found a <nowiki>"<code>"</nowiki> but no <nowiki>"</code>"</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne '') {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_016_unicode_control_characters{
	my $error_code = 16;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Template with Unicode control characters';
		$error_description[$error_code][2] = 'Find Unicode control characters <tt>&#x<code></code>FEFF;</tt> or <tt>&#x<code></code>200E;</tt> or <tt>&#x<code></code>200B;</tt> ([[:en:Left-to-right_mark]], [[:en:Right-to-left mark]], [[:en:Byte-order mark]]). This could be a problem inside a template. Copy the template in a texteditor (for example [[Notepad++]]), where you see the controle characters and delete this. Copy then this text back in the article.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0  or $page_namespace == 6 or $page_namespace == 104 ) {
			foreach (@templates_all) {
				my $template_text = $_;
				my $pos = -1;
				#$pos = index( $text, '&#xFEFF;') 	if ($pos == -1);	# l in Wrozlaw
				#$pos = index( $text, '&#x200E;') 	if ($pos == -1);	# l in Wrozlaw
				#$pos = index( $text, '&#x200B;') 	if ($pos == -1);	# –
				$pos = index( $template_text, '‎') if ($pos == -1);	# &#x200E;
				$pos = index( $template_text, '﻿') if ($pos == -1);	# &#xFEFF;
				#$pos = index( $template_text, '​') if ($pos == -1);	# &#x200B;  # problem with IPA characters like "͡" in cs:Czechowice-Dziedzice.
				
				if ($pos > -1) {
					my $found_text = substr ( $template_text , $pos);
					$found_text = text_reduce($found_text, 80);
					error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".$found_text."\n";
				}
			}
		}
	}
}

sub error_017_category_double{
	my $error_code = 17; 
	my $attribut = $_[0];
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Category double';
		$error_description[$error_code][2] = 'In this article is a category double.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {

		#print $title."\n" if ($page_number > 25000);;
		for (my $i = 0; $i <= $category_counter-1; $i++) {

			#if ($title eq 'File:TobolskCoin.jpg') {
			#	print "\t".'Begin='.$category[$i][0].' End='.$category[$category_counter][1]."\n";
			#	print "\t".'catname=' .$category[$i][2]."\n";
			#	print "\t".'linkname='.$category[$i][3]."\n";
			#	print "\t".'full cat='.$category[$i][4]."\n";
			#}
			
			my $test1 = $category[$i][2];
			
			if ($test1 ne '') {
				$test1 = uc(substr($test1,0,1)).substr($test1,1); #first letter big
			
				for (my $j = $i+1; $j <= $category_counter; $j++) {
				
					my $test2 = $category[$j][2];
					if ($test2 ne '') {
					
						$test2 = uc(substr($test2,0,1)).substr($test2,1); #first letter big
				
						#print $title."\t".$category[$i][2]."\t".$category[$j][2]."\n";
						if ($test1 eq $test2
							and ($page_namespace == 0 or $page_namespace == 104)) {
							error_register($error_code, '<nowiki>'.$category[$i][2].'</nowiki>'); 
							#print "\t". $error_code."\t".$title."\t".$category[$i][2]."\n";
						}
					}
				}	
			}

	
		}

	}
}

sub error_018_category_first_letter_small{
	my $error_code = 18; 
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 0;
		$error_description[$error_code][1] = 'Category first letter small';
		$error_description[$error_code][2] = 'The first letter of the category is small. It should be a big letter. If a user would scan a dump and he use the category then he will be very happy if all categories begin with a big letter.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($project ne 'commonswiki') {
			for (my $i = 0; $i <= $category_counter; $i++) {
				my $test_letter = substr($category[$i][2],0,1);
				if ( $test_letter =~ /([a-z]|ä|ö|ü)/ ) {
					error_register($error_code, '<nowiki>'.$category[$i][2].'</nowiki>'); 
					#print "\t".$test_letter.' - '.$category[$i][2]."\n";
				}		
			}
		}
	}
}

sub error_019_headline_only_one{
	my $error_code = 19; 
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Headlines start with one "="';
		$error_description[$error_code][2] = 'The first headline start with <nowiki>"= XY ="</nowiki>. It should only <nowiki>"== XY =="</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $headlines[0] 
			and ($page_namespace == 0 or $page_namespace == 104)){
			if ( $headlines[0] =~ /^=[^=]/){
				error_register($error_code, '<nowiki>'.$headlines[0].'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$headlines[0].'</nowiki>'."\n";
			}
		}
	}
}

sub error_020_symbol_for_dead{
	my $error_code = 20; 
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Symbol for dead';
		$error_description[$error_code][2] = 'The article had a &dag<code></code>ger; and not †.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $pos = index ($text, '&dagger;');
		if ( $pos > -1
			and ($page_namespace == 0 or $page_namespace == 104)){
			my $test_text = substr ($text, $pos, 100);
			$test_text = text_reduce($test_text, 50);
			error_register($error_code, '<nowiki>…'.$test_text.'…</nowiki>'); 
			#print "\t". $error_code."\t".$title."\t".'<nowiki>…'.$test_text.'…</nowiki>'."\n";
		}
	}
}

sub error_021_category_is_english{
	my $error_code = 21; 
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Category is english';
		$error_description[$error_code][2] = 'The article had a category in english. It should renamed in "'.$namespace_cat[0].':ABC…". It is ok for the mediawiki software, but a new wikipedian maybe have a problem with the english language.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if (    $project ne 'enwiki'
			and $project ne 'commonswiki'
			and ($page_namespace == 0 or $page_namespace == 104)
			and $namespace_cat[0] ne 'Category') {
			for (my $i=0; $i <= $category_counter; $i++) {
				my $current_cat = lc ($category[$i][4]);
				
				if (   index ( $current_cat, lc($namespace_cat[1])) > -1 ) {
					error_register($error_code, '<nowiki>'.$current_cat.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$category[$i][4].'</nowiki>'."\n";
				}
			}
		}
	}
}

sub error_022_category_with_space{
	my $error_code = 22; 
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Category with space';
		$error_description[$error_code][2] = 'The article had a category a space in front (for example: <nowiki>[[  Category:ABC]] or [[Category : ABC]]</nowiki> ). The mediawiki has no problem with this, but but if you write a external parser this it only one of your problem. Please fix it.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104 ) {
			for (my $i=0; $i <= $category_counter; $i++) {
				#print "\t". $category[$i][4]. "\n";
				if (    $category[$i][4] =~ /\[\[ /
					 or $category[$i][4] =~ /\[\[[^:]+ :/
					 #or $category[$i][4] =~ /\[\[[^:]+: /
					) {
					error_register($error_code, '<nowiki>'.$category[$i][4].'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$category[$i][4].'</nowiki>'."\n";
				}
			}
		}
	}
}

sub error_023_nowiki_no_correct_end{
	my $error_code = 23; 
	my $attribut = $_[0];
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Nowiki not correct end';
		$error_description[$error_code][2] = 'Found no nowiki end.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne ''
			and ( $page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104 )
			) {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_024_pre_no_correct_end{
	my $error_code = 24; 
	my $attribut = $_[0];
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {		
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Pre not correct end';
		$error_description[$error_code][2] = 'Found no pre end.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne ''
			and ( $page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104 )
			) {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_025_headline_hierarchy{
	my $error_code = 25; 
	my $attribut = $_[0];
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {		
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Headline hierarchy';
		$error_description[$error_code][2] = 'After a headline of level 1 (==) should not be a headline of level 3 (====). (See also [http://www.w3.org/TR/WCAG20-TECHS/G141.html W3C Techniques for WCAG 2.0])';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $number_headline = -1;
		my $old_headline = '';
		my $new_headline = '';
		if ( $page_namespace == 0 or $page_namespace == 104 ){
			foreach (@headlines) {
				$number_headline = $number_headline +1;
				$old_headline = $new_headline;
				$new_headline = $_;
				
				if ($number_headline > 0) {
					my $level_old = $old_headline;
					my $level_new = $new_headline;
					
					#print $old_headline."\n";
					#print $new_headline."\n";
					$level_old =~ s/^([=]+)//;
					$level_new =~ s/^([=]+)//;
					$level_old = length($old_headline) - length($level_old);
					$level_new = length($new_headline) - length($level_new);
					#print $level_old ."\n";
					#print $level_new ."\n";
					
					if ( $level_new > $level_old and  ($level_new - $level_old) >1  ){
						error_register($error_code, '<nowiki>'.$old_headline.'</nowiki><br /><nowiki>'.$new_headline.'</nowiki>'); 
						#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$headlines[0].'</nowiki>'."\n";
					}
				}
			}
		}
	}
}

sub error_026_html_text_style_elements{
	my $error_code = 26;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {		
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><b></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><b></nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if (index($test_text, '<b>') > -1) {
			foreach (@lines) {
				my $current_line = $_;
				my $current_line_lc = lc($current_line);

				if ( ($page_namespace == 0 or $page_namespace == 104)
					and (
						index( $current_line_lc, '<b>') > -1
				)) {
					$test = 'found';
					$test_line = $current_line if ($test_line eq '');
				}
			}
		}
		
		if ($test eq 'found' ) {
			$test_line = text_reduce($test_line, 80);
			$test_line = $test_line.'…';
			error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
			#print "\t". $error_code."\t".$title."\t".$test_line."\n";
		}
	}
}


sub error_027_unicode_syntax{
	my $error_code = 27;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {		
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Unicode syntax';
		$error_description[$error_code][2] = 'Find <tt>&#<code></code>0000;</tt> (decimal) or <tt>&#x<code></code>0000;</tt> (hexadecimal). Please use the [[Unicode]] characters.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0  or $page_namespace == 6 or $page_namespace == 104) {
			my $pos = -1;
			$pos = index( $text, '&#322;') 		if ($pos == -1);	# l in Wrozlaw
			$pos = index( $text, '&#x0124;') 	if ($pos == -1);	# l in Wrozlaw
			$pos = index( $text, '&#8211;') 	if ($pos == -1);	# –
			#$pos = index( $text, '&#x') if ($pos == -1);
			#$pos = index( $text, '&#') if ($pos == -1);
			
			if ($pos > -1) {
				my $found_text = substr ( $text , $pos);
				$found_text = text_reduce($found_text, 80);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}



sub error_028_table_no_correct_end{
	my $error_code = 28; 
	my $attribut = $_[0];
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {		
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Table not correct end';
		$error_description[$error_code][2] = 'Found no end of the table.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne ''
			and ($page_namespace == 0 or $page_namespace == 104)
			and index ($text, '{{end}}') == -1
			and index ($text, '{{End box}}') == -1
			and index ($text, '{{end box}}') == -1
			) {
			error_register($error_code, '<nowiki> '.$comment.'…  </nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}


sub error_029_gallery_no_correct_end{
	my $error_code = 29; 
	my $attribut = $_[0];
	my $comment =  $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {		
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Gallery not correct end';
		$error_description[$error_code][2] = 'Found no end of the gallery.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne ''
			and ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104)
			) {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_030_image_without_description {
	my $error_code = 30; 
	my $attribut = $_[0];
	my $comment  = $_[1];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Image without description';
		$error_description[$error_code][2] = 'The article has an image without a description. In order to provide good accessibility for everyone (e.g. blind people) a description for every image is needed. (See also [http://www.w3.org/TR/2008/NOTE-WCAG20-TECHS-20081211/H37.html W3C Techniques for WCAG 2.0]) ';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne '') {
			if ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104) {
				error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$comment."\n";
			}
		}
	}
}

sub error_031_html_table_elements{
	my $error_code = 31;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'HTML table element';
		$error_description[$error_code][2] = 'Article contains a <nowiki>"<table>", "<td>", "<th>" or "<tr>"</nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104) {
			if (index($test_text, '<t') > -1) {
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);

					if ( $page_namespace == 0 
						and (
							#index( $current_line_lc, '<table>') > -1
							#or index( $current_line_lc, '<td>') > -1
							#or index( $current_line_lc, '<th>') > -1
							#or index( $current_line_lc, '<tr>') > -1
							#or 
							$current_line_lc =~ /<(table|tr|td|th)(>| border| align| bgcolor| style)/
						
					)) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
					}
				}
			}
			if ($test eq 'found' ) {
				# http://aktuell.de.selfhtml.org/artikel/cgiperl/html-in-html/
				$test_line = text_reduce($test_line, 80);
				$test_line =~ s/\&/&amp;/g;
				$test_line =~ s/</&lt;/g;
				$test_line =~ s/>/&gt;/g;
				$test_line =~ s/\"/&quot;/g;
				
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}
		}
	}
}

sub error_032_double_pipe_in_link{
	my $error_code = 32;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Double pipe in one link';
		$error_description[$error_code][2] = 'Article contains a link like <nowiki>[[text|text2|text3]]</nowiki>' ;
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104) {
			foreach (@lines) {
				my $current_line = $_;
				my $current_line_lc = lc($current_line);
				if ( $current_line_lc =~ /\[\[[^\]:\{]+\|([^\]\{]+\||\|)/g ){
					my $pos = pos($current_line_lc);
					my $first_part = substr($current_line, 0, $pos);
					my $second_part = substr($current_line, $pos);
					my @first_part_split = split ( /\[\[/ , $first_part);
					foreach (@first_part_split) {
						$first_part = '[['.$_;								# find last link in first_part
					}
					$current_line = $first_part . $second_part;
					$current_line = text_reduce($current_line, 80);
					error_register($error_code, '<nowiki>'.$current_line.' </nowiki>');
					#print "\t". $error_code."\t".$title."\t".$current_line."\n";
				}	
			}
		}
	}
}

sub error_033_html_text_style_elements_underline{
	my $error_code = 33;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><u></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><u></nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if (index($test_text, '<u>') > -1) {
			foreach (@lines) {
				my $current_line = $_;
				my $current_line_lc = lc($current_line);

				if ( ($page_namespace == 0 or $page_namespace == 104)
					and (
						index( $current_line_lc, '<u>') > -1
				)) {
					$test = 'found';
					$test_line = $current_line if ($test_line eq '');
				}
			}
		}
		if ($test eq 'found' ) {
			$test_line = text_reduce($test_line, 80);
			$test_line = $test_line.'…';
			error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
			#print "\t". $error_code."\t".$title."\t".$test_line."\n";
		}
	}
}

sub error_034_template_programming_elements{
	my $error_code = 34;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Template programming element';
		$error_description[$error_code][2] = 'Article contains a <nowiki>"#if:" or "#ifeq:" or "#ifexist:" or "#switch:" or "#tag:" or "{{NAMESPACE}}" or "{{SITENAME}}" or "{{PAGENAME}}" or "{{FULLPAGENAME}}" or "{{{1}}}" (Parameter)</nowiki>. ' ;
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		foreach (@lines) {
			my $current_line = $_;
			my $current_line_lc = lc($current_line);
			
			my $pos = -1;
			if ( $page_namespace == 0 or $page_namespace == 104 ) {
			
				$pos = index( $current_line_lc, '#if:') 					if (index( $current_line_lc, '#if:')> -1);
				$pos = index( $current_line_lc, '#ifeq:') 					if (index( $current_line_lc, '#ifeq:') > -1);
				$pos = index( $current_line_lc, '#ifeq:') 					if (index( $current_line_lc, '#ifeq:') > -1	);
				$pos = index( $current_line_lc, '#switch:') 				if (index( $current_line_lc, '#switch:') > -1);
				$pos = index( $current_line_lc, '{{namespace}}') 			if (index( $current_line_lc, '{{namespace}}') > -1);
				$pos = index( $current_line_lc, '{{sitename}}') 			if (index( $current_line_lc, '{{sitename}}') > -1);
				$pos = index( $current_line_lc, '{{fullpagename}}') 		if (index( $current_line_lc, '{{fullpagename}}') > -1);
				$pos = index( $current_line_lc, '#ifexist:') 				if (index( $current_line_lc, '#ifexist:') > -1	);
				$pos = index( $current_line_lc, '{{{') 						if (index( $current_line_lc, '{{{') > -1);	
				$pos = index( $current_line_lc, '#tag:')					if (index( $current_line_lc, '#tag:') > -1 and index( $current_line_lc, '#tag:ref') == -1);	# http://en.wikipedia.org/wiki/Wikipedia:Footnotes#Known_bugs

				if ($pos > -1 ) {
					$test = 'found';
					if ($test_line eq '') {
						$test_line = $current_line;
						$test_line = substr ($test_line, $pos);
					}
				}
			}
		}
		
		if ($test eq 'found' ) {
			$test_line = text_reduce($test_line, 50);
			error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
			#print "\t". $error_code."\t".$title."\t".$test_line."\n";
		}
	}
}


sub error_035_gallery_without_description{
	my $error_code = 35;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Gallery without description';
		$error_description[$error_code][2] = 'Article contains a gallery without image description. ' ;
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $text_gallery = $_[0];
			
		my $test = '';
		if ($text_gallery ne ''
			and ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104) ) {
			#print $text_gallery."\n";
			my @split_gallery = split ( /\n/, $text_gallery );
			my $test_line = '';
			foreach (@split_gallery) {
				my $current_line = $_;
				#print $current_line."\n";
				foreach (@namespace_image) {
					my $namespace_image_word = $_;
					#print $namespace_image_word."\n";
					if ($current_line =~ /^$namespace_image_word:[^\|]+$/ ) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
					}
				}
			}				
			if ($test eq 'found' ) {
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}		
		}
	}
}

sub error_036_redirect_not_correct{
	my $error_code = 36;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Redirect not correct';
		$error_description[$error_code][2] = 'Article contains something like "<nowiki>#REDIRECT = [[Target page]]</nowiki>". The equal sign is not correct. Correct is "<nowiki>#REDIRECT [[Target page]]</nowiki>" or "<nowiki>#REDIRECT: [[Target page]]</nowiki>".' ;
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_is_redirect  eq 'yes') {
			if ( lc($text) =~ /#redirect[ ]?+[^ :\[][ ]?+\[/) {
				my $output_text = text_reduce($text, 80);
				
				error_register($error_code, '<nowiki>'.$output_text.' </nowiki>');
				#print "\t".$title."\n";
				#print "\t\t".$text."\n";
			}
		}
	}
}


sub error_037_title_with_special_letters_and_no_defaultsort{
	my $error_code = 37;
	my $attribut = $_[0];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Title with special letters and no DEFAULTSORT';
		$error_description[$error_code][2] = 'The title has a special letter and in the article is no DEFAULTSORT (or in ca: ORDENA, es:ORDENAR, de:SORTIERUNG). Also one category has not the syntax <nowiki>[[Category:ABC|Text]]</nowiki>'."\n"."\n";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104)
			 and $category_counter > -1
			 and $project ne 'arwiki'
			 and $project ne 'jawiki'
			 and $project ne 'hewiki'
			 and $project ne 'plwiki'
			 and $project ne 'trwiki'
			 and $project ne 'yiwiki'
			 and $project ne 'zhwiki'
			 and length($title) > 2
			 ) {

			# test of magicword_defaultsort
			my $pos1 = -1;
			foreach (@magicword_defaultsort) {
				$pos1 = index($text, $_) if ($pos1 == -1);
			}
			
			if ($pos1 == -1 ) {
				# no defaultsort in article
				# now test title
				#print 'No defaultsort'."\n";
				
				my $test = $title;
				if (index ($test, '(') > -1) {
					# only text of title before bracket
					$test = substr ($test, 0, index ($test, '(')-1);
					$test =~ s/ $//g;
				}

				my $testtext = $test;
				$testtext = substr ($testtext, 0, 3);
				$testtext = substr ($testtext, 0, 1) if ($project eq 'frwiki'); #request from fr:User:Laddo
				#print "\t".'Testtext0'.$testtext."\n";
				
				$testtext =~ s/[-—–:,\.0-9 A-Za-z!\?']//g;
				$testtext =~ s/[&]//g;
				$testtext =~ s/\+//g;
				$testtext =~ s/#//g;
				$testtext =~ s/\///g;
				$testtext =~ s/\(//g;
				$testtext =~ s/\)//g;
				$testtext =~ s/[ÅÄÖåäö]//g  if ($project eq 'svwiki');    # For Swedish, ÅÄÖ should also be allowed
				$testtext =~ s/[ÅÄÖåäö]//g  if ($project eq 'fiwiki');    # For Finnish, ÅÄÖ should also be allowed
				$testtext =~ s/[čďěňřšťžČĎŇŘŠŤŽ]//g if ($project eq 'cswiki'); 
				$testtext =~ s/[ÆØÅæøå]//g  if ($project eq 'dawiki');
				$testtext =~ s/[ÆØÅæøå]//g  if ($project eq 'nowiki');
				$testtext =~ s/[ÆØÅæøå]//g  if ($project eq 'nnwiki');
				$testtext =~ s/[ăîâşţ]//g   if ($project eq 'rowiki');
				$testtext =~ s/[АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдежзийклмнопрстуфхцчшщьыъэюя]//g   if ($project eq 'ruwiki');
				$testtext =~ s/[АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдежзийклмнопрстуфхцчшщьыъэюяiїґ]//g   if ($project eq 'ukwiki');
				
				#print "\t".'Testtext1'.$testtext."\n";
				if ( $testtext ne '' ) {
					#print "\t".'Testtext2'.$testtext."\n";
					my $found = 'no';
					for (my $i=0; $i <= $category_counter; $i++) {
						$found = "yes" if ($category[$i][3] eq '' and index ($category[$i][4], '|') == -1 );
					}
				
					if ($found eq 'yes') {
						#print "\t".$title."\n";
						#print "\t".$test."\n";
						#for (my $i=0; $i <= $category_counter; $i++) {
						#	print $category[$i][4]."\n";
						#}
						error_register($error_code, '');
						#print "\t". $error_code."\t".$title."\n";
					}
				}
			}
		}
	}
}


sub error_038_html_text_style_elements_italic{
	my $error_code = 38; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><i></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><i></nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			if (index($test_text, '<i>') > -1) {
			
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);

					if ( index( $current_line_lc, '<i>') > -1 ) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
						
					}
				}
			}
			
			if ($test eq 'found' ) {
				$test_line = text_reduce($test_line, 80);
				$test_line = $test_line.'…';
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}
		}
	}
}

sub error_039_html_text_style_elements_paragraph{
	my $error_code = 39;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><p></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><p></nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if ( $page_namespace == 0 or $page_namespace == 104) {
			if (index($test_text, '<p>') > -1) {
			
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);

					if ( index( $current_line_lc, '<p>') > -1 ) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
					}
				}
			}
			if ($test eq 'found' ) {
				$test_line = text_reduce($test_line, 80);
				$test_line = $test_line.'…';
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}
		}
	}
}

sub error_040_html_text_style_elements_font{
	my $error_code = 40;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><font></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><font></nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if ( $page_namespace == 0 or $page_namespace == 104) {
			if (index($test_text, '<font') > -1) {
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);

					if (    index( $current_line_lc, '<font ') > -1
						 or index( $current_line_lc, '<font>') > -1) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
					}
				}
			}
			
			if ($test eq 'found' ) {
				$test_line = text_reduce($test_line, 80);
				$test_line = $test_line.'…';
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}
		}
	}
}

sub error_041_html_text_style_elements_big{
	my $error_code = 41;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><big></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><big></nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		if ( $page_namespace == 0 or $page_namespace == 104) {
			if (index($test_text, '<big>') > -1) {
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);

					if ( index( $current_line_lc, '<big>') > -1) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
					}
				}
			}
			if ($test eq 'found' ) {
				$test_line = text_reduce($test_line, 80);
				$test_line = $test_line.'…';
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}
		}
	}
}


sub error_042_html_text_style_elements_small{
	my $error_code = 42;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><small></nowiki>';
		$error_description[$error_code][2] = 'Article contains a <nowiki><small</nowiki>. '. "In most cases we can use simpler wiki markups in place of these HTML-like tags.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test = 'no found';
		my $test_line = '';
		my $test_text = lc($text);
		
		if ( $page_namespace == 0 or $page_namespace == 104) {
			if (index($test_text, '<small>') > -1) {
				foreach (@lines) {
					my $current_line = $_;
					my $current_line_lc = lc($current_line);

					if ( index( $current_line_lc, '<small>') > -1) {
						$test = 'found';
						$test_line = $current_line if ($test_line eq '');
					}
				}
			}
			if ($test eq 'found' ) {
				$test_line = text_reduce($test_line, 80);
				$test_line = $test_line.'…';
				error_register($error_code, '<nowiki>'.$test_line.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".$test_line."\n";
			}
		}
	}
}


sub error_043_template_no_correct_end{
	my $error_code = 43; 
	my $attribut = $_[0];	
	my $comment = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Template not correct end';
		$error_description[$error_code][2] = 'Found a template with <nowiki>"{{"</nowiki> and with no <nowiki>"}}"</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($comment ne ''
			and ($page_namespace == 0 or $page_namespace == 6 or $page_namespace == 104 ) ) {
			error_register($error_code, '<nowiki>'.$comment.'</nowiki>'); 
			#print "\t". $error_code."\t".$title."\n";
		}
	}
}

sub error_044_headline_with_bold{
	my $error_code = 44;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Headlines with bold';
		$error_description[$error_code][2] = 'The headline is bold <nowiki>"== '."'''XY'''".' =="</nowiki>. It should only be <nowiki>"== XY =="</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104) {
			foreach (@headlines) {
				my $current_line = $_;
				#print $current_line ."\n";
				if (     index ($current_line , "'''" ) > -1 			# if bold ther
					 and not $current_line =~ /[^']''[^']/				# for italic in headlinses   for example: == Acte au sens d'''instrumentum'' ==
				   ) {
					# there is a bold in headline
					my $bold_ok = 'no';
					if (index ($current_line , "<ref" ) > -1) {
						# test for bold in ref
						# # ===This is a headline with reference <ref>A reference with '''bold''' text</ref>===
						my $pos_begin_ref = index ($current_line , "<ref" );
						my $pos_end_ref   = index ($current_line , "</ref" );
						my $pos_begin_bold= index ($current_line , "'''" );
						if ($pos_begin_ref < $pos_begin_bold
							and $pos_begin_bold < $pos_end_ref ) {
								$bold_ok = 'yes';
						}
					}
					if ($bold_ok eq 'no') {
						$current_line = text_reduce($current_line, 80);
						error_register($error_code, '<nowiki>'.$current_line.'</nowiki>'); 
						#print "\t". $error_code."\t".$title."\t".$current_line."\n";
					}
				}		
			}
		}
	}
}


sub error_045_interwiki_double{
	my $error_code = 45;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Interwiki double';
		$error_description[$error_code][2] = 'Article contains double interwiki link to one other languages.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		#print $title."\n";
		#print 'Interwikis='.$interwiki_counter."\n";
		my $found_double = '';
		
		if ($page_namespace == 0 or $page_namespace == 104 )
			{
			for (my $i = 0; $i <= $interwiki_counter; $i++ ) {
				#print $interwiki[$i][0]. $interwiki[$i][1]. $interwiki[$i][2]. $interwiki[$i][3]. $interwiki[$i][4]. "\n";
				for (my $j = $i + 1; $j <= $interwiki_counter; $j++ ) {
					if ( lc($interwiki[$i][5]) eq lc($interwiki[$j][5])) {
						my $test1 = lc($interwiki[$i][2]);
						my $test2 = lc($interwiki[$j][2]);
						#print $test1."\n";
						#print $test2."\n";
						
						if ( $test1 eq  $test2) {
							$found_double = '<nowiki>'.$interwiki[$i][4].'</nowiki><br /><nowiki>'.$interwiki[$j][4].'</nowiki>'."\n";
						}
						
					}
				}
			}
		}
		
		if ($found_double ne '') {
			error_register($error_code, $found_double);
			#print "\t". $error_code."\t".$title."\t".$found_double."\n";
		}
	}
}

sub error_046_count_square_breaks_begin{
	my $error_code = 46;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Square brackets not correct begin';
		$error_description[$error_code][2] = 'Different number of <nowiki>[[</nowiki> and <nowiki>]]</nowiki> brackets. If it is sourcecode then use <nowiki><source> or <code></nowiki>.';
		$error_description[$error_code][2] = infotext_new_error( $error_description[$error_code][2] );
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $text_test = '';
		
		#$text_test = 'abc[[Kartographie]], Bild:abd|[[Globus]]]] ohne [[Gradnetz]] weiterer Text 
		#aber hier [[Link234|sdsdlfk]]  [[Test]]';
		#print 'Start 46'."\n";
		if (    $page_namespace == 0
			 or $page_namespace == 6
			 or $page_namespace == 104)
			{
			$text_test = $text;
			#print $text_test."\n";
			my $text_test_1_a = $text_test;
			my $text_test_1_b = $text_test;
			
			if ( ($text_test_1_a =~ s/\[\[//g) != ($text_test_1_b =~ s/\]\]//g) ) {
				my $found_text = '';
				while($text_test =~ /\]\]/g) {
					#Begin of link
					my $pos_end = pos($text_test) - 2;
					my $link_text = substr ( $text_test, 0, $pos_end);
					my $link_text_2 = '';
					my $beginn_square_brackets = 0;
					my $end_square_brackets = 1;
					while($link_text =~ /\[\[/g) {
						# Find currect end - number of [[==]]
						my $pos_start = pos($link_text);
						$link_text_2 = substr ( $link_text, $pos_start);
						$link_text_2 = ' '.$link_text_2.' ';
						#print 'Link_text2:'."\t".$link_text_2."\n";

						# test the number of [[and  ]]
						my $link_text_2_a = $link_text_2;
						$beginn_square_brackets = ($link_text_2_a =~ s/\[\[//g);			
						my $link_text_2_b = $link_text_2;
						$end_square_brackets = ($link_text_2_b =~ s/\]\]//g);			

						#print $beginn_square_brackets .' vs. '.$end_square_brackets."\n";
						last if ($beginn_square_brackets eq $end_square_brackets);
						
					}
					
					if ($beginn_square_brackets != $end_square_brackets ) {
						# link has no correct begin
						#print $link_text."\n";	
						$found_text = $link_text;
						$found_text =~ s/  / /g;
						$found_text = text_reduce_to_end( $found_text, 50).']]';
						#$link_text = '…'.substr($link_text, length($link_text)-50 ).']]';
					}
					
					last if ($found_text ne '');		# end if a problem was found, no endless run
				}
				
				if ( $found_text ne '') {
					error_register($error_code, '<nowiki>'.$found_text.'</nowiki>');
					#print 'Error 46: '.$title.' '.$found_text."\n";
					#print $page_namespace."\n";
				}
			}
		}
		#print 'End 46'."\n";
	}
}



sub error_047_template_no_correct_begin{
	my $error_code = 47;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Template not correct begin';
		$error_description[$error_code][2] = 'Found a template with no <nowiki>"{{"</nowiki> but with <nowiki>"}}"</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
	
		my $text_test = '';
		 
		#$text_test = 'abc[[Kartographie]], [[Bild:abd|[[Globus]]]] ohne {{xyz}} [[Gradnetz]] weiterer Text {{oder}} wer}} warum
		##aber hier [[Link234|sdsdlfk]] {{abc}} [[Test]]';

		if (    $page_namespace == 0
			 or $page_namespace == 6
			 or $page_namespace == 104)
			{
			$text_test = $text;
			#print $text_test."\n";
			my $text_test_1_a = $text_test;
			my $text_test_1_b = $text_test;
			
			if ( ($text_test_1_a =~ s/\{\{//g) != ($text_test_1_b =~ s/\}\}//g) ) {
				#print 'Error 47 not equl $title'."\n";
				while($text_test =~ /\}\}/g) {
					#Begin of link
					my $pos_end = pos($text_test) - 2;
					my $link_text = substr ( $text_test, 0, $pos_end);
					my $link_text_2 = '';
					my $beginn_square_brackets = 0;
					my $end_square_brackets = 1;
					while($link_text =~ /\{\{/g) {
						# Find currect end - number of [[==]]
						my $pos_start = pos($link_text);
						$link_text_2 = substr ( $link_text, $pos_start);
						$link_text_2 = ' '.$link_text_2.' ';
						#print $link_text_2."\n";

						# test the number of [[and  ]]
						my $link_text_2_a = $link_text_2;
						$beginn_square_brackets = ($link_text_2_a =~ s/\{\{//g);			
						my $link_text_2_b = $link_text_2;
						$end_square_brackets = ($link_text_2_b =~ s/\}\}//g);			

						#print $beginn_square_brackets .' vs. '.$end_square_brackets."\n";
						last if ($beginn_square_brackets eq $end_square_brackets);
					}
					
					if ($beginn_square_brackets != $end_square_brackets ) {
						# template has no correct begin
						$link_text =~ s/  / /g;
						#$link_text = '…'.substr($link_text, length($link_text) -50 ).'}}';
						$link_text = text_reduce_to_end( $link_text, 50).'}}';
						error_register($error_code, '<nowiki>'.$link_text.'</nowiki>');
						#print 'Error 47: '.$title.' '.$link_text."\n";
						#print $page_namespace."\n"; 
					}
				}
			}
		}
	}
}

sub error_048_title_in_text{
	my $error_code = 48; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Title in text';
		$error_description[$error_code][2] = 'Found a link to the title inside the text. Change this <nowiki>[[Title]]</nowiki> into <nowiki>'."'''Title'''".'</nowiki>';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		
		my $text_test = $text;
		

		if (    $page_namespace == 0
			 or $page_namespace == 6
			 or $page_namespace == 104)
			{
		
			my $pos = index($text_test, '[['.$title.']]');
			
			if ($pos == -1) {
				$pos = index($text_test, '[['.$title.'|');
			}
			
			if ($pos != -1) {
				my $found_text = substr ( $text_test, $pos);
				$found_text = text_reduce($found_text, 50);
				$found_text =~ s/\n//g;
				error_register($error_code, '<nowiki>'.$found_text .'</nowiki>');
				#print 'Error 48: '.$title.' '.$found_text."\n";
			}
		}
	}
}

sub error_049_headline_with_html{
	my $error_code = 49;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Headline with HTML';
		$error_description[$error_code][2] = 'Found a headline in format <nowiki><h2>Headline</h2></nowiki> in the text. Please use wikisyntax <nowiki>== Headline ==</nowiki>. If it is sourcecode then use <nowiki><source> or <code></nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		
		if (    $page_namespace == 0
			 or $page_namespace == 6
			 or $page_namespace == 104)
			{
		
			my $text_test = lc($text);
			my $pos = -1;
			$pos = index($text_test, '<h2>') if ($pos == -1);
			$pos = index($text_test, '<h3>') if ($pos == -1);
			$pos = index($text_test, '<h4>') if ($pos == -1);
			$pos = index($text_test, '<h5>') if ($pos == -1);
			$pos = index($text_test, '<h6>') if ($pos == -1);
			$pos = index($text_test, '</h2>') if ($pos == -1);
			$pos = index($text_test, '</h3>') if ($pos == -1);
			$pos = index($text_test, '</h4>') if ($pos == -1);
			$pos = index($text_test, '</h5>') if ($pos == -1);
			$pos = index($text_test, '</h6>') if ($pos == -1);
			if ($pos != -1) {
				my $found_text = substr ( $text_test, $pos);
				$found_text = text_reduce($found_text, 50);
				$found_text =~ s/\n//g;
				error_register($error_code, '<nowiki>'.$found_text .'</nowiki>');
				#print 'Error 49: '.$title.' '.$found_text."\n";
			}
		}
	}
}

sub error_050_dash{
	my $error_code = 50; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'en dash or em dash';
		$error_description[$error_code][2] = 'The article had a dash. Write for  <tt>&nda<code></code>sh;</tt> better "–" or <tt>&mda<code></code>sh;</tt> better "—". ';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $pos = -1;
		$pos = index (lc($text), '&ndash;');
		$pos = index (lc($text), '&mdash;') if $pos == -1;
		
		if ( $pos > -1
			and ($page_namespace == 0 or $page_namespace == 104) )
			{
			my $found_text = substr ($text, $pos );
			$found_text =~ s/\n//g;
			$found_text = text_reduce($found_text, 50);
			$found_text =~ s/^&/&amp;/g;
			error_register($error_code, '<nowiki>…'.$found_text.'…</nowiki>'); 
			#print "\t". $error_code."\t".$title."\t".$found_text."\n";
		}
	}
}


sub error_051_interwiki_before_last_headline{
	my $error_code = 51;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Interwiki before last headline';
		$error_description[$error_code][2] = 'The article had in the text a interwiki before the last headline. Interwikis should written at the end of the article.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $number_of_headlines = @headlines;
		my $pos = -1;
		#print 'number_of_headlines: '.$number_of_headlines.' '.$title."\n";

		if ($number_of_headlines > 0) {
			#print 'number_of_headlines: '.$number_of_headlines.' '.$title."\n";
			$pos = index($text, $headlines[$number_of_headlines-1]); #pos of last headline
			#print 'pos: '. $pos."\n";
		}
		if ( $pos > -1
			and ($page_namespace == 0 or $page_namespace == 104 )) {
			
			my $found_text = '';
			for (my $i = 0; $i <= $interwiki_counter; $i++ ) {
				
				if ($pos > $interwiki[$i][0]) {
					#print $pos .' and '.$interwiki[$i][0]."\n";
					$found_text = $interwiki[$i][4];
				}
			}

			if ( $found_text ne '' )
				{
				#$found_text = text_reduce($found_text, 50);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print 'Error 51: '.$title.' '.$found_text."\n";
			}
		}
	}
}

sub error_052_category_before_last_headline{
	my $error_code = 52;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Category before last headline';
		$error_description[$error_code][2] = 'The article had in the text a category before the last headline. Category should written at the end of the article before the interwikis.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $number_of_headlines = @headlines;
		my $pos = -1;
		#print 'number_of_headlines: '.$number_of_headlines.' '.$title."\n";

		if ($number_of_headlines > 0) {
			#print 'number_of_headlines: '.$number_of_headlines.' '.$title."\n";
			$pos = index($text, $headlines[$number_of_headlines-1]); #pos of last headline
			#print 'pos: '. $pos."\n";
		}
		if ( $pos > -1
			and ($page_namespace == 0 or $page_namespace == 104 )) {
			
			my $found_text = '';
			for (my $i = 0; $i <= $category_counter; $i++ ) {
				if ($pos > $category[$i][0]) {
					$found_text = $category[$i][4];
				}
			}

			if ( $found_text ne '' )
				{
				#$found_text = text_reduce($found_text, 50);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print 'Error 52: '.$title.' '.$found_text."\n";
			}
		}
	}
}

sub error_053_interwiki_before_category{
	my $error_code = 53;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Interwiki before last category';
		$error_description[$error_code][2] = 'The article had in the text a interwiki before the last category. Interwikis should written at the end of the article after the categories.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if (    $category_counter > -1
			and $interwiki_counter > -1
			and ($page_namespace == 0 or $page_namespace == 104)) {

			my $pos_interwiki = $interwiki[0][0];
			my $found_text = $interwiki[0][4];
			for (my $i = 0; $i <= $interwiki_counter; $i++ ) {
				if ( $interwiki[$i][0] < $pos_interwiki) {
					$pos_interwiki = $interwiki[$i][0];
					$found_text = $interwiki[$i][4];
				}
			}
			
			my $found = 'false';
			for (my $i = 0; $i <= $category_counter; $i++ ) {
				#print $pos_interwiki .' and '.$category[$i][0]."\n";
				$found = 'true' if ($pos_interwiki < $category[$i][0]);
			}
			if ($found eq 'true') {		
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}		

		}
	}
}

sub error_054_break_in_list{
	my $error_code = 54;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Break in list';
		$error_description[$error_code][2] = 'The article had a list, where one line had a break (<nowiki><br /></nowiki>) at the and of the line. This break can be deleted.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@lines) {
				my $current_line = $_;
				my $current_line_lc = lc($current_line);
				#print $current_line_lc."END\n";
				if (substr ($current_line,0,1) eq '*'
					and index($current_line_lc, 'br') > -1) {
					#print 'Line is list'."\n";
					if ($current_line_lc =~ /<([ ]+)?(\/|\\)?([ ]+)?br([ ]+)?(\/|\\)?([ ]+)?>([ ]+)?$/) {
						$found_text = $current_line;
						#print "\t".'Found:'."\t".$current_line_lc."\n";
					}
				}
			}
			
			if ($found_text ne '') {
				if (length($found_text) > 65) {
					$found_text = substr($found_text,0,30).' … '. substr($found_text, length($found_text) - 30);
				}
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}		
		}
	}
}


sub error_055_html_text_style_elements_small_double{
	my $error_code = 55;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><small></nowiki> double';
		$error_description[$error_code][2] = 'Article contains the tag <nowiki><small></nowiki>. '." In the most case we don't need this double tag.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test_line = '';
		my $test_text = lc($text);
		
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			#print 'a'."\n";
			my $test_text = lc($text);
			my $pos = -1 ;
			#print $test_text."\n";
			if ( index($test_text, '<small>') > -1) {
				#print 'b'."\n";
				$pos = index( $test_text, '<small><small>')     if ($pos == -1 );
				$pos = index( $test_text, '<small> <small>')    if ($pos == -1 );
				$pos = index( $test_text, '<small>  <small>')   if ($pos == -1 );
				$pos = index( $test_text, '</small></small>')   if ($pos == -1 );
				$pos = index( $test_text, '</small> </small>')  if ($pos == -1 );
				$pos = index( $test_text, '</small>  </small>') if ($pos == -1 );
				if ($pos > -1 ) {
					#print 'c'."\n";
					my $found_text_1 = text_reduce_to_end(substr($text, 0, $pos), 40);	# text before
					my $found_text_2 = text_reduce(substr($text, $pos), 30);				#text after
					my $found_text = $found_text_1. $found_text_2;
					$found_text =~ s/\n//g;
					$found_text = text_reduce($found_text, 80);
					error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
					#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
				}
			}
		}
	}
}

sub error_056_arrow_as_ASCII_art{
	my $error_code = 56;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Arrow as ASCII art';
		$error_description[$error_code][2] = 'The article had an arrow like "<nowiki><--</nowiki>" or "<nowiki>--></nowiki>" or "<nowiki><==</nowiki>" or "<nowiki>==></nowiki>". Write better this arrow with the Unicode "←" or "→" or "⇐" or "⇒". See [[:en:Arrow (symbol)]]. If it is sourcecode then use <nowiki><source> or <code></nowiki>. Also you can use <nowiki><math></nowiki> for mathematical formula.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $pos = -1;
			$pos = index (lc($text), '->');
			$pos = index (lc($text), '<-') if $pos == -1;
			$pos = index (lc($text), '<=') if $pos == -1;
			$pos = index (lc($text), '=>') if $pos == -1;
		
			if ($pos > -1 ){
				my $test_text = substr ($text, $pos-10, 100);
				$test_text =~ s/\n//g;
				$test_text = text_reduce($test_text, 50);
				error_register($error_code, '<nowiki>…'.$test_text.'…</nowiki>'); 
				#print 'Error '.$error_code.': '.$title.' '.$test_text."\n";
			}
		}
	}
}



sub error_057_headline_end_with_colon{
	my $error_code = 57; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Headlines end with colon';
		$error_description[$error_code][2] = 'One headline in this article end with a colon <nowiki>"== Headline : =="</nowiki>. This colon can be deleted.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {	
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			foreach (@headlines) {
				my $current_line = $_;
				#print $current_line."\n";
				if ( $current_line =~ /:[ ]?[ ]?[ ]?[=]+([ ]+)?$/) {
					$current_line = text_reduce($current_line, 80);
					error_register($error_code, '<nowiki>'.$current_line.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".$current_line."\n";
					
				}		
			}
		}
	}	
}

sub error_058_headline_with_capitalization{
	my $error_code = 58; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Headlines with capitalization';
		$error_description[$error_code][2] = 'One headline in this article has only capitalization <nowiki>"== HEADLINE IS BIG =="</nowiki>. Also this headline has more then 10 letters, so a normal abbreviation like <nowiki>"== UNO =="</nowiki> is not a problem.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
	
		my $found_text = '';
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			foreach (@headlines) {
				my $current_line = $_;
				my $current_line_normal = $current_line;

				$current_line_normal =~ s/[^A-Za-z,\/&]//g;		# only english characters and comma
				
				my $current_line_uc	    = uc($current_line_normal);
				if (length($current_line_normal) > 10) {
					#print "A:\t".$current_line_normal."\n";
					#print "B:\t".$current_line_uc."\n";
					if ( $current_line_normal eq $current_line_uc ) {
						# found ALL CAPS HEADLINE(S)
						#print "A:\t".$current_line_normal."\n"; 
						my $check_ok = 'yes';
						# check comma
						if (index( $current_line_normal ,',') > -1 ) {
							my @comma_split = split ( ',' , $current_line_normal);
							foreach (@comma_split) {
								if ( length($_) < 10 ) {
									$check_ok = 'no';
									#print $_."\n";
								}
							}
						}
						#print "\t".$check_ok."\n";
						
						# problem
						# ===== PPM, PGM, PBM, PNM =====
						# 	== RB-29J ( RB-29, FB-29J, F-13, F-13A) ==
						#  == GP40PH-2, GP40PH-2A, GP40PH-2B ==
						# ===20XE, 20XEJ, [[C20XE]], [[C20LET]]===
						
						if ($check_ok eq 'yes') {
							$found_text = $current_line;
						}
					}
				}
			}
			if ($found_text ne ''
				and index ($found_text, 'SSDSDSSWEMUGABRTLAD') == -1 		# de:TV total
				) {
				$found_text = text_reduce($found_text, 80);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";		
			}
		}
	}
}

sub error_059_template_value_end_with_br{
	my $error_code = 59; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Template value end with break';
		$error_description[$error_code][2] = 'At the end of a value in a template is a break. (For example: <nowiki>{{Template|name=Mr. King<br/>}}</nowiki>) This break should inside the template not in the value and you can delete this break. ';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $found_text = '';
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			for (my $i = 0; $i <=$number_of_template_parts; $i++) {
				#print $template[$i][3]."\t".$template[$i][4]."\n";
				if ( $found_text eq '') {
					if ($template[$i][4] =~ /<([ ]+)?(\/|\\)?([ ]+)?br([ ]+)?(\/|\\)?([ ]+)?>([ ])?([ ])?$/) {
						$found_text = $template[$i][3].'=…'.text_reduce_to_end($template[$i][4], 20);
					}
				}
			}
			if ($found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}

sub error_060_template_parameter_with_problem{
	my $error_code = 60; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Template parameter with problem';
		$error_description[$error_code][2] = 'In the parameter of a template the script found an unusual letter (<nowiki>[|]:*</nowiki>) For example: <nowiki>{{Template| parameter_1=100 | [[parameter]]_2=200 }}</nowiki>).';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $found_text = '';
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			for (my $i = 0; $i <=$number_of_template_parts; $i++) {
				#print $template[$i][3]."\t".$template[$i][4]."\n";
				if ( $found_text eq '') {
					if ($template[$i][3] =~ /(\[|\]|\|:|\*)/) {
						$found_text = $template[$i][1].', '. $template[$i][3];
					}
				}
			}
			if ($found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}

sub error_061_reference_with_punctuation{
	my $error_code = 61; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Reference with punctuation';
		$error_description[$error_code][2] = 'The script found a punctuation after the reference. For example: "<nowiki></ref>.</nowiki>" - The punctation should stand before the references.';
 	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $found_text = '';
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $pos = -1;
			$pos = index( $text, '</ref>.') if ($pos == -1);	
			$pos = index( $text, '</ref> .') if ($pos == -1);
			$pos = index( $text, '</ref>  .') if ($pos == -1);
			$pos = index( $text, '</ref>   .') if ($pos == -1);
			$pos = index( $text, '</ref>!') if ($pos == -1);
			$pos = index( $text, '</ref> !') if ($pos == -1);
			$pos = index( $text, '</ref>  !') if ($pos == -1);
			$pos = index( $text, '</ref>   !') if ($pos == -1);
			$pos = index( $text, '</ref>?') if ($pos == -1);
			$pos = index( $text, '</ref> ?') if ($pos == -1);
			$pos = index( $text, '</ref>  ?') if ($pos == -1);
			$pos = index( $text, '</ref>   ?') if ($pos == -1);		
			
			if ($pos > -1) {
				my $found_text = substr ( $text , $pos);
				$found_text = text_reduce($found_text, 50);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}


sub error_062_headline_alone {
	my $error_code = 62; 
	my $attribut = $_[0];	
	my $comment  = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {	
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Headline alone';
		$error_description[$error_code][2] = "There are more then 5 headlines and one headline of level 3 (===) or deeper is alone. The script don't found an other headline of this level in this subsection. If you have only one subpoint, integrate it with the point above or reorganize.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ){
			
			my $number_of_headlines = @headlines;
			my $old_level = 2;
			my $found_text = '';
			if ($number_of_headlines >= 5) {
				for (my $i = 0; $i < $number_of_headlines; $i ++) {
					#print $headlines[$i]."\n";
					my $headline_test_1 = $headlines[$i];
					my $headline_test_2 = $headlines[$i];
					$headline_test_1 =~ s/^([=]+)//;
					my $current_level = length($headline_test_2) - length($headline_test_1);
					
					if ($current_level > 2
						and $old_level < $current_level
						and $i < $number_of_headlines -1
						and $found_text eq '') {
						# first headline in this level
						#print 'check: '.$headlines[$i]."\n";
						my $found_same_level = 'no';
						my $found_end = 'no';
						for (my $j = $i+1; $j < $number_of_headlines; $j ++) {
							# check all headlinds behind
							my $headline_test_1b = $headlines[$j];
							my $headline_test_2b = $headlines[$j];
							$headline_test_1b =~ s/^([=]+)//;
							my $test_level = length($headline_test_2b) - length($headline_test_1b);
							#print 'check: '.$headlines[$i]."\n";
							if ($test_level < $current_level) {
								$found_end = 'yes'; 
								#print 'Found end'.$headlines[$j]."\n";
							}
							
							if ($test_level = $current_level
								and $found_end eq 'no') {
								$found_same_level = 'yes'; 
								#print 'Found end'.$headlines[$j]."\n";
							}
						}
						
						if ( $found_text eq ''
							and $found_same_level eq 'no') {				
							# found alone text
							$found_text = $headlines[$i];
							
						}
						
					}
					
					if ($current_level > 2
						and $old_level < $current_level
						and $i == $number_of_headlines -1
						and $found_text eq '') {
						#found a last headline stand alone 
						$found_text = $headlines[$i];
					}
					$old_level = $current_level;
				}
			}
			if ( $found_text ne ''  ){
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

sub error_063_html_text_style_elements_small_ref_sub_sup{
	my $error_code = 63; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'HTML text style element <nowiki><small></nowiki> in ref, sub or sup';
		$error_description[$error_code][2] = 'Article contains the tag <nowiki><small></nowiki> in a <nowiki><ref></nowiki> or <nowiki><sub></nowiki> or <nowiki><sub></nowiki> tag. '." Inside inside this tags we don't need a small text because the tag output is smaller then the standard.";
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $test_line = '';
		my $test_text = lc($text);
		
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			#print 'a'."\n";
			my $test_text = lc($text);
			my $pos = -1 ;
			#print $test_text."\n";
			if ( index($test_text, '</small>') > -1) {
				#print 'b'."\n";
				$pos = index( $test_text, '</small></ref>')     if ($pos == -1 );
				$pos = index( $test_text, '</small> </ref>')    if ($pos == -1 );
				$pos = index( $test_text, '</small>  </ref>')   if ($pos == -1 );
				$pos = index( $test_text, '</small></sub>')     if ($pos == -1 );
				$pos = index( $test_text, '</small> </sub>')    if ($pos == -1 );
				$pos = index( $test_text, '</small>  </sub>')   if ($pos == -1 );
				$pos = index( $test_text, '</small></sup>')     if ($pos == -1 );
				$pos = index( $test_text, '</small> </sup>')    if ($pos == -1 );
				$pos = index( $test_text, '</small>  </sup>')   if ($pos == -1 );
				if ($pos > -1 ) {
					#print 'pos:'.$pos."\n";
					my $found_text_1 = text_reduce_to_end(substr($text, 0, $pos), 40);	# text before
					my $found_text_2 = text_reduce(substr($text, $pos), 30);				#text after
					#print 'f1:'."\t".$found_text_1."\n\n";
					#print 'f2:'."\t".$found_text_2."\n\n";
					
					my $found_text = $found_text_1. $found_text_2;
					$found_text =~ s/\n//g;
					#print $found_text."\n";
					$found_text = text_reduce($found_text, 80);
					error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
					#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
				}
			}
		}
	}
}


sub error_064_link_equal_linktext{
	my $error_code = 64; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Link equal to linktext';
		$error_description[$error_code][2] = 'The script found a structur like <nowiki>[[Link|Link]]</nowiki> in this article.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
	
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@links_all) {
				# check all links
				if ($found_text eq '') {
					# if nothing found
					my $current_link = $_ ;
					if (index ($current_link, '|') > -1 ) {
						# only [[Link|Linktext]]
						#print "\t".$current_link."\n";
						my $test_link = $current_link;
						$test_link =~ s/\[\[//;
						$test_link =~ s/\]\]//;
						
						if ( length($test_link) <2						#  link like [[|]]
							){						
							$found_text = $current_link;
						} else {
							#print '1:'.$test_link."\n";
							if ( substr( $test_link, length($test_link) -1 ,1 ) ne '|'		#  link like [[link|]]
								and index( $test_link, '||') == -1							# link like [ link||linktest]]
								and index( $test_link, '|') != 0							# link [[|linktext]]
								) {
								my @split_link = split ( /\|/ , $test_link);
								#print "\t".'0:'."\t".$split_link[0]."\n";
								#print "\t".'1:'."\t".$split_link[1]."\n";
								#print '2:'.$test_link."\n";
								if ($split_link[0] eq $split_link[1]) {
									# [[link|link]]
									#print "\t".$current_link."\n";
									$found_text = $current_link;
								}
							}
						}
					}
				} 
			}
			if ( $found_text ne '' ) {
				$found_text = text_reduce($found_text, 80);
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}


sub error_065_image_description_with_break{
	my $error_code = 65; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Image description with break';
		$error_description[$error_code][2] = 'The script found in this article at the end of an image description the tag <nowiki><br /></nowiki>. You can delete this manual break.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@images_all) {
				my $current_image = $_;
				if ( $found_text eq '') {
					#print $current_image."\n";
					if ($current_image =~ /<([ ]+)?(\/|\\)?([ ]+)?br([ ]+)?(\/|\\)?([ ]+)?>([ ])?(\||\])/i ) {
						$found_text = $current_image;
					}
				}
			}
			if ($found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";			
			}
		}
	}
}

sub error_066_image_description_with_full_small{
	my $error_code = 66;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Image description with full <nowiki><small></nowiki>.';
		$error_description[$error_code][2] = 'The script found in the description of an image the <nowiki><small></nowiki>. The description is already set to 94% in the stylesheet. This tag can be deleted.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@images_all) {
				my $current_image = $_;
				if ( $found_text eq '') {
					#print $current_image."\n";
					if ($current_image =~ /<([ ]+)?(\/|\\)?([ ]+)?small([ ]+)?(\/|\\)?([ ]+)?>([ ])?(\||\])/i 
						and $current_image =~ /\|([ ]+)?<([ ]+)?small/ ) {
						$found_text = $current_image;
					}
				}
			}
			if ($found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";			
			}
		}
	}
}

sub error_067_reference_after_punctuation{
	my $error_code = 67; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 0;
		$error_description[$error_code][1] = 'Reference after punctuation';
		$error_description[$error_code][2] = 'The script found the reference after a punctuation. For example: "<nowiki>.<ref></nowiki>" - The punctation should stand after the references.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		my $found_text = '';
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $pos = -1;
			$pos = index( $text, '.<ref') if ($pos == -1);	
			$pos = index( $text, '. <ref') if ($pos == -1);
			$pos = index( $text, '.  <ref') if ($pos == -1);
			$pos = index( $text, '.   <ref') if ($pos == -1);
			$pos = index( $text, '!<ref') if ($pos == -1);	
			$pos = index( $text, '! <ref') if ($pos == -1);
			$pos = index( $text, '!  <ref') if ($pos == -1);
			$pos = index( $text, '!   <ref') if ($pos == -1);
			$pos = index( $text, '?<ref') if ($pos == -1);	
			$pos = index( $text, '? <ref') if ($pos == -1);
			$pos = index( $text, '?  <ref') if ($pos == -1);
			$pos = index( $text, '?   <ref') if ($pos == -1);	
			
			if ($pos > -1) {
				my $found_text = substr ( $text , $pos);
				$found_text = text_reduce($found_text, 50);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}


sub error_068_link_to_other_language{
	my $error_code = 68;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Link to other language';
		$error_description[$error_code][2] = 'The script found a link to another language, for example <nowiki>[[:is:Link]]</nowiki> in this article (not an interwiki-link). In many languages is a direct link inside the article not allowed (for example in plwiki).';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@links_all) {
				# check all links
				if ($found_text eq '') {
					my $current_link = $_;
					foreach (@inter_list) {
						my $current_lang = $_;
						if ($current_link =~ /^\[\[([ ]+)?:([ ]+)?$current_lang:/i) {
							$found_text = $current_link;
						}
					}
				} 
			}
			if ( $found_text ne '' ) {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

sub error_069_isbn_wrong_syntax{
	my $error_code = 69;
	my $attribut = $_[0];
	my $found_text = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'ISBN wrong syntax';
		$error_description[$error_code][2] = 'The script check the ISBN and found a problem with the syntax. A normal ISBN look like ISBN 3-8001-6191-5 or ISBN 0-911266-16-X or ISBN 978-0911266160. Allowed are numbers, space, "-" and "X"/"x". Without space and "-" only 10 or 13 characters. Please don'."'".'t write ISBN-10: or ISBN-13.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104) 
			and $found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
		}
	}
}

sub error_070_isbn_wrong_length{
	my $error_code = 70; 
	my $attribut = $_[0];	
	my $found_text = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'ISBN wrong length';
		$error_description[$error_code][2] = 'The script check the ISBN and found with not 10 or 13 characters. ISBN should have 10 or 13 characters.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104 )
			and $found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
		}
	}
}

sub error_071_isbn_wrong_pos_X{
	my $error_code = 71;
	my $attribut = $_[0];	
	my $found_text = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'ISBN wrong position of X';
		$error_description[$error_code][2] = 'The script check the ISBN and found a ISBN where the character "X" are not at position 10. The character X is only at position 10 allowed. It is for the checksum of 10.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {

		if ( ($page_namespace == 0 or $page_namespace == 104 )
			and $found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
		}
	}
}

sub error_072_isbn_10_wrong_checksum{
	my $error_code = 72; 
	my $attribut = $_[0];	
	my $found_text = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'ISBN wrong checksum in ISBN-10';
		$error_description[$error_code][2] = 'The script check the ISBN and found a problem with the checksum in this ISBN-10.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104)
			and $found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
		}
	}
}

sub error_073_isbn_13_wrong_checksum{
	my $error_code = 73;
	my $attribut = $_[0];	
	my $found_text = $_[1];
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'ISBN wrong checksum in ISBN-13';
		$error_description[$error_code][2] = 'The script check the ISBN and found a problem with the checksum in this ISBN-13.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104)
			and $found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
		}
	}
}

sub error_074_link_with_no_target{
	my $error_code = 74;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Link with no target';
		$error_description[$error_code][2] = 'The script found a link with no target, for example <nowiki>[[|linktext]]</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@links_all) {
				# check all links
				if ($found_text eq '') {
					my $current_link = $_;
					if ( index ($current_link, '[[|') > -1) {
						$found_text = $current_link;
					}
				} 
			}
			if ( $found_text ne '' ) {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

sub error_075_indented_list{
	my $error_code = 75; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Indented list';
		$error_description[$error_code][2] = 'The article had a list, where one line is indent (<nowiki>:* text</nowiki>). A list don'."'".'t need an intend with ":". Use more "*" to indent the list. ';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@lines) {
				my $current_line = $_;
				if (   substr ($current_line, 0, 2) eq ':*'
					or substr ($current_line, 0, 2) eq ':-'
					or substr ($current_line, 0, 2) eq ':#'
					or substr ($current_line, 0, 2) eq ':·'
					) {
					$found_text = $current_line if ($found_text eq '');
					#print "\t".'Found:'."\t".$current_line_lc."\n";
				}
			}
			
			if ($found_text ne '') {
				$found_text = text_reduce($found_text, 50);
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}		
		}
	}
}


sub error_076_link_with_no_space{
	my $error_code = 76;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Link with no space';
		$error_description[$error_code][2] = 'The script found a link with "%20" for space <nowiki>[[Link%20Link|Linktext]]</nowiki>. Please replace this %20 with a space.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@links_all) {
				# check all links
				if ($found_text eq '') {
					my $current_link = $_;
					if ($current_link =~ /^\[\[([^\|]+)%20([^\|]+)/i) {
						$found_text = $current_link;
					}
				} 
			}
			if ( $found_text ne '' ) {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

sub error_077_image_description_with_partial_small{
	my $error_code = 77;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Image description with partial <nowiki><small></nowiki>';
		$error_description[$error_code][2] = 'The script found in the description of an image the <nowiki><small></nowiki>. The description is already set to 94% in the stylesheet. This tag can be deleted.';
 	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@images_all) {
				my $current_image = $_;
				if ( $found_text eq '') {
					#print $current_image."\n";
					if ($current_image =~ /<([ ]+)?(\/|\\)?([ ]+)?small([ ]+)?(\/|\\)?([ ]+)?>([ ])?/i 
						and not $current_image =~ /\|([ ]+)?<([ ]+)?small/ ) {
						$found_text = $current_image;
					}
				}
			}
			if ($found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";			
			}
		}
	}
}

sub error_078_reference_double{
	my $error_code = 78;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Reference double';
		$error_description[$error_code][2] = 'The script found in the article two <nowiki><references ...></nowiki>. One can be deleted.';
 	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0 or $page_namespace == 104 ) {
			my $test_text = lc($text);
			my $number_of_refs = 0;
			my $pos_first  = -1;
			my $pos_second = -1;
			while($test_text =~ /<references[ ]?\/>/g) {
				my $pos = pos($test_text); 
				#print $number_of_refs." ".$pos."\n";
				$number_of_refs ++;
				$pos_first  = $pos if ($pos_first  == -1 and $number_of_refs == 1);
				$pos_second = $pos if ($pos_second == -1 and $number_of_refs == 2);
			}
			#my $pos  = index($test_text, '<references');
			#my $pos2 = index($test_text, '<references', $pos+1);
			if ( $number_of_refs > 1) {
				$test_text = $text;
				$test_text =~ s/\n/ /g;
				my $found_text = substr ($test_text, 0, $pos_first);
				$found_text = text_reduce_to_end($found_text, 50);
				my $found_text2 = substr ($test_text, 0, $pos_second);
				$found_text2 = text_reduce_to_end($found_text2, 50);
				$found_text = $found_text."</nowiki><br /><nowiki>".$found_text2;
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";			
			}
		}
	}
}


sub error_079_external_link_without_description{
	my $error_code = 79; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'External link without description';
		$error_description[$error_code][2] = 'The script found in the article an external link without description (for example: <nowiki>[http://www.wikipedia.org]</nowiki>). Please insert a description to this link like <nowiki>[http://www.wikipedia.org Wikipedia]</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0 or $page_namespace == 104 ) {
			my $test_text = lc($text);
			
			my $pos = -1;
			my $found_text = '';
			while (    index ($test_text, '[http://', $pos +1) > -1
					or index ($test_text, '[ftp://',  $pos +1) > -1 
					or index ($test_text, '[https://', $pos +1) > -1
				){
				my $pos1 = index ($test_text, '[http://', $pos +1 );
				my $pos2 = index ($test_text, '[ftp://' , $pos +1);
				my $pos3 = index ($test_text, '[https://', $pos +1);
				
				#print 'pos1: '. $pos1."\n";
				#print 'pos2: '. $pos2."\n";
				#print 'pos3: '. $pos3."\n";
				
				my $next_pos = -1;
				$next_pos = $pos1 if ( $pos1 > -1 );
				$next_pos = $pos2 if ( ($next_pos == -1 and $pos2 > -1) or ($pos2 > -1 and  $next_pos > $pos2) );
				$next_pos = $pos3 if ( ($next_pos == -1 and $pos3 > -1) or ( $pos3 > -1 and $next_pos > $pos3) );
				#print 'next_pos '.$next_pos."\n";
				my $pos_end =  index ($test_text, ']', $next_pos );
				#print 'pos_end '.$pos_end."\n";
				my $weblink =  substr( $text, $next_pos, $pos_end - $next_pos + 1 );
				#print $weblink."\n";
			
				if (index ($weblink, ' ') == -1) {
					$found_text = $weblink if ($found_text eq '');
				}
				$pos = $next_pos ;
			}

			if ( $found_text ne '' ) {
				$found_text   = text_reduce($found_text, 80);
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";			
			}
		}
	}
}

sub error_080_external_link_with_line_break{
	my $error_code = 80;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'External link with line break';
		$error_description[$error_code][2] = 'The script found in the article an external link with a line break in the description. This is a problem for the mediawiki parser. Please delete the line break.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0 or $page_namespace == 104 ) {
			my $test_text = lc($text);
			
			my $pos = -1;
			my $found_text = '';
			while (    index ($test_text, '[http://', $pos +1) > -1
					or index ($test_text, '[ftp://',  $pos +1) > -1 
					or index ($test_text, '[https://', $pos +1) > -1
				){
				my $pos1 = index ($test_text, '[http://', $pos +1 );
				my $pos2 = index ($test_text, '[ftp://' , $pos +1);
				my $pos3 = index ($test_text, '[https://', $pos +1);
				
				my $next_pos = -1;
				$next_pos = $pos1 if ( $pos1 > -1 );
				$next_pos = $pos2 if ( ($next_pos == -1 and $pos2 > -1) or ($pos2 > -1 and  $next_pos > $pos2) );
				$next_pos = $pos3 if ( ($next_pos == -1 and $pos3 > -1) or ( $pos3 > -1 and $next_pos > $pos3) );
				#print 'next_pos '.$next_pos."\n";
				my $pos_end =  index ($test_text, ']', $next_pos );
				#print 'pos_end '.$pos_end."\n";
				my $weblink =  substr( $text, $next_pos, $pos_end - $next_pos + 1 );
				#print $weblink."\n";
			
				if ( $weblink =~ /\n/ ) {
					$found_text = $weblink if ($found_text eq '');
				}
				$pos = $next_pos;
			}

			if ( $found_text ne '' ) {
				$found_text   = text_reduce($found_text, 80);
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";			
			}
		}
	}
}


sub error_081_ref_double{
	my $error_code = 81; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Reference tag in article double';
		$error_description[$error_code][2] = 'The script found in the article a double ref-tag. Please use the format <nowiki><ref name="foo">Book ABC</ref></nowiki> and the following times <nowiki><ref name="foo" /></nowiki>';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0 or $page_namespace == 104 ) {
			my $number_of_ref = @ref;
			my $found_text = '';
			for (my $i = 0; $i < $number_of_ref -1 ; $i++) {
				#print $i ."\t".$ref[$i]."\n";
				for (my $j = $i+1; $j < $number_of_ref  ; $j++) {
					#print $i." ".$j."\n";
					if ($ref[$i] eq $ref[$j]
						and $found_text eq '' ) {
						#found a double ref
						$found_text = $ref[$i] ;
						#print 'found'."\n";
					}
				}
			}
			if ($found_text ne '') {
				#$found_text   = text_reduce($found_text, 80);
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";	
			}
		}
	}
}

sub error_082_link_to_other_wikiproject{
	my $error_code = 82;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Link to other wikiproject';
		$error_description[$error_code][2] = 'The script found a link to another wikimedia foundation project, for example <nowiki>[[:wikt:Link]]</nowiki> in this article (not an interwiki-link) (See [[:en:Wikipedia:InterWikimedia links]]. In many languages is a direct link inside the article not allowed.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@links_all) {
				# check all links
				if ($found_text eq '') {
					my $current_link = $_;
					foreach (@foundation_projects) {
						my $current_project = $_;
						if (   $current_link =~ /^\[\[([ ]+)?$current_project:/i
							or $current_link =~ /^\[\[([ ]+)?:([ ]+)?$current_project:/i) {
							$found_text = $current_link;
						}
					}
				} 
			}
			if ( $found_text ne '' ) {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

sub error_083_headline_only_three_and_later_level_two{
	my $error_code = 83;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Headlines start with three "=" and later with level two';
		$error_description[$error_code][2] = 'The first headline start with <nowiki>"=== XY ==="</nowiki>. It should only be <nowiki>"== XY =="</nowiki>. Later in the text the script found a level 2 headline (<nowiki>"=="</nowiki>). See also error 007!';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $headlines[0] 
			and ($page_namespace == 0 or $page_namespace == 104 )){
			if (  $headlines[0] =~ /===/ 
				 ){
				 
				my $found_level_two = 'no';
				foreach (@headlines) {
					if ($_ =~ /^==[^=]/) {
						$found_level_two = 'yes'; #found level two (error 83)
					}
				}
				if ($found_level_two eq 'yes') {
					error_register($error_code, '<nowiki>'.$headlines[0].'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$headlines[0].'</nowiki>'."\n";
				}
			}
		}
	}
}

sub error_084_section_without_text{
	my $error_code = 84;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 1;
		$error_description[$error_code][1] = 'Section without content';
		$error_description[$error_code][2] = 'There is a section between two headlines without content.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $headlines[0] 
			and ($page_namespace == 0 or $page_namespace == 104) ){
			# this article has headlines
			
			my $number_of_headlines = @headlines;
			my $found_text = '';
			
			for (my $i = 0; $i < $number_of_headlines-1 ; $i++ ) {
				# check level of headline and behind headline
				my $level_one = $headlines[$i];
				my $level_two = $headlines[$i+1];
				
				$level_one =~ s/^([=]+)//;
				$level_two =~ s/^([=]+)//;
				$level_one = length($headlines[$i])   - length($level_one);
				$level_two = length($headlines[$i+1]) - length($level_two);
					

				if ($level_one == $level_two or $level_one > $level_two) {
					# check section if level identical or lower
					#print LOGFILE $i   ."=".$level_one." ".$headlines[$i]."\n";
					#print LOGFILE $i+1 ."=".$level_two." ".$headlines[$i+1]."\n";
					#print LOGFILE 'Section i+1:BEGIN'."\n". $section[$i+1]."END\n";
					if ($section[$i]) {
						#print LOGFILE 'Section is ok'."\n";
						my $test_section   = $section[$i+1];
						my $test_section_2 = $section[$i+1];
						my $test_headline  = $headlines[$i];
						$test_headline =~ s/\n//g;
						#print LOGFILE 'X'.$test_headline.'X'."\n";
						#print LOGFILE length($test_section).' - '.length($test_section_2).' - '.length($test_headline)."\n";
						#print LOGFILE $section[$i+1]."\n";
						
						$test_section = substr ($test_section, length($test_headline)) if ($test_section);
						if ($test_section) {
							
							$test_section =~ s/[ ]//g;
							$test_section =~ s/\n//g;
							$test_section =~ s/\t//g;
						
							if ($test_section eq '' ) {
								#print LOGFILE "\t test ".$test_headline."\n";
								#print LOGFILE index( $text_without_comments, $test_section_2 )."\n";
								#print "\t x".$test_section_2."x\n";
								if (index( $text_without_comments, $test_section_2 )>-1 ) {
									#print $text_without_comments."\n";
									$found_text = $test_headline if ($found_text eq '');
								}
							}
						}
					}
					#print LOGFILE "\n\n";	
				}
			}
			
			if ($found_text ne '') {
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print LOGFILE "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
				
			}		
		}
	}
}

sub error_085_tag_without_content{
	my $error_code = 85;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'Tag without content';
		$error_description[$error_code][2] = 'The script found a tag without content or a line break like <nowiki><noinclude></noinclude></nowiki>. This tag can be deleted.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ){
			my $found_text = '';
			my $found_pos = -1;
			
			$found_pos = index ($text, '<noinclude></noinclude>') 				if (index ($text, '<noinclude></noinclude>') > -1) ;
			$found_pos = index ($text, '<onlyinclude></onlyinclude>') 			if (index ($text, '<onlyinclude></onlyinclude>') > -1) ;
			$found_pos = index ($text, '<includeonly></includeonly>') 			if (index ($text, '<includeonly></includeonly>') > -1) ;
			$found_pos = index ($text, '<noinclude>'."\n".'</noinclude>') 		if (index ($text, '<noinclude>'."\n".'</noinclude>') > -1) ;
			$found_pos = index ($text, '<onlyinclude>'."\n".'</onlyinclude>') 	if (index ($text, '<onlyinclude>'."\n".'</onlyinclude>') > -1) ;
			$found_pos = index ($text, '<includeonly>'."\n".'</includeonly>') 	if (index ($text, '<includeonly>'."\n".'</includeonly>') > -1) ;

			if ($found_pos != -1) {
				$found_text = substr ($text, $found_pos);
				$found_text = text_reduce($found_text, 80);
				$found_text =~ s/\n//g;
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}		
		}
	}
}

sub error_086_link_with_two_brackets_to_external_source{
	my $error_code = 86;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Link with two brackets to external source';
		$error_description[$error_code][2] = 'The script found a link with two brackets to external source like <nowiki>[[http://www.wikipedia.org Wikipedia]]</nowiki>. External links only need one bracket like <nowiki>[http://www.wikipedia.org Wikipedia]</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ) {
			my $found_text = '';
			foreach (@links_all) {
				# check all links
				if ($found_text eq '') {
					my $current_link = $_;
					if (   $current_link =~ /^\[\[([ ]+)?http:\/\//
						or $current_link =~ /^\[\[([ ]+)?ftp:\/\//
						or $current_link =~ /^\[\[([ ]+)?https:\/\//) {
							$found_text = $current_link;
					}
					
				} 
			}
			if ( $found_text ne '' ) {
				error_register($error_code, '<nowiki>'.$found_text.' </nowiki>');
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

sub error_087_html_names_entities_without_semicolon{
	my $error_code = 87;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = -1;
		$error_description[$error_code][1] = 'HTML named entities without semicolon';
		$error_description[$error_code][2] = 'Find named entities (like &amp;uml;) in the text without the semicolon.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ($page_namespace == 0  or $page_namespace == 6 or $page_namespace == 104 ) {
			my $pos = -1;
			my $test_text = lc($text);
			
			# see http://turner.faculty.swau.edu/webstuff/htmlsymbols.html
			while($test_text =~ /&sup2[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&sup3[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&auml[^;]/g) { $pos = pos($test_text) };			
			while($test_text =~ /&ouml[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&uuml[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&szlig[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&aring[^;]/g) { $pos = pos($test_text) };	
			while($test_text =~ /&hellip[^;]/g) { $pos = pos($test_text) };	# …
			#while($test_text =~ /&lt[^;]/g) { $pos = pos($test_text) };						# for example, &lt;em> produces <em> for use in examples
			#while($test_text =~ /&gt[^;]/g) { $pos = pos($test_text) };
			#while($test_text =~ /&amp[^;]/g) { $pos = pos($test_text) };	
			while($test_text =~ /&quot[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&minus[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&oline[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&cent[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&pound[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&euro[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&sect[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&dagger[^;]/g) { $pos = pos($test_text) };

			while($test_text =~ /&lsquo[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&rsquo[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&middot[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&bull[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&copy[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&reg[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&trade[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&iquest[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&iexcl[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&aelig[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&ccedil[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&ntilde[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&acirc[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&aacute[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&agrave[^;]/g) { $pos = pos($test_text) };
			
			#arrows 
			while($test_text =~ /&darr[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&uarr[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&crarr[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&rarr[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&larr[^;]/g) { $pos = pos($test_text) };
			while($test_text =~ /&harr[^;]/g) { $pos = pos($test_text) };
			
			if ($pos > -1) {
				my $found_text = substr ( $text , $pos - 10);
				$found_text = text_reduce($found_text, 50);

				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".$found_text."\n";
			}
		}
	}
}

sub error_088_defaultsort_with_first_blank{
	my $error_code = 88; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'DEFAULTSORT with blank at first position';
		$error_description[$error_code][2] = 'The script found a DEFAULTSORT with a blank at first position like <nowiki>{{DEFAULTSORT: Doe, John}}</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
	
		if ( ($page_namespace == 0 or $page_namespace == 104)
			and $project ne 'arwiki'
			and $project ne 'hewiki'
			and $project ne 'plwiki'
			and $project ne 'jawiki'
			and $project ne 'yiwiki'
			and $project ne 'zhwiki'
			) {
			my $pos1 = -1;
			my $current_magicword = '';
			foreach (@magicword_defaultsort) {
				if ($pos1 == -1 and index($text, $_) > -1 ) {
					$pos1 = index($text, $_);
					$current_magicword = $_ ;
				}
			}
			if ($pos1 > -1 ) {
				my $pos2 = index(substr($text,$pos1), '}}');
				my $testtext = substr($text, $pos1, $pos2);	
				#print $testtext."\n";
				my $sortkey = $testtext;
				$sortkey =~ s/^([ ]+)?$current_magicword//;
				$sortkey =~ s/^([ ]+)?://;
				#print '-'.$sortkey."-\n";
				
				
				if  ( index ($sortkey, ' ') == 0 ){
					my $found_text = $testtext;
					error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".$found_text."\n";
				}
			}
		}
	}
}

sub error_089_defaultsort_with_capitalization_in_the_middle_of_the_word{
	my $error_code = 89;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'DEFAULTSORT with capitalization in the middle of the word';
		$error_description[$error_code][2] = 'The script found a DEFAULTSORT with capitalization in the middle of the word like  <nowiki>{{DEFAULTSORT:DuBois, Lewis}} or {{DEFAULTSORT:SSX}}</nowiki>. The Mediawiki-software allowed not a capitalization in the word. Write "Dubois, Lewis" or "Ssx" for correct sorting in the category';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104)
			and $project ne 'arwiki'
			and $project ne 'hewiki'
			and $project ne 'plwiki'
			and $project ne 'jawiki'
			and $project ne 'yiwiki'
			and $project ne 'zhwiki'
			) {
			my $pos1 = -1;
			my $current_magicword = '';
			foreach (@magicword_defaultsort) {
				if ($pos1 == -1 and index($text, $_) > -1 ) {
					$pos1 = index($text, $_);
					$current_magicword = $_ ;
				}
			}
			if ($pos1 > -1 ) {
				my $pos2 = index(substr($text,$pos1), '}}');
				my $testtext = substr($text, $pos1, $pos2);	
				#print $testtext."\n";
				my $sortkey = $testtext;
				$sortkey =~ s/^([ ]+)?$current_magicword//;
				$sortkey =~ s/^([ ]+)?://;
				#print '-'.$sortkey."-\n";
				
				
				if  ( $sortkey =~ /[a-z][A-Z]/ ){
					my $found_text = $testtext;
					error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".$found_text."\n";
				}
			}
		}
	}
}

sub error_090_defaultsort_with_lowercase_letters{
	my $error_code = 90; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'DEFAULTSORT with lowercase letters';
		$error_description[$error_code][2] = 'The script found a DEFAULTSORT with lowercase letters like  <nowiki>{{DEFAULTSORT:Role-playing game}} or {{DEFAULTSORT:2004 in Film}}</nowiki>. The Mediawiki-software need for every word a capitalization of the first letter. Write "Role-Playing Game" or "2004 In Film" for correct sorting in the category';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104 )
			and $project ne 'arwiki'
			and $project ne 'hewiki'
			and $project ne 'plwiki'
			and $project ne 'jawiki'
			and $project ne 'yiwiki'
			and $project ne 'zhwiki'
			) {
			my $pos1 = -1;
			my $current_magicword = '';
			foreach (@magicword_defaultsort) {
				if ($pos1 == -1 and index($text, $_) > -1 ) {
					$pos1 = index($text, $_);
					$current_magicword = $_ ;
				}
			}
			if ($pos1 > -1 ) {
				my $pos2 = index(substr($text,$pos1), '}}');
				my $testtext = substr($text, $pos1, $pos2);	
				#print $testtext."\n";
				my $sortkey = $testtext;
				$sortkey =~ s/^([ ]+)?$current_magicword//;
				$sortkey =~ s/^([ ]+)?://;
				#print '-'.$sortkey."-\n";
				
				
				if  ( $sortkey =~ /[ -][a-z]/ ){
					my $found_text = $testtext;
					error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
					#print "\t". $error_code."\t".$title."\t".$found_text."\n";
				}
			}
		}
	}
}

sub error_091_title_with_lowercase_letters_and_no_defaultsort{
	my $error_code = 91;
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 3;
		$error_description[$error_code][1] = 'DEFAULTSORT is missing and title with lowercase_letters';
		$error_description[$error_code][2] = 'The script found no DEFAULTSORT and the title of the article has lowercase letters at the beginning of a word like "Role-playing game" or "2004 in Film". This article make problem with sorting in categories. Write a <nowiki>{{DEFAULTSORT:Role-Playing Game}} or {{DEFAULTSORT:2004 In Film}}</nowiki>.';
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( ($page_namespace == 0 or $page_namespace == 104 )
			and $category_counter > -1
			and $project ne 'arwiki'
			and $project ne 'hewiki'
			and $project ne 'plwiki'
			and $project ne 'jawiki'
			and $project ne 'yiwiki'
			and $project ne 'zhwiki'
			) {

			my $pos1 = -1;
			my $current_magicword = '';
			foreach (@magicword_defaultsort) {
				if ($pos1 == -1 and index($text, $_) > -1 ) {
					$pos1 = index($text, $_);
					$current_magicword = $_ ;
				}
			}
			if ($pos1 == -1 ) {
				# no defaultsort
				my $subtitle = $title;
				$subtitle = substr($subtitle, 0, 9) if (length($subtitle) > 10);
				if  ( $subtitle =~ /[ -][a-z]/ ){
					error_register($error_code, ''); 
					#print "\t". $error_code."\t".$title."\n";
				}
			}
		}
	}
}

sub error_092_headline_double {
	my $error_code = 92; 
	my $attribut = $_[0];	
	print $error_code."\n" if ($details_for_page eq 'yes');
	if ($attribut eq 'get_description') {
		$error_description[$error_code][0] = 2;
		$error_description[$error_code][1] = 'Headline double';
		$error_description[$error_code][2] = "There is a double headline (one behind the other) in this article. ";
		$error_description[$error_code][2] = infotext_new_error( $error_description[$error_code][2] );
	}
	if ($attribut eq 'check' and $error_description[$error_code][4] != 0 ) {
		if ( $page_namespace == 0 or $page_namespace == 104 ){
			my $found_text = '';
			my $number_of_headlines = @headlines;
			for (my $i = 0; $i < $number_of_headlines -1 ; $i ++) {
				my $first_headline = $headlines[$i];
				my $secound_headline = $headlines[$i+1];

				if ($first_headline eq $secound_headline) {
					$found_text = $headlines[$i];
				}
			}
			if ( $found_text ne ''  ){
				error_register($error_code, '<nowiki>'.$found_text.'</nowiki>'); 
				#print "\t". $error_code."\t".$title."\t".'<nowiki>'.$found_text.'</nowiki>'."\n";
			}
		}
	}
}

######################################################################
######################################################################

sub error_register {
	# all errors will be regestrie
	
	my $error_code = $_[0];
	my $notice = $_[1];
	
	
	if ( 	($error_description[$error_code][0] > 0 and $error_description[$error_code][4] == -1) 	#in script activated and in project unknown	
		 or ($error_description[$error_code][0] > 0 and $error_description[$error_code][4] > 0)	    #in script activated and in project activated 
		 or ($error_description[$error_code][0] == 0 and $error_description[$error_code][4] > 0)	#in script deactivated and in project activated 
		) {
		# only register if in script higher than 0 and…
		#	in project is unknown
		#       or in project higher 0
		
		$notice =~ s/\n//g;
		#print "\t". $error_code."\t".$title."\t".$notice."\n";
		#print "\t". $error_code."\t".$title."\t".$notice."\n" ;
		
		$page_has_error = 'yes';
		$page_error_number = $page_error_number + 1;
		#print 'Page errir number: '.$page_error_number."\n";
		$error_description[$error_code][3] = $error_description[$error_code][3] + 1;
		
		$error_counter = $error_counter + 1;
		
		insert_into_db($error_counter, $title, $error_code, $notice); 
	}
	
	
}

sub insert_into_db{
	my $error_counter =$_[0];
	my $article = $_[1];
	my $code = $_[2];
	my $notice = $_[3];
	$notice = substr($notice, 0, 3999) if (length($notice) > 3999);
	$notice =~ s/'/\\'/g;
	$notice =~ s/[^\\]\\\\'/\\\\\\'/g;		# fr:Orthose "Gordon\'s Mineralogy of Pennsylvania (1922) p. 191"
	$article =~ s/'/\\'/g;
	$article =~ s/[^\\]\\\\'/\\\\\\'/g;

	#insert error in database
	my $sql_text = "insert into ";
	my $date_of_found = 'now()';
	if ($dump_or_live eq 'live'){
		$sql_text = $sql_text. 'cw_error ';
	} else {
		$sql_text = $sql_text. 'cw_dumpscan ';
		$date_of_found = "'".$revision_time."'";
		$date_of_found =~ s/Z//;
		$date_of_found =~ s/T/ /;
	}
	$sql_text = $sql_text. "values ( '". $project."', ".$page_id.", '".$article."', ".$code.", '".$notice."', 0, ".$date_of_found." );";
	#print $sql_text."\n\n";
	my $sth = $dbh->prepare( $sql_text );
	#print $sql_text ."\n";
	#print $page_id."\t".$article."\t".$notice. "\n";# if ($page_id > 1960);
	$sth->execute;

}




sub set_article_as_scan_live_in_db{
	# if an article was scan live, than set this in the table cw_dumpscan as true
	my $article = $_[0];
	my $id = $_[1];
	
	my $sql_text;
	my $sth;
	
	# problem: title of an article is "  Ali's Bar   "
	$article =~ s/'/\\'/g;
	$article =~ s/[^\\]\\\\'/\\\\\\'/g;

	#update in the table cw_dumpscan
	#my $sql_text = "update cw_dumpscan set scan_live = true where project = '".$project."' and (title = '".$article."' or id = ".$id.");";
	#my $sth = $dbh->prepare( $sql_text );
	#$sth->execute;
	
	#update in the table cw_new
	$sql_text = "update cw_new set scan_live = true where project = '".$project."' and title = '".$article."';";
	$sth = $dbh->prepare( $sql_text );
	$sth->execute;

	#update in the table cw_change
	$sql_text = "update cw_change set scan_live = true where project = '".$project."' and title = '".$article."';";
	$sth = $dbh->prepare( $sql_text );
	$sth->execute;	

}


sub insert_into_db_table_tt{
	# if a new error where found in the dump, then write this into the database table cw_dumpscan
	my $article   = $_[0];
	my $page_id   = $_[1];
	my $template  = $_[2];
	my $name      = $_[3];
	my $number    = $_[4];
	my $parameter = $_[5];
	my $value     = $_[6];
	
	# problem: title of an article is "  Ali's Bar   "
	$article =~ s/'/\\'/g;
	$article =~ s/[^\\]\\\\'/\\\\\\'/g;
	$name =~ s/'/\\'/g;
	$name =~ s/[^\\]\\\\'/\\\\\\'/g;
	$parameter =~ s/'/\\'/g;
	$parameter =~ s/[^\\]\\\\'/\\\\\\'/g;
	$value =~ s/'/\\'/g;
	$value =~ s/[^\\]\\\\'/\\\\\\'/g;
	#insert error in database
	my $sql_text = "insert into tt (project, id, title, template, name, number, parameter, value) values ( '". $project."', '".$page_id."', '".$article."', ".$template.", 
	'".$name."', ".$number." , '".$parameter."', '".$value."' );";
	#print $page_id."\n";
	#print $sql_text."\n\n";
	
	#print LOGFILE $sql_text."\n\n";
#	my $sth = $dbh->prepare( $sql_text );			# deactivate for a moment
#	$sth->execute;
}



sub text_reduce{
	# this procedure reduce the input text to number of letters, but only with full words
	my $input = $_[0];
	my $number = $_[1];
	my $output = '';
	#print $input."\n";
	if ( length($input) > $number) {
		# text verkürzen
		my $pos = index($input, ' ', $number);
		$output = substr($input, 0, $pos);
		#print $input."\n";
		#print $output."\n";
		
	} else {
		$output = $input;
	}
	#print $output."\n";
	return($output);
}

sub text_reduce_to_end{
	# this procedure reduce the input text to number of letters, but only with full words
	my $input = $_[0];
	my $number = $_[1];
	my $output = '';
	#print 'Input:'."\t".$input."\n\n";
	#print 'Number:'."\t".$number."\n\n";
	#print 'length:'."\t".length($input)."\n\n";
	if ( length($input) > $number) {
		# text verkürzen
		my $pos = index($input, ' ', length($input)-$number);
		#print 'Length:'."\t".length($input)."\n\n";
		#print 'Pos:'."\t".$pos."\n\n";
		$pos = length($input)-$number  if ($pos == -1);
		$output = substr($input, $pos+1);
		#print 'Input:'."\t".$input."\n\n";
		#print 'Output:'."\t".$output."\n\n";
		
	} else {
		$output = $input;
	}
	#print $output."\n\n";
	
	return($output);
}

sub special_test {
	if ($title eq 'ALTER') {
		my $file_output= 'test.txt';
		open (FILE_TEST, '>test.txt');
		print FILE_TEST $title."\n".$text."\n";
		close (FILE_TEST);
	}
}

sub infotext_new_error{
	my $infotext = $_[0];
	$infotext = $infotext."\n\n".'<span style="color:#e80000;">This is a new error. If you find a bug then please tell this [[:de:Benutzer Diskussion:Stefan Kühn/Check Wikipedia|here]].</span>';
	return($infotext);
}

sub infotext_change_error{
	my $infotext = $_[0];
	$infotext = $infotext."\n\n".'<span style="color:#e80000;">The script was change for this error. Please fix the translation. If you find a bug then please tell this [[:de:Benutzer:Stefan Kühn/Check Wikipedia|here]].</span>';
	return($infotext);
}

sub warn_error{
	my $msg = shift;
	print 'WARNING: '.$msg;
	print LOGFILE 'WARNING: '.$msg if ($starter_modus	ne 'starter');
}

sub die_error{
	my $msg = shift;
	print 'DIE ERROR: '.$msg;
	print LOGFILE 'DIE ERROR: '.$msg if ($starter_modus	ne 'starter');
}


