package SystemVerilogTools;

#******************************************************************
# vim:tw=160:softtabstop=8:shiftwidth=8:cindent:syn=perl:
#******************************************************************
#
# SystemVerilogTools.pm
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
# SystemVerilogTools
#
#  This package is intended to parse and create SystemVerilog files.
#  
#******************************************************************

use strict;
use warnings;
use diagnostics;
use Exporter;
use vars qw($VERSION @ISA @EXPORT ); # @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.01';
@ISA         = qw(Exporter);
@EXPORT      = qw( printModInst
		   genTBTestFile
		   genUCFFile
		   genSVLowModule
		   genSVTopModule );
#@EXPORT_OK   = qw(&func1);
#%EXPORT_TAGS = ( DEFAULT => [qw(&func1)],
#                 Both    => [qw(&func1 &func2)]);



1;

sub getFile {
	#------------------------------------------------------------------------------ 
	# Get SystemVerilog File:
	#
	#  The sub-routine getFile() will open the SystemVerilog file 
	#  and read its contents into an array. It will also determine
	#  the file length. The following parameters are created
	#
	#	* filedata:		@vdataA
	#	* fileLen:		scalar(@vdataA)
	#
	#  Usage: $sv_rH = getFile(\%svH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.
	
	#------------------------------------------------------------------------------ 
	# Open the SystemVerilog file, and read the results into an array
	# for manipulating the data array. Strip new lines and carriage returns from 
	# remove string array, and initialize for loop variables. Close file when done.
	#------------------------------------------------------------------------------
	open(inF, "<", $svH{ 'file' }) or dienice ("$svH{ 'file' } open failed");
	my @svdataA = <inF>;
	close(inF);
	
	# Strip newlines
	foreach my $i (@svdataA) {
		chomp($i); # Remove any \n line-feeds.
	        $i =~ s/\r//g; # Remove any \r carriage-returns.
	}
	push (@{ $svH{ 'filedata' } }, @svdataA);
	
	#------------------------------------------------------------------------------ 
	# Determine number of lines, and set beginning for loop index.
	#------------------------------------------------------------------------------ 
	$svH{ 'fileLen' } = scalar(@{ $svH{ 'filedata' } }); # number of lines in Verilog file
	
	print("\n\n") if $debug;
	print("Total number of lines: $svH{ 'fileLen' }\n") if $debug;
	print("\n\n") if $debug;
		
	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;
}

sub parseFile {
	#------------------------------------------------------------------------------ 
	# Parse SystemVerilog File:
	#
	#  The sub-routine parseFile() will search through the 
	#  input SystemVerilog File and retrieve line numbers for 
	#  the following parameters:
	#
	#	* modFound:		'module'
	#	* pCFound:		');'
	#	* paramFound:		'#('
	#	* paramEndFound:	')'
	#	* endModFound:		'endmodule'
	#
	#  Usage: $sv_rH = parseFile(\%svH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	my ($modfound) = "";
	my ($pcfound) = "";
	my ($paramfound) = "";
	my ($paramendfound) = "";
	my ($endmodfound) = "";

	#------------------------------------------------------------------------------ 
	# Search through $file for keywords.
	#------------------------------------------------------------------------------
	my $j = -1; 
	for ($j=0; $j < $svH{ 'fileLen' }; $j++) {
		# Search for: 'module'
		if (${ $svH{ 'filedata' } }[$j] =~ m/^module/) {
			$modfound = $j;
			print("'module' Line Number: $modfound\n") if $debug;
		}
		# Search for: ');'
		if (($pcfound eq "") and (${ $svH{ 'filedata' } }[$j] =~ m/\x29\x3b/)) {
			$pcfound = $j;
			print("'\)\;' Line Number: $pcfound\n") if $debug;
		}
		# Search for: '#('
		if (($paramfound eq "") and (${ $svH{ 'filedata' } }[$j] =~ m/\x23\x28/)) {
			$paramfound = $j;
			print("'\#\(' Line Number: $paramfound\n") if $debug;
		}
		# Search for: ')'
		if (($paramfound ne "") and ($paramendfound eq "") and (${ $svH{ 'filedata' } }[$j] =~ m/\x29/)) {
			$paramendfound = $j;
			print("'\)' Line Number: $paramendfound\n") if $debug;
		}
		# Search for: 'endmodule'
		if (${ $svH{ 'filedata' } }[$j] =~ m/^endmodule/) {
			$endmodfound = $j;
			print("'endmodule' Line Number: $endmodfound\n") if $debug;
			$j = $svH{ 'fileLen' };
		}
	}
	
	$svH{ 'modFound' } = $modfound; 
	$svH{ 'pCFound' } = $pcfound;
	$svH{ 'paramFound' } = $paramfound;
	$svH{ 'paramEndFound' } = $paramendfound;
	$svH{ 'endModFound' } = $endmodfound;

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;
}

