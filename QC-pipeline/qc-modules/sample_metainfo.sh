#!/bin/sh

# Required software for this module:
# samtools 1.7+
# bedtools 2+
# Java 8+
# perl 5.10+

#Ends script if any of the shell commands fail
set -e

usage()
{
    echo 'sample_metainfo.sh -i <INPUT PATH> -s <SampleID> -c <ControlID> -a <Path to scripts> -r <Path to references>'
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

SBAM=$INPUT/$SAMPLEID\.bam
CBAM=$INPUT/$CONTROLID\.bam

# PICARD jar
PICARD=$SCRIPT/external_app/picard.jar
# # FastQC
# FASTQC=$SCRIPT/external_app/FastQC/fastqc

# Text parsers
BAMSTATS=$SCRIPT/external_app/picard_parsers/parse_BamIndexStats.pl

#Blacklist filter
BLACKLIST=$REF/Blacklist/hg19_Blacklist.bed

# Make BAM index for Sample and Control BAM files
echo "Generating BAI index files..."
samtools index $SBAM $INPUT/$SAMPLEID".bam.bai"
samtools index $CBAM $INPUT/$CONTROLID".bam.bai"
echo "Complete"

# Remove any existing meta-information file
rm -f $INPUT/metainformation-info.txt
# Output sample ID to meta-information file
echo -e "SampleID:\t$SAMPLEID" >> $INPUT/metainformation-info.txt

# Get number of aligned reads in sample BAM
java -jar $PICARD BamIndexStats I=$SBAM > $INPUT/sample_bam_stats.out
READS=$(perl $BAMSTATS $INPUT/sample_bam_stats.out)
echo -e "Total Reads:\t$READS" >> $INPUT/metainformation-info.txt
# Get number of aligned reads in control BAM
java -jar $PICARD BamIndexStats I=$CBAM > $INPUT/control_bam_stats.out


