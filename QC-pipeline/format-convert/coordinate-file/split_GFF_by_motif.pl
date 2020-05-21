#! /usr/bin/perl

die "GFF_File\tMotif_Score\tTop_Sites\tMinimum_Log2\tOutput_Name\n" unless $#ARGV == 4;
my($input, $score, $TOP, $THRESH, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

#chr1   fimo    nucleotide_motif        11866222        11866239        78.4    -       .       Name=cluster_4_chr1-;Alias=;ID=cluster_4-23-chr1;pvalue=1.45e-08;qvalue= 0.183;sequence=GACGGTCACGTGGCCCTC;
#chr1   fimo    nucleotide_motif        11866245        11866262         52     +       .       Name=cluster_4_chr1+;Alias=;ID=cluster_4-2158-chr1;pvalue=6.23e-06;qvalue= 0.58;sequence=GCCAGTCACGTGAGGCGC;
#chr1   fimo    nucleotide_motif        11866266        11866285        50.7    -       .       Name=cluster_28_chr1-;Alias=;ID=cluster_28-22481-chr1;pvalue=8.5e-06;qvalue= 0.0418;sequence=CAACCCCCTCCCAGCCAGGA;

$line = "";
@GFF = ();
# Don't output motif stats if only ONE a priori motif overlaps, even if significant
%CLUSTERCOUNT = ();
while($line = <IN>) {
	chomp($line);
	next if($line  =~ "##");
	@array = split(/\t/, $line);
	@ATTR = split(/\;/, $array[8]);
        @MOTIF = split(/\=/, $ATTR[2]);
        @CLUSTER = split(/\-/, $MOTIF[1]);
	push(@GFF, {line => $line, id => $CLUSTER[0]});
	if(exists $CLUSTERCOUNT{$CLUSTER[0]}) { $CLUSTERCOUNT{$CLUSTER[0]}++; }
	else { $CLUSTERCOUNT{$CLUSTER[0]} = 1; }
}
close IN;

#cluster_4       5.5559989513226
#cluster_72      4.32332390874593
#cluster_50      3.81042792824585
#cluster_6       2.82492005933381
#cluster_77      2.76601000184211
#cluster_47      2.66335155853908
#cluster_38      2.62207676944108
#cluster_7       2.60813548878301
#cluster_28      2.32599531048385

if($#GFF < 0) {
	exit;
} else {
	open(SCORE, "<$score") or die "Can't open $score for reading!\n";
	$counter = 0;
	while($line = <SCORE>) {
		$counter++;
		@array = split(/\t/, $line);
		if($counter > $TOP) { close SCORE; }
		elsif($array[1] < $THRESH) { close SCORE; }
		elsif($CLUSTERCOUNT{$array[0]} > 1) {
			open(OUT, ">$output\_$array[0]\.gff") or die "Can't open $output\_$array[0]\.gff for writing!\n";
			for($x = 0; $x <= $#GFF; $x++) {
				if($GFF[$x]{'id'} eq $array[0]) { print OUT $GFF[$x]{'line'},"\n"; }
			}
			close OUT;
		}
	}
}

