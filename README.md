# PCRPpipeline
Bioinformatic pipeline used to process PCRP datasets

## Pipeline requirements
* python 2.7.14
* python - matplotlib
* Java 8 or later
* perl v5.10.1 or later
* bedtools v2.27.1 or later
* samtools 1.7
* MEME v5+
* ChExMix v0.45 available here: https://github.com/seqcode/chexmix
* * Compiled JAR should be moved here: /QC-pipeline/external_app/

## Command to run pipeline:
`sh 11_RUN_MEP_QC_XO.sh -s sampleID.txt -a /path/to/QC-pipeline`

## sampleID.txt file format
4-column tab-delimited file containing the information required to run the pipeline for each sample

| SampleID | Full path to SAMPLE.bam | Full path to CONTROL.bam | Full path to Reference features |
| --- |---|---|---|

## Reference features folder structure
* REF/Genome
* * REF/Genome/hg19.fa
* * REF/Genome/hg19.fa.fai
* * REF/Genome/hg19.info
* * REF/Genome/hg19_background_model.txt
* REF/Blacklist
* * REF/Blacklist/hg19_Blacklist.bed
* REF/TSS
* * REF/TSS/hg19_TSS_2000bp.bed
* REF/CTCF
* * REF/CTCF/hg19_CTCF_2000bp.bed
* REF/Motif_Coord/
* * REF/Motif_Coord/JASPAR2020_CORE_vertebrates_non-redundant_pfms_meme.txt
* * REF/Motif_Coord/hg19_JASPAR2020_cluster_occurrence.tab
* * REF/Motif_Coord/JASPAR2020_cluster_ID.out
* * REF/Motif_Coord/hg19_JASPAR2020_MotifCluster.gff.gz
* * REF/Motif_Coord/TOMTOM_Fail.png
* * REF/Motif_Coord/NoMotifDetected.png
* * REF/Motif_Coord/JASPAR2020_weblogo/JASPAR_cluster_*.png
* REF/ChromatinState
* * REF/ChromatinState/chromHMM/chromHMM.bed.gz
* * REF/ChromatinState/segway/segway.bed.gz
* * REF/ChromatinState/Repeat/hg19_RepeatMasker.bed.gz
