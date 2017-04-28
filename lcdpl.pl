#!/usr/bin/perl -w
#
#########################################################################################
#
# Purpose: Build a program that takes a file as input and displays it 
#          in a 7 segment display akin to a calc display.
#
#          - Always use strict and -w warnings. 
#          - Keep POD up to date - ALWAYS!
#          - Use debug where possible, helps ppl coming behind you. 
#          - Be consistent with var naming conventions aBcDe or a_b_c_d_e
#          - Remember TIMTOADY
#
# Functions ( See POD ):
#          rescaleDigit($$$)  
#          dumpArrays($)
#          setUpInitialDigits()
#
##########################################################################################

use strict;
use Getopt::Long;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

#Prototypes so I can put subroutines at the bottom of the script. 
sub rescaleDigit($$$);
sub dumpArrays($);
sub setUpInitialDigits();

###Check for valid number of arguments, here we expect one. 
my $argc=$#ARGV+1;

#Lets set up some vars
my ( 
    $gDebugLvl,
    $gInputString,
    $gScaleFactor
) = undef;

#Deal with the command line. So bug level,scale and string if we want to read from cmdline and not a file. (Handy for testing)
GetOptions("d=i"        => \$gDebugLvl,
            "i=i"  => \$gScaleFactor,
            "s=s"  => \$gInputString
);

#Open and read the file. 
my $line = undef;
if (! $gInputString ) {
    my $gInputFile = $ARGV[0];
    if (! $gInputFile ) {
        warn "WARN - No input file supplied, exiting ... ";
        exit(4);
    }
    print "Input file is $gInputFile\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 1 ));
    open(FILE,"$gInputFile") or die "Could not open file $gInputFile$!\n";
    $line = <FILE>;
    chomp($line);
    print "$line\n" if (( defined $line ) && (( defined $gDebugLvl ) && ( $gDebugLvl == 1 )));
}

#If we've not been supplied cmd line params get these from the file. 
if ((! $gInputString ) && (! $gScaleFactor )) {
    ($gScaleFactor, $gInputString) = split / /, $line;
}

#DEBUG
print "Debug Level: $gDebugLvl\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 1 ));
print "Scale Factor: $gScaleFactor\n" if (( $gScaleFactor ) && ( defined $gDebugLvl ) && ( $gDebugLvl == 1 ));
print "Input String: $gInputString\n" if (( $gInputString ) && ( defined $gDebugLvl ) && ( $gDebugLvl == 1 ));

#Check if we have anything other than inegers in the input string
#Used http://www.perlmonks.org/?node_id=955846
if (! looks_like_number($gInputString)) {
    warn "WARN - Looks like there is a char in the inpout string that is not a valid integer 0 .. 9 exiting ... ";
    exit(3);
}

#Check the scaling figure, if this is > 10 or < 1 reject and exit. 
if (( $gScaleFactor > 10 ) || ( $gScaleFactor < 1 )) {
    warn "WARN - The scaling supplied is outwith the required bounds, N value must be 1 <= N <= 10 exiting ....";
    exit(1);
}

#Check the len of the inoput string, if this is > 25 or < 1 reject and exit. 
if (( length($gInputString) > 25 ) || ( $gInputString < 1 )) {
    warn "WARN - The length of the integral supplied is outwith the required bounds, M value must be 1 <= N <= 25 exiting ....";
    exit(2);
}

#Set up the initial digits, i.e. with a scale of 1
my $gDigitalStore = setUpInitialDigits();
my @gDigitalStore = @$gDigitalStore;

#To keep track of what we have already resized. 
my %alreadyScaled = ( 0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0 );

#Treat the input as a string, get the bits of the vector we need for each char and add it to an output array. 
my $inputLength = length($gInputString);
my $count = 0;
my $level = 0;
my $inputDigit = undef;
my $digitDepth = ( $gScaleFactor * 2 ) + 3; #lets keep the indexes aligned. This needs to grow with the scaling. 
print "digitDepth: $digitDepth\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 4 ));

my @finalOutput = (); #Multi dimensional array will used to store final output.
my $finalOutputRef = \@finalOutput;

#Iterate thru the input string one char at a time and store the 'vectors' of each horizontal row 
while ( $count < $inputLength ) {
    my @digitOutput = ();
    while ( $level < $digitDepth ) {
        $inputDigit = substr $gInputString, $count, 1;

        #Some debug
        print "Input Length: $inputLength Count: $count, Input Digit: $inputDigit\n" 
                                            if (( defined $gDebugLvl ) && ( $gDebugLvl == 4 ));

        #Rescale the digit, lets not bother rescaling the ones we don't need to, extra processing not required. 
        #Pass what we want to change, how, and a ref to the data...
        #Don't do this if we don't need to resize. i.e. scaling of 1
        if ( $gScaleFactor != 1 && ( ! $alreadyScaled{$inputDigit} )) {
            rescaleDigit(\@gDigitalStore, $inputDigit, $gScaleFactor);
            $alreadyScaled{$inputDigit} = 1;

        }

        push @digitOutput, $gDigitalStore[$inputDigit]->[$level];
        $level++;
    }
    my $digitOutRef = \@digitOutput;
    push @finalOutput, $digitOutRef;
    #Reset the horizontal level for the next int
    $level = 0;
    $count++;
}


