#!/usr/bin/perl 

# ------------------------------------------------------------------ #
# includes

use strict;

# ------------------------------------------------------------------ #
# initialise
my $ini_path = "d:\\emu\\maws\\dat\\nplayers\\nplayers101.ini";

# ------------------------------------------------------------------ #
# globals
my @ini_content;
my $ini_name = "";
my %ini_data;

# ------------------------------------------------------------------ #
# main


# read source ini file
if ( open(INIDATA,"<$ini_path" ) ) {
  @ini_content = <INIDATA>;
  close(INIDATA);

  # read each line and parse
  foreach my $curr_line (@ini_content) {
    # check for just whitespace
    if ( $curr_line =~ m/^\s+$/i ) {
      # print "White space only: ".$line_num."\n";
    # comment line
    } elsif ($curr_line =~ m/^(\;|\:).*$/i ) {
      # ignore comment line

    # new folder type (new file?)
    } elsif ($curr_line =~ m/\[(.*)\]/i ) {
      if ( $ini_name ) {
        # multiple folders (like catver.ini)
        &write_ini32_file( $ini_name."_32\.ini", \%ini_data );
      }
      $ini_name = $1;
      %ini_data = ();
      print "ini ".$ini_name."\n";
        
    # capture data
    } elsif ($curr_line =~ m/^(\S+)\=(.*?)\s*$/i ) {
      if ( $ini_data{$2} ) {
        $ini_data{$2} .= "\r\n".$1;
      } else {
        $ini_data{$2} = $1;
      }
    }
  }
  &write_ini32_file( $ini_name."_32\.ini", \%ini_data );
  @ini_content = ();

} else {
  print "Can\'t open $ini_path for reading\n";
}

exit;

sub write_ini32_file {
  my ( $ini32_path, $ini_hash_ref, @p ) = @_;
  my ( %ini_hash, $folder );
  %ini_hash = %$ini_hash_ref;
  if ( open(INI32DATA,">$ini32_path" ) ) {
    print INI32DATA "[FOLDER_SETTINGS]\r\n";
    print INI32DATA "RootFolderIcon = cust1.ico\r\n";
    print INI32DATA "SubFolderIcon = cust2.ico\r\n\r\n";
    print INI32DATA "[ROOT_FOLDER]\r\n\r\n";
    
    foreach $folder (sort keys %ini_hash) {
      print INI32DATA "[".$folder."]\r\n".$ini_hash{$folder}."\r\n\r\n";
    }
  } else {
    print "Can\'t open $ini32_path for writing\n";
  }
}

__END__

