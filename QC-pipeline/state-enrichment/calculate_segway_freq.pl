#! /usr/bin/perl

die "BED_File\tOutput_FrequencyFile\n" unless $#ARGV == 1;
my($sample, $freq) = @ARGV;
if($sample =~ /.gz$/) { open(IN, "gunzip -c $sample |") || die "Can’t open pipe to $sample"; }
else { open(IN, "<$sample") || die "Can't open $sample for reading!\n"; }

#chr1	10000	10600	15_Repetitive/CNV	0	.	10000	10600	245,245,245
#chr1	135937	137337	4_Strong_Enhancer	0	.	135937	137337	250,202,0
#chr1	462937	464937	4_Strong_Enhancer	0	.	462937	464937	250,202,0

#11_Weak_Txn
#12_Repressed
#13_Heterochrom/lo
#14_Repetitive/CNV
#15_Repetitive/CNV

$INS=$OPEN=$TXN=$ENH=$PROX=$ACT=$INA=$HETERO=$POLY=$SAMPLETOTAL=0;
$INS_SIZE=$OPEN_SIZE=$TXN_SIZE=$ENH_SIZE=$PROX_SIZE=$ACT_SIZE=$INA_SIZE=$HETERO_SIZE=$POLY_SIZE=$SAMPLESIZE=0;

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
        if($key eq "Ctcf" || $key eq "CtcfO") { $INS += $STATE_FREQ{$key}; $INS_SIZE += $STATE_SIZE{$key} }
        elsif($key eq "DnaseD" || $key eq "Faire") { $OPEN += $STATE_FREQ{$key}; $OPEN_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Elon" || $key eq "Elon1" || $key eq "Elon2" || $key eq "ElonW" || $key eq "ElonW1" || $key eq "ElonW2" || $key eq "ElonW3" || $key eq "Gen3" || $key eq "Gen3'1" || $key eq "Gen3'2" || $key eq "Gen5" || $key eq "Gen5'1" || $key eq "Gen5'2") { $TXN += $STATE_FREQ{$key}; $TXN_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Enh" || $key eq "Enh1" || $key eq "Enh2" || $key eq "EnhF" || $key eq "EnhF1" || $key eq "EnhF2" || $key eq "EnhF3" || $key eq "EnhP" || $key eq "EnhPr" || $key eq "EnhW" || $key eq "EnhW1" || $key eq "EnhW2" || $key eq "EnhWf" || $key eq "EnhWf1" || $key eq "EnhWf2" || $key eq "EnhWf3") { $ENH += $STATE_FREQ{$key}; $ENH_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Low1" || $key eq "Low2" || $key eq "Low3" || $key eq "Low4" || $key eq "Low5" || $key eq "Low6" || $key eq "Low7") { $PROX += $STATE_FREQ{$key}; $PROX_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "PromF" || $key eq "Tss" || $key eq "TssF") { $ACT += $STATE_FREQ{$key}; $ACT_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "PromP" || $key eq "PromP1" || $key eq "PromP2") { $INA += $STATE_FREQ{$key}; $INA_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Quies") { $HETERO += $STATE_FREQ{$key}; $HETERO_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Repr" || $key eq "Repr1" || $key eq "Repr2" || $key eq "Repr3" || $key eq "Repr4" || $key eq "Repr5" || $key eq "Repr6" || $key eq "Repr7") { $POLY += $STATE_FREQ{$key}; $POLY_SIZE += $STATE_SIZE{$key}; }
        else { print $key,"\n"; }
}

if($SAMPLETOTAL != 0) {
	$INS /= $SAMPLETOTAL;
	$OPEN /= $SAMPLETOTAL;
	$TXN /= $SAMPLETOTAL;
	$ENH /= $SAMPLETOTAL;
	$PROX /= $SAMPLETOTAL;
	$ACT /= $SAMPLETOTAL;
	$INA /= $SAMPLETOTAL;
	$HETERO /= $SAMPLETOTAL;
	$POLY /= $SAMPLETOTAL;
} else { $INS=$OPEN=$TXN=$ENH=$PROX=$ACT=$INA=$HETERO=$POLY="NaN"; }
if($SAMPLESIZE != 0) {
	$INS_SIZE /= $SAMPLESIZE;
	$OPEN_SIZE /= $SAMPLESIZE;
	$TXN_SIZE /= $SAMPLESIZE;
	$ENH_SIZE /= $SAMPLESIZE;
	$PROX_SIZE /= $SAMPLESIZE;
	$ACT_SIZE /= $SAMPLESIZE;
	$INA_SIZE /= $SAMPLESIZE;
	$HETERO_SIZE /= $SAMPLESIZE;
	$POLY_SIZE /= $SAMPLESIZE;
} else { $INS_SIZE=$OPEN_SIZE=$TXN_SIZE=$ENH_SIZE=$PROX_SIZE=$ACT_SIZE=$INA_SIZE=$HETERO_SIZE=$POLY_SIZE="NaN"; }

open(OUT, ">$freq") or die "Can't open $freq for writing!\n";
@ID = split(/\//, $sample);
@NAME = split(/\./, $ID[$#ID]);
print OUT "\tActive_Promoter\tProximal_Active\tInactive_Promoter\tTranscription\tEnhancer\tOpen_Chromatin\tInsulator\tHeterochromatin\tPolycomb\n";
print OUT "$NAME[0]\t$ACT\t$PROX\t$INA\t$TXN\t$ENH\t$OPEN\t$INS\t$HETERO\t$POLY\n";
print OUT "$NAME[0]\t$ACT_SIZE\t$PROX_SIZE\t$INA_SIZE\t$TXN_SIZE\t$ENH_SIZE\t$OPEN_SIZE\t$INS_SIZE\t$HETERO_SIZE\t$POLY_SIZE\n";
close OUT;

