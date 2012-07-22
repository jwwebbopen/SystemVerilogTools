#!/usr/bin/env perl

#******************************************************************
#
# update.pl module
#
#******************************************************************
#
# created on:	07/21/2012 
# created by:	jwwebb
# last edit on:	07/21/2012
# last edit by:	jwwebb
# 
#******************************************************************
# Revision List:
#
#		1.0	07/21/2012	Initial release
# 
#	Please report bugs, errors, etc.
#******************************************************************
# Update Company Name
#
#  This utility is intended to do the following:
#
#	* update COMPANY string with user's company name.
#
#  * Usage:
#
#   The "update" script can be called as shown below:
#
#  	* Update the Version Register: ./update -C
#
#   Entering just "./update" will cause the program to print out the 
#   usage information:
#
#		Usage: ./update [-h] [-v] [-C]
#		
#			-h		Print Help.
#			-v		Verbose: Print Debug Information.
#			-C		Update Company Name.
#		
#			Example:
#				./update -v -C
#
#******************************************************************
#
#  Copyright (c) 2012, Jeremy W. Webb 
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions 
#  are met: 
#
#  1. Redistributions of source code must retain the above copyright 
#     notice, this list of conditions and the following disclaimer. 
#  2. Redistributions in binary form must reproduce the above copyright 
#     notice, this list of conditions and the following disclaimer in 
#     the documentation and/or other materials provided with the 
#     distribution. 
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
#  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
#  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
#  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
#  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
#  DAMAGE.
#
#  The views and conclusions contained in the software and documentation 
#  are those of the authors and should not be interpreted as representing 
#  official policies, either expressed or implied, of the FreeBSD Project.
#        
#******************************************************************

#******************************************************************
# CPAN Modules
#****************************************************************** 
use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use POSIX;
use Time::tm;
use Time::Local;
use File::stat;
use SDBM_File;					# Simple database
use Term::ANSIColor;				# For colorizing text

#****************************************************************** 
# Constants and Variables:
#****************************************************************** 
my (%opts)=();
my ($company);
my ($test);
my ($debug);
my (%fpgaH, $fpga_rH);

#****************************************************************** 
# Retrieve command line argument
#****************************************************************** 
getopts('hvCt',\%opts);

#check for valid combination command-line arguments
if ($opts{h} || (!$opts{C} && !$opts{t}) ) {
    print_usage();
    exit;
}

# parse command-line arguments
$company = $opts{C};
$test = $opts{t};
$debug = $opts{v};

#****************************************************************** 
# Stuff input options into a Hash:
#****************************************************************** 
$fpgaH{ 'debug' }  = $debug;
$fpgaH{ 'pIfile' } = "./in/SystemVerilogTools.pm";
$fpgaH{ 'pOfile' } = "./lib/SystemVerilogTools.pm";

#****************************************************************** 
# Persistent data
#****************************************************************** 
my(%persistent_data);                           # Pre-declare hash
my($user)=$ENV{'USER'};
my($persistent_datafile)=$user."_svtools_persistent_data";
tie(%persistent_data, 'SDBM_File', "/tmp/$persistent_datafile", 
     O_RDWR|O_CREAT, 0666) || die "Couldn't tie file!  $!\n";

#****************************************************************** 
# Set Company Name:
#****************************************************************** 
if ($company) {
    $fpga_rH = modCompany(\%fpgaH);
}

if ($test) {
    $fpga_rH = getCompany(\%fpgaH);
}

exit;
 
#****************************************************************** 
# Generic Error and Exit routine 
#******************************************************************
 
sub dienice {
	my($errmsg) = @_;
	print"$errmsg\n";
	exit;
}

sub print_usage {
	my ($usage);	
	$usage = "\nUsage: $0 [-h] [-v] [-C]\n";
	$usage .= "\n";
	$usage .= "\t-h\t\tPrint Help.\n";
	$usage .= "\t-v\t\tVerbose: Print Debug Information.\n";
	$usage .= "\t-C\t\tUpdate Company Name.\n";
	$usage .= "\n";
	$usage .= "\tExample:\n";
	$usage .= "\t\t$0 -v -C\n";
	$usage .= "\n";
	print($usage);	
	return;
}

sub getCompany {
    #****************************************************************** 
    # Get Company Name:
    #
    #  The sub-routine getCompany() will ask the user for a Company Name,
    #  if no input is provided a default name of "My Company Name" will
    #  be used.
    #
    #  Usage: $fpga_rH = getCompany(\%fpgaH);
    #
    #****************************************************************** 
    my ($fpga_rH) = shift;              # Read user's variable.
    my (%fpgaH)   = %{ $fpga_rH };      # De-reference hash.
    my ($debug)   = $fpgaH{'debug'};    # Print out Debug Info.

    #****************************************************************** 
    # Get Company Name from User:
    #****************************************************************** 
    my $companyUser = Get_Input( "CompanyName","Enter company name","text","My Company Name");
    $fpgaH{ 'companyName' } = $companyUser; 
    printf("Company Name: %s\n", $fpgaH{'companyName'}) if $debug;
    
    #****************************************************************** 
    # Return data to user
    #****************************************************************** 
    return \%fpgaH;
}

