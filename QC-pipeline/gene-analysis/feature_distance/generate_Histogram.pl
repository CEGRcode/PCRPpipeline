#! /usr/bin/perl/

die "bedtools_Intersect\tRef_Coord\tOutput_Histogram\tOutput_Ref_Counts\n" unless $#ARGV == 3;
my($input, $ref, $outhist, $outcount) = @ARGV;

open(REF, "<$ref") or die "Can't open $ref for reading!\n";
#chr1   69090   69091   ENSG00000186092-OR4F5   .       +
#chr1   367639  367640  ENSG00000235249-OR4F29  .       +
#chr1   622053  622054  ENSG00000185097-OR4F16  .       -
#chr1   861117  861118  ENSG00000187634-SAMD11  .       +

$line = "";
%COORD = ();
%STRAND = ();
while($line = <REF>) {
	chomp($line);
	@array = split(/\t/, $line);
	$COORD{$array[3]} = int(($array[1] + $array[2]) / 2);
	$STRAND{$array[3]} = $array[5];	
}
close REF;

open(IN, "<$input") or die "Can't open $sense for reading!\n";
#chr1	0	362638	ENSG00000186092-OR4F5	.	+	chr1	237773	237860	chr1_237773_237860	.	+
#chr1	70090	621052	ENSG00000235249-OR4F29	.	+	chr1	237773	237860	chr1_237773_237860	.	+
#chr1	368639	856116	ENSG00000185097-OR4F16	.	-	chr1	713878	714346	chr1_713878_714346	.	+
#chr1	627053	890965	ENSG00000187634-SAMD11	.	+	chr1	713878	714346	chr1_713878_714346	.	+
#chr1	862117	896966	ENSG00000187961-KLHL17	.	+	.	-1	-1	.	-1	.
#chr1	893670	899670	ENSG00000188976-NOC2L	.	-	.	-1	-1	.	-1	.

$N500 = 0;
$N500_50 = 0;
$N50_5 = 0;
$N5_0 = 0;
$P0_5 = 0;
$P5_50 = 0;
$P50_500 = 0;
$P500 = 0;

$line = "";
%COUNT = ();
while($line = <IN>) {
	chomp($line);
	@array = split(/\t/, $line);
	if(!(exists $COUNT{$array[3]})) {
		$COUNT{$array[3]} = 0;
	}

	if($array[6] ne "." && $#array >= 6) {
		$COUNT{$array[3]}++;

		$TSS = $COORD{$array[3]};
		$DIR = $STRAND{$array[3]};
	
		$MID = int(($array[9] + $array[10]) / 2);
		$DIST = $TSS - $MID;
		#print $TSS,"\t$array[7]\t$array[8]\t",$MID,"\t",$DIST,"\n";
		if($DIR eq "+") { $DIST *= -1; }
		
		if($DIST <= -500000) { $N500++; }
		elsif($DIST < -50000) { $N500_50++; }
       		elsif($DIST < -5000) { $N50_5++; }
		elsif($DIST < 0) { $N5_0++; }
		elsif($DIST < 5000) { $P0_5++; }
		elsif($DIST < 50000) { $P5_50++; }
		elsif($DIST < 500000) { $P50_500++; }
		elsif($DIST >= 500000) { $P500++; }
	}
}
close IN;

open(OUT, ">$outhist") or die "Can't open $outhist for writing!\n";
print OUT "<-500k\t",$N500,"\n";
print OUT "-500k to -50k\t",$N500_50,"\n";
print OUT "-50k to -5k\t",$N50_5,"\n";
print OUT "-5k to 0\t",$N5_0,"\n";
print OUT "0 to 5k\t",$P0_5,"\n";
print OUT "5k to 50k\t",$P5_50,"\n";
print OUT "50k to 500k\t",$P50_500,"\n";
print OUT ">500k\t",$P500,"\n";
close OUT;

open(OUT, ">$outcount") or die "Can't open $outcount for writing!\n";
for $key (keys %COUNT) {
	print OUT $key,"\t",$COUNT{$key},"\n";
}
close OUT;