sub getModDecl {
	#------------------------------------------------------------------------------ 
	# Get Module Declaration from SystemVerilog File:
	#
	#  The sub-routine getModDecl() will search through the 
	#  input SystemVerilog File and extract the Module Declaration
	#  into an array. Push the array into the Verilog Hash.
	#
	#	* modFound:		'module'
	#	* pCFound:		');'
	#	* paramFound:		'#('
	#	* paramEndFound:	')'
	#	* endModFound:		'endmodule'
	#
	#  Usage: $sv_rH = getModDecl($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Push contents between 'module' and ending paren '\)\;' into an array.
	#------------------------------------------------------------------------------ 
	my ($k) = -1;
	my (@modDeclTmpA);
	my ($modFound) = $svH{ 'modFound' };		# "module" keyword found.
	my ($pCFound) = $svH{ 'pCFound' };		# ");" Parenthesis Found
	for ($k = $modFound; $k <= $pCFound; $k++) {
		push(@modDeclTmpA, ${ $svH{ 'filedata' } }[$k]);
	}
	
	#------------------------------------------------------------------------------ 
	# Clear out trailing comments and indentation spaces and tabs.
	#------------------------------------------------------------------------------ 
	foreach my $n (@modDeclTmpA) {
		$n =~ s/^.*?input/input/g;	#strip spaces up to input.
		$n =~ s/^.*?output/output/g;	#strip spaces up to output.
		$n =~ s/^.*?inout/inout/g;	#strip spaces up to inout.
		$n =~ s/\x2f\x2f.*//;		#strip any trailing //comment
		$n =~ s/\/\*.*\*\///;		#strip embedded comments
		$n =~ s/.*\x29\x3b/\x29\x3b/;	#strip spaces or tabs up to ");"
		#print("$n\n");
	}
	
	#------------------------------------------------------------------------------ 
	# Print out cleaned module declaration.
	#------------------------------------------------------------------------------ 
	foreach my $m (@modDeclTmpA) {
		if ($m =~ m/\S+/) {
			push(@{ $svH{ 'modDecl' } }, $m);
			print("$m\n") if $debug;
		}
	}
		
	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub getModName {
	#------------------------------------------------------------------------------ 
	# Get Module Name from Module Declaration:
	#
	#  The sub-routine getModName() will search through the 
	#  Module Declaration and extract the following information:
	#
	#	* modName
	#	* Parameterized: "yes" or "no"
	#
	#  Usage: $sv_rH = getModName($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Strip off the Module name:
	#------------------------------------------------------------------------------ 
	print("\n\n") if $debug;
	my ($crap1);
	my ($crap2);
	my ($modname);
	($crap1, $modname, $crap2) = (${ $svH{ 'modDecl' } }[0] =~ /(\S+\s+)(\S+)(.*)/);
	$svH{ 'modName' } = $modname;
	print("Module Name: $svH{ 'modName' }\n") if $debug;
	
	if (($svH{ 'paramFound' } eq "") or ($svH{ 'paramFound' } > $svH{ 'pCFound' }))  {
		$svH{ 'Parameterized' } = "no";
		print("Is this a parameterizable module? $svH{ 'Parameterized' }\n") if $debug;
	} else {
		$svH{ 'Parameterized' } = "yes";
		print("Is this a parameterizable module? $svH{ 'Parameterized' }\n") if $debug;
	}
		
	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub getModIO {
	#------------------------------------------------------------------------------ 
	# Get Module I/O from Module Declaration:
	#
	#  The sub-routine getModIO() will search through the 
	#  Module Declaration and extract the input, inout, and 
	#  output signal names. The following paramters are created:
	#
	#	* modIO
	#	* modIn
	#	* modOut
	#
	#  Usage: $sv_rH = getModIO($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Get Module Declaration:
	#
	#	* Store Module Declaration array in a temporary array.
	#	* Determine the number of ports.
	#
	#------------------------------------------------------------------------------ 
	my (@modDeclA) = @{ $svH{ 'modDecl' } }; # Module Decl for parsing ports.
	my (@paramA) = @{ $svH{ 'modDecl' } }; # Module Decl for parsing parameters.
	my ($modLen) = scalar(@modDeclA);

	#------------------------------------------------------------------------------ 
	# Get Inputs, InOuts, and Outputs and store each in their respective arrays.
	#------------------------------------------------------------------------------ 
	my ($line) = -1;
	my (@allportsonlyA);
	my ($allportsonlyA_Len);
	my (@allportsA);
	my ($allportsA_Len);

	# Push lines from the module declaration that match input, inout, or output into 
	# an arrays:
	for ($line = 1; $line < ($modLen-1); $line++) {
	        if ($modDeclA[$line] =~  m/\s*(input|output|inout).*/) {
			push(@allportsA, $modDeclA[$line]);
		}
	}

	$allportsA_Len = scalar(@allportsA);
	print("Port Length: $allportsA_Len\n") if $debug;

	@allportsonlyA = @allportsA;
	$allportsonlyA_Len = scalar(@allportsonlyA);
	print("Line Length: $allportsonlyA_Len\n") if $debug;

	# Strip off all information except the port name for all ports:
	foreach my $i (@allportsonlyA) {
		$i =~ s/\s*(input|output|inout)\s*//;
		$i =~ s/\s*signed\s*//;
		$i =~ s/\s*(logic|reg|wire)\s*//;
		$i =~ s/\s*\x5b.*\x5d\s*//;
		$i =~ s/\s+$//;
		$i =~ s/,//;
		print("$i\n") if ($debug);
		
	}	
	for ($line = 1; $line < ($allportsA_Len-1); $line++) {
		print("Line: $allportsA[$line]\n") if $debug;
		print("Port: $allportsonlyA[$line]\n") if $debug;
	}

	#------------------------------------------------------------------------------ 
	# Get Parameters and Values. Calculate width of each port.
	#------------------------------------------------------------------------------ 
	my (%allportsHoH) = ();
	my ($param, $crap2, $paramval, $crap3);	
	my (%paramHoH) = (); # Parameter Hash: param = paramval.
	my ($msb, $colon, $lsb); # MSB:LSB.
	my ($width); # Port Width.
	my ($tempLine);
	my ($direction); # Port Direction: input, inout, or output.
	my ($wrl); # Wire, Register, or Logic.
	if ($svH{ 'Parameterized' } =~ m/yes/) {
	    foreach my $j (@paramA) {
	        if ($j =~ m/parameter/) {
	            $j =~ s/.*parameter\s+//;
	            ($param, $crap2, $paramval, $crap3) = ($j =~ /(\S+)(\s+=\s+)(\S+)([,\x29].*)/);
	            $paramHoH{ $param }{ 'parameter' } = $param;
	            $paramHoH{ $param }{ 'value' } = $paramval;
	            print("Parameter: $paramHoH{ $param }{ 'parameter' }\n") if $debug;
	            print("Parameter Value: $paramHoH{ $param }{ 'value' }\n") if $debug;
	        }
	    }
	    for ($line = 0; $line < ($allportsA_Len); $line++) {
	        if ($allportsA[$line] =~ m/\x5b/) {
                    # Determine port direction:
		    if ($allportsA[$line] =~ m/input/) {
			    $direction = "input";
		    } elsif ($allportsA[$line] =~ m/inout/) {
			    $direction = "inout";
		    } elsif ($allportsA[$line] =~ m/output/) {
			    $direction = "output";
		    }
		    if ($allportsA[$line] =~ m/wire/) {
			    $wrl = "wire";
		    } elsif ($allportsA[$line] =~ m/reg/) {
			    $wrl = "reg";
		    } elsif ($allportsA[$line] =~ m/logic/) {
			    $wrl = "logic";
		    }
	            $tempLine = $allportsA[$line];
	            $tempLine =~ s/\s+/ /g;
	            $tempLine =~ s/,//;
	            $tempLine =~ s/\s+$//;
	            $allportsA[$line] =~ s/.*\x5b//;
	            $allportsA[$line] =~ s/\x5d.*//;
	            ($msb, $colon, $lsb) = ($allportsA[$line] =~ /(\S+)(:)(\S+)/);
	            #print("MSB: $msb, LSB: $lsb\n");
	            for my $key ( sort(keys %paramHoH) ) {
	                #print("$key => $paramHoH{$key}{'value'}\n") if $debug;
	                if ($msb =~ m/$paramHoH{$key}{'parameter'}/) {
	                    print("Key: $paramHoH{$key}{'parameter'}\n") if $debug;
	                    print("Value: $paramHoH{$key}{'value'}\n") if $debug;
	                    my $param_minus_1 = ($paramHoH{$key}{'value'}-1);
			    if ($msb =~ /\x28/) {
		                    $msb =~ s/\x28$paramHoH{$key}{'parameter'}-1\x29/$param_minus_1/;
			    } else {
		                    $msb =~ s/$paramHoH{$key}{'parameter'}-1/$param_minus_1/;
			    }
	                }
	            }
	            $width = ($msb+1);
		    $allportsHoH{$allportsonlyA[$line]}{'port'} = $allportsonlyA[$line];
		    $allportsHoH{$allportsonlyA[$line]}{'width'} = $width;
		    $allportsHoH{$allportsonlyA[$line]}{'direction'} = $direction;
		    $allportsHoH{$allportsonlyA[$line]}{'wrl'} = $wrl;
	            print("Line: $tempLine, MSB: $msb, LSB: $lsb, Width: $width, Direction: $direction\n") if $debug;
	        } else {
                    # Determine port direction:
		    if ($allportsA[$line] =~ m/input/) {
			    $direction = "input";
		    } elsif ($allportsA[$line] =~ m/inout/) {
			    $direction = "inout";
		    } elsif ($allportsA[$line] =~ m/output/) {
			    $direction = "output";
		    }
		    if ($allportsA[$line] =~ m/wire/) {
			    $wrl = "wire";
		    } elsif ($allportsA[$line] =~ m/reg/) {
			    $wrl = "reg";
		    } elsif ($allportsA[$line] =~ m/logic/) {
			    $wrl = "logic";
		    }
	            $tempLine = $allportsA[$line];
	            $tempLine =~ s/\s+/ /g;
	            $tempLine =~ s/,//;
	            $tempLine =~ s/\s+$//;
	            $width = 1;
		    $allportsHoH{$allportsonlyA[$line]}{'port'} = $allportsonlyA[$line];
		    $allportsHoH{$allportsonlyA[$line]}{'width'} = $width;
		    $allportsHoH{$allportsonlyA[$line]}{'direction'} = $direction;
		    $allportsHoH{$allportsonlyA[$line]}{'wrl'} = $wrl;
	            print("Line: $tempLine, Width: $width, Direction: $direction\n") if $debug;
	        }
	    }
	    print("\n\n") if $debug;
	} else {
	    for ($line = 0; $line < ($allportsA_Len); $line++) {
	        if ($allportsA[$line] =~ m/\x5b/) {
                    # Determine port direction:
		    if ($allportsA[$line] =~ m/input/) {
			    $direction = "input";
		    } elsif ($allportsA[$line] =~ m/inout/) {
			    $direction = "inout";
		    } elsif ($allportsA[$line] =~ m/output/) {
			    $direction = "output";
		    }
		    if ($allportsA[$line] =~ m/wire/) {
			    $wrl = "wire";
		    } elsif ($allportsA[$line] =~ m/reg/) {
			    $wrl = "reg";
		    } elsif ($allportsA[$line] =~ m/logic/) {
			    $wrl = "logic";
		    }
	            $tempLine = $allportsA[$line];
	            $tempLine =~ s/(\s+)/ /;
	            $tempLine =~ s/,//;
	            $tempLine =~ s/\s+$//;
	            $allportsA[$line] =~ s/.*\x5b//;
	            $allportsA[$line] =~ s/\x5d.*//;
	            ($msb, $colon, $lsb) = ($allportsA[$line] =~ /(\S+)(:)(\S+)/);
	            $width = ($msb+1);
		    $allportsHoH{$allportsonlyA[$line]}{'port'} = $allportsonlyA[$line];
		    $allportsHoH{$allportsonlyA[$line]}{'width'} = $width;
		    $allportsHoH{$allportsonlyA[$line]}{'direction'} = $direction;
		    $allportsHoH{$allportsonlyA[$line]}{'wrl'} = $wrl;
	            print("Line: $tempLine, MSB: $msb, LSB: $lsb, Width: $width, Direction: $direction\n") if $debug;
	        } else {
                    # Determine port direction:
   		    if ($allportsA[$line] =~ m/input/) {
			    $direction = "input";
		    } elsif ($allportsA[$line] =~ m/inout/) {
			    $direction = "inout";
		    } elsif ($allportsA[$line] =~ m/output/) {
			    $direction = "output";
		    }
		    if ($allportsA[$line] =~ m/wire/) {
			    $wrl = "wire";
		    } elsif ($allportsA[$line] =~ m/reg/) {
			    $wrl = "reg";
		    } elsif ($allportsA[$line] =~ m/logic/) {
			    $wrl = "logic";
		    }
	            $tempLine = $allportsA[$line];
	            $tempLine =~ s/\s+/ /g;
	            $tempLine =~ s/,//;
	            $tempLine =~ s/\s+$//;
	            $width = 1;
		    $allportsHoH{$allportsonlyA[$line]}{'port'} = $allportsonlyA[$line];
		    $allportsHoH{$allportsonlyA[$line]}{'width'} = $width;
		    $allportsHoH{$allportsonlyA[$line]}{'direction'} = $direction;
		    $allportsHoH{$allportsonlyA[$line]}{'wrl'} = $wrl;
	            print("Line: $tempLine, Width: $width, Direction: $direction\n") if $debug;
	        }
	    }
	    print("\n\n") if $debug;
	}

	%{ $svH{ 'modParams' } } = %paramHoH;
	%{ $svH{ 'modIO' } } = %allportsHoH;

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genModInst {
	#------------------------------------------------------------------------------ 
	# Generate Module Instantiation:
	#
	#  The sub-routine genModInst() will generate the SystemVerilog module 
	#  instantiation. An example module instantiation is shown below:
	#
	#		freq_meas   _freq_meas (.clk50mhz (clk50mhz),
	#					.rst_n (rst_n),
	#					.clk_in (clk_in),
	#					.cnt_rm_ref_lmt (cnt_rm_ref_lmt),
	#					.cnt_fm_ref_lmt (cnt_fm_ref_lmt),
	#					.rm_d1_out (rm_d1_out),
	#					.rm_d2_out (rm_d2_out),
	#					.rm_done (rm_done),
	#					.fm_d1_out (fm_d1_out),
	#					.fm_d2_out (fm_d2_out),
	#					.fm_done (fm_done));
	#
	#  Usage: $sv_rH = genModInst($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Get Module IO Ports Array:
	#
	#	* Assign to temporary array.
	#	* Determine number of IO Ports.
	#
	#------------------------------------------------------------------------------ 
	# Copy the Parameter Hash to a local hash:
	my (%allportsHoH) = %{ $svH{ 'modIO' } };
	my (@ioports) = ();
	my (@inports) = ();
	my (@outports) = ();
	# Push lines from the module declaration that match input, inout, or output into 
	# their respective arrays:
	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} =~ m/input/) {
			push(@inports, $allportsHoH{$key}{'port'});
		} elsif ($allportsHoH{$key}{'direction'} =~ m/inout/) {
			push(@ioports, $allportsHoH{$key}{'port'});
		} elsif ($allportsHoH{$key}{'direction'} =~ m/output/) {
			push(@outports, $allportsHoH{$key}{'port'});
		}
	}
	my ($numioports) = scalar(@ioports);
	my ($numinports) = scalar(@inports);
	my ($numoutports) = scalar(@outports);
	print("Number of IO Ports: $numioports\n") if $debug;
	print("Number of In Ports: $numinports\n") if $debug;
	print("Number of Out Ports: $numoutports\n") if $debug;

	#------------------------------------------------------------------------------ 
	# Get Module Name:
	#------------------------------------------------------------------------------ 
	my ($modname) = $svH{ 'modName' };

	if ( ($numinports eq 0) and ($numioports eq 0) and ($numoutports eq 0) ) {
		print("* Error: Cannot create instantiation of module '$modname'.\n  Verify module uses an ANSI-C Type Module Declaration.\n");
		exit;
	} else {

		#------------------------------------------------------------------------------ 
		# Print out Module Instantiation:
		#------------------------------------------------------------------------------ 
		my ($indent_spaces) = "";
		my ($modinst) = "";
		$modinst = "// *** Instantiate the $modname module ***\n";
		if ($svH{ 'Parameterized' } =~ m/yes/) {
			#----------------------------------------------------------------------
			# Assemble First Line of Instantiation:
			#----------------------------------------------------------------------
			# Copy the Parameter Hash to a local hash:
			my (%paramHoH) = %{ $svH{ 'modParams' } };
			# Determine number of parameters:
			my ($paramHoH_Size) = 0;
		        $paramHoH_Size += scalar keys %paramHoH;  # method 1: explicit scalar context
			print("Size of Hash: $paramHoH_Size\n") if $debug;
			# Start building up the first line of the instantiation:
			my ($modinst_line1) = "$modname  #(";
			for my $key ( sort(keys %paramHoH) ) {
				print("Parameter Size Count: $paramHoH_Size\n") if $debug;
				if ($paramHoH_Size <= 1) {
					# If we're on the last parameter, 
					# don't add a ", " (i.e., a comma followed by a space).
					$modinst_line1 .= ".$paramHoH{$key}{'parameter'}($paramHoH{$key}{'value'})";
				} else {
					$modinst_line1 .= ".$paramHoH{$key}{'parameter'}($paramHoH{$key}{'value'}), ";
				}
				$paramHoH_Size -= 1;
			}
			$modinst_line1 .= ")  _$modname";
			$modinst_line1 = sprintf("$modinst_line1    (");

			#----------------------------------------------------------------------
			# Determine number of indent spaces:
			#
			#	* Tab Space = 8
			#	* Create string with correct numer of indent spaces.
			#
			#----------------------------------------------------------------------
			my ($tmpinst_len) = length($modinst_line1);
			print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
			my ($i) = 0;
			my (@indent);
			for ($i = 0; $i < $tmpinst_len; $i++) {
				push(@indent, " ");
			}
			$indent_spaces = join("",@indent);
			$modinst .= "$modinst_line1";
		} else {
			#----------------------------------------------------------------------
			# Assemble First Line of Instantiation:
			#----------------------------------------------------------------------
			my ($modinst_line1) = "$modname        _$modname        (";

			#----------------------------------------------------------------------
			# Determine number of indent spaces:
			#
			#	* Tab Space = 8
			#	* Assemble first line of Module Instantiation.
			#	* Create string with correct numer of indent spaces.
			#
			#----------------------------------------------------------------------
			my ($tmpinst_len) = length($modinst_line1);
			print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
			my ($i) = 0;
			my (@indent);
			for ($i = 0; $i < $tmpinst_len; $i++) {
				push(@indent, " ");
			}
			$indent_spaces = join("",@indent);
			$modinst .= "$modinst_line1";
		}

		# Sort In,I/O,Out Array of Net Names Alphabetically:
		@inports = sort(@inports);
		@ioports = sort(@ioports);
		@outports = sort(@outports);

		# Create Clock Hash:
		my (%clkH);
		my (%clk_rH);

		# Find clock net(s): 
		my (@clk_indexA) = ();
		my ($i) = 0;
		for ($i = 0; $i < $numinports; $i++) {
			if ($inports[$i] =~ m/clk/i) {
				print("Clk Index: $i\n") if $debug;
				push(@clk_indexA, $i);
			}
		}
		push (@{ $clkH{ 'clk_indexA' } }, @clk_indexA);

		# Find min clk_net index:
		my (@clk_index_sortedA) = ();
		@clk_index_sortedA = sort {$a <=> $b} @clk_indexA;
		print("Clock Net (minimum index): ") if $debug;
		if (defined $clk_index_sortedA[0]) {
			print("$clk_index_sortedA[0]\n") if $debug;
		} else {
			print("NA\n") if $debug;
		}
		my ($clk_len) = scalar(@clk_index_sortedA);
		print("Number of Clock Nets: $clk_len\n") if $debug;
		push (@{ $clkH{ 'clk_index_sortedA' } }, @clk_index_sortedA);
		$clkH{ 'clk_indexA_Len' } = $clk_len;
		$clkH{ 'debug' } = $debug;

		# Print out the "clock inputs" in the instantiation:
		my ($c) = 0;
		for ($c = 0; $c < $clk_len; $c++) {
			if ($c eq 0) {
				$modinst .= ".$inports[$clk_index_sortedA[$c]] ($inports[$clk_index_sortedA[$c]]),\n";
			} else {
				$modinst .= "$indent_spaces.$inports[$clk_index_sortedA[$c]] ($inports[$clk_index_sortedA[$c]]),\n";
			}	
		}
		
		# Print out the remainder of the "inputs" in the instantiation:
		my ($j) = 0;
		for ($j = 0; $j < $numinports; $j++) {
			# Assign current index to clock hash:
			$clkH{ 'j' } = $j;

			# Check current index against all clock indices:
			if ((&checkClkIndex(\%clkH)) eq 0) {
				$modinst .= "$indent_spaces.$inports[$j] ($inports[$j]),\n";
			}	
		}

		# Print out the "inouts" in the instantiation:
		if ($numioports > 0) {
			$modinst .= "\n";
			for ($j = 0; $j < $numioports; $j++) {
				$modinst .= "$indent_spaces.$ioports[$j] ($ioports[$j]),\n";
			}
		}

		$modinst .= "\n";

		# Print out the "outputs" in the instantiation:
		for ($j = 0; $j < $numoutports; $j++) {
			if ($j eq ($numoutports-1)) {
				$modinst .= "$indent_spaces.$outports[$j] ($outports[$j]));\n";
			} else {
				$modinst .= "$indent_spaces.$outports[$j] ($outports[$j]),\n";
			}
		}
		
		$svH{ 'modInst' } = $modinst;
	}


	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub checkClkIndex {
	#------------------------------------------------------------------------------ 
	# Check Input Port Index Against Clock Indices:
	#
	#  The sub-routine checkClkIndex() will check the current input port index 
	#  against all identified clock indices. It will set a flag high if it matches,
	#  or leave it low if no match has occured.
	#
	#
	#  Usage: $clk_rH = checkClkIndex(\%clkH);
	#
	#------------------------------------------------------------------------------ 
	my ($clk_rH) = shift;	# Read in user's variable.

	my (%clkH) = %{ $clk_rH };
	my $len = $clkH{ 'clk_indexA_Len'};
	my $debug = $clkH{ 'debug' };
	my $index = $clkH{ 'j' };

    	my (@clk_index_sortedA);
	push(@clk_index_sortedA, @{$clkH{ 'clk_index_sortedA' }});

	print("Index: $index\n") if $debug;
	print("Clk Index Len: $len\n") if $debug;

	my ($cnt) = 0;
	my ($yes_or_no) = 0; # Default No
	my ($i) = 0;
	for ($i = 0; $i < $len; $i++) {
		if ($index eq $clk_index_sortedA[$i]) {
			$cnt += 1;
			print("Clk Index: $clk_index_sortedA[$i]\n") if $debug;
		}
	}
	if ($cnt > 0) {
		$yes_or_no = 1;
	}

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
	return $yes_or_no;
}

sub printModInst {
	#------------------------------------------------------------------------------ 
	# Print Module Instantiation:
	#
	#  The sub-routine printModInst() will print out the SystemVerilog module 
	#  instantiation. An example module instantiation is shown below:
	#
	#		freq_meas   _freq_meas (.clk50mhz (clk50mhz),
	#					.rst_n (rst_n),
	#					.clk_in (clk_in),
	#					.cnt_rm_ref_lmt (cnt_rm_ref_lmt),
	#					.cnt_fm_ref_lmt (cnt_fm_ref_lmt),
	#					.rm_d1_out (rm_d1_out),
	#					.rm_d2_out (rm_d2_out),
	#					.rm_done (rm_done),
	#					.fm_d1_out (fm_d1_out),
	#					.fm_d2_out (fm_d2_out),
	#					.fm_done (fm_done));
	#
	#  Usage: $sv_rH = printModInst($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Open $file and stuff it into an array.
	#------------------------------------------------------------------------------ 
	$sv_rH = getFile($sv_rH);

	#------------------------------------------------------------------------------ 
	# Search through $file for keywords.
	#------------------------------------------------------------------------------ 
	$sv_rH = parseFile($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module Declaration:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModDecl($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module Name:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModName($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module I/O:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModIO($sv_rH);

	#------------------------------------------------------------------------------ 
	# Generate Module Instantiation:
	#------------------------------------------------------------------------------ 
	$sv_rH = genModInst($sv_rH);

	%svH = %{ $sv_rH }; # De-reference Verilog hash.

        my $modinst = $svH{ 'modInst' };
	print("$modinst");

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genTBTop {
	#------------------------------------------------------------------------------ 
	# Print Test Bench Top Module Header:
	#
	#  The sub-routine genTBTop() will generate the SystemVerilog test bench top module. 
	#
	#  Usage: $sv_rH = genTBTop($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;	    # Read in user's variable.

	my (%svH) = %{ $sv_rH }; # De-reference Verilog hash.

	my $file_sv = $svH{'file'};
	my $tbTestFile = $svH{ 'tbTestFile' };
        my $modinst = $svH{ 'modInst' };
	my $day = $svH{'day'};
	my $month = $svH{'month'};
	my $username = $svH{'username'};
	my $year = $svH{'year'};
	my ($debug) = $svH{'debug'};   # Print out Debug Info.

	# Fix month, day, year:
	my $monthR = $month+1;
	my $yearR = $year+1900;

	# Get Filename:
	# strip .sv from filename
	my $file = $file_sv;
        $file =~ s/\x2esv//;
        $file =~ s/\x2e//g;
        $file =~ s/\x2f//g;
	my $tbTopFile = join ".","top","sv";

	#------------------------------------------------------------------------------ 
	# Generate Test Module Instantiation
	#------------------------------------------------------------------------------ 
	#------------------------------------------------------------------------------ 
	#------------------------------------------------------------------------------ 
	# Get Module IO Ports Array:
	#
	#	* Assign to temporary array.
	#	* Determine number of IO Ports.
	#
	#------------------------------------------------------------------------------ 
	# Copy the Parameter Hash to a local hash:
	my (%allportsHoH) = %{ $svH{ 'modIO' } };
	my (@ioports) = ();
	my (@clkports) = ();
	my (@inports) = ();
	my (@outports) = ();
	# Push lines from the module declaration that match input, inout, or output into 
	# their respective arrays:
	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} =~ m/input/) {
			if ($allportsHoH{$key}{'port'} =~ m/(clk|clock|CLK)/) {
				push(@inports, $allportsHoH{$key}{'port'});
				push(@clkports, $allportsHoH{$key}{'port'});
			} else {
				push(@outports, $allportsHoH{$key}{'port'});
			}
		} elsif ($allportsHoH{$key}{'direction'} =~ m/inout/) {
			push(@ioports, $allportsHoH{$key}{'port'});
		} elsif ($allportsHoH{$key}{'direction'} =~ m/output/) {
			push(@inports, $allportsHoH{$key}{'port'});
		}
	}
	my ($numioports) = scalar(@ioports);
	my ($numinports) = scalar(@inports);
	my ($numoutports) = scalar(@outports);
	print("Number of IO Ports: $numioports\n") if $debug;
	print("Number of In Ports: $numinports\n") if $debug;
	print("Number of Out Ports: $numoutports\n") if $debug;

	#------------------------------------------------------------------------------ 
	# Get Module Name:
	#------------------------------------------------------------------------------ 
	my ($modname) = $svH{ 'modName' };
	my $test_modname = join "_", "test", $modname;

	#------------------------------------------------------------------------------ 
	# Print out Module Instantiation:
	#------------------------------------------------------------------------------ 
	my ($indent_spaces) = "";
        my ($TestModInst) = "";
	$TestModInst = "// ** Instantiate the Test module **\n";
#	if ($svH{ 'Parameterized' } =~ m/yes/) {
#		#----------------------------------------------------------------------
#		# Assemble First Line of Instantiation:
#		#----------------------------------------------------------------------
#		# Copy the Parameter Hash to a local hash:
#		my (%paramHoH) = %{ $svH{ 'modParams' } };
#		# Determine number of parameters:
#		my ($paramHoH_Size) = 0;
#	        $paramHoH_Size += scalar keys %paramHoH;  # method 1: explicit scalar context
#		print("Size of Hash: $paramHoH_Size\n") if $debug;
#		# Start building up the first line of the instantiation:
#		my ($modinst_line1) = "$modname  #(";
#		for my $key ( keys %paramHoH ) {
#			print("Parameter Size Count: $paramHoH_Size\n") if $debug;
#			if ($paramHoH_Size <= 1) {
#				# If we're on the last parameter, 
#				# don't add a ", " (i.e., a comma followed by a space).
#				$modinst_line1 .= ".$paramHoH{$key}{'parameter'}($paramHoH{$key}{'value'})";
#			} else {
#				$modinst_line1 .= ".$paramHoH{$key}{'parameter'}($paramHoH{$key}{'value'}), ";
#			}
#			$paramHoH_Size -= 1;
#		}
#		$modinst_line1 .= ")  test";
#		$modinst_line1 = sprintf("$modinst_line1    (");
#
#		#----------------------------------------------------------------------
#		# Determine number of indent spaces:
#		#
#		#	* Tab Space = 8
#		#	* Create string with correct numer of indent spaces.
#		#
#		#----------------------------------------------------------------------
#		my ($tmpinst_len) = length($modinst_line1);
#		print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
#		my ($i) = 0;
#		my (@indent);
#		for ($i = 0; $i < $tmpinst_len; $i++) {
#			push(@indent, " ");
#		}
#		$indent_spaces = join("",@indent);
#		$TestModInst .= "$modinst_line1";
#	} else {
		#----------------------------------------------------------------------
		# Assemble First Line of Instantiation:
		#----------------------------------------------------------------------
		my ($modinst_line1) = "$test_modname        test        (";

		#----------------------------------------------------------------------
		# Determine number of indent spaces:
		#
		#	* Tab Space = 8
		#	* Assemble first line of Module Instantiation.
		#	* Create string with correct numer of indent spaces.
		#
		#----------------------------------------------------------------------
		my ($tmpinst_len) = length($modinst_line1);
		print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
		my ($i) = 0;
		my (@indent);
		for ($i = 0; $i < $tmpinst_len; $i++) {
			push(@indent, " ");
		}
		$indent_spaces = join("",@indent);
		$TestModInst .= "$modinst_line1";
#	}

	# Sort In,I/O,Out Array of Net Names Alphabetically:
	@inports = sort(@inports);
	@ioports = sort(@ioports);
	@outports = sort(@outports);

	# Create Clock Hash:
	my (%clkH);
	my (%clk_rH);

	# Find clock net(s): 
	my (@clk_indexA) = ();
	my ($u) = 0;
	for ($u = 0; $u < $numinports; $u++) {
		if ($inports[$u] =~ m/clk/i) {
			print("Clk Index: $u\n") if $debug;
			push(@clk_indexA, $u);
		}
	}
	push (@{ $clkH{ 'clk_indexA' } }, @clk_indexA);

	# Find min clk_net index:
	my (@clk_index_sortedA) = ();
	@clk_index_sortedA = sort {$a <=> $b} @clk_indexA;
	print("Clock Net (minimum index): ") if $debug;
	if (defined $clk_index_sortedA[0]) {
		print("$clk_index_sortedA[0]\n") if $debug;
	} else {
		print("NA\n") if $debug;
	}
	my ($clk_len) = scalar(@clk_index_sortedA);
	print("Number of Clock Nets: $clk_len\n") if $debug;
	push (@{ $clkH{ 'clk_index_sortedA' } }, @clk_index_sortedA);
	$clkH{ 'clk_indexA_Len' } = $clk_len;
	$clkH{ 'debug' } = $debug;

	# Print out the "clock inputs" in the instantiation:
	my ($c) = 0;
	for ($c = 0; $c < $clk_len; $c++) {
		if ($c eq 0) {
			$TestModInst .= ".$inports[$clk_index_sortedA[$c]] ($inports[$clk_index_sortedA[$c]]),\n";
		} else {
			$TestModInst .= "$indent_spaces.$inports[$clk_index_sortedA[$c]] ($inports[$clk_index_sortedA[$c]]),\n";
		}	
	}
	
	# Print out the remainder of the "inputs" in the instantiation:
	my ($v) = 0;
	for ($v = 0; $v < $numinports; $v++) {
		# Assign current index to clock hash:
		$clkH{ 'j' } = $v;

		# Check current index against all clock indices:
		if ((&checkClkIndex(\%clkH)) eq 0) {
			$TestModInst .= "$indent_spaces.$inports[$v] ($inports[$v]),\n";
		}	
	}

	# Print out the "inouts" in the instantiation:
	if ($numioports > 0) {
		$TestModInst .= "\n";
		for ($v = 0; $v < $numioports; $v++) {
			$TestModInst .= "$indent_spaces.$ioports[$v] ($ioports[$v]),\n";
		}
	}
	$TestModInst .= "\n";
	# Print out the "outputs" in the instantiation:
	for ($v = 0; $v < $numoutports; $v++) {
		if ($v eq ($numoutports-1)) {
			$TestModInst .= "$indent_spaces.$outports[$v] ($outports[$v]));\n";
		} else {
			$TestModInst .= "$indent_spaces.$outports[$v] ($outports[$v]),\n";
		}
	}

        $svH{ 'TestModInst' } = $TestModInst;

	#------------------------------------------------------------------------------ 
	# Generate: Clocks
	#------------------------------------------------------------------------------ 
	my ($clkgen1) = "";
	my ($clkgen2) = "";

	foreach my $i (@clkports) {
		$clkgen1 .= "  $i <= 1'b1;\n";	
		$clkgen2 .= "always #4 $i <= ~$i;\n";
	}
	
	$clkgen1 =~ s/\n$//;
	$clkgen2 =~ s/\n$//;

	#------------------------------------------------------------------------------ 
        # Generate the Input portion of the Module Declarations:
	#------------------------------------------------------------------------------ 
	#my (%allportsHoH) = %{ $svH{ 'modIO' } };
	my (@iolines) = ();
	my (@inlines) = ();
	my (@outlines) = ();
	my ($msb) = 0;
	my ($lsb) = 0;
	my ($templine) = "";
	# Push lines from the module declaration that match input, inout, or output into 
	# their respective arrays:
	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'port'} =~ m/(clk|clock|CLK)/) {
			$templine = "logic            $allportsHoH{$key}{'port'};\n";
			push(@inlines, $templine);
			print("Clock: $templine\n") if $debug;
		}
	}

	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} eq "input") {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				$msb -= 1;
				$templine = "logic  [$msb:$lsb]    $allportsHoH{$key}{'port'};\n";
				push(@inlines, $templine);
				print("Input: $templine\n") if $debug;
			} elsif(($allportsHoH{$key}{'width'} == 1) and !($allportsHoH{$key}{'port'} =~ m/(clk|clock|CLK)/)) {
				$templine = "logic            $allportsHoH{$key}{'port'};\n";
				push(@inlines, $templine);
				print("Input: $templine\n") if $debug;
			}
		} 
	}

	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} eq "inout") {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				$msb -= 1;
				$templine = "wire  [$msb:$lsb]    $allportsHoH{$key}{'port'};\n";
				push(@iolines, $templine);
				print("InOut: $templine\n") if $debug;
			} else {
				$templine = "wire            $allportsHoH{$key}{'port'};\n";
				push(@iolines, $templine);
				print("InOut: $templine\n") if $debug;
			}
		} 
	}

	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} eq "output") {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				$msb -= 1;
				$templine = "logic  [$msb:$lsb]    $allportsHoH{$key}{'port'};\n";
				push(@outlines, $templine);
				print("Output: $templine\n") if $debug;
			} else {
				$templine = "logic            $allportsHoH{$key}{'port'};\n";
				push(@outlines, $templine);
				print("Output: $templine\n") if $debug;
			}
		} 
	}

	my ($inDecl) = join("",@inlines);
	my ($ioDecl) = join("",@iolines);
	my ($outDecl) = join("",@outlines);

	print("\n\nInput Declarations: \n$inDecl") if $debug;
	print("InOut Declarations: \n$ioDecl") if $debug;
	print("Output Declarations: \n$outDecl\n") if $debug;

	#------------------------------------------------------------------------------ 
	# Build up Top-Level Test Bench File.
	#------------------------------------------------------------------------------ 
	my $tbTopBody=<<"EOF";