sub getFile {
    #****************************************************************** 
    # Get Input File:
    #
    #  The sub-routine getFile() will open the input file, which is either a 
    #  binary or text file and read its contents into an array. It will also 
    #  determine the file length. The following parameters are created
    #
    #	* filedata:		@vdata1A
    #	* fileLen:		scalar(@vdata1A)
    #
    #  Usage: $fpga_rH = getFile(\%fpgaH);
    #
    #****************************************************************** 
    my ($fpga_rH) = shift;	           # Read user's variable.
    my (%fpgaH)   = %{ $fpga_rH };     # De-reference hash.
    my ($file)    = $fpgaH{'pIfile'};  # File Name
    my ($debug)   = $fpgaH{'debug'};   # Print out Debug Info.

    #-------------------------------------------------------------------------- 
    # Open the reg_defines.h file, and read the results into an array for 
    # manipulating the data array. Close file when done. 
    #--------------------------------------------------------------------------
    open(inF, "<", $file) or dienice ("$file open failed");
    my (@vdata1A) = <inF>;
    close(inF);

    print("** Chomp input file line endings **\n") if $debug;
    print scalar(@vdata1A), "\n" if $debug;
    foreach my $j (@vdata1A) {
        chomp($j);
        $j =~ s/\r//;
        #print("$j\n") if $debug;
    }

    push (@{ $fpgaH{ 'pm_in' } }, @vdata1A);

    $fpgaH{ 'pm_lines' } = scalar(@{ $fpgaH{ 'pm_in' } }); 
   
    print("\n\n") if $debug;
    print("Total number of lines: $fpgaH{ 'pm_lines' }\n") if $debug;
    print("\n\n") if $debug;
    
    #****************************************************************** 
    # Return data to user
    #****************************************************************** 
    return \%fpgaH;
}

sub parseFile {
    #****************************************************************** 
    # Parse HDL File
    #
    #  The sub-routine parseFile() will parse the input HDL File
    #  and overwrite the following information:
    #
    #				DATESTAMP
    #
    #  Usage: $fpga_rH = parseFile(\%fpgaH);
    #
    #****************************************************************** 
    my ($fpga_rH) = shift;		        # Read user's variable.
    my (%fpgaH)   = %{ $fpga_rH };	    # De-reference hash.
    my ($debug)   = $fpgaH{'debug'};	# Print out Debug Info.
    
    #****************************************************************** 
    # Search through $file for keywords.
    #****************************************************************** 
    my ($i) = 0;
    
    for ($i=0; $i < $fpgaH{ 'pm_lines' }; $i++) {
        if (${ $fpgaH{ 'pm_in' } }[$i] =~ m/COMPANY/) {
    		${ $fpgaH{ 'pm_in' } }[$i] =~ s/COMPANY/$fpgaH{'companyName'}/;
    	}
    }

    #print Dumper($fpgaH{'pm_in'}) if $debug;
    for (my $i=0; $i < $fpgaH{ 'pm_lines' }; $i++) {
        print(${ $fpgaH{ 'pm_in' } }[$i]) if $debug;
        printf("\n") if $debug;
    }
    
    #****************************************************************** 
    # Return data to user
    #****************************************************************** 
    return \%fpgaH;
}

sub writeFile {
    #****************************************************************** 
    # Write Out Perl File:
    #
    #  The sub-routine writeFile() will print the contents of the Perl 
    #  files into a new local file.
    #
    #  Usage: $fpga_rH = writeFile($fpgaH);
    #
    #****************************************************************** 
    my ($fpga_rH) = shift;	          # Read user's variable.
    my (%fpgaH)   = %{ $fpga_rH };    # De-reference hash.
    my ($file)    = $fpgaH{'pOfile'}; # File Name
    my ($debug)   = $fpgaH{'debug'};  # Print out Debug Info.
    
    #****************************************************************** 
    # Write HDL to File
    #****************************************************************** 
    open(outF, ">", $file) or dienice ("$file open failed");
    my ($i) = 0;
    for ($i=0; $i < $fpgaH{ 'pm_lines' }; $i++) {
        print outF ${ $fpgaH{ 'pm_in' } }[$i];
        printf(outF "\n");
    }
    close(outF); 

    #****************************************************************** 
    # Return data to user
    #****************************************************************** 
    return \%fpgaH;
}

sub modCompany {
    #****************************************************************** 
    # Modify Perl Module File:
    #
    #  The sub-routine modCompany() will modify the company name in the
    #  VerilogTools.pm file and write the file back out.
    #
    #  Usage: $fpga_rH = modCompany($fpga_rH);
    #
    #****************************************************************** 
    my ($fpga_rH) = shift;	          # Read user's variable.
    my (%fpgaH)   = %{ $fpga_rH };    # De-reference hash.
    my ($debug)   = $fpgaH{'debug'};  # Print out Debug Info.

    #****************************************************************** 
    # Check to see if lib/VerilogTools.pm file exists and delete:
    #****************************************************************** 
    printf("\n");
    if (-e $fpgaH{'pOfile'}) {
        printf("Cleaning lib/ directory!!\n");
        system("rm -f $fpgaH{'pOfile'}");
    }
    #****************************************************************** 
    # Calculate FPGA Date:
    #****************************************************************** 
    $fpga_rH = getCompany(\%fpgaH);
    #****************************************************************** 
    # Get File:
    #****************************************************************** 
    $fpga_rH = getFile($fpga_rH);
    #****************************************************************** 
    # Modify File:
    #****************************************************************** 
    $fpga_rH = parseFile($fpga_rH);
    #****************************************************************** 
    # Write File:
    #****************************************************************** 
    $fpga_rH = writeFile($fpga_rH);

    #****************************************************************** 
    # Return data to user
    #****************************************************************** 
    return \%fpgaH;
}



