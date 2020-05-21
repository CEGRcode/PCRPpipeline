#! /usr/bin/perl

die "Events_File\tOutput_BED\n" unless $#ARGV == 1;
my($input, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

#### ChExMix output
##Condition	Name	Index	TotalSigCount	SigCtrlScaling	SignalFraction
##Condition	experiment	0	2351284.0	0.265	0.129
##Replicate	ParentCond	Name	Index	SigCount	CtrlCount	CtrlScaling	SignalFraction
##Replicate	experiment	experiment:rep1	0	2351284.0	8117412.0	0.265	0.129
##
##Point	experiment_Sig	experiment_Ctrl	experiment_log2Fold	experiment_log2Q	SubtypePoint	Tau	SubtypeName	SubtypeSequence	SubtypeMotifScore
#chr2:33141481	463.2	1127.0	0.631	-17.960	chr2:33141481:+	1.00	Subtype3		0.00
#chr17:7137915	97.3	0.7	6.604	-75.954	chr17:7137924:-	0.53	Subtype0	GGTCACGTGAT	19.50
#chr10:46222642	96.7	0.0	6.596	-80.583	chr10:46222642:+	0.51	Subtype0	TGTCACGTGAC	17.77
#chr11:84024417	94.5	25.6	3.799	-54.541	chr11:84024417:-	1.00	Subtype1		0.00
#chr1:73361720	91.1	26.4	3.703	-52.263	chr1:73361719:-	0.87	Subtype1		0.00
#chr10:26692605	90.6	21.9	3.960	-54.066	chr10:26692605:-	1.00	Subtype1		0.00
#chr16:5083948	87.3	7.9	5.374	-58.277	chr16:5083954:-	0.61	Subtype0	AGTCACGTGAG	14.36

$line = "";
@LIST = ();
while($line = <IN>) {
	chomp($line);
	next if($line =~ "track" || $line =~ "#");
	@array = split(/\s+/, $line);
	@COORD = split(/\:/, $array[5]);
	$START = $COORD[1] - 1;
#	if($COORD[2] eq "-") { $START = $COORD[1] - 1; }
	$STOP = $START + 1;
	$line = "$COORD[0]\t$START\t$STOP\t$array[7]\t$array[3]\t$COORD[2]";
	push(@LIST, {line => $line, score => $array[3], type => $array[7]});

}
close IN;

open(OUT, ">$output") or die "Can't open $output for writing!\n";
@temp = sort { $$b{'score'} <=> $$a{'score'} } @LIST;
@SORT = sort { $$a{'type'} cmp $$b{'type'} } @temp;

for($x = 0; $x <= $#SORT; $x++) {
	print OUT $SORT[$x]{'line'},"\n";
}
close OUT;
