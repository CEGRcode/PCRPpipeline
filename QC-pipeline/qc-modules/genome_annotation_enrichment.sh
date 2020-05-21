#!/bin/bash

# Required software for this module:
# python 2.7.14
# python - matplotlib
# Java 8 or later
# perl

# bedtools

usage()
{
    echo 'genome_annotation_enrichment.sh -i <INPUT PATH> -s <SampleID> -c <ControlID> -a <Path to scripts> -r <Path to references>'
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

SPEAK=$INPUT/peak_calling/$SAMPLEID\_rawpeak.bed
CPEAK=$INPUT/$CONTROLID\_raw.bed
#SPEAK=$INPUT/peak_calling/$SAMPLEID\_peak.bed
#CPEAK=$INPUT/$CONTROLID\.bed
SBAM=$INPUT/$SAMPLEID\.bam
CBAM=$INPUT/$CONTROLID\.bam

#ChromHMM
CHROM=$REF/ChromatinState/chromHMM/chromHMM.bed.gz
#Segway
SEGWAY=$REF/ChromatinState/segway/segway.bed.gz
#Repeats
REPEAT=$REF/ChromatinState/Repeat/hg19_RepeatMasker.bed.gz

#ChromHMM histogram
CHROMCOUNT=$SCRIPT/state-enrichment/calculate_chromHMM_freq.pl
#Segway histogram
SEGCOUNT=$SCRIPT/state-enrichment/calculate_segway_freq.pl
#Repeat histogram
REPEATCOUNT=$SCRIPT/state-enrichment/calculate_repeatelement_freq.pl
#Log2 calculation
LOG=$SCRIPT/state-enrichment/calculate_log2.pl

# Make folder structure for testing chromatin feature enrichment
mkdir -p $INPUT/chromatin_state
cd $INPUT/chromatin_state

#ChromHMM state count
echo "chromHMM intersect"
bedtools intersect -wa -a $CHROM -b $SPEAK > $SAMPLEID\_chromHMM.bed
bedtools intersect -wa -a $CHROM -b $CPEAK > $CONTROLID\_chromHMM.bed
#Calculate intersect stats
perl $CHROMCOUNT $SAMPLEID\_chromHMM.bed $SAMPLEID\_chromHMM_FREQ.out
perl $CHROMCOUNT $CONTROLID\_chromHMM.bed $CONTROLID\_chromHMM_FREQ.out 
perl $CHROMCOUNT $CHROM Genome_chromHMM_FREQ.out 
perl $LOG $SAMPLEID\_chromHMM_FREQ.out $CONTROLID\_chromHMM_FREQ.out $SAMPLEID\_chromHMM_LOG2.out
#Output stats to *info.txt
cat $SAMPLEID\_chromHMM_FREQ.out | head -n 2 > chromHMM-info.txt
cat $CONTROLID\_chromHMM_FREQ.out | head -n 2 | tail -1 >> chromHMM-info.txt
cat Genome_chromHMM_FREQ.out | head -n 3 | tail -1 >> chromHMM-info.txt
cat $SAMPLEID\_chromHMM_LOG2.out | head -n 2 | tail -1 >> chromHMM-info.txt
# Remove temp files
rm $SAMPLEID\_chromHMM.bed $CONTROLID\_chromHMM.bed

#Segway state count
echo "Segway intersect"
bedtools intersect -wa -a $SEGWAY -b $SPEAK > $SAMPLEID\_segway.bed
bedtools intersect -wa -a $SEGWAY -b $CPEAK > $CONTROLID\_segway.bed
#Calculate intersect stats
perl $SEGCOUNT $SAMPLEID\_segway.bed $SAMPLEID\_segway_FREQ.out
perl $SEGCOUNT $CONTROLID\_segway.bed $CONTROLID\_segway_FREQ.out
perl $SEGCOUNT $SEGWAY Genome_segway_FREQ.out
perl $LOG $SAMPLEID\_segway_FREQ.out $CONTROLID\_segway_FREQ.out $SAMPLEID\_segway_LOG2.out
#Output stats to *info.txt
cat $SAMPLEID\_segway_FREQ.out | head -n 2 > segway-info.txt
cat $CONTROLID\_segway_FREQ.out | head -n 2 | tail -1 >> segway-info.txt
cat Genome_segway_FREQ.out | head -n 3 | tail -1 >> segway-info.txt
cat $SAMPLEID\_segway_LOG2.out | head -n 2 | tail -1 >> segway-info.txt
# Remove temp files
rm $SAMPLEID\_segway.bed $CONTROLID\_segway.bed

# Make folder structure for testing sequence feature enrichment
mkdir -p $INPUT/sequence_state
cd $INPUT/sequence_state
#Repeat count
echo "RepeatElement intersect"
bedtools intersect -wa -a $REPEAT -b $SPEAK > $SAMPLEID\_repeat.bed
bedtools intersect -wa -a $REPEAT -b $CPEAK > $CONTROLID\_repeat.bed
#Calculate intersect stats
perl $REPEATCOUNT $SAMPLEID\_repeat.bed $SAMPLEID\_repeat_FREQ.out
perl $REPEATCOUNT $CONTROLID\_repeat.bed $CONTROLID\_repeat_FREQ.out
perl $REPEATCOUNT $REPEAT Genome_repeat_FREQ.out
perl $LOG $SAMPLEID\_repeat_FREQ.out $CONTROLID\_repeat_FREQ.out $SAMPLEID\_repeat_LOG2.out
#Output stats to *info.txt
cat $SAMPLEID\_repeat_FREQ.out | head -n 2 > repeatelement-info.txt
cat $CONTROLID\_repeat_FREQ.out | head -n 2 | tail -1 >> repeatelement-info.txt
cat Genome_repeat_FREQ.out | head -n 3 | tail -1 >> repeatelement-info.txt
cat $SAMPLEID\_repeat_LOG2.out | head -n 2 | tail -1 >> repeatelement-info.txt
# Remove temp files
rm $SAMPLEID\_repeat.bed $CONTROLID\_repeat.bed