/******************************************************************************
 vim:tw=160:softtabstop=4:shiftwidth=4:et:syn=verilog:
*******************************************************************************

 $tbTopFile module

*******************************************************************************

 COMPANY Confidential Copyright � $yearR

*******************************************************************************

 created on:	$monthR/$day/$yearR 
 created by:	$username
 last edit on:	\$DateTime: \$ 
 last edit by:	\$Author: \$
 revision:      \$Revision: \$
 comments:      Generated

*******************************************************************************
 //Project// (//Number//)

 This module tests the $file_sv module.

******************************************************************************/
`include "../../../$file_sv"
`include "$tbTestFile"
`timescale        1ns/1ps

module top;  // top-level netlist to connect testbench to dut
  
timeunit 1ns; timeprecision 1ps;

// *** Input to UUT ***
$inDecl
// *** Inouts to UUT ***
$ioDecl
// *** Outputs from UUT ***
$outDecl

$modinst

$TestModInst


// clk generators
initial begin
$clkgen1
end

// Generate clock:
$clkgen2


endmodule : top


EOF

	$svH{ 'tbTopFile' } = $tbTopFile;
	$svH{ 'tbTopBody' } = $tbTopBody;

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genTBTestHeader {
	#------------------------------------------------------------------------------ 
	# Print Test Bench Module Header:
	#
	#  The sub-routine printTBHeader() will print out the SystemVerilog test bench 
	#  module instantiation. 
	#
	#  Usage: $sv_rH = printTBHeader($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my $file_sv = $svH{'file'};
	my $day = $svH{'day'};
	my $month = $svH{'month'};
	my $username = $svH{'username'};
	my $year = $svH{'year'};
	my ($debug) = $svH{'debug'};   # Print out Debug Info.

	# Fix month, day, year:
	my $monthR = $month+1;
	my $yearR = $year+1900;

	# Get Filename:
	# strip .v from filename
	my $file = $file_sv;
        $file =~ s/\x2esv//;
        $file =~ s/\x2e//g;
        $file =~ s/\x2f//g;
	my $test_file = join "_", "test", $file;
	my $tbTestFile = join ".",$test_file,"sv";

	my $tbTestHead=<<"EOF";
/******************************************************************************
 vim:tw=160:softtabstop=4:shiftwidth=4:et:syn=verilog:
*******************************************************************************

 $tbTestFile module

*******************************************************************************

 COMPANY Confidential Copyright � $yearR

*******************************************************************************

 created on:	$monthR/$day/$yearR 
 created by:	$username
 last edit on:	\$DateTime: \$ 
 last edit by:	\$Author: \$
 revision:      \$Revision: \$
 comments:      Generated

*******************************************************************************
 //Project// (//Number//)

 This module implements the test bench for the $file_sv module.

	// enter detailed description here;


******************************************************************************/
`timescale        1ns/1ps


