#! /usr/bin/perl

die "BED_File\tOutput_ID\n" unless $#ARGV == 1;
my($input, $output) = @ARGV;
open(IN, "<$input") or die "Can't open $input for reading!\n";

#chr17  6915689 6915690 Subtype0        6.714   -
#chr10  46222643        46222644        Subtype0        6.575   -
#chr17  7137924 7137925 Subtype0        6.505   -
#chr17  80246038        80246039        Subtype0        6.487   +
#chr1   154531281       154531282       Subtype0        6.329   -
#chr12  122751032       122751033       Subtype0        6.297   -
#chr10  51827643        51827644        Subtype0        6.285   -
#chr17  72510614        72510615        Subtype0        6.210   +

$line = "";
@LIST = ();
%UNIQ = ();
while($line = <IN>) {
	chomp($line);
	@array = split(/\t/, $line);
        push(@LIST, {line => $line, score => $array[4], type => $array[3]});
	$UNIQ{$array[3]} = 1;
}
close IN;
@temp = sort { $$b{'score'} <=> $$a{'score'} } @LIST;
@SORT = sort { $$a{'type'} cmp $$b{'type'} } @temp;

$currentType = "";
for($x = 0; $x <= $#SORT; $x++) {
	if($currentType ne $SORT[$x]{'type'}) {
		$currentType = $SORT[$x]{'type'};
		close OUT;
		open(OUT, ">$output\_$currentType\.bed") or die "Can't open $output\_$currentType\.bed for writing!\n";
	}
	print OUT $SORT[$x]{'line'},"\n";
}
close OUT;