##############################################################################
#
# Get_Input - program for querrying user.
#
# Note:  This subroutine uses the global hash called "%persistent_data" to
#	 store/retrieve data.
#
# Input Types:
#   -> "number"
#   -> "pwr"
#   -> "freq"
#   -> "voltage"
#   -> "current"
#   -> "time"
#   -> "deg"
#   -> "text"
#
# Example Usage:
#   my($input)=Get_Input("Fmin","Enter Min Input Freq","freq",undef,1);
#
##############################################################################
sub Get_Input {
    my($variable)=shift;			# Read user variable
    my($message)=shift || "Enter Min Number";	# Read user message 
    my($input_type)=shift || "number";		# Read user input type
    my($def_value)=shift || undef;		# Read user default value
    my($prec)=shift || 0;			# Read user precision

    ##########################################################################
    #
    # Sub-routine variables
    #
    ##########################################################################
    my($string);				# Set asside variable

    ##########################################################################
    #
    # Establish some default values if we have nothing...
    #
    ##########################################################################
    if ($input_type =~ /freq/i) {
	$def_value = (defined $def_value ? $def_value : 1e9 );
    } elsif ($input_type =~ /current/i) {
	$def_value = (defined $def_value ? $def_value : 1e-3 );
    } elsif ($input_type =~ /text/i) {
	$def_value = (defined $def_value ? $def_value : "Default" );
    } else {
	$def_value = (defined $def_value ? $def_value : 0.0 );
    }

    $persistent_data{$variable}=$def_value if 
	!defined $persistent_data{$variable};

    ##########################################################################
    # ...or use last values entered as new defaults
    ##########################################################################
    my($Value)=$persistent_data{$variable};

    ##########################################################################
    # Ask user for input
    ##########################################################################
    my($input);						# Pre-declare variable

    if ($input_type =~ /number|time/i) {
	$string = color('bold yellow').$Value.
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n-> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /pwr$/i) {
	$string = color('bold yellow').sprintf("%.${prec}f dBm",$Value).
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input =~ s/dbm?//i;			# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /pwrrel/i) {
	$string = color('bold yellow').sprintf("%.${prec}f dB",$Value).
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input =~ s/dbm?//i;			# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /freq/i) {
	$string = color('bold yellow').Suffix($Value,"Hz",$prec).
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input =~ s/^(\S+)\s*gh?z?.*$/$1e9/i;	# Nope, clean up
	    $input =~ s/^(\S+)\s*mh?z?.*$/$1e6/i;	# Nope, clean up
	    $input =~ s/^(\S+)\s*kh?z?.*$/$1e3/i;	# Nope, clean up
	    $input =~ s/^(\S+)\s*hz.*$/$1/i;		# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /bps/i) {
	$string = color('bold yellow').Suffix($Value,"bps",$prec).
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input =~ s/^(\S+)\s*gb?p?s?.*$/$1e9/i;	# Nope, clean up
	    $input =~ s/^(\S+)\s*mb?p?s?.*$/$1e6/i;	# Nope, clean up
	    $input =~ s/^(\S+)\s*kb?p?s?.*$/$1e3/i;	# Nope, clean up
	    $input =~ s/^(\S+)\s*b?p?s?.*$/$1/i;	# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /volt/i) {
	$string = color('bold yellow').Suffix($Value,"V",$prec).
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input =~ s/v//i;				# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /current/i) {
	$string = color('bold yellow').Suffix($Value,"A",$prec).
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $input =~ s/^(\S+)\s*ma?.*$/$1e-3/i;	# Nope, clean up
	    $input += 0.0;				# Force number interp
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /text/i) {
	$string = color('bold yellow').$Value.
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /deg/i) {
	$string = color('bold yellow').$Value." Deg".
	          color('reset');			# Colorize string
	printf STDERR "$message [$string]:\n -> ";	# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    } elsif ($input_type =~ /nodef/i) {
	printf STDERR "$message:\n -> ";		# Query user
	$input = scalar <>;				# Get input
	chomp($input);					# Remove newline
	if ($input !~ /^ *$/){				# Blank line?
	    $input =~ s/^\s+//;				# Nope, clean up
	    $input =~ s/\s+$//;				# Nope, clean up
	    $persistent_data{$variable}=$input;		# Store for later use
	    $Value=$input;				# Use as input
	}

    }

    ##########################################################################
    # Return user value to caller
    ##########################################################################
    return $Value;

}