EOF

	$svH{ 'tbTestFile' } = $tbTestFile;
	$svH{ 'tbTestHead' } = $tbTestHead;

	#------------------------------------------------------------------------------ 
        #
        # Return data to user
        #
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genTBTestBody {
	#------------------------------------------------------------------------------ 
	# Print Test Bench Module Body:
	#
	#  The sub-routine printTBBody() will print out the body of the SystemVerilog 
	#  module test bench.
	#
	#  Usage: $sv_rH = printTBBody($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my $modname = $svH{ 'modName' };
	my $test_modname = join "_", "test", $modname;
	my ($debug) = $svH{'debug'};   # Print out Debug Info.

	#----------------------------------------------------------------------
	# Determine number of indent spaces:
	#
	#	* Tab Space = 8
	#	* Create string with correct numer of indent spaces.
	#
	#----------------------------------------------------------------------
	my ($indent_spaces) = "";
	my ($modinst_line1) = "module    $test_modname        (/";
	my ($tmpinst_len) = length($modinst_line1);
	print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
	my ($i) = 0;
	my (@indent);
	for ($i = 0; $i < $tmpinst_len; $i++) {
		push(@indent, " ");
	}
	$indent_spaces = join("",@indent);
	$indent_spaces =~ s/  //;
	my $indentCparen = $indent_spaces;
	$indentCparen =~ s/ //;

	#------------------------------------------------------------------------------ 
        # Generate the Input portion of the Module Declarations:
	#------------------------------------------------------------------------------ 
	my (%allportsHoH) = %{ $svH{ 'modIO' } };
	my (@iolines) = ();
	my (@inlines) = ();
	my (@outlines) = ();
	my ($msb) = 0;
	my ($lsb) = 0;
	my ($templine) = "";
	# Push lines from the module declaration that match input, inout, or output into 
	# their respective arrays:
	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'port'} =~ m/(clk|clock|CLK)/) {
			$templine = "$indent_spaces input   logic           $allportsHoH{$key}{'port'},\n";
			push(@inlines, $templine);
			print("Clock: $templine\n") if $debug;
		}
	}

	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} eq "input") {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				$msb -= 1;
				$templine = "$indent_spaces output  logic  [$msb:$lsb]    $allportsHoH{$key}{'port'},\n";
				push(@outlines, $templine);
				print("Input: $templine\n") if $debug;
			} elsif(($allportsHoH{$key}{'width'} == 1) and !($allportsHoH{$key}{'port'} =~ m/(clk|clock|CLK)/)) {
				$templine = "$indent_spaces output  logic            $allportsHoH{$key}{'port'},\n";
				push(@outlines, $templine);
				print("Input: $templine\n") if $debug;
			}
		} 
	}

	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} eq "inout") {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				$msb -= 1;
				$templine = "$indent_spaces inout   wire [$msb:$lsb]    $allportsHoH{$key}{'port'},\n";
				push(@iolines, $templine);
				print("InOut: $templine\n") if $debug;
			} else {
				$templine = "$indent_spaces inout   wire           $allportsHoH{$key}{'port'},\n";
				push(@iolines, $templine);
				print("InOut: $templine\n") if $debug;
			}
		} 
	}

	for my $key ( sort(keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} eq "output") {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				$msb -= 1;
				$templine = "$indent_spaces input   logic  [$msb:$lsb]    $allportsHoH{$key}{'port'},\n";
				push(@inlines, $templine);
				print("Output: $templine\n") if $debug;
			} else {
				$templine = "$indent_spaces input   logic           $allportsHoH{$key}{'port'},\n";
				push(@inlines, $templine);
				print("Output: $templine\n") if $debug;
			}
		} 
	}

	my ($inDecl) = join("",@inlines);
	my ($ioDecl) = join("",@iolines);
	my ($outDecl) = join("",@outlines);
	$outDecl =~ s/,\n$//;

	print("\n\nInput Declarations: \n$inDecl") if $debug;
	print("InOut Declarations: \n$ioDecl") if $debug;
	print("Output Declarations: \n$outDecl\n") if $debug;

	#------------------------------------------------------------------------------ 
        # Build up Test Bench Module Body:
	#------------------------------------------------------------------------------ 
	my $tbTestBody=<<"EOF";
