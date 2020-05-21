#!/bin/bash

## Shell script to run the mammalian QC pipeline on the cluster

usage()
{
    echo '00_RUN_MEP_QC.sh -s <sampleID.txt> -a <FULL Path to Scripts directory>'
    exit
}

if [ "$#" -ne 4 ]
then
    usage
fi

while getopts ":s:a:" IN; do
    case "${IN}" in
        s)
            s=${OPTARG}
            ;;
        a)
            SCRIPT=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${s}" ] || [ -z "${SCRIPT}" ]; then
    usage
fi

echo "s = ${s}"
echo "a = ${SCRIPT}"
bname=$(basename $s)

#Set sample path here
SAMPLEPATH=/gpfs/group/bfp2/default/pughlab-members/wkl2-WillLai/MEP_Project/QC
mkdir -p $SAMPLEPATH

while read line; do
        sampleID="$(cut -f1 <<<"$line")"
        sampleBAM="$(cut -f2 <<<"$line")"
        controlID="CONTROL"
        controlBAM="$(cut -f3 <<<"$line")"
        controlBED=$(echo $controlBAM | sed "s/.bam/.bed/g")
        REF="$(cut -f4 <<<"$line")"

	if [ "$sampleID" != "SampleID" ] && ! [[ "$sampleID" =~ "#" ]]
        then
		rm -f $SAMPLEPATH/$sampleID\.pbs
		
		echo "#!/bin/bash" >> $SAMPLEPATH/$sampleID\.pbs
		echo "#PBS -l nodes=1:ppn=4" >> $SAMPLEPATH/$sampleID\.pbs
		echo "#PBS -l pmem=24gb" >> $SAMPLEPATH/$sampleID\.pbs
		echo "#PBS -l walltime=24:00:00" >> $SAMPLEPATH/$sampleID\.pbs
		echo "#PBS -A open" >> $SAMPLEPATH/$sampleID\.pbs
		
		echo "# Set run directory" >> $SAMPLEPATH/$sampleID\.pbs
		echo "cd $SAMPLEPATH" >> $SAMPLEPATH/$sampleID\.pbs

		echo "# Load all modules" >> $SAMPLEPATH/$sampleID\.pbs
		echo "module load python/2.7.14-anaconda5.0.1" >> $SAMPLEPATH/$sampleID\.pbs

		echo "#Initialize files for QC analysis" >> $SAMPLEPATH/$sampleID\.pbs
		echo "mkdir -p $sampleID" >> $SAMPLEPATH/$sampleID\.pbs
                echo "ln -fs $sampleBAM $sampleID/$sampleID\.bam" >> $SAMPLEPATH/$sampleID\.pbs
                echo "ln -fs $controlBAM $sampleID/$controlID\.bam" >> $SAMPLEPATH/$sampleID\.pbs
                echo "ln -fs $controlBED $sampleID/$controlID\.bed" >> $SAMPLEPATH/$sampleID\.pbs

		echo "#QC Modules" >> $SAMPLEPATH/$sampleID\.pbs
		echo "SAMPLEMETA=$SCRIPT/qc-modules/sample_metainfo.sh" >> $SAMPLEPATH/$sampleID\.pbs
		echo "PEAKCALL=$SCRIPT/qc-modules/peak_calling_ChExMix.sh" >> $SAMPLEPATH/$sampleID\.pbs
		echo "SUBTYPEANALYSIS=$SCRIPT/qc-modules/subtype_analysis.sh" >> $SAMPLEPATH/$sampleID\.pbs
		echo "APRIORIMOTIF=$SCRIPT/qc-modules/apriori_motif_discovery.sh" >> $SAMPLEPATH/$sampleID\.pbs
		echo "ANNOTATE=$SCRIPT/qc-modules/genome_annotation_enrichment.sh" >> $SAMPLEPATH/$sampleID\.pbs
		echo "FEATUREPILEUP=$SCRIPT/qc-modules/feature_pileup.sh" >> $SAMPLEPATH/$sampleID\.pbs
                echo "# Initialize sample QC" >> $SAMPLEPATH/$sampleID\.pbs
                echo "sh \$SAMPLEMETA -i $SAMPLEPATH//$sampleID -s $sampleID -c $controlID -r $REF -a $SCRIPT" >> $SAMPLEPATH/$sampleID\.pbs
                echo "# Peak calling" >> $SAMPLEPATH/$sampleID\.pbs
                echo "sh \$PEAKCALL -i $SAMPLEPATH//$sampleID -s $sampleID -c $controlID -r $REF -a $SCRIPT" >> $SAMPLEPATH/$sampleID\.pbs
                echo "# ChExMix motif analysis" >> $SAMPLEPATH/$sampleID\.pbs
                echo "sh \$SUBTYPEANALYSIS -i $SAMPLEPATH//$sampleID -s $sampleID -c $controlID -r $REF -a $SCRIPT" >> $SAMPLEPATH/$sampleID\.pbs
                echo "# a prioir motif enrichment" >> $SAMPLEPATH/$sampleID\.pbs
                echo "sh \$APRIORIMOTIF -i $SAMPLEPATH//$sampleID -s $sampleID -c $controlID -r $REF -a $SCRIPT" >> $SAMPLEPATH/$sampleID\.pbs
                echo "# State enrichment testing" >> $SAMPLEPATH/$sampleID\.pbs
                echo "sh \$ANNOTATE -i $SAMPLEPATH//$sampleID -s $sampleID -c $controlID -r $REF -a $SCRIPT" >> $SAMPLEPATH/$sampleID\.pbs
                echo "# Feature tag pileup" >> $SAMPLEPATH/$sampleID\.pbs
                echo "sh \$FEATUREPILEUP -i $SAMPLEPATH/$sampleID -s $sampleID -c $controlID -r $REF -a $SCRIPT" >> $SAMPLEPATH/$sampleID\.pbs
		
		qsub $SAMPLEPATH/$sampleID\.pbs
	fi
done < $s

