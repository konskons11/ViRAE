#!/bin/bash
### SCRIPT EXECUTION PARAMETERS
print_usage() {
	echo "
# DESCRIPTION:
ZWA2 is a context-based trimming bioinformatics tool for virus genome RNA-seq read decontamination based on a given reference.
The tool dissects chimera reads that arise during NGS, removing chimeric moieties with the user input reference. 
The clean output reads are then ready to be fed into de novo assemblers, increasing the availability of reads for more accurate and more efficacious de novo virus genome assembly.

# REQUIRED ARGUMENTS (FULL ZWA2 DEPLOYMENT):
-i <string>,	directory of INPUT NGS READS file (.fastq, .fq or .gz extension)
-r <string>,	directory of INPUT REFERENCE file (.fasta, .fa, .fna, .fsta or .gz extension)
-o <string>,	directory of OUTPUT folder

# REQUIRED ARGUMENTS (PARTIAL ZWA2 DEPLOYMENT):
-m <string>,	directory of MAPPED NGS READS on REFERENCE file (.bam extension)
-o <string>,	directory of OUTPUT folder

# OPTIONAL ARGUMENTS:
-u <string>,	directory of UNMAPPED NGS READS on REFERENCE file (.bam, .fastq, .fq or .gz extension) (ZWA2 partial deployment ONLY)
-l <integer>,	BWA alignment stringency value (default value 30)

# RUN EXAMPLES:
./ZWA2.sh -i reads.fastq -r ref.fasta -o ./
./ZWA2.sh -m mapped.bam -o ./
./ZWA2.sh -m mapped.bam -u unmapped.bam -o ./
"
}

if [[ $# -eq 0 ]] ; then
	print_usage
	exit 1
elif [[ ! $@ =~ ^\-.+ ]] ; then
	echo "No arguments passed ! See help below"
	print_usage
	exit 1
fi

while getopts ':i:r:m:u:o:l:' flag; do
	case "${flag}" in
		i)	input_reads="${OPTARG}"
			;;
		r)	input_ref="${OPTARG}"
			;;
		m)  mapped_input="${OPTARG}"
            ;;
        u)  unmapped_input="${OPTARG}"
            ;;
        o)	output="${OPTARG}"
			;;
		l)	alignment_stringency_value="${OPTARG}"
			;;
		*)	print_usage
			exit 1
			;;
	esac
done

if [[ -z $alignment_stringency_value ]] ; then
	alignment_stringency_value=30
	alignment_stringency_mode="default"
elif [ "$alignment_stringency_value" -eq "$alignment_stringency_value" 2>/dev/null ] && [ $alignment_stringency_value -gt 0 2>/dev/null ] ; then
	# stringent alignment
	if [[ $alignment_stringency_value -gt 30 ]] ; then
		alignment_stringency_mode="stringent"
	# default/std
	elif [[ $alignment_stringency_value -eq 30 ]] ; then
		alignment_stringency_mode="default"
	# loose alignment
	elif [[ $alignment_stringency_value -lt 30 ]] ; then
		alignment_stringency_mode="loose"
	fi
else
	print_usage
	echo "Please enter a valid integer number for alignment stringency !!!"
	exit 1
fi

if [ -z $output ] ; then
    echo "Invalid output directory !!! Please specify an output directory"
    exit
fi