module    $test_modname        (//** Inputs **
$inDecl
$indent_spaces //** InOuts **
$ioDecl
$indent_spaces //** Outputs **
$outDecl
$indentCparen );

// *** Local Variable Declarations ***
// Local Parameter Declarations:
// N/A
// Local Logic Declarations:
// N/A
// Local Event Declarations:
event           start_Monitor;

// *** Local Integer Declarations ***
integer		results_file;	// for writing signal values

// initial block
initial
begin
    #1;
    \$timeformat(-9, 0, " ns", 9);

    /*************************************************************************/
    /**
        Open results file, write header:
            
            1. Setup top-level results file.

    **************************************************************************/
    // open results file, write header
    results_file=\$fopen("../out/top_results.txt");
    \$fdisplay(results_file, " $test_modname testbench results");
    \$fwrite(results_file, "\\n");
    DisplayHeader;
    
    /*************************************************************************/
    /**
        Initialize signals:
            
            1. Set Default Variables
            2. Force registers to safe state

    **************************************************************************/
    // initialize signals
    \$display("Initialize Signals");
    rst <= 0;

    VarClockDelay(.delay(100));
    ->start_Monitor;              //trigger routine to monitor 
    CpuReset;
	
	// Add more test bench stuff here
	
	\$fclose(results_file);
	\$stop;
