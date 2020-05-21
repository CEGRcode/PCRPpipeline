#! /usr/bin/perl

die "TOMTOM_File\tInput_FilePath\tSampleID\tOutput_FilePath\n" unless $#ARGV == 3;
my($tomtom, $input, $ID, $output) = @ARGV;
open(TOM, "<$tomtom") or die "Can't open $tomtom for reading!\n";

# Query ID	Target ID	Optimal offset	p-value	E-value	q-value	Overlap	Query consensus	Target consensus	Orientation
# memeCluster13	CTCF	1	4.34998e-16	2.51864e-13	5.00467e-13	18	CTCCAGCAGGTGGCGCTG	TGGCCACCAGGGGGCGCTA	+
# memeCluster13	CTCFL	-3	4.33674e-07	0.000251098	0.000249472	14	CTCCAGCAGGTGGCGCTG	CACCAGGGGGCACC	+
# memeCluster13	SCRT1	0	0.00100141	0.579818	0.326311	15	CTCCAGCAGGTGGCGCTG	GAGCAACAGGTGGTT	+
# memeCluster13	NEUROD1	-3	0.00130297	0.754418	0.326311	13	CTCCAGCAGGTGGCGCTG	GGACAGATGGCAG	+
# memeCluster13	ASCL1	-2	0.00168923	0.978064	0.326311	13	CTCCAGCAGGTGGCGCTG	GCAGCAGCTGGCG	+

$line  = "";
%MOTIF = ();
%PVAL = ();
while($line = <TOM>) {
	chomp($line);
	next if($line =~ "Query");
	@array = split(/\t/, $line);
	next if($#array != 9);
	if(exists $MOTIF{$array[0]}) {
		if($PVAL{$array[0]} > $array[3]) {
			$PVAL{$array[0]} = $array[3];
			$MOTIF{$array[0]} = $array[1];
		}
	} else {
		$MOTIF{$array[0]} = $array[1];
		$PVAL{$array[0]} = $array[3];
	}
}
close TOM;

print "MotifCluster\tBest TOMTOM match\tp-value\n";
for $key (keys %MOTIF) {
	print $key,"\t",$MOTIF{$key},"\t",$PVAL{$key},"\n";
#	system("cp $input/*$key*$MOTIF{$key}\.png $output/$ID\_$key\_$MOTIF{$key}\_TOMTOM.png");

	if( system("cp $input/*$key*$MOTIF{$key}\.png $output/$ID\_$key\_$MOTIF{$key}\_TOMTOM.png") != 0) {
	    print "failed to execute: cp $input/*$key*$MOTIF{$key}\.png $output/$ID\_$key\_$MOTIF{$key}\_TOMTOM.png\n";
	}
}