#Now lets get the data back out. 
$count = $level = 0;;
while ( $level < $digitDepth ) {
    while ( $count < $inputLength ) {
        my $char = $finalOutput[$count]->[$level];
        print ($char); 
        print (" ");    #The empty string is the vertical space betwen digital chars. Best to do this here and not mess with data. 
        $count++;
    }
    $level++;
    $count = 0;
    print "\n";
}

#Handy to see what's in our arrays. I've used this before but had to check http://perldoc.perl.org/Data/Dumper.html
print Dumper \@finalOutput if (( defined $gDebugLvl ) && ( $gDebugLvl == 5 ));

################################################################################
#   Function: setUpInitialDigits()
#   Args: 
#       None.
#       lScaleFactor - what we want to scale it to. 
#       pDigitalStore - a reference to the array of array refs storing our data. ( I know a mouthful )
#   Return
#       Reference to the array of array references. 
#   Purpose: 
#   Sets up the initial digits at scale 1
#   Stores each digit as an array of strings. 
#
################################################################################
################################################################################
#Lets set up the vectors for each digital digit 
#Stick these in an array? One for each digit?
#Source: multi-demensional arrays: http://www.perlmonks.org/?node_id=90647
#The spaces in the horizontal 'bits' is needed for scaling. 
#If we can store the size of the scale part here it may make things easier.

sub setUpInitialDigits() {
    my @lDigit0 = ( 
        " - ", 
        "| |", 
        "   ", 
        "| |", 
        " - ");
    my @lDigit1 = ( 
        "   ", 
        "  |", 
        "   ", 
        "  |", 
        "   ");
    my @lDigit2 = ( 
        " - ", 
        "  |", 
        " - ", 
        "|  ", 
        " - ");
    my @lDigit3 = ( 
        " - ", 
        "  |", 
        " - ", 
        "  |", 
        " - ");
    my @lDigit4 = ( 
        "   ", 
        "| |", 
        " - ", 
        "  |", 
        "   ");
    my @lDigit5 = ( 
        " - ", 
        "|  ", 
        " - ", 
        "  |", 
        " - ");
    my @lDigit6 = ( 
        " - ", 
        "|  ", 
        " - ", 
        "| |", 
        " - ");
    my @lDigit7 = ( 
        " - ", 
        "| |", 
        "   ", 
        "  |", 
        "   ");
    my @lDigit8 = ( 
        " - ", 
        "| |", 
        " - ", 
        "| |", 
        " - ");
    my @lDigit9 = ( 
        " - ", 
        "| |", 
        " - ", 
        "  |", 
        " - ");

    my $lDigitRef0 = \@lDigit0;
    my $lDigitRef1 = \@lDigit1;
    my $lDigitRef2 = \@lDigit2;
    my $lDigitRef3 = \@lDigit3;
    my $lDigitRef4 = \@lDigit4;
    my $lDigitRef5 = \@lDigit5;
    my $lDigitRef6 = \@lDigit6;
    my $lDigitRef7 = \@lDigit7;
    my $lDigitRef8 = \@lDigit8;
    my $lDigitRef9 = \@lDigit9;
    
    my @lDigitalStore = ( $lDigitRef0, $lDigitRef1, $lDigitRef2, $lDigitRef3, $lDigitRef4,
    $lDigitRef5, $lDigitRef6, $lDigitRef7, $lDigitRef8, $lDigitRef9);
    my $lDigitalStoreRef = \@lDigitalStore;

    # Call this if we are in debug mode 
    dumpArrays($lDigitalStoreRef) if (( defined $gDebugLvl ) && ( $gDebugLvl == 8 ));

    return($lDigitalStoreRef);
}

################################################################################
#   Function: rescaleDigit()
#   Args: 
#       lChangeDigit - the digit in the initial array we want to change
#       lScaleFactor - what we want to scale it to. 
#       pDigitalStore - a reference to the array of array refs storing our data. ( I know a mouthful )
#   Purpose: 
#   Deal with the scaling of the digits.. 
#   Add to the depth of the digits, by repeating the vertical patterns
#   Stretch the horizontal patterns. Can we use splice() https://perldoc.perl.org/functions/splice.html
#   Just use http://www.perlmonks.org/?node_id=372245
#   we can use the same output code if we manipulate the array 
#
################################################################################

