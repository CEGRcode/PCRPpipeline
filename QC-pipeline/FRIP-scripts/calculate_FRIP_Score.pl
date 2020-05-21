#! /usr/bin/perl

die "BAM_Stats\tSAM_Overlap_File\tOutput_FRIP\n" unless $#ARGV == 2;
my($exp, $peak, $output) = @ARGV;
open(IN, "<$exp") or die "Can't open $exp for reading!\n";

#chr1 length=    249250621       Aligned= 318094 Unaligned= 0
#chr10 length=   135534747       Aligned= 186512 Unaligned= 0
#chr11 length=   135006516       Aligned= 186363 Unaligned= 0
#chr11_gl000202_random length=   40103   Aligned= 49     Unaligned= 0
#chr12 length=   133851895       Aligned= 167128 Unaligned= 0
#chr13 length=   115169878       Aligned= 102187 Unaligned= 0

$line = "";
$READCOUNT = 0;
$GENOMESIZE = 0;

while($line = <IN>) {
        chomp($line);
        next if($line =~ "INFO");
        @array = split(/\s+/, $line);
        if($#array == 6) {
                $READCOUNT += $array[4];
                $GENOMESIZE += $array[2];
	}
}
close IN;

#NS500168:319:HC3VMBGX5:1:12303:6927:13344       99      chr1    11866219        60      40M     =       11866277        94      CGAGAGGGCCACGTGACCGTCCCGGGGCCAGTCACGTGAG        AAAAAEEEEEEEEEEEEEEEEEEEEEE/EEEEEEEEEEEE        MC:Z:36M        MD:Z:40 PG:Z:MarkDuplicates     NM:i:0  AS:i:40 XS:i:0
#NS500168:319:HC3VMBGX5:4:21601:25824:8844       65      chr1    11866219        60      40M     chr2    33141472        0       CGAGAGGGCCACGTGACCGTCCCGGGGCCAGTCACGTGAG        AAAAAEEEEEEEEEEEEEEEEEEEEEEEE/EEE/EE6E6E        MC:Z:36M        MD:Z:40 PG:Z:MarkDuplicates     NM:i:0  AS:i:40 XS:i:0
#NS500168:319:HC3VMBGX5:1:23108:13198:18552      99      chr1    11866220        60      40M     =       11866297        100     GAGAGGGCCACGTGACCGTCCCGGGGCCAGTCACGTGAGG        AAAAAAEE/EAEEEEEEEEEAEEEEEEAAEEE/AEEEEEE        MC:Z:23M13S     MD:Z:40 PG:Z:MarkDuplicates     NM:i:0  AS:i:40 XS:i:0
#NS500168:319:HC3VMBGX5:3:23606:20241:12089      99      chr1    11866221        60      40M     =       11866287        102     AGAGGGCCACGTGACCGTCCCGGGGCCAGTCACGTGAGGC        AAAAAEEEEEEEEEEEEEEEEEEEEEEEEEEE<EEEEEEA        MC:Z:36M        MD:Z:40 PG:Z:MarkDuplicates     NM:i:0  AS:i:40 XS:i:0
#NS500168:319:HC3VMBGX5:4:13603:19879:9014       73      chr1    11866222        60      40M     =       11866222        0       GAGGGCCACGTGACCGTCCCGGGGCCAGTCACGTGAGGCG        AAAAAEEEEEEE6EEEEE/EEEEEEEEEEEEEEEEEEEEE        MD:Z:40 PG:Z:MarkDuplicates     NM:i:0  AS:i:40 XS:i:0
#NS500168:319:HC3VMBGX5:2:13101:3940:11367       83      chr1    11866223        60      40M     =       11866158        -105    AGGGCCACGTGACCGTCCCGGGGCCAGTCACGTGAGGCGC        EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEAAAAA        MC:Z:36M        MD:Z:40 PG:Z:MarkDuplicates     NM:i:0  AS:i:40 XS:i:0

open(IN, "<$peak") or die "Can't open $peak for reading!\n";
$PEAK = 0;
$line  = "";
while($line = <IN>) { 
        chomp($line); 
        next if($line =~ "#");
        @array = split(/\t/, $line);
        $PEAK += $array[5];
}
close IN;

open(OUT, ">$output") or die "Can't open $output for writing!\n";

print OUT "All tags:\t$READCOUNT\n";
print OUT "Peak tags:\t$PEAK\n";
$RATIO = "N/A";
if($READCOUNT != 0) { $RATIO = $PEAK / $READCOUNT; }
print OUT "FRIP Score:\t$RATIO\n";

close OUT;
