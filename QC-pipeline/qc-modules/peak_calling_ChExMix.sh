#!/bin/sh

# Required software for this module:
# python 2.7.14
# python - matplotlib
# Java 8 or later
# perl

# bedtools

#Ends script if any of the shell commands fail
set -e

usage()
{
    echo 'peak_calling.sh -i <INPUT PATH> -s <SampleID> -c <ControlID> -a <Path to scripts> -r <Path to references>'
    exit
}

if [ "$#" -ne 10 ]
then
    usage
fi

while getopts ":i:s:c:a:r:" IN; do
    case "${IN}" in
        i)
            INPUT=${OPTARG}
            ;;
        s)
            SAMPLEID=${OPTARG}
            ;;
        c)
            CONTROLID=${OPTARG}
            ;;
        a)
            SCRIPT=${OPTARG}
            ;;
        r)
            REF=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${INPUT}" ] || [ -z "${SAMPLEID}" ] || [ -z "${CONTROLID}" ] || [ -z "${SCRIPT}" ] || [ -z "${REF}" ]; then
    usage
fi

echo "i = ${INPUT}"
echo "s = ${SAMPLEID}"
echo "c = ${CONTROLID}"
echo "a = ${SCRIPT}"
echo "r = ${REF}"

#Load modules
module load python/2.7.14-anaconda5.0.1

SBAM=$INPUT/$SAMPLEID\.bam
CBAM=$INPUT/$CONTROLID\.bam

#Genome
GENOME=$REF/Genome/hg19.fa
GENLEN=$REF/Genome/hg19.info
BACKGROUND=$REF/Genome/hg19_background_model.txt
#Blacklist filter
BLACKLIST=$REF/Blacklist/hg19_Blacklist.bed

#ChExMix parameters
CHEXMIX=$SCRIPT/external_app/chexmix_v0.45.jar
THREADS=4
PRLOGCONF=-4 #Poisson log threshold for potential region scanning, determines number of potential regions
ALPHASCALE=1 #alpha scaling factor; increase for stricter event calls, range of 0 to 1
BETASCALE=0.05 #beta scaling factor; prior on subtype assignment, UNKNOWN EFFECTS
EPSILONSCALE=0.5 #epsilon scaling factor; increase for more weight on motif in subtype assignment, increase for additional motif weighting 0 to 1
EMWINDOW=1000 #Max window size for running a mixture model over binding events (bp)
QVAL=0.1 #Q-value minimum
MINFOLD=1 #minimum event fold-change vs scaled control

MINSUBTYPEFRAC=0.10 #subtypes must have at least this percentage of associated binding events; increase for fewer subtypes
MINMODELUPDATEEVENTS=50 #minimum number of events to support an update using read distributions
MINMODELUPDATEREF=25 #minimum number of motif reference to support an subtype distribution update
KLDIVERGENCE=-10 #KL divergence dissimilarity threshold for merging subtypes using read distributions; increase for fewer subtypes, UNPREDICTABLE EFFECTS
MOTIFPCCTHRES=0.95 #motif length adjusted similarity threshold for merging subtypes using motifs; decrease for fewer subtypes

# MEME parameters
MEMEMIN=8
MEMEMAX=21
MOTIFNUM=5
ROCCUTOFF=0.65 #Motif prior is used only if the ROC is greater than this

#Calculate Peak FRIP
ECONVERT=$SCRIPT/format-convert/coordinate-file/convert_ChExMix-events_to_BED.pl
TCONVERT=$SCRIPT/format-convert/coordinate-file/convert_ChExMix-table_to_BED.pl 
EXPAND=$SCRIPT/format-convert/coordinate-file/expand_BED.pl
CALCULATE=$SCRIPT/FRIP-scripts/calculate_FRIP_Score.pl
#FRIP parameters
FRIPSIZE=100
 
#Peak report script
REPORT=$SCRIPT/report/generate_peak-info.pl

# Call ChExMix peaks
java -Xmx24G -jar $CHEXMIX --expt $SBAM --format BAM --ctrl $CBAM --threads $THREADS --geninfo $GENLEN --seq $GENOME --back $BACKGROUND --meme1proc --noread2 --scalewin 1000 --round 3 --minsubtypefrac $MINSUBTYPEFRAC --minmodelupdateevents $MINMODELUPDATEEVENTS --kldivergencethres $KLDIVERGENCE --motifpccthres $MOTIFPCCTHRES --prlogconf $PRLOGCONF --alphascale $ALPHASCALE --betascale $BETASCALE --epsilonscale $EPSILONSCALE --excludebed $BLACKLIST --mememinw $MEMEMIN --mememaxw $MEMEMAX --memenmotifs $MOTIFNUM --minroc $ROCCUTOFF --minmodelupdaterefs $MINMODELUPDATEREF --pref -0.1 --numcomps 500 --win 250 --q $QVAL --minfold $MINFOLD --bmwindowmax $EMWINDOW --out $INPUT/peak_calling/chexmix

#Convert Events files final peak file
perl $ECONVERT $INPUT/peak_calling/chexmix/chexmix_experiment.events $INPUT/peak_calling/$SAMPLEID\_peak.bed
perl $TCONVERT $INPUT/peak_calling/chexmix/chexmix.all.events.table $INPUT/peak_calling/$SAMPLEID\_rawpeak.bed

#Calculate FRIP
echo "Calculating FRIP..."
cd $INPUT/peak_calling
mkdir -p $INPUT/peak_calling/frip
perl $EXPAND $SAMPLEID\_peak.bed $FRIPSIZE $SAMPLEID\_$FRIPSIZE\bp.bed
bedtools intersect -a $SBAM -b $SAMPLEID\_$FRIPSIZE\bp.bed | samtools view - -f 0x40 > $SAMPLEID\_SAMPLE_FRIP_Peak_Overlap.sam
bedtools intersect -a $CBAM -b $SAMPLEID\_$FRIPSIZE\bp.bed | samtools view - -f 0x40 > $SAMPLEID\_CONTROL_FRIP_Peak_Overlap.sam

perl $CALCULATE $INPUT/sample_bam_stats.out $SAMPLEID\_SAMPLE_FRIP_Peak_Overlap.sam $INPUT/peak_calling/frip/$SAMPLEID\_SAMPLE_FRIP.out
perl $CALCULATE $INPUT/control_bam_stats.out $SAMPLEID\_CONTROL_FRIP_Peak_Overlap.sam $INPUT/peak_calling/frip/$SAMPLEID\_CONTROL_FRIP.out
SFRIP_FILE=$INPUT/peak_calling/frip/$SAMPLEID\_SAMPLE_FRIP.out
CFRIP_FILE=$INPUT/peak_calling/frip/$SAMPLEID\_CONTROL_FRIP.out
rm -f $SAMPLEID\_SAMPLE_FRIP_Peak_Overlap.sam $SAMPLEID\_CONTROL_FRIP_Peak_Overlap.sam $SAMPLEID\_$FRIPSIZE\bp.bed
echo "Complete"

#Generate stats for report
read bevent filename <<<  $(wc -l $INPUT/peak_calling/$SAMPLEID\_peak.bed)
perl $REPORT $((bevent--)) $SFRIP_FILE $CFRIP_FILE $INPUT/peak_calling/peak-info.txt

