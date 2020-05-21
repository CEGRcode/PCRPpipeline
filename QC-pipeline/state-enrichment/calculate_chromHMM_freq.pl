#! /usr/bin/perl

die "BED_File\tOutput_FrequencyFile\n" unless $#ARGV == 1;
my($sample, $freq) = @ARGV;
if($sample =~ /.gz$/) { open(IN, "gunzip -c $sample |") || die "Can’t open pipe to $sample"; }
else { open(IN, "<$sample") || die "Can't open $sample for reading!\n"; }

#chr1	10000	10600	15_Repetitive/CNV	0	.	10000	10600	245,245,245
#chr1	135937	137337	4_Strong_Enhancer	0	.	135937	137337	250,202,0
#chr1	462937	464937	4_Strong_Enhancer	0	.	462937	464937	250,202,0

#1_Active_Promoter
#2_Weak_Promoter
#3_Poised_Promoter
#4_Strong_Enhancer
#5_Strong_Enhancer
#6_Weak_Enhancer
#7_Weak_Enhancer
#8_Insulator
#9_Txn_Transition
#10_Txn_Elongation
#11_Weak_Txn
#12_Repressed
#13_Heterochrom/lo
#14_Repetitive/CNV
#15_Repetitive/CNV

$PROMOTER=$ENHANCER=$INS=$TXN=$REP=$HETERO=$SAMPLETOTAL=0;
$PROM_SIZE=$ENH_SIZE=$INS_SIZE=$TXN_SIZE=$REP_SIZE=$HET_SIZE=$SAMPLESIZE=0;
%STATE_FREQ = ();
%STATE_SIZE = ();
while(<IN>) {
	chomp($_);
	@array = split(/\t/, $_);
	if(exists $STATE_FREQ{$array[3]}) {
		$STATE_FREQ{$array[3]}++;
		$STATE_SIZE{$array[3]} += ($array[2] - $array[1]);
	}
	else {
		$STATE_FREQ{$array[3]} = 1;
		$STATE_SIZE{$array[3]} = ($array[2] - $array[1]); 
	}
	$SAMPLETOTAL++;
	$SAMPLESIZE += ($array[2] - $array[1]);
}
close IN;

#Set effective genome size to 2.7Gb if genome size covered by BED file is smaller
if($SAMPLESIZE < 2.7e9) { $SAMPLESIZE = 2.7e9;}

foreach $key (keys %STATE_FREQ) {
	if($key eq "1_Active_Promoter" || $key eq "2_Weak_Promoter" || $key eq "3_Poised_Promoter") { $PROMOTER += $STATE_FREQ{$key}; $PROM_SIZE += $STATE_SIZE{$key}; }
	if($key eq "4_Strong_Enhancer" || $key eq "5_Strong_Enhancer" || $key eq "6_Weak_Enhancer" || $key eq "7_Weak_Enhancer") { $ENHANCER += $STATE_FREQ{$key}; $ENH_SIZE += $STATE_SIZE{$key}; }
	if($key eq "8_Insulator") { $INS += $STATE_FREQ{$key}; $INS_SIZE += $STATE_SIZE{$key}; }
	if($key eq "9_Txn_Transition" || $key eq "10_Txn_Elongation" || $key eq "11_Weak_Txn") { $TXN += $STATE_FREQ{$key}; $TXN_SIZE += $STATE_SIZE{$key}; }
	if($key eq "12_Repressed") { $REP += $STATE_FREQ{$key}; $REP_SIZE += $STATE_SIZE{$key}; }
	if($key eq "13_Heterochrom/lo" || $key eq "14_Repetitive/CNV" || $key eq "15_Repetitive/CNV") { $HETERO += $STATE_FREQ{$key}; $HET_SIZE += $STATE_SIZE{$key}; }
}

if($SAMPLETOTAL != 0) {
	$PROMOTER /= $SAMPLETOTAL;
	$ENHANCER /= $SAMPLETOTAL;
	$INS /= $SAMPLETOTAL;
	$TXN /= $SAMPLETOTAL;
	$REP /= $SAMPLETOTAL;
	$HETERO /= $SAMPLETOTAL;
} else { $PROMOTER = $ENHANCER = $INS = $TXN = $REP = $HETERO = "NaN"; }
if($SAMPLESIZE != 0) {
	$PROM_SIZE /= $SAMPLESIZE;
	$ENH_SIZE /= $SAMPLESIZE;
	$INS_SIZE /= $SAMPLESIZE;
	$TXN_SIZE /= $SAMPLESIZE;
	$REP_SIZE /= $SAMPLESIZE;
	$HET_SIZE /= $SAMPLESIZE;
} else { $PROM_SIZE=$ENH_SIZE=$INS_SIZE=$TXN_SIZE=$REP_SIZE=$HET_SIZE="NaN"; }

open(OUT, ">$freq") or die "Can't open $freq for writing!\n";
@ID = split(/\//, $sample);
@NAME = split(/\./, $ID[$#ID]);
print OUT "\tPromoter\tTranscription\tEnhancer\tInsulator\tRepressed\tHeterochromatin\n";
print OUT "$NAME[0]\t$PROMOTER\t$TXN\t$ENHANCER\t$INS\t$REP\t$HETERO\n";
print OUT "$NAME[0]\t$PROM_SIZE\t$TXN_SIZE\t$ENH_SIZE\t$INS_SIZE\t$REP_SIZE\t$HET_SIZE\n";
close OUT;
