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

$DNA=$LINE=$LOW=$LTR=$OTHER=$RNA=$SAT=$SIM=$SINE=$UNK=$SAMPLETOTAL=0;
$DNA_SIZE=$LINE_SIZE=$LOW_SIZE=$LTR_SIZE=$OTHER_SIZE=$RNA_SIZE=$SAT_SIZE=$SIM_SIZE=$SINE_SIZE=$UNK_SIZE=$SAMPLESIZE=0;
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
        if($key eq "DNA" || $key eq "DNA?") { $DNA += $STATE_FREQ{$key}; $DNA_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "LINE" || $key eq "LINE?") { $LINE += $STATE_FREQ{$key}; $LINE_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Low_complexity") { $LOW += $STATE_FREQ{$key}; $LOW_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "LTR" || $key eq "LTR?") { $LTR += $STATE_FREQ{$key}; $LTR_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Other" || $key eq "RC") { $OTHER += $STATE_FREQ{$key}; $OTHER_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "RNA" || $key eq "rRNA" || $key eq "scRNA" || $key eq "snRNA" || $key eq "srpRNA" || $key eq "tRNA") { $RNA += $STATE_FREQ{$key}; $RNA_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Satellite") { $SAT += $STATE_FREQ{$key}; $SAT_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Simple_repeat") { $SIM += $STATE_FREQ{$key}; $SIM_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "SINE" || $key eq "SINE?") { $SINE += $STATE_FREQ{$key}; $SINE_SIZE += $STATE_SIZE{$key}; }
        elsif($key eq "Unknown" || $key eq "Unknown?") { $UNK += $STATE_FREQ{$key}; $UNK_SIZE += $STATE_SIZE{$key}; }
        else { print "Unknown id: ",$key,"\n"; exit; }
}

if($SAMPLETOTAL != 0) {
	$DNA /= $SAMPLETOTAL;
	$LINE /= $SAMPLETOTAL;
	$LOW /= $SAMPLETOTAL;
	$LTR /= $SAMPLETOTAL;
	$OTHER /= $SAMPLETOTAL;
	$RNA /= $SAMPLETOTAL;
	$SAT /= $SAMPLETOTAL;
	$SIM /= $SAMPLETOTAL;
	$SINE /= $SAMPLETOTAL;
	$UNK /= $SAMPLETOTAL;
} else { $DNA=$LINE=$LOW=$LTR=$OTHER=$RNA=$SAT=$SIM=$SINE=$UNK="NaN"; }
if($SAMPLESIZE != 0) {
	$DNA_SIZE /= $SAMPLESIZE;
	$LINE_SIZE /= $SAMPLESIZE;
	$LOW_SIZE /= $SAMPLESIZE;
	$LTR_SIZE /= $SAMPLESIZE;
	$OTHER_SIZE /= $SAMPLESIZE;
	$RNA_SIZE /= $SAMPLESIZE;
	$SAT_SIZE /= $SAMPLESIZE;
	$SIM_SIZE /= $SAMPLESIZE;
	$SINE_SIZE /= $SAMPLESIZE;
	$UNK_SIZE /= $SAMPLESIZE;
} else { $DNA_SIZE=$LINE_SIZE=$LOW_SIZE=$LTR_SIZE=$OTHER_SIZE=$RNA_SIZE=$SAT_SIZE=$SIM_SIZE=$SINE_SIZE=$UNK_SIZE="NaN"; }

open(OUT, ">$freq") or die "Can't open $freq for writing!\n";
@ID = split(/\//, $sample);
@NAME = split(/\./, $ID[$#ID]);
print OUT "\tLINE\tSINE\tLTR\tSimple_repeats\tLow_complexity\tSatellite\tRNA\tDNA\tOther\tUnknown\n";
print OUT "$NAME[0]\t$LINE\t$SINE\t$LTR\t$SIM\t$LOW\t$SAT\t$RNA\t$DNA\t$OTHER\t$UNK\n";
print OUT "$NAME[0]\t$LINE_SIZE\t$SINE_SIZE\t$LTR_SIZE\t$SIM_SIZE\t$LOW_SIZE\t$SAT_SIZE\t$RNA_SIZE\t$DNA_SIZE\t$OTHER_SIZE\t$UNK_SIZE\n";
close OUT;
