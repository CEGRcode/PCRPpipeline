#! /usr/bin/perl/

die "Sample_CDT\tControl_CDT\t#_Lines\tSmoothing_Window\tOutput_TAB\n" unless $#ARGV == 4;
my($sample, $control, $NUM, $SMOOTH, $output) = @ARGV;

open(IN, "<$sample") or die "Can't open $sample for reading!\n";
$ARRAYLENGTH = 0;
$SIZE = 0;
while(<IN>) {
	chomp;
	next if(/YORF/);
	@temparray = split(/\t/, $_);
	$ARRAYLENGTH = $#temparray - 1;
	$SIZE++;
}
close IN;

open(OUT, ">$output") or die "Can't open $output Sense for writing!\n";
print OUT "\"Xaxis\": \"";

open(SAM, "<$sample") or die "Can't open $sample for reading!\n";
open(CON, "<$control") or die "Can't open $control for reading!\n";
@CDT = ();
$count = 0;
$line = "";
my @SAMPLEList = ((0) x $ARRAYLENGTH);
my @CONTROLList = ((0) x $ARRAYLENGTH);
my @WeightList = ((0) x $ARRAYLENGTH);

while($sline = <SAM>) {
	chomp($sline);
	$cline = <CON>;
	chomp($cline);

	@Sarray = split(/\t/, $sline);
        @Carray = split(/\t/, $cline);
	if($sline =~ "YORF") {
		for($x = -1 * ($ARRAYLENGTH / 2); $x < ($ARRAYLENGTH / 2); $x++) {
			print OUT $x;
			if($x + 1 < ($ARRAYLENGTH / 2)) { print OUT ","; }
		}
		print OUT "\"\n";
	} else {
		for($x = 2; $x <= $#Sarray; $x++) {
               		$SAMPLEList[$x-2] += $Sarray[$x];
			$CONTROLList[$x-2] += $Carray[$x];
	                $WeightList[$x-2]++;
		}
		$count++;
	}
	if($count == $NUM) { close SAM; close CON; }
}
close SAM;
close CON;

for($x = 0; $x <= $#SAMPLEList; $x++) {
	$SAMPLEList[$x] /= $WeightList[$x];
        $CONTROLList[$x] /= $WeightList[$x];
}

my @SAMPLESmooth = ((0) x $ARRAYLENGTH);
my @CONTROLSmooth = ((0) x $ARRAYLENGTH);
for($x = 0; $x <= $#SAMPLEList; $x++) {
	$smoothweight = 0;
	$SAMPLE_SUM = 0;
	$CONTROL_SUM = 0;
	for($y = $x - (($SMOOTH - 1) / 2); $y <= $x + (($SMOOTH - 1) / 2); $y++) {
		if($y < 0) { $y = 0; }
		if($y > $#SAMPLEList) { $y = $y + (($SMOOTH - 1) / 2) + 1; }
		else {
			$SAMPLE_SUM += $SAMPLEList[$y];
			$CONTROL_SUM += $CONTROLList[$y];
			$smoothweight++;
		}
	}
	$SAMPLE_SUM /= $smoothweight;
	$CONTROL_SUM /= $smoothweight;
	$SAMPLESmooth[$x] = $SAMPLE_SUM;
	$CONTROLSmooth[$x] = $CONTROL_SUM;
}

print OUT "\"sampleYaxis\": \"";
for($x = 0; $x <= $#SAMPLESmooth; $x++) {
	print OUT sprintf("%.2f",$SAMPLESmooth[$x]);
	if($x < $#SAMPLESmooth) { print OUT ","; }
}
print OUT "\"\n";
print OUT "\"controlYaxis\": \"";
for($x = 0; $x <= $#CONTROLSmooth; $x++) {
        print OUT sprintf("%.2f",$CONTROLSmooth[$x]);
        if($x < $#CONTROLSmooth) { print OUT ","; }
}
print OUT "\"\n";
close OUT;
