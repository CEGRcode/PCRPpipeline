#! /usr/bin/perl

die "Intersect.gff\tMotif_Count\tWindow(bp)\tOutput_File\n" unless $#ARGV == 3;
my($intersect, $prob, $WINDOW, $output) = @ARGV;

#chr1	fimo	nucleotide_motif	11866222	11866239	78.4	-	.	Name=cluster_4_chr1-;Alias=;ID=cluster_4-23-chr1;pvalue=1.45e-08;qvalue= 0.183;sequence=GACGGTCACGTGGCCCTC;
#chr1	fimo	nucleotide_motif	11866245	11866262	 52	+	.	Name=cluster_4_chr1+;Alias=;ID=cluster_4-2158-chr1;pvalue=6.23e-06;qvalue= 0.58;sequence=GCCAGTCACGTGAGGCGC;
#chr1	fimo	nucleotide_motif	11866266	11866285	50.7	-	.	Name=cluster_28_chr1-;Alias=;ID=cluster_28-22481-chr1;pvalue=8.5e-06;qvalue= 0.0418;sequence=CAACCCCCTCCCAGCCAGGA;
#chr1	fimo	nucleotide_motif	11866273	11866292	41.1	-	.	Name=cluster_75_chr1-;Alias=;ID=cluster_75-349003-chr1;pvalue=7.75e-05;qvalue= 0.012;sequence=CCTCTACCAACCCCCTCCCA;

open(INT, "<$intersect") or die "Can't open $intersect for reading!\n";
%MOTIFOCC = ();
$line = "";
$peakcount = 0;
while($line = <INT>) {
	chomp($line);
	next if($line  =~ "##");
	@array = split(/\t/, $line);
	@ATTR = split(/\;/, $array[8]);
	@MOTIF = split(/\=/, $ATTR[2]);
	@CLUSTER = split(/\-/, $MOTIF[1]);
	if(exists $MOTIFOCC{$CLUSTER[0]}) { $MOTIFOCC{$CLUSTER[0]} += 1; }
	else { $MOTIFOCC{$CLUSTER[0]} = 1; }

	$peakcount++;
}
close INT;
print "$peakcount motifs overlapping with peaks\n";

open(OUT, ">$output") or die "Can't open $output for writing!\n";
if($peakcount < 1) {
        close OUT;
        exit;
}

#cluster_44	1136843
#cluster_70	474043 
#cluster_18	853243 
#cluster_63	884459 
#cluster_66	654573 

#Human genome size
$GENOMESIZE = 3000000000;

open(PROB, "<$prob") or die "Can't open $prob for reading!\n";
%PROB = ();
$line = "";
$count = 0;
while($line = <PROB>) {
        chomp($line);
        @array = split(/\t/, $line);
        $PROB{$array[0]} = ($array[1] * $peakcount * $WINDOW) / $GENOMESIZE;
        $count++;
}
close PROB;
print "Testing $count motifs for overlap\n";

@ENRICH = ();
for $key (keys %MOTIFOCC) {
	$SCORE = log($MOTIFOCC{$key} / $PROB{$key}) / log(2);
	push(@ENRICH, {id => $key, score => $SCORE});
}
@FINAL = sort { $$b{'score'} <=> $$a{'score'} } @ENRICH;

for($x = 0; $x <= $#FINAL; $x++) {
	print OUT $FINAL[$x]{'id'},"\t",$FINAL[$x]{'score'},"\n";
}
close OUT;