if ([ ! -z "$input_reads" ] && [ ! -z "$input_ref" ]) && ([ -z "$mapped_input" ] && [ -z "$unmapped_input" ]) ; then
    echo "##### ZWA2 #####"
    echo -e "\nCOMMAND LINE INPUT\n-i $input_reads\n-r $input_ref\n-o $output\n-l $alignment_stringency_value"

    # Check if input files have valid extensions
    input_reads_extension=$(echo ${input_reads##*.} | tr '[[:upper:]]' '[[:lower:]]' )
    input_ref_extension=$(echo ${input_ref##*.} | tr '[[:upper:]]' '[[:lower:]]' )

    if [[ $input_reads_extension != "fastq" && $input_reads_extension != "fq" && $input_reads_extension != "gz" ]] ; then
        echo "Invalid fastq file !!! Make sure file has .fastq, .fq or .gz extension"
        exit
    elif [[ $input_ref_extension != "fasta" && $input_ref_extension != "fa" && $input_ref_extension != "fna" && $input_ref_extension != "fsta" && $input_ref_extension != "gz" ]] ; then
    	echo "Invalid fasta file !!! Make sure file has .fasta, .fa, .fna, .fsta or .gz extension"
    	exit
    else
        input_reads_filename=$(basename $input_reads .$input_reads_extension)
        input_ref_filename=$(basename $input_ref .$input_ref_extension) 
        input_ref_dirname=$(realpath $(dirname $input_ref))

        output_directory="$output/ZWA-${input_reads_filename}_ON_${input_ref_filename}"
        mkdir -m a=rwx $output_directory
    fi

elif ([ -z $input_reads ] && [ -z $input_ref ]) && [ ! -z $mapped_input ] ; then
    # Check if input files have valid extensions
    mapped_input_extension=$(echo ${mapped_input##*.} | tr '[[:upper:]]' '[[:lower:]]' )

    if [[ $mapped_input_extension != "bam" ]] ; then
        echo "Invalid mapped reads file !!! Make sure file has .bam extension"
        exit
    else
        echo "##### ZWA2 #####"
        echo -e "\nCOMMAND LINE INPUT\n-m $mapped_input"

        mapped_input_filename=$(basename $mapped_input .$mapped_input_extension)

        output_directory="$output/ZWA-${mapped_input_filename}"
        mkdir -m a=rwx $output_directory

        if [ ! -z $unmapped_input ] ; then
            unmapped_input_extension=$(echo ${unmapped_input##*.} | tr '[[:upper:]]' '[[:lower:]]' )

            if [[ $unmapped_input_extension != "bam" && $unmapped_input_extension != "fastq" && $unmapped_input_extension != "fq" && $unmapped_input_extension != "gz" ]] ; then
                echo "Invalid unmapped reads file !!! Make sure file has .bam, .fastq, .fq or .gz extension"
                exit
            else
                echo -e "\n-u $unmapped_input\n-o $output"
            fi
        else
            echo -e "\n-o $output"
        fi
    fi

else
    print_usage
    exit
fi
###



### MAIN SCRIPT
### FUNCTION BWA MAPPING
bwa_mapping() {
    threads_count=$(nproc --all)

    if [[ $1 == "$input_ref" && $2 == "$input_reads" ]] ; then
        bwa_mapping_start_time=$(date +%s)
        
        echo -e "\nPerforming $alignment_stringency_mode BWA alignment, please wait..."

        # Bwa align input reads on reference
        index=$(find $input_ref_dirname -maxdepth 1 -type f -name "$input_ref_filename.$input_ref_extension*.amb" -o -name "$input_ref_filename.$input_ref_extension*.ann" -o -name "$input_ref_filename.$input_ref_extension*.pac" -o -name "$input_ref_filename.$input_ref_extension*.bwt" -o -name "$input_ref_filename.$input_ref_extension*.sa")

        if [[ $(wc -l <<< "$index" | bc) -eq 5 ]] ; then
            echo "Reference file already indexed, proceeding to next step"
        else
            bwa index $1 2>/dev/null
        fi

        bwa mem -t $threads_count -v 0 -T $alignment_stringency_value $1 $2 2>/dev/null > $output_directory/bwa.sam

        # Get BWA fully & partially mapped reads
        samtools view -b -F 4 $output_directory/bwa.sam > $output_directory/reads_mapped.bam
        samtools sort $output_directory/reads_mapped.bam > $output_directory/sort_reads_mapped.bam
        samtools index $output_directory/sort_reads_mapped.bam

        # Get BWA unmapped reads & convert bam to fastq
        samtools view -b -f 4 $output_directory/bwa.sam > $output_directory/reads_unmapped.bam
        
        # Convert bam to fastq (WARNING samtools bam2fq keep 1 of paired-end reads !!! reformat.sh or bedtools bamtofastq, they keep secondary aligned reads and paired-end reads)
        samtools view $output_directory/reads_unmapped.bam | awk -F'\t' '{print "@"$1"\n"$10"\n+\n"$11}' > $output_directory/unmapped.fastq 

        # Transfer unmapped sequences into clean FASTQ
        cat $output_directory/unmapped.fastq > $output_directory/$input_reads_filename.ZWA_cleaned.fastq
        
    elif [[ $1 == "$mapped_input" ]] ; then
        bwa_mapping_start_time=$(date +%s)
        
        samtools sort $1 > $output_directory/sort_reads_mapped.bam
        samtools index $output_directory/sort_reads_mapped.bam

        if [[ $2 == "$unmapped_input" ]] ; then
            if [[ $unmapped_input_extension == "bam" ]] ; then
                samtools view $2 | awk -F'\t' '{print "@"$1"\n"$10"\n+\n"$11}' > $output_directory/unmapped.fastq 
                cat $output_directory/unmapped.fastq > $output_directory/$mapped_input_filename.ZWA_cleaned.fastq
            elif [[ $unmapped_input_extension == "fastq" || $unmapped_input_extension == "fq" ]] ; then
                cat $2 > $output_directory/unmapped.fastq
                cat $output_directory/unmapped.fastq > $output_directory/$mapped_input_filename.ZWA_cleaned.fastq
            elif [[ $unmapped_input_extension == "gz" ]] ; then
                zcat < $2 > $output_directory/unmapped.fastq
                zcat < $2 > $output_directory/$mapped_input_filename.ZWA_cleaned.fastq
            fi
        fi
    
    fi

    samtools view $output_directory/sort_reads_mapped.bam | awk -F'\t' '$6 ~ /S/ {print $1,$3,$6,$10,$11,length($10)}' OFS="\t" > $output_directory/softclipped.tsv
    samtools view $output_directory/sort_reads_mapped.bam | awk -F'\t' '$6 !~ /S/ && $6 !~ /H/ {print $1,$3,$6,$10,length($10),$10,length($10),1,length($10),"-","-","-","-","-","-","-","-","-","-"}' OFS="\t" > $output_directory/fully_mapped.tsv
    
    bwa_mapping_end_time=$(date +%s)
    bwa_mapping_execution_time=$((bwa_mapping_end_time-bwa_mapping_start_time))

}
###


### FUNCTION HYBRIDS CLEANING
chimeric_reads_cleaning() {
    
    chimeric_reads_cleaning_start_time=$(date +%s)

    echo -e "\nCleaning hybrids, please wait..."

    # Keep hybrid reads (partially mapped on ref) which contain softclipping CIGAR "S" flag and are primarily aligned
    awk -F'\t' '{seq=$4; quality=$5; seq_length=$6 ; split($3,cigar_flag,/[0-9]*/) ; split($3,cigar_flag_length,/[SMDIN]/); if (cigar_flag[2]=="S") {left_softclipped_seq_start=1 ; left_softclipped_seq_end=cigar_flag_length[1]; left_softclipped_seq=substr(seq,1,cigar_flag_length[1]); left_softclipped_seq_quality=substr(quality,1,cigar_flag_length[1]); left_softclipped_seqlength=length(left_softclipped_seq) } else {left_softclipped_seq_start="-" ; left_softclipped_seq_end="-"; left_softclipped_seq="-"; left_softclipped_seq_quality="-"; left_softclipped_seqlength="-"} ; if (cigar_flag[length(cigar_flag)]=="S") {right_softclipped_seq_start=seq_length-cigar_flag_length[length(cigar_flag_length)-1]+1; right_softclipped_seq_end=seq_length ; right_softclipped_seq=substr(seq,right_softclipped_seq_start,seq_length-1); right_softclipped_seq_quality=substr(quality,right_softclipped_seq_start,seq_length-1); right_softclipped_seqlength=length(right_softclipped_seq)} else {right_softclipped_seq_start="-"; right_softclipped_seq_end="-"; right_softclipped_seq="-"; right_softclipped_seq_quality="-"; right_softclipped_seqlength="-"} ; print $0,left_softclipped_seq_start,left_softclipped_seq_end,left_softclipped_seq,left_softclipped_seq_quality,left_softclipped_seqlength,right_softclipped_seq_start,right_softclipped_seq_end,right_softclipped_seq,right_softclipped_seq_quality,right_softclipped_seqlength }' OFS="\t" $output_directory/softclipped.tsv > $output_directory/hybrids.tsv
    awk -F'\t' '$7 != "-" && $12 == "-" {mapped_start=$8+1 ; mapped_end=$6; print $1,$2,$3,mapped_start,mapped_end,$4,$5,$6}' OFS="\t" $output_directory/hybrids.tsv > $output_directory/right_mapped.tsv
    awk -F'\t' '$12 != "-" && $7 == "-" {mapped_start=1 ; mapped_end=$12-1; print $1,$2,$3,mapped_start,mapped_end,$4,$5,$6}' OFS="\t" $output_directory/hybrids.tsv > $output_directory/left_mapped.tsv
    awk -F'\t' '$12 != "-" && $7 != "-" {mapped_start=$8+1 ; mapped_end=$12-1; print $1,$2,$3,mapped_start,mapped_end,$4,$5,$6}' OFS="\t" $output_directory/hybrids.tsv > $output_directory/middle_mapped.tsv

    cat $output_directory/left_mapped.tsv $output_directory/right_mapped.tsv $output_directory/middle_mapped.tsv > $output_directory/hybrids.tsv
    percentage10=$(awk -F'\t' '{p10=$8*0.1 ; print p10}' $output_directory/hybrids.tsv)
    percentage90=$(awk -F'\t' '{p90=$8*0.9 ; print p90}' $output_directory/hybrids.tsv)

    paste $output_directory/hybrids.tsv <(echo "$percentage10") <(echo "$percentage90") > $output_directory/tmp && mv $output_directory/tmp $output_directory/hybrids.tsv

    awk -F'\t' '{fullseq=$6; fullseq_quality=$7; fullseq_length=$8; mapped_span=$5-$4+1; mapped_seq=substr(fullseq,$4,mapped_span); mapped_seq_length=length(mapped_seq) ; if ($5>$10) {if ($4==1){left_softclipped_seq_start="-" ; left_softclipped_seq_end="-"; left_softclipped_seq="-"; left_softclipped_seq_quality="-"; left_softclipped_seqlength="-"} else {left_softclipped_seq_start=1 ; left_softclipped_seq_end=$4-1; left_softclipped_seq=substr(fullseq,1,$4-1); left_softclipped_seq_quality=substr(fullseq_quality,1,$4-1); left_softclipped_seqlength=length(left_softclipped_seq)} } else {left_softclipped_seq_start="-" ; left_softclipped_seq_end="-"; left_softclipped_seq="-"; left_softclipped_seq_quality="-"; left_softclipped_seqlength="-"} ; if ($4<$9) {if ($5==fullseq_length){right_softclipped_seq_start="-" ; right_softclipped_seq_end="-"; right_softclipped_seq="-"; right_softclipped_seq_quality="-"; right_softclipped_seqlength="-"} else {right_softclipped_seq_span=fullseq_length-$5 ; right_softclipped_seq_start=$5+1 ; right_softclipped_seq_end=right_softclipped_seq_start+right_softclipped_seq_span-1 ; right_softclipped_seq=substr(fullseq,$5+1,right_softclipped_seq_span); right_softclipped_seq_quality=substr(fullseq_quality,$5+1,right_softclipped_seq_span); right_softclipped_seqlength=length(right_softclipped_seq)}} else {right_softclipped_seq_start="-" ; right_softclipped_seq_end="-"; right_softclipped_seq="-"; right_softclipped_seq_quality="-"; right_softclipped_seqlength="-"} ; print $1,$2,$3,fullseq,fullseq_length,mapped_seq,mapped_seq_length,$4,$5,left_softclipped_seq_start,left_softclipped_seq_end,left_softclipped_seq,left_softclipped_seq_quality,left_softclipped_seqlength,right_softclipped_seq_start,right_softclipped_seq_end,right_softclipped_seq,right_softclipped_seq_quality,right_softclipped_seqlength }' OFS="\t" $output_directory/hybrids.tsv > $output_directory/tmp && mv $output_directory/tmp $output_directory/hybrids.tsv
    
    # Make separate left_softclipped.fasta and right_softclipped.fasta, discard empty sequences
    awk -F'\t' '$10 != "-" {print "@"$1":"$10"-"$11"\n"$12"\n+\n"$13}' $output_directory/hybrids.tsv >  $output_directory/left_softclipped.fastq
    awk -F'\t' '$15 != "-" {print "@"$1":"$15"-"$16"\n"$17"\n+\n"$18}' $output_directory/hybrids.tsv >  $output_directory/right_softclipped.fastq
    
    # Send to clean FASTQ
    if [ ! -z $input_reads ] && [ ! -z $input_ref ] ; then
        cat  $output_directory/left_softclipped.fastq  $output_directory/right_softclipped.fastq  >> $output_directory/$input_reads_filename.ZWA_cleaned.fastq
        
        gzip $output_directory/$input_reads_filename.ZWA_cleaned.fastq &
        zip_clean_fastq_process_id=$!
    elif [ ! -z $mapped_input ] ; then
        cat  $output_directory/left_softclipped.fastq  $output_directory/right_softclipped.fastq  >> $output_directory/$mapped_input_filename.ZWA_cleaned.fastq
        
        gzip $output_directory/$mapped_input_filename.ZWA_cleaned.fastq &
        zip_clean_fastq_process_id=$!
    fi

    chimeric_reads_cleaning_end_time=$(date +%s)
    chimeric_reads_cleaning_execution_time=$((chimeric_reads_cleaning_end_time-chimeric_reads_cleaning_start_time))

}
###


### FUNCTION REPORT READS COUNT
reads_count_analysis() {

    if ([ ! -z $input_reads ] && [ ! -z $input_ref ]) || [ ! -z $unmapped_input ] ; then
        total_unmapped_reads_count=$(($(wc -l < $output_directory/unmapped.fastq | bc)/4))
    else 
        total_unmapped_reads_count=0
    fi

    total_mapped_reads_count=$(samtools view $output_directory/sort_reads_mapped.bam | awk -F'\t' '$6 !~ /H/' | wc -l | bc)
    total_input_reads_count=$((total_unmapped_reads_count+total_mapped_reads_count))

    softclipped_reads_count=$(samtools view $output_directory/sort_reads_mapped.bam | awk -F'\t' '$6 ~ /S/' | wc -l | bc)
    percent_softclipped_reads_count=$(LC_NUMERIC="en_US.UTF-8" printf "%.2f" $(bc -l <<< $softclipped_reads_count/$total_mapped_reads_count*100))

    fully_mapped_reads_count=$((total_mapped_reads_count-softclipped_reads_count))
    percent_fully_mapped_reads_count=$(LC_NUMERIC="en_US.UTF-8" printf "%.2f" $(bc -l <<< $fully_mapped_reads_count/$total_mapped_reads_count*100))
        
    echo -e "\nAlignment results"
    echo "Total reads:     $total_input_reads_count"
    echo "Mapped reads:    $total_mapped_reads_count ($fully_mapped_reads_count / $percent_fully_mapped_reads_count% fully mapped + $softclipped_reads_count / $percent_softclipped_reads_count% partially mapped/softclipped)"
    echo "Unmapped reads:  $total_unmapped_reads_count"
        
}
###


### FUNCTION WRITE FINAL REPORT FILE
write_report() {
    
    average_mapped_bases_of_softclipped_reads=$(awk -F'\t' '{mapped+=$7} END {print mapped/NR}' $output_directory/hybrids.tsv )
    percent_average_mapped_bases_of_softclipped_reads=$(awk -F'\t' '{percent+=$7/$5*100} END {print percent/NR}' $output_directory/hybrids.tsv )

    zwa_discarded_softclipped_reads_count=$(awk -F'\t' '$10 == "-" && $15 == "-"' $output_directory/hybrids.tsv | wc -l | bc )
    percent_zwa_discarded_softclipped_reads_count=$(LC_NUMERIC="en_US.UTF-8" printf "%.2f" $(bc -l <<< $zwa_discarded_softclipped_reads_count/$softclipped_reads_count*100))
    total_discarded_reads_count=$((zwa_discarded_softclipped_reads_count+fully_mapped_reads_count))

    zwa_cleaned_softclipped_reads_count=$((softclipped_reads_count-zwa_discarded_softclipped_reads_count))
    percent_zwa_cleaned_softclipped_reads_count=$(LC_NUMERIC="en_US.UTF-8" printf "%.2f" $(bc -l <<< $zwa_cleaned_softclipped_reads_count/$softclipped_reads_count*100))
    total_clean_reads_count=$((zwa_cleaned_softclipped_reads_count+total_unmapped_reads_count))

    echo -e "\nCleaning results"
    echo "Discarded reads: $zwa_discarded_softclipped_reads_count ($percent_zwa_discarded_softclipped_reads_count% of softclipped reads)"
    echo "Cleaned reads:   $zwa_cleaned_softclipped_reads_count ($percent_zwa_cleaned_softclipped_reads_count% of softclipped reads)"
    echo "ZWA clean reads: $total_clean_reads_count"

    zwa_execution_time=$((bwa_mapping_execution_time+chimeric_reads_cleaning_execution_time))
    
    header=$(echo -e "Read_ID\tRefID\tCIGAR\tRead_seq\tRead_seqlength\tMapped_seq\tMapped_seq_length\tMapped_start\tMapped_end\tLeft_softclipped_seq_start\tLeft_softclipped_seq_end\tLeft_softclipped_seq\tLeft_softclipped_seq_quality\tLeft_softclipped_seqlength\tRight_softclipped_seq_start\tRight_softclipped_seq_end\tRight_softclipped_seq\tRight_softclipped_seq_quality\tRight_softclipped_seqlength" )
    footer=$(echo -e "(-) Sequence discarded\nBWA alignment stringency\t$alignment_stringency_value\nTotal input reads\t$total_input_reads_count\nTotal unmapped reads\t$total_unmapped_reads_count\nTotal mapped reads\t$total_mapped_reads_count\nFully mapped reads\t$fully_mapped_reads_count\nFully mapped reads/Total mapped reads (%)\t$percent_fully_mapped_reads_count\nPartially mapped (softclipped) reads\t$softclipped_reads_count\nPartially mapped (softclipped) reads/Total mapped reads (%)\t$percent_softclipped_reads_count\nAverage mapped bases\t$average_mapped_bases_of_softclipped_reads\nAverage mapped bases/Average read length (%)\t$percent_average_mapped_bases_of_softclipped_reads\nZWA cleaned softclipped reads\t$zwa_cleaned_softclipped_reads_count\nZWA cleaned softclipped reads/Softclipped reads (%)\t$percent_zwa_cleaned_softclipped_reads_count\nTotal clean reads (Unmapped+ZWA cleaned)\t$total_clean_reads_count\nZWA discarded softclipped reads\t$zwa_discarded_softclipped_reads_count\nZWA discarded softclipped reads/Softclipped reads (%)\t$percent_zwa_discarded_softclipped_reads_count\nTotal discarded reads (Fully mapped+ZWA discarded)\t$total_discarded_reads_count\nExecution time (seconds)\t$zwa_execution_time" )

    cat <(echo "$header") $output_directory/fully_mapped.tsv $output_directory/hybrids.tsv <(echo "$footer") > $output_directory/ZWA_cleaning_report.out

    gzip $output_directory/ZWA_cleaning_report.out &
    zip_zwa_report_process_id=$!
    
    wait $zip_zwa_report_process_id
    wait $zip_clean_fastq_process_id

    chmod 777 $output_directory/*.gz
}
###



### MAIN - CALL FUNCTIONS
echo "Executing ZWA..."

if [ ! -z $input_reads ] && [ ! -z $input_ref ] ; then
    bwa_mapping $input_ref $input_reads
elif [ ! -z $mapped_input ] ; then
    if [ -z $unmapped_input ] ; then
        bwa_mapping $mapped_input
    else
        bwa_mapping $mapped_input $unmapped_input
    fi
fi
reads_count_analysis

# if there are hybrids reads, then clean
if [[ $softclipped_reads_count -gt 0 ]] ; then

    chimeric_reads_cleaning
    write_report

    echo -e "\nZWA2 script completed successfully !!!"
    
    # Cleanup unnecessary files 
    rm -rf $output_directory/*softclipped* $output_directory/*mapped*
    rm -rf $output_directory/*.bam* $output_directory/*.sam $output_directory/*.tsv $output_directory/*.txt            

# if there are no hybrids reads but only unmapped, then keep only unmapped as clean
elif [[ $softclipped_reads_count -eq 0 && $total_unmapped_reads_count -gt 0 ]] ; then
    echo -e "\nAll reads unmapped against $input_ref_filename database !!!"

    # Cleanup unnecessary files 
    rm -rf $output_directory/*softclipped* $output_directory/*mapped*
    rm -rf $output_directory/*.bam* $output_directory/*.sam $output_directory/*.tsv $output_directory/*.txt            

# if all reads are fully mapped with no hubrids, then no need to clean
elif [[ $softclipped_reads_count -eq 0 && $total_unmapped_reads_count -eq 0 ]] ; then
    echo -e "\nAll reads fully aligned against $input_ref_filename database, no hybrids or unmapped reads !!!"
    rm -rf $output_directory
    exit
fi
