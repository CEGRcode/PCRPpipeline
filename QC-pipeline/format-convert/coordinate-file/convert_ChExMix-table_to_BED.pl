#! /usr/bin/perl

die "Events_File\tOutput_BED_File\n" unless $#ARGV == 1;
my($input, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";
open(OUT, ">$output") or die "Can't open $output for writing!\n";

#### ChExMix output
##Condition      Name    Index   TotalSigCount   SigCtrlScaling  SignalFraction
##Condition      experiment      0       6.923849E7      1.000   0.060
##Replicate      ParentCond      Name    Index   SigCount        CtrlCount       SigCtrlScaling  SignalFraction
##Replicate      experiment      experiment:rep1 0       6.923849E7      0       1       0.06
##
##Point  experiment_Sig  experiment_Ctrl experiment_log2Fold     experiment_log2Q        ActiveConds
#chr2:33141377   8860.4  5.9     10.561  -Infinity       1
#chr2:33141484   4035.1  2.7     10.561  -Infinity       1
#chr2:33141434   3327.2  2.2     10.561  -Infinity       1
#chr2:33141600   2917.8  1.9     10.561  -Infinity       1
#chr14:99887301  598.8   3.7     7.348   -552.825        1
#chr1:200457188  568.4   5.7     6.651   -511.953        1
#chr11:61158807  515.9   3.1     7.360   -470.177        1
#chr2:33141444   452.4   0.3     8.821   -427.031        1

$line = "";
while($line = <IN>) {
	chomp($line);
	next if($line =~ "#");
	@array = split(/\t/, $line);
	@COORD = split(/\:/, $array[0]);
	$START = $COORD[1];
	$STOP = $START + 1;
	print OUT "$COORD[0]\t$START\t$STOP\t$array[0]\t$array[1]\t.\n";
}
close IN;
close OUT;
