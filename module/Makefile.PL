#!/usr/bin/env perl

#******************************************************************
#
# Makefile.pl module
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
# Generate Installation Makefile
#
#  This utility is intended to generate installation Makefile.
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
#use 5.010000;
use ExtUtils::MakeMaker;

#****************************************************************** 
# Update Company Name in ./in/VerilogTools.pm
#****************************************************************** 
system("./scripts/update.pl -C");

#****************************************************************** 
# Generate Makefile
#****************************************************************** 
WriteMakefile(
    NAME              => 'SystemVerilogTools',
    VERSION_FROM      => 'lib/SystemVerilogTools.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SystemVerilogTools.pm', # retrieve abstract from module
       AUTHOR         => 'Jeremy Webb <jwwebb@jwebb-design.com>') : ()),
);
printf("\n");