end

// Add more test bench stuff here as well
always 
begin: Monitor
  \$timeformat(-9, 0, " ns", 9);
  \@(start_Monitor)
  forever @(negedge clk)
  begin
    \$fstrobe(results_file,"At \%%t:    \\t\%%h\\t\%%h",\$realtime, data_in, data_out);
  end
end


// Test Bench Tasks
task DisplayHeader;
  \$fdisplay(results_file,"                       data_in      data_out ");
  \$fdisplay(results_file,"                 ============================");
endtask    

/****************************************************************************/
/**
* CpuReset - Perform a board level reset.
*
* \@param    none
*
* \@return   none
*
* \@note   
*
*****************************************************************************/
task CpuReset;
begin
    \$display("Perform a Reset");
    \@ (posedge clk);
    \$display("Set Reset High");
    rst = 1;
    \@ (posedge clk);
    \$display("Wait for 10 clock cycles");
    repeat(10) @ (posedge clk);
    \$display("Set Reset Low");
    rst = 0;
    \@ (posedge clk);
end
endtask


/****************************************************************************/
/**
* VarClockDelay - Variable delay block in increments of clk.
*
* \@param    delay - Number of Clock Cyles to Insert.
*
* \@return   none
*
* \@note   
*
*   This task allows delay to be added between test bench code without 
*   ending on a non-integer multiple of the clock.
*
*****************************************************************************/
task VarClockDelay (input int delay);
string delay_str;
begin
    delay_str.itoa(delay);
    \$display("Wait for \%%s clock cycles", delay_str);
    for(int i=0; i < delay; i++)
    begin
        \@ (posedge clk);
    end
end
endtask

endmodule : $test_modname

