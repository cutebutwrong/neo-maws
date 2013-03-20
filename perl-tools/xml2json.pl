#!/usr/bin/perl

# FIXME: remaining bug allows a blank details, probably from putting clones in wrong hash

# ------------------------------------------------------------------ #
# includes

use XML::Parser;
use Data::Dumper;
use strict;

# ------------------------------------------------------------------ #
# initialise

my $parser = XML::Parser->new( Style => 'Stream', Pkg => 'MameXml' );
my $mame_xml = shift;

my %settings = (
    ## general
    # program
    "program"=>"xml2json.pl", 
    # version
    "build"=>"v0.1 - 2012/10/16", 
    # max sets to load (0 is no limit)
    "max_sets"=>"0", 
  );  


# ------------------------------------------------------------------ #
# main

if ( !((-e $mame_xml) && (-r $mame_xml)) ) {
  print "=======================================================\n";
  print $settings{"program"} . " - " . $settings{"build"} . "\n";
  print "  cutebutwrong - http://www.mameworld.net/maws/\n";
  print "=======================================================\n";
  print "Read MAME -listxml file and produce listxml.json\n";
  print "=======================================================\n";
  print "Usage:\n";
  print "  perl " . $settings{"program"} . " \"listxml.xml\" > listxml.json\n\n";
  
  exit;
}

$parser->parsefile($mame_xml);

exit;

# ------------------------------------------------------------------ #
# packages

package MameXml;
use Data::Dumper;

my ( $game_count, $str_game, $str_mame, %repeating_tags, %repeating_nested );
## XML handlers

sub StartTag {
	my ($self, $element) = @_;
	my %attributes = %_;

	## mame
	if ( $element eq 'mame' ) {
		$str_mame = "{ '".&escape_for_sql( $element )."': { ";
		## if we have attribute, then add these into an array
		$str_mame .= &buildMiniAttributes( \%attributes );
		$str_mame .= " } }\n";
		print $str_mame;
	## game
	} elsif ( $element eq 'game' ) {
		$game_count++;
		%repeating_tags = {};
		%repeating_nested = {};
		$str_game = "{ '".&escape_for_sql( $element )."': { ";
		## if we have attribute, then add these into an array
		$str_game .= &buildMiniAttributes( \%attributes );
		## leave it ready for the next elements
	## simple text tags
	} elsif ( ($element eq 'description') || ($element eq 'year') || ($element eq 'manufacturer')  || ($element eq 'ramoption') ) {
		$str_game .= ", { '".&escape_for_sql( $element )."': '".&escape_for_sql( $self->{Text} )."' } " if $self->{Text};
	## single tags with attributes
	} elsif ( ($element eq 'driver') || ($element eq 'sound') ) {
		$str_game .= ", '".&escape_for_sql( $element )."': { ".&buildMiniAttributes( \%attributes )." }";
	## repeating tags with attributes
	} elsif ( ($element eq 'rom') || ($element eq 'disk')
		|| ($element eq 'sample') || ($element eq 'chip')
		|| ($element eq 'display') || ($element eq 'softwarelist')
		|| ($element eq 'biosset') || ($element eq 'device_ref')
		|| ($element eq 'adjuster')	) {
		if ( !$repeating_tags{ $element } ) {
			$repeating_tags{ $element } = ", '".&escape_for_sql( $element )."': [ ";
			$repeating_tags{ $element } .= " { ".&buildMiniAttributes( \%attributes )." }";
		} else {
			$repeating_tags{ $element } .= ", { ".&buildMiniAttributes( \%attributes )." }";
		}
	## nested repeating tags
	} elsif ( ($element eq 'input') || ($element eq 'dipswitch') 
		|| ($element eq 'configuration') || ($element eq 'device')
		|| ($element eq 'slot') ) {
		
	}
}

sub EndTag {
	my ($self, $element) = @_;
	if ( $element eq 'game' ) {
		## close game
		foreach my $tag ( keys %repeating_tags ) {
			$str_game .= $repeating_tags{$tag}." ]" if $repeating_tags{$tag};
		}		
		$str_game .= " } }\n";
		print $str_game;
		
	} elsif ($element eq "g") {
		
	}
	if ($element eq "mame") {
		print "\n\n\/\/ ".($game_count - 1)." games\n\n";
	}
}

sub StartDocument {
	my ($self) = @_;
}

sub EndDocument {
	my ($self) = @_;
}

sub Text {
	my ($self, $element) = @_;
	if ( ($element eq 'description')
		|| ($element eq 'year')
		|| ($element eq 'manufacturer')) {
		my $text = $self->{Text};
		## clear white space
		$text =~ s/^\s*//;
		$text =~ s/\s*$//;
		## append
		$str_game .= ", { '".&escape_for_sql( $element )."': '".&escape_for_sql( $text )."' }" if $text;
	}
}

sub Characters {
	my ($self, $element) = @_;
	if ( ($element eq 'description')
		|| ($element eq 'year')
		|| ($element eq 'manufacturer')) {
		my $text = $self->{Text};
		## clear white space
		$text =~ s/^\s*//;
		$text =~ s/\s*$//;
		## append
		$str_game .= ", { '".&escape_for_sql( $element )."': '".&escape_for_sql( $text )."' }" if $text;
	}
}

## utility functions

sub buildAttributes {
	my ( $hashref, @p ) = @_;
	my %attributes = %$hashref;
	my $str_output = '';
	## if we have attribute, then add these into an array
	my $count_att = 0;
	foreach my $key ( keys %attributes ) {
		if ($count_att > 0) {
			$str_output .= ", ";
		} else {
			$str_output .= "'\@attributes': { ";
		}
		$str_output .= "'".&escape_for_sql( $key )."': '".&escape_for_sql( $attributes{$key} )."'";
		$count_att++
	}
	if ( $count_att > 0 ) {
		$str_output .= " }";
	}
	return $str_output;
}

sub buildMiniAttributes {
	my ( $hashref, @p ) = @_;
	my %attributes = %$hashref;
	my $str_output = '';
	## if we have attribute, then add these into an array
	my $count_att = 0;
	foreach my $key ( keys %attributes ) {
		if ($count_att > 0) {
			$str_output .= ", ";
		}
		$str_output .= "'".&escape_for_sql( $key )."': '".&escape_for_sql( $attributes{$key} )."'";
		$count_att++
	}
	return $str_output;
}

sub escapeHtml {
	my ($html, @p) = @_;
	$html  =~ s/</&lt;/;
	$html  =~ s/>/&gt;/;
	$html  =~ s/"/&quot;/;
	return $html;
}

sub escape_for_sql {
	my ( $in_string, @p ) = @_;
	if ( $in_string ) {
		$in_string =~ s/\'/\'\'/ig;
		return $in_string;
	} else {
		return "";
	}
}

sub escape_hash_for_sql {
	my ( $hashref, @p ) = @_;
	my %htable = %$hashref;
	foreach my $key ( keys %htable ) {
		$htable{$key} = &escape_for_sql( $htable{$key} );
	}
	return \%htable;
}

sub pad_spaces {
	my ( $in_string, $req_length, @p ) = @_;
	if ( length($in_string) < $req_length ) {
		return sprintf '%-'.$req_length.'s', $in_string;
	} else {
		return substr $in_string, 0, $req_length;
	}
}


1;


__END__

