#! /usr/bin/perl/

die "Composite_Data\tWindow (bp)\tOutput_TAB\n" unless $#ARGV == 2;
my($input, $WINDOW, $output) = @ARGV;

#"Xaxis": "-1000,-999,-998,-997,-996...
#"sampleYaxis": "1.69,1.64,1.61,1.55...                                  
#"controlYaxis": "1.69,1.64,1.61,1.55...                                  

open(IN, "<$input") or die "Can't open $sample for reading!\n";

$SSUM = $CSUM = 0;
$line = <IN>;
chomp($line);
@array = split(/[",]/, $line);
$START = $#array - $WINDOW - ($WINDOW / 2) + 1;
$STOP = $START + $WINDOW;

$SSUM = $CSUM = 0;

$line = <IN>;
chomp($line);
@array = split(/[",]/, $line);
for($x = $START; $x <= $STOP; $x++) { $SSUM += $array[$x]; }

$line = <IN>;
chomp($line);
@array = split(/[",]/, $line);
for($x = $START; $x <= $STOP; $x++) { $CSUM += $array[$x]; }
close IN;

open(OUT, ">$output") or die "Can't open $output Sense for writing!\n";
print OUT "Feature log2 enrichment:\t";
if($CSUM == 0 || $SSUM == 0) { print OUT "NaN\n"; }
else {
	$SCORE = log($SSUM / $CSUM) / log(2);
	print OUT $SCORE,"\n";
}
close OUT;