EOF

	$svH{ 'tbmodName' } = $test_modname;
	$svH{ 'tbTestBody' } = $tbTestBody;
 
	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genTBTestFile {
	#------------------------------------------------------------------------------ 
	# Generate the SystemVerilog Test Bench:
	#
	#  The sub-routine genTBTestFile() will generate a set of Test Bench
	#  files based on the SystemVerilog module provided by the user. For 
	#  example, if the user provides a SystemVerilog module called 'mymodule'
	#  then the following files will be generated:
	#      
	#      - top.sv
	#      - test_mymodule.sv
	#  
	#  The file 'top.sv' instantiates both the UUT (mymodule.sv) and the 
	#  Test Bench (test_mymodule.sv). All nets labeled with either 'clk' or
	#  'clock' will be generated using an always block in the following form:
	#  
	#      // clk generators
	#      initial begin
	#        clk <= 1'b1;
	#      end
	#      
	#      // Generate clock:
	#      always #4 clk <= ~clk;
	#  
	#  All nets in the 'mymodule.sv' file are declared in the top.v file.
	#  
	#  The file 'test_mymodule.sv' contains the same number of i/o as 
	#  'mymodule.sv' with inputs and outputs swapped, except for clock 
	#  signals.
	#
	#  Usage: $sv_rH = genTBTestFile(\%svH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Open $file and stuff it into an array.
	#------------------------------------------------------------------------------ 
	$sv_rH = getFile($sv_rH);

	#------------------------------------------------------------------------------ 
	# Search through $file for keywords.
	#------------------------------------------------------------------------------ 
	$sv_rH = parseFile($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module Declaration:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModDecl($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module Name:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModName($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module I/O:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModIO($sv_rH);

	#------------------------------------------------------------------------------ 
	# Generate Module Instantiation:
	#------------------------------------------------------------------------------ 
	$sv_rH = genModInst($sv_rH);

	#------------------------------------------------------------------------------ 
	# Generate Header and Body of Test Bench File
	#------------------------------------------------------------------------------ 
	$sv_rH = genTBTestHeader($sv_rH);
	$sv_rH = genTBTestBody($sv_rH);
	$sv_rH = genTBTop($sv_rH);
	%svH = %{ $sv_rH }; # De-reference Verilog hash.

	#------------------------------------------------------------------------------ 
	# Get Filename, Header and Body of UCF File
	#------------------------------------------------------------------------------ 
	my $tbTestFile = $svH{ 'tbTestFile' };
	my $tbTestHead  = $svH{ 'tbTestHead' };;
	my $tbTestBody  = $svH{ 'tbTestBody' };;
	my $tbTopFile = $svH{ 'tbTopFile' };
	my $tbTopBody  = $svH{ 'tbTopBody' };;


	#------------------------------------------------------------------------------ 
	# Create File Handle for the new UCF file, and check for existing file.
	#------------------------------------------------------------------------------
	open(outF, ">", $tbTestFile) or dienice ("$tbTestFile open failed");
	
	#------------------------------------------------------------------------------ 
	# Print Header and Body to UCF File Handle
	#------------------------------------------------------------------------------ 
	printf(outF "$tbTestHead");
	printf(outF "$tbTestBody");
	printf(outF "\n\n");

	close(outF);

	#------------------------------------------------------------------------------ 
	# Create File Handle for the new UCF file, and check for existing file.
	#------------------------------------------------------------------------------
	open(out2F, ">", $tbTopFile) or dienice ("$tbTopFile open failed");
	
	#------------------------------------------------------------------------------ 
	# Print Header and Body to UCF File Handle
	#------------------------------------------------------------------------------ 
	printf(out2F "$tbTopBody");
	printf(out2F "\n\n");

	close(out2F);
	
	print("\n");	
	print("Test Bench File(s): $tbTestFile and $tbTopFile are ready for use.\n");
	print("\n");	

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;
}

sub genUCFHeader {
	#------------------------------------------------------------------------------ 
	# Print UCF File Header:
	#
	#  The sub-routine printUCFHeader() will print out the UCF File Header. 
	#
	#  Usage: $sv_rH = printUCFHeader($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;	    # Read in user's variable.

	my (%svH) = %{ $sv_rH }; # De-reference Verilog hash.

	my $file_sv = $svH{'file'};
	my $day = $svH{'day'};
	my $month = $svH{'month'};
	my $username = $svH{'username'};
	my $year = $svH{'year'};
	my ($debug) = $svH{'debug'};   # Print out Debug Info.

	# Fix month, day, year:
	my $monthR = $month+1;
	my $yearR = $year+1900;

	# Get Filename:
	# strip .v from filename
	my $file = $file_sv;
        $file =~ s/\x2esv//;
        $file =~ s/\x2e//g;
        $file =~ s/\x2f//g;
	my $ucf_file = join ".",$file,"ucf";

	my $ucfhead=<<"EOF";
#******************************************************************
#
# $ucf_file module
#
#******************************************************************
#
# COMPANY Confidential Copyright � $yearR
#
#******************************************************************
#
# created on:	$monthR/$day/$yearR 
# created by:	$username
# last edit on:	\$DateTime: \$ 
# last edit by:	\$Author: \$
# revision:     \$Revision: \$
# comments:     Generated
#
# board name:		<board name> Board
# board number:		Pxxx
# board revision:	A
# device mpn:		XC3S1400A-4FGG484C
# 
#******************************************************************

#--------------------------------------
# T I M I N G   C O N S T R A I N T S
#--------------------------------------
# N/A

#--------------------------------------
# I P  C O R E  C O N S T R A I N T S
#--------------------------------------
# N/A

#-------------------------------------------------
# P L A C E  &  R O U T E  C O N S T R A I N T S
#-------------------------------------------------
# N/A

#---------------------------------------------------
# T I M I N G   I G N O R E  C O N S T R A I N T S
#---------------------------------------------------
# N/A

EOF

	$svH{ 'ucffile' } = $ucf_file;
	$svH{ 'ucfhead' } = $ucfhead;

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}


sub genUCFBody {
	#------------------------------------------------------------------------------ 
	# Print UCF Body:
	#
	#  The sub-routine printUCFBody() will print out the body of the UCF File.
	#
	#  Usage: $sv_rH = printUCFBody($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.


	#------------------------------------------------------------------------------ 
        # Build up Test Bench Module Body:
	#------------------------------------------------------------------------------ 

	my $ucfbody=<<"EOF";
#--------------------------------------
# P I N   A S S I G N M E N T S      
#--------------------------------------

EOF
	my (%allportsHoH) = %{ $svH{ 'modIO' } };
	my ($msb) = 0;
	my ($i) = 0;
	# Push lines from the module declaration that match input, inout, or output into 
	# their respective arrays:
	
	for my $key ( sort (keys %allportsHoH) ) {
		if ($allportsHoH{$key}{'direction'} =~ m/input/) {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				for ($i = 0; $i < $msb; $i++) {
					$ucfbody .= "NET \"$allportsHoH{$key}{'port'}\[$i\]\"\t\tLOC = \"\" | IOSTANDARD = LVCMOS33;\n";
				}
			} else {
				$ucfbody .= "NET \"$allportsHoH{$key}{'port'}\"\t\tLOC = \"\" | IOSTANDARD = LVCMOS33;\n";
			}
		} elsif ($allportsHoH{$key}{'direction'} =~ m/inout/) {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				for ($i = 0; $i < $msb; $i++) {
					$ucfbody .= "NET \"$allportsHoH{$key}{'port'}\[$i\]\"\t\tLOC = \"\" | IOSTANDARD = LVCMOS33;\n";
				}
			} else {
				$ucfbody .= "NET \"$allportsHoH{$key}{'port'}\"\t\tLOC = \"\" | IOSTANDARD = LVCMOS33;\n";
			}
		} elsif ($allportsHoH{$key}{'direction'} =~ m/output/) {
			if ($allportsHoH{$key}{'width'} > 1) {
				$msb = $allportsHoH{$key}{'width'};
				for ($i = 0; $i < $msb; $i++) {
					$ucfbody .= "NET \"$allportsHoH{$key}{'port'}\[$i\]\"\t\tLOC = \"\" | IOSTANDARD = LVCMOS33;\n";
				}
			} else {
				$ucfbody .= "NET \"$allportsHoH{$key}{'port'}\"\t\tLOC = \"\" | IOSTANDARD = LVCMOS33;\n";
			}
		}
	}

	$svH{ 'ucfbody' } = $ucfbody;
 
	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genUCFFile {
	#------------------------------------------------------------------------------ 
	# Generate Xilinx UCF File:
	#
	#  The sub-routine genUCFFile() will generate a Xilinx User Constraints File (UCF)
	#  based on the SystemVerilog module provided by the user. For 
	#  example, if the user provides a Verilog HDL module called 'mymodule'
	#  then the following files will be generated:
	#  
	#      - mymodule.ucf
	#  
	#  The file 'mymodule.ucf' inserts net location and IO Standard declarations 
	#  for all I/O in 'mymodule.sv'. The location keyword 'LOC' defaults to empty, 
	#  and the 'IOSTANDARD' defaults to 'LVCMOS33'.
	#
	#  Usage: $sv_rH = genUCFFile(\%svH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my ($debug) = $svH{'debug'};	# Print out Debug Info.

	#------------------------------------------------------------------------------ 
	# Open $file and stuff it into an array.
	#------------------------------------------------------------------------------ 
	$sv_rH = getFile($sv_rH);

	#------------------------------------------------------------------------------ 
	# Search through $file for keywords.
	#------------------------------------------------------------------------------ 
	$sv_rH = parseFile($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module Declaration:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModDecl($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module Name:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModName($sv_rH);
	
	#------------------------------------------------------------------------------ 
	# Get Module I/O:
	#------------------------------------------------------------------------------ 
	$sv_rH = getModIO($sv_rH);

	#------------------------------------------------------------------------------ 
	# Generate Header and Body of UCF File
	#------------------------------------------------------------------------------ 
	$sv_rH = genUCFHeader($sv_rH);
	$sv_rH = genUCFBody($sv_rH);
	%svH = %{ $sv_rH }; # De-reference Verilog hash.

	#------------------------------------------------------------------------------ 
	# Get Filename, Header and Body of UCF File
	#------------------------------------------------------------------------------ 
	my $ucf_file = $svH{ 'ucffile' };
	my $ucfhead  = $svH{ 'ucfhead' };;
	my $ucfbody  = $svH{ 'ucfbody' };;


	#------------------------------------------------------------------------------ 
	# Create File Handle for the new UCF file, and check for existing file.
	#------------------------------------------------------------------------------
	open(outF, ">", $ucf_file) or dienice ("$ucf_file open failed");
	
	#------------------------------------------------------------------------------ 
	# Print Header and Body to UCF File Handle
	#------------------------------------------------------------------------------ 
	printf(outF "$ucfhead");
	printf(outF "$ucfbody");
	printf(outF "\n\n");

	close(outF);
	
	print("\n");	
	print("UCF File: $ucf_file is ready for use.\n");
	print("\n");	

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;
}

sub genSVLowModule {
	#------------------------------------------------------------------------------ 
	# Generate SystemVerilog Lower Module File:
	#
	#  The sub-routine genSVLowModule() will generate an empty lower-level 
	#  SystemVerilog module. A standard header is used containing an empty description 
	#  and the new module name. The module contains 3 input signals: clk, rst_n, 
	#  and data_in[15:0]. The module also contains 1 output signal: data_out[15:0].
	#
	#  Usage: $sv_rH = genSVLowModule($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my $file_sv = $svH{'file'};
	my $day = $svH{'day'};
	my $month = $svH{'month'};
	my $username = $svH{'username'};
	my $year = $svH{'year'};
	my ($debug) = $svH{'debug'};   # Print out Debug Info.

	# Fix month, day, year:
	my $monthR = $month+1;
	my $yearR = $year+1900;

	# Get Filename:
	# strip .v from filename
	my $modname = $file_sv;
        $modname =~ s/\x2esv//;
        $modname =~ s/\x2e//g;
        $modname =~ s/\x2f//g;
	
	#----------------------------------------------------------------------
	# Determine number of indent spaces:
	#
	#	* Tab Space = 8
	#	* Create string with correct numer of indent spaces.
	#
	#----------------------------------------------------------------------
	my ($indent_spaces) = "";
	my ($modinst_line1) = "module    $modname        (/";
	my ($tmpinst_len) = length($modinst_line1);
	print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
	my ($i) = 0;
	my (@indent);
	for ($i = 0; $i < $tmpinst_len; $i++) {
		push(@indent, " ");
	}
	$indent_spaces = join("",@indent);
	$indent_spaces =~ s/  //;
	my $indentCparen = $indent_spaces;
	$indentCparen =~ s/ //;


	my $svLowHead=<<"HEAD";
/******************************************************************************
 vim:tw=160:softtabstop=4:shiftwidth=4:et:syn=verilog:
*******************************************************************************

 $file_sv module

*******************************************************************************

 COMPANY Confidential Copyright � $yearR

*******************************************************************************

 created on:	$monthR/$day/$yearR 
 created by:	$username
 last edit on:	\$DateTime: \$ 
 last edit by:	\$Author: \$
 revision:      \$Revision: \$
 comments:      Generated

*******************************************************************************
 //Project// (//Number//)

 This module implements the ... in the //name// fpga.

	// enter detailed description here;


******************************************************************************/
`timescale        1ns/1ps

module    $modname        (// *** Inputs ***
HEAD

	$svLowHead .= "$indent_spaces input	logic	     	clk,		// System Clock (xxx MHz)\n";
	$svLowHead .= "$indent_spaces input	logic	     	rst_n,		// System Reset (Active Low)\n";
	$svLowHead .= "$indent_spaces input	logic	[15:0]	data_in,	// Data In.\n";
	$svLowHead .= "\n";
	$svLowHead .= "$indent_spaces // *** Outputs ***\n";
	$svLowHead .= "$indent_spaces output	logic	[15:0]	data_out	// Data Out.\n";
	$svLowHead .= "$indentCparen );\n";
	$svLowHead .= "\n";
	$svLowHead .= "\n";
	$svLowHead .= "// *** Local Variable Declarations ***\n";
	$svLowHead .= "// Local Parameter Declarations:\n";
	$svLowHead .= "// N/A\n";
	$svLowHead .= "// Local Logic Declarations:\n";
	$svLowHead .= "// N/A\n";
	$svLowHead .= "\n";
	$svLowHead .= "endmodule : $modname\n";


	$svH{ 'svLowHead' } = $svLowHead;

	#------------------------------------------------------------------------------ 
	# Create File Handle for the new SystemVerilog file, and check for existing file.
	#------------------------------------------------------------------------------
	if (-e $file_sv) {
		print("Oops! A file called '$file_sv' already exists.\n");
		exit 1;
	} else {
		open(outF, ">", $file_sv);
	
		#----------------------------------------------------------------------
		# Print Header and Body to UCF File Handle
		#----------------------------------------------------------------------
		printf(outF "$svLowHead");
		printf(outF "\n\n");

		close(outF);
	
		print("\nNew SystemVerilog File: $file_sv is ready for use.\n\n");
	}

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}

sub genSVTopModule {
	#------------------------------------------------------------------------------ 
	# Generate SystemVerilog Top-Level Module File:
	#
	#  The sub-routine genSVTopModule() will generate an empty top-level 
	#  SystemVerilog module. A standard header is used containing an empty description 
	#  and the new module name. The module contains 3 input signals: clk, rst_n, 
	#  and data_in[15:0]. The module also contains 1 output signal: data_out[15:0].
	#
	#  Usage: $sv_rH = genSVTopModule($sv_rH);
	#
	#------------------------------------------------------------------------------ 
	my ($sv_rH) = shift;		# Read in user's variable.
	my (%svH) = %{ $sv_rH };	# De-reference hash.
	my $file_sv = $svH{'file'};
	my $day = $svH{'day'};
	my $month = $svH{'month'};
	my $username = $svH{'username'};
	my $year = $svH{'year'};
	my ($debug) = $svH{'debug'};   # Print out Debug Info.

	# Fix month, day, year:
	my $monthR = $month+1;
	my $yearR = $year+1900;

	# Get Filename:
	# strip .v from filename
	my $modname = $file_sv;
        $modname =~ s/\x2esv//;
        $modname =~ s/\x2e//g;
        $modname =~ s/\x2f//g;
	
	#----------------------------------------------------------------------
	# Determine number of indent spaces:
	#
	#	* Tab Space = 8
	#	* Create string with correct numer of indent spaces.
	#
	#----------------------------------------------------------------------
	my ($indent_spaces) = "";
	my ($modinst_line1) = "module    $modname        (/";
	my ($tmpinst_len) = length($modinst_line1);
	print("Number of Indent Spaces: $tmpinst_len\n") if $debug;
	my ($i) = 0;
	my (@indent);
	for ($i = 0; $i < $tmpinst_len; $i++) {
		push(@indent, " ");
	}
	$indent_spaces = join("",@indent);
	$indent_spaces =~ s/  //;
	my $indentCparen = $indent_spaces;
	$indentCparen =~ s/ //;

	my $svTopHead=<<"HEAD";
/******************************************************************************
 vim:tw=160:softtabstop=4:shiftwidth=4:et:syn=verilog:
*******************************************************************************

 $file_sv module

*******************************************************************************

 COMPANY Confidential Copyright � $yearR

*******************************************************************************

 created on:	$monthR/$day/$yearR 
 created by:	$username
 last edit on:	\$DateTime: \$ 
 last edit by:	\$Author: \$
 revision:      \$Revision: \$
 comments:      Generated

 board name:		//Name// Board
 board number:		Pxxx
 board revision:	A
 device mpn:		XCxxxx-4FG676C
 
*******************************************************************************
 //Project// (//Number//)

 This module is the top level for the $modname FPGA
 on the ... board for the //Project//.

 This design performs the following functions:

	// enter functions here;

 The sub-modules included in this design are:

	// enter sub-modules here;

 The physical constraints file for the ... FPGA is in the 
 file:

	$modname.ucf

******************************************************************************/
`timescale        1ns/1ps

module    $modname        (// *** Inputs ***
HEAD

	$svTopHead .= "$indent_spaces input	logic	     	clk,		// System Clock (xxx MHz)\n";
	$svTopHead .= "$indent_spaces input	logic	     	rst_n,		// System Reset (Active Low)\n";
	$svTopHead .= "$indent_spaces input	logic	[15:0]	data_in,	// Data In.\n";
	$svTopHead .= "\n";
	$svTopHead .= "$indent_spaces // *** Outputs ***\n";
	$svTopHead .= "$indent_spaces output	logic	[15:0]	data_out	// Data Out.\n";
	$svTopHead .= "$indentCparen );\n";
	$svTopHead .= "\n";
	$svTopHead .= "\n";
	$svTopHead .= "// *** Local Variable Declarations ***\n";
	$svTopHead .= "// Local Parameter Declarations:\n";
	$svTopHead .= "// N/A\n";
	$svTopHead .= "// Local Logic Declarations:\n";
	$svTopHead .= "// N/A\n";
	$svTopHead .= "\n";
	$svTopHead .= "endmodule : $modname\n";


	$svH{ 'svTopHead' } = $svTopHead;

	#------------------------------------------------------------------------------ 
	# Create File Handle for the new SystemVerilog file, and check for existing file.
	#------------------------------------------------------------------------------
	if (-e $file_sv) {
		print("Oops! A file called '$file_sv' already exists.\n");
		exit 1;
	} else {
		open(outF, ">", $file_sv);
	
		#----------------------------------------------------------------------
		# Print Header and Body to UCF File Handle
		#----------------------------------------------------------------------
		printf(outF "$svTopHead");
		printf(outF "\n\n");

		close(outF);
	
		print("\nNew SystemVerilog File: $file_sv is ready for use.\n\n");
	}

	#------------------------------------------------------------------------------ 
        # Return data to user
	#------------------------------------------------------------------------------ 
        return \%svH;

}



=pod

=head1 NAME

SystemVerilogTools - Package to parse and create SystemVerilog files

=head1 VERSION

Version 1.0

=head1 ABSTRACT

SystemVerilogTools - Package to parse and create SystemVerilog files

=head1 SYNOPSIS

    use SystemVerilogTools;

    #******************************************************************
    # Initialize SystemVerilog Hash:
    #******************************************************************
    my (%svH, $sv_rH);
    $svH{ 'username' } = $author;
    $svH{ 'file' } = $file;
    $svH{ 'day' } = $day;
    $svH{ 'month' } = $month;
    $svH{ 'year' } = $year;
    $svH{ 'debug' } = $debug;

    # Generate Top-Level Module
    $sv_rH = genSVTopModule(\%svH);

    # Generate Low-Level Module
    $sv_rH = genSVLowModule(\%svH);

    # Generate Module Instantiateion
    $sv_rH = printModInst(\%svH);

    # Generate UCF File from Module
    $sv_rH = genUCFFile(\%svH);

    # Generate Test Benches
    $sv_rH = genTBTestFile(\%svH);

=head1 DESCRIPTION

The SystemVerilogTools is used to generate or parse SystemVerilog files.

=head2 printModInst:

The sub-routine printModInst() will print out the SystemVerilog module 
instantiation. The SystemVerilog module must use an ANSI-C style module
declaration. An example module instantiation is shown below:

    mymodule        _mymodule  (.clk (clk),
				.data_in (data_in),
                                .rst_n (rst_n),

                                .data_out (data_out));

=head2 genTBTestFile:

The sub-routine genTBTestFile() will generate a set of Test Bench
files based on the SystemVerilog module provided by the user. For 
example, if the user provides a SystemVerilog module called 'mymodule'
then the following files will be generated:
    
    - top.sv
    - test_mymodule.sv

The file 'top.sv' instantiates both the UUT (mymodule.sv) and the 
Test Bench (test_mymodule.sv). All nets labeled with either 'clk' or
'clock' will be generated using an always block in the following form:

    // clk generators
    initial begin
      clk <= 1'b1;
    end
    
    // Generate clock:
    always #4 clk <= ~clk;

All nets in the 'mymodule.sv' file are declared in the 'top.sv' file.

The file 'test_mymodule.sv' contains the same number of i/o as 
'mymodule.sv' with inputs and outputs swapped, except for clock 
signals.

=head2 genUCFFile:

The sub-routine genUCFFile() will generate a Xilinx User Constraints File (UCF)
based on the SystemVerilog module provided by the user. For 
example, if the user provides a SystemVerilog module called 'mymodule'
then the following files will be generated:

    - mymodule.ucf

The file 'mymodule.ucf' inserts net location and IO Standard declarations 
for all I/O in 'mymodule.sv'. The location keyword 'LOC' defaults to empty, 
and the 'IOSTANDARD' defaults to 'LVCMOS33'.

=head2 genSVLowModule:

The sub-routine genSVLowModule() will generate an empty lower-level SystemVerilog 
module. A standard header is used containing an empty description and the 
new module name. The module contains 3 input signals: clk, rst_n, and data_in[15:0].
The module also contains 1 output signal: data_out[15:0].

=head2 genSVTopModule:

The sub-routine genSVTopModule() will generate an empty top-level SystemVerilog 
module. A standard header is used containing an empty description and the 
new module name. The module contains 3 input signals: clk, rst_n, and data_in[15:0].
The module also contains 1 output signal: data_out[15:0].

=head2 EXPORT
 
None at the moment.

=head1 INSTALLATION

   perl Makefile.PL  # build the Makefile
   make              # build the package
   make install      # Install package

=head1 SEE ALSO

Example scripts can be accessed at the following website:

    * http://www.jwebb-design.com/ee/howto/using_perl_with_sv.shtml

=head1 AUTHOR

Jeremy Webb, E<lt>jeremy.webb@jwebb-consulting.com<gt>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2017 by Jeremy Webb

=cut
