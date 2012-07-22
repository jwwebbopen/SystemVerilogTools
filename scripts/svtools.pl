#!/usr/bin/env perl

#******************************************************************
# vim:ts=8:sw=8:expandtab:cindent
#******************************************************************
#
# svtools.pl module
#
#******************************************************************
#
# created on:	07/21/2012 
# created by:	jwwebb
# last edit on:	$DateTime: $ 
# last edit by:	$Author: $
# revision:     $Revision: $
# comments:     Generated
# 
#******************************************************************
# Revision List:
#
#		1.0	07/21/2012	Initial release
# 
#******************************************************************
# SystemVerilog Tools Module
#
#  This utility is intended to make designing with SystemVerilog
#  simpler. This utility supports the following options:
#
#      Usage: svtools.pl [-h] [-v] [-i|-t|-u|-a|-z] [-f <FILE>]
#      
#              -h              Print this help message.
#              -v              Verbose: Print Debug Information.
#              -i              Generate SystemVerilog Instantiation.
#              -t              Generate SystemVerilog Test Bench.
#              -u              Generate UCF file from SystemVerilog file.
#              -a              Generate new SystemVerilog top-level module file from Template.
#              -z              Generate new SystemVerilog low-level module file from Template.
#              -f <FILE>       SystemVerilog input file.
#      
#  Example of Module Instantiation:
#  
#	svtools.pl -i -f sample.v
#	svtools.pl -a -f sample.v
#	svtools.pl -z -f sample.v
#	svtools.pl -t -f sample.v
#	svtools.pl -u -f sample.v
#  
#  Save this file in your home 'bin' directory.
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

#******************************************************************
# Custom Modules
#******************************************************************
use SystemVerilogTools qw( printModInst 
     		         genTBTestFile
			 genUCFFile
     		         genSVLowModule
     		         genSVTopModule );

#******************************************************************
# Constants and Variables:
#******************************************************************
my (%svH, $sv_rH);
my (%opts)=();
my ($file);
my ($debug);

#******************************************************************
# Retrieve command line argument
#******************************************************************
getopts('hvituf:az',\%opts);

my $optslen = scalar( keys %opts );
print("Number of Options on Command-Line: $optslen\n") if $opts{v};
# check for valid combination of command-line arguments
if ( $opts{h} || !$opts{f} || !($opts{i} || $opts{t} || $opts{u} || $opts{a} || $opts{z}) || ($optslen eq "0") ) {
    print_usage();
    exit;
}

# parse command-line arguments
$file  = $opts{f};
$debug = $opts{v};

#******************************************************************
# Make Date int MM/DD/YYYY
#******************************************************************
my $year      = 0;
my $month     = 0;
my $day       = 0;
($day, $month, $year) = (localtime)[3,4,5];

#******************************************************************
# Grab username from PC:
#******************************************************************
my $author= "$^O user";
if ($^O =~ /mswin/i) { 
    $author= $ENV{USERNAME} if defined $ENV{USERNAME};
} else { 
    $author = getlogin();
}

#******************************************************************
# Initialize Verilog Hash:
#******************************************************************
$svH{ 'username' } = $author;
$svH{ 'file' } = $file;
$svH{ 'day' } = $day;
$svH{ 'month' } = $month;
$svH{ 'year' } = $year;
$svH{ 'debug' } = $debug;

#******************************************************************
# Generate Top-Level SystemVerilog Module:
#******************************************************************
if ($opts{a}) {
    print("Filename: $opts{f}\n") if $debug;
    $sv_rH = genSVTopModule(\%svH);
}

#******************************************************************
# Generate Lower SystemVerilog Module:
#******************************************************************
if ($opts{z}) {
    print("Filename: $opts{f}\n") if $debug;
    $sv_rH = genSVLowModule(\%svH);
}

#******************************************************************
# Print Module Declaration:
#******************************************************************
if ($opts{i}) {
    $sv_rH = printModInst(\%svH);
    print("\n\n");
}

#******************************************************************
# Generate UCF File:
#******************************************************************
if ($opts{u}) {
    $sv_rH = genUCFFile(\%svH);
}

#******************************************************************
# Generate Test Bench File:
#******************************************************************
if ($opts{t}) {
    $sv_rH = genTBTestFile(\%svH);
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
    $usage = "\nUsage: $0 [-h] [-v] [-i|-t|-u|-a|-z] [-f <FILE>]\n";
    $usage .= "\n";
    $usage .= "\t-h\t\tPrint this help message.\n";
    $usage .= "\t-v\t\tVerbose: Print Debug Information.\n";
    $usage .= "\t-i\t\tGenerate SystemVerilog Instantiation.\n";
    $usage .= "\t-t\t\tGenerate SystemVerilog Test Bench.\n";
    $usage .= "\t-u\t\tGenerate UCF file from SystemVerilog file.\n";
    $usage .= "\t-a\t\tGenerate new SystemVerilog top-level module file from Template.\n";
    $usage .= "\t-z\t\tGenerate new SystemVerilog low-level module file from Template.\n";
    $usage .= "\t-f <FILE>\tSystemVerilog input file.\n";
    $usage .= "\n";
    $usage .= "\tExample of Module Instantiation:\n";
    $usage .= "\t\t$0 -i -f sample.v \n";
    $usage .= "\n";
    print($usage);
    return;
}