sub rescaleDigit($$$) {

    #Deref the array ref
    my (@lDigitalStore)  = @{$_[0]};
    my ($lChangeDigit)  = $_[1];
    my ($lScaleFactor)  = $_[2];

    #print "Array ref:  @lDigitalStore\n";
    print "Change Digit $lChangeDigit\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print "Scale Factor: $lScaleFactor\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print "Dump out array before modification:\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print Dumper \@lDigitalStore if (( defined $gDebugLvl ) && ( $gDebugLvl == 6 ));
    #
    #Elements 0,2 & 4 are horizontal and need to be stretched. 
    #Need to see if we need to pad with spaces or -'s, 
    my $lScaleCounter = 0;
    my ( $padChar, $stretchedSegment ) = undef;
    #
    foreach my $pos (0, 2, 4){
        my $padChar = substr $lDigitalStore[$lChangeDigit][$pos], 1, 1;
        $stretchedSegment = " " . $padChar x $lScaleFactor . " ";
        $lDigitalStore[$lChangeDigit]->[$pos] = $stretchedSegment;
    }
    
    #Elements 1&3 in the initial data are vertical, we just need to repeat that pattern and pad out the array. 
    #We need to determine if we need to pad with spaces or -'s, we also need to check the top and bottom of the origianl digit. 
    #They will also need to be moved to the correct positions
    #
    my $topLeftPadChar = substr $lDigitalStore[$lChangeDigit]->[1], 0, 1;
    my $topRightPadChar = substr $lDigitalStore[$lChangeDigit]->[1], -1, 1;
    my $bttmLeftPadChar = substr $lDigitalStore[$lChangeDigit]->[3], 0, 1;
    my $bttmRightPadChar = substr $lDigitalStore[$lChangeDigit]->[3], -1, 1;

    print "Top Left PadChar <$topLeftPadChar>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print "Top Right PadChar <$topRightPadChar>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print "Bottom Left PadChar <$bttmLeftPadChar>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print "Bottom Right PadChar <$bttmRightPadChar>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));

    #So working top down and bottom up we need to add vertical bars ( or spaces ). 
    #the array if scale is 2 should be of length (or height) 7
    #if 3 size = 9, 4 = 11 etc etc.. scale * 2 + 3 for the horizontal bits. 
       
    my $temparrayref = $lDigitalStore[$lChangeDigit];
    my $currLen = @$temparrayref;
    print "Current Length of array is: $currLen\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));

    my $padding = " " x $lScaleFactor; 
    print "Horizonral Padding for Vertical 'bits': <$padding>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));

    #Replace what's in the array with our new padded version
    $lDigitalStore[$lChangeDigit]->[1] = $topLeftPadChar . $padding . $topRightPadChar;
    $lDigitalStore[$lChangeDigit]->[3] = $bttmLeftPadChar . $padding . $bttmRightPadChar;
    print "New in Store position 1: <$lDigitalStore[$lChangeDigit]->[1]>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));
    print "New in Store position 3: <$lDigitalStore[$lChangeDigit]->[3]>\n" if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));

    #How many verticals 'bits' do we need to add? 
    my $verticalsToAdd = $lScaleFactor - 1 ;

    #So this will add the needed chars top down and bottom up, inserting into the array.
    while ( $verticalsToAdd > 0 ) {
        my $bttmPatternToAdd =  $bttmLeftPadChar . $padding . $bttmRightPadChar;
        my $topPatternToAdd =  $topLeftPadChar . $padding . $topRightPadChar;
        splice $lDigitalStore[$lChangeDigit], 1, 0, $topPatternToAdd;
        splice $lDigitalStore[$lChangeDigit], $currLen, 0, $bttmPatternToAdd;
        $currLen = @$temparrayref;
        $verticalsToAdd--;
    }

    print Dumper \@lDigitalStore if (( defined $gDebugLvl ) && ( $gDebugLvl == 9 ));

} # End of rescaleDigit

    
################################################################################
#   Function: dumpArays()
#   Args: 
#       none
#   Purpose: 
#   Iterate through the initial 10 digits stored in the initial array(s)
#
################################################################################
sub dumpArrays($) {

    my (@lDigitalStore)  = @{$_[0]};
    my $row = 0;

    foreach my $lDigit (0 .. 9)
    {
        printf( "$lDigit\n%s\n%s\n%s\n%s\n%s\n", 
                $lDigitalStore[$lDigit]->[$row], 
                $lDigitalStore[$lDigit]->[$row+1], 
                $lDigitalStore[$lDigit]->[$row+2], 
                $lDigitalStore[$lDigit]->[$row+3], 
                $lDigitalStore[$lDigit]->[$row+4]) 
    }
}# End of dumpInitialArrays() 

################################################################################
#
# POD
#
=pod

=head1 NAME 

lcd.pl

=head1 SYNOSPSIS 

    lcd.pl <file> [options]

=head1 DESCRIPTION

lcd.pl takes an input file as an argument. 

The following options are available:

=over

=item -i <scaling factor>

This must be an integer between 1 and 10, other values are not permitted. This determines how to scale the individual digits. This is overridden by the input file, but is useful for test purposes.   

=item -s <input string>

This must be a string of integers > 0 and <= 25 characters long, other lengths are not permitted. This is overridden by the input file, but is useful for test purposes.   

=item -d <debug level>

Various levels of debug, to help with, yes, debugging. 

=back

=head2 Functions 

=over

=item rescaleDigit();

Resizes each digit in the input string to the scale factor supplied in the input file. 

=item dumpArrays();

Dumps to STDOUT the contents of the initial arrays. 

=item setUpInitialDigits();

Populates the initial arrays, one for each digit with the scale size of 1.

=back

=cut
################################################################################
#EOF
