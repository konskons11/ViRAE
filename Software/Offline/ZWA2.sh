#!/bin/bash
### SCRIPT EXECUTION PARAMETERS
print_usage() {
	echo "
# DESCRIPTION:
ZWA2 is a context-based trimming bioinformatics tool for virus genome RNA-seq read decontamination based on a given reference.
The tool dissects chimera reads that arise during NGS, removing chimeric moieties with the user input reference. 
The clean output reads are then ready to be fed into de novo assemblers, increasing the availability of reads for more accurate and more efficacious de novo virus genome assembly.

ZWA2 may be fully or partially deployed upon execution depending on the available user input files as shown below: 

# REQUIRED ARGUMENTS (FULL ZWA2 DEPLOYMENT):
-i <string>,	directory of INPUT NGS READS file (.fastq, .fq or .gz extension)
-r <string>,	directory of INPUT REFERENCE file (.fasta, .fa, .fna, .fsta or .gz extension)
-o <string>,	directory of OUTPUT folder

# REQUIRED ARGUMENTS (PARTIAL ZWA2 DEPLOYMENT):
-m <string>,	directory of MAPPED NGS READS on REFERENCE file (.bam extension)
-o <string>,	directory of OUTPUT folder

# OPTIONAL ARGUMENTS:
-u <string>,	directory of UNMAPPED NGS READS on REFERENCE file (.bam, .fastq, .fq or .gz extension) (ZWA2 partial deployment ONLY)
-l <integer>,	alignment stringency value (default value 30 | <30 loose, >30 stringent)
-t,             run ZWA2 on a test dataset to verify installation

# RUN EXAMPLES:
./ZWA2.sh -i reads.fastq -r ref.fasta -o ./
./ZWA2.sh -i reads.fastq -r ref.fasta -l 40 -o ./
./ZWA2.sh -m mapped.bam -o ./
./ZWA2.sh -m mapped.bam -u unmapped.bam -o ./
./ZWA2.sh -t

More information on ZWA2 can be found here:
https://github.com/konskons11/ZWA2/
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

while getopts ':i:r:m:u:o:l:t' flag; do
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
		t)	test_flag=true
			;;
		*)	print_usage
			exit 1
			;;
	esac
done

# Check if alignment stringency was adjusted
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

# Check type of user input files
if ([ ! -z "$input_reads" ] && [ ! -z "$input_ref" ]) && ([ -z "$mapped_input" ] && [ -z "$unmapped_input" ]) && [ ! -z $output ] ; then
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

        output_directory="$output/ZWA2-${input_reads_filename}_ON_${input_ref_filename}"
        mkdir -m a=rwx $output_directory
    fi

elif ([ -z $input_reads ] && [ -z $input_ref ]) && [ ! -z $mapped_input ] && [ ! -z $output ] ; then
    # Check if input files have valid extensions
    mapped_input_extension=$(echo ${mapped_input##*.} | tr '[[:upper:]]' '[[:lower:]]' )

    if [[ $mapped_input_extension != "bam" ]] ; then
        echo "Invalid mapped reads file !!! Make sure file has .bam extension"
        exit
    else
        echo "##### ZWA2 #####"
        echo -e "\nCOMMAND LINE INPUT\n-m $mapped_input"

        mapped_input_filename=$(basename $mapped_input .$mapped_input_extension)

        output_directory="$output/ZWA2-${mapped_input_filename}"
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

elif [[ -n $test_flag ]] ; then
    echo "##### ZWA2 #####"
    echo -e "\nCOMMAND LINE INPUT\n-t TRUE"

    output_directory="$PWD/ZWA2-test_reads_ON_test_ref"
    mkdir -m a=rwx $output_directory

else
    print_usage
    exit
fi
###



### MAIN SCRIPT
### FUNCTION DOWNLOAD ZWA2 PREREQUISITES
verify_zwa2_installation() {

    prerequisite="$1"
    desired_version="$2"

    installed_version=$(man "$prerequisite" 2>/dev/null | awk 'END{gsub("'"$prerequisite"'-","",$1) ; gsub(/-.*$/,"",$1) ; print $1}')
    echo "Checking for $desired_version version of $prerequisite..."

    # Download correct versions of prerequisites
    download_prerequisites () {
        system_type=$(uname -s)
        #macOS
        if [[ "$system_type" == "Darwin" ]] ; then
            if [ -z "$(man brew 2>/dev/null)" ] ; then
                echo "ERROR !!! Please make sure you have Homebrew installed, exiting now"
                exit
            else
                if [ "$prerequisite" == "bwa" ] ; then
                    brew install https://github.com/Homebrew/homebrew-core/blob/4b1fbe464f23a44f15bf8e28d6129a0547b1d3e4/Formula/bwa.rb >/dev/null 2>&1
                elif [ "$prerequisite" == "samtools" ] ; then
                    brew install https://github.com/Homebrew/homebrew-core/blob/8199697be49f02b9cbc225d98e5c25f553efe390/Formula/samtools.rb >/dev/null 2>&1
                fi
                brew tap-new $USER/local-"$prerequisite" >/dev/null 2>&1
                brew extract --version="$desired_version" "$prerequisite" $USER/local-"$prerequisite" >/dev/null 2>&1
                brew install "$prerequisite"@"$desired_version" >/dev/null 2>&1

                installed_version=$(man "$prerequisite" 2>/dev/null | awk 'END{gsub("'"$prerequisite"'-","",$1) ; print $1}')
                if [ -z "$installed_version" ] ; then
                    echo "ERROR !!! Please make sure your connected to the internet, exiting now"
                    exit
                else
                    echo "$prerequisite $installed_version correctly installed !!!"
                fi
            fi
        #Linux Ubuntu
        elif [[ "$system_type" == "Linux" ]] ; then
            if [ -z "$(man apt-get 2>/dev/null)" ] ; then
                echo "ERROR !!! Please make sure you have apt-get installed, exiting now"
                exit
            else
                if [ "$prerequisite" == "bwa" ] ; then
                    sudo apt-get install "$prerequisite"="$desired_version-6" >/dev/null 2>&1
                elif [ "$prerequisite" == "samtools" ] ; then
                    sudo apt-get install "$prerequisite"="$desired_version-4" >/dev/null 2>&1
                fi
                installed_version=$(man "$prerequisite" 2>/dev/null | awk 'END{gsub("'"$prerequisite"'-","",$1) ; print $1}')

                if [ -z "$installed_version" ] ; then
                    echo "ERROR !!! Please make sure you are connected to the internet and have provide root privileges for installation, exiting now"
                    exit
                else
                    echo "$prerequisite $installed_version correctly installed !!!"
                fi
            fi
        fi
    }

    # If prerequite not found, check system type and install
    if [ -z "$installed_version" ] ; then
        echo "$prerequisite $desired_version not installed !!! Downloading now, please wait..."
        download_prerequisites
    else
        # Split versions into numeric and non-numeric parts
        IFS='.' read -r -a v1_segments <<< "$(echo "$installed_version" | tr -cs '[:alnum:].' ' ')"
        IFS='.' read -r -a v2_segments <<< "$(echo "$desired_version" | tr -cs '[:alnum:].' ' ')"

        len=${#v1_segments[@]}
        if ((len < ${#v2_segments[@]})); then
            len=${#v2_segments[@]}
        fi

        for ((i = 0; i < len; i++)); do
            v1_seg=${v1_segments[i]:-0}
            v2_seg=${v2_segments[i]:-0}

            # Compare numeric parts as integers
            if [[ "$v1_seg" =~ ^[0-9]+$ ]] && [[ "$v2_seg" =~ ^[0-9]+$ ]]; then
                if ((v1_seg < v2_seg)); then
                    echo "$prerequisite version $installed_version is older than $desired_version !!! Now downloading the correction version, please wait..."
                    download_prerequisites
                elif ((v1_seg > v2_seg)); then
                    echo "$prerequisite version $installed_version is newer than $desired_version !!! Now downloading the correction version, please wait..."
                    download_prerequisites
                fi
            else
                # Compare non-numeric parts as strings
                if [[ "$v1_seg" < "$v2_seg" ]]; then
                    echo "$prerequisite version $installed_version is older than $desired_version !!! Now downloading the correction version, please wait..."
                    download_prerequisites
                elif [[ "$v1_seg" > "$v2_seg" ]]; then
                    echo "$prerequisite version $installed_version is newer than $desired_version !!! Now downloading the correction version, please wait..."
                    download_prerequisites
                fi
            fi
        done

        echo "$prerequisite $installed_version correctly installed !!!"
    fi

}
###


### FUNCTION BWA MAPPING
bwa_mapping() {
    
    system_type=$(uname -s)
    if [[ "$system_type" == "Darwin" ]] ; then
        threads_count=$(sysctl -n hw.ncpu)
    elif [[ "$system_type" == "Linux" ]] ; then
        threads_count=$(nproc --all)
    fi

    time (
    if [[ $1 == "$input_ref" && $2 == "$input_reads" ]] ; then
        input_ref_dirname=$(realpath $(dirname $input_ref))

        echo -e "\nPerforming $alignment_stringency_mode BWA alignment, please wait..."

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
        cat $output_directory/unmapped.fastq > $output_directory/$input_reads_filename.ZWA2_cleaned.fastq
                
    elif [[ $1 == "$mapped_input" ]] ; then
        
        samtools sort $1 > $output_directory/sort_reads_mapped.bam
        samtools index $output_directory/sort_reads_mapped.bam

        if [[ $2 == "$unmapped_input" ]] ; then
            if [[ $unmapped_input_extension == "bam" ]] ; then
                samtools view $2 | awk -F'\t' '{print "@"$1"\n"$10"\n+\n"$11}' > $output_directory/unmapped.fastq 
                cat $output_directory/unmapped.fastq > $output_directory/$mapped_input_filename.ZWA2_cleaned.fastq
            elif [[ $unmapped_input_extension == "fastq" || $unmapped_input_extension == "fq" ]] ; then
                cat $2 > $output_directory/unmapped.fastq
                cat $output_directory/unmapped.fastq > $output_directory/$mapped_input_filename.ZWA2_cleaned.fastq
            elif [[ $unmapped_input_extension == "gz" ]] ; then
                zcat < $2 > $output_directory/unmapped.fastq
                zcat < $2 > $output_directory/$mapped_input_filename.ZWA2_cleaned.fastq
            fi
        fi
    
    fi
    
    samtools view $output_directory/sort_reads_mapped.bam | awk -F'\t' '$6 ~ /S/ {print $1,$3,$6,$10,$11,length($10)}' OFS="\t" > $output_directory/softclipped.tsv
    samtools view $output_directory/sort_reads_mapped.bam | awk -F'\t' '$6 !~ /S/ && $6 !~ /H/ {print $1,$3,$6,$10,length($10),$10,length($10),1,length($10),"-","-","-","-","-","-","-","-","-","-"}' OFS="\t" > $output_directory/fully_mapped.tsv
    
    ) 3>&2 2>$output_directory/mapping_time.txt
    
    bwa_mapping_execution_time=$(awk '$1 == "real" {print $NF}' $output_directory/mapping_time.txt | awk -F'm|s' '{total=($1*60)+$2 ; print total}')
    

}
###


### FUNCTION CHIMERA CLEANING
chimeric_reads_cleaning() {
        
    time (
    echo -e "\nCleaning chimeric, please wait..."

    # Keep chimeric reads (partially mapped on ref) which contain softclipping CIGAR "S" flag and are primarily aligned
    # Keep only left and right softclipped sequences with their quality, discard mapped on ref
    awk -F'\t' '{seq=$4; quality=$5; seq_length=$6 ; split($3,cigar_flag,/[0-9]*/) ; split($3,cigar_flag_length,/[SMDIN]/); if (cigar_flag[2]=="S") {left_softclipped_seq_start=1 ; left_softclipped_seq_end=cigar_flag_length[1]; left_softclipped_seq=substr(seq,1,cigar_flag_length[1]); left_softclipped_seq_quality=substr(quality,1,cigar_flag_length[1]); left_softclipped_seqlength=length(left_softclipped_seq) } else {left_softclipped_seq_start="-" ; left_softclipped_seq_end="-"; left_softclipped_seq="-"; left_softclipped_seq_quality="-"; left_softclipped_seqlength="-"} ; if (cigar_flag[length(cigar_flag)]=="S") {right_softclipped_seq_start=seq_length-cigar_flag_length[length(cigar_flag_length)-1]+1; right_softclipped_seq_end=seq_length ; right_softclipped_seq=substr(seq,right_softclipped_seq_start,seq_length-1); right_softclipped_seq_quality=substr(quality,right_softclipped_seq_start,seq_length-1); right_softclipped_seqlength=length(right_softclipped_seq)} else {right_softclipped_seq_start="-"; right_softclipped_seq_end="-"; right_softclipped_seq="-"; right_softclipped_seq_quality="-"; right_softclipped_seqlength="-"} ; print $0,left_softclipped_seq_start,left_softclipped_seq_end,left_softclipped_seq,left_softclipped_seq_quality,left_softclipped_seqlength,right_softclipped_seq_start,right_softclipped_seq_end,right_softclipped_seq,right_softclipped_seq_quality,right_softclipped_seqlength }' OFS="\t" $output_directory/softclipped.tsv > $output_directory/chimeric.tsv
    awk -F'\t' '$7 != "-" && $12 == "-" {mapped_start=$8+1 ; mapped_end=$6; print $1,$2,$3,mapped_start,mapped_end,$4,$5,$6}' OFS="\t" $output_directory/chimeric.tsv > $output_directory/right_mapped.tsv
    awk -F'\t' '$12 != "-" && $7 == "-" {mapped_start=1 ; mapped_end=$12-1; print $1,$2,$3,mapped_start,mapped_end,$4,$5,$6}' OFS="\t" $output_directory/chimeric.tsv > $output_directory/left_mapped.tsv
    awk -F'\t' '$12 != "-" && $7 != "-" {mapped_start=$8+1 ; mapped_end=$12-1; print $1,$2,$3,mapped_start,mapped_end,$4,$5,$6}' OFS="\t" $output_directory/chimeric.tsv > $output_directory/middle_mapped.tsv

    cat $output_directory/left_mapped.tsv $output_directory/right_mapped.tsv $output_directory/middle_mapped.tsv > $output_directory/chimeric.tsv
    percentage10=$(awk -F'\t' '{p10=$8*0.1 ; print p10}' $output_directory/chimeric.tsv)
    percentage90=$(awk -F'\t' '{p90=$8*0.9 ; print p90}' $output_directory/chimeric.tsv)

    paste $output_directory/chimeric.tsv <(echo "$percentage10") <(echo "$percentage90") > $output_directory/tmp && mv $output_directory/tmp $output_directory/chimeric.tsv

    awk -F'\t' '{fullseq=$6; fullseq_quality=$7; fullseq_length=$8; mapped_span=$5-$4+1; mapped_seq=substr(fullseq,$4,mapped_span); mapped_seq_length=length(mapped_seq) ; if ($5>$10) {if ($4==1){left_softclipped_seq_start="-" ; left_softclipped_seq_end="-"; left_softclipped_seq="-"; left_softclipped_seq_quality="-"; left_softclipped_seqlength="-"} else {left_softclipped_seq_start=1 ; left_softclipped_seq_end=$4-1; left_softclipped_seq=substr(fullseq,1,$4-1); left_softclipped_seq_quality=substr(fullseq_quality,1,$4-1); left_softclipped_seqlength=length(left_softclipped_seq)} } else {left_softclipped_seq_start="-" ; left_softclipped_seq_end="-"; left_softclipped_seq="-"; left_softclipped_seq_quality="-"; left_softclipped_seqlength="-"} ; if ($4<$9) {if ($5==fullseq_length){right_softclipped_seq_start="-" ; right_softclipped_seq_end="-"; right_softclipped_seq="-"; right_softclipped_seq_quality="-"; right_softclipped_seqlength="-"} else {right_softclipped_seq_span=fullseq_length-$5 ; right_softclipped_seq_start=$5+1 ; right_softclipped_seq_end=right_softclipped_seq_start+right_softclipped_seq_span-1 ; right_softclipped_seq=substr(fullseq,$5+1,right_softclipped_seq_span); right_softclipped_seq_quality=substr(fullseq_quality,$5+1,right_softclipped_seq_span); right_softclipped_seqlength=length(right_softclipped_seq)}} else {right_softclipped_seq_start="-" ; right_softclipped_seq_end="-"; right_softclipped_seq="-"; right_softclipped_seq_quality="-"; right_softclipped_seqlength="-"} ; print $1,$2,$3,fullseq,fullseq_length,mapped_seq,mapped_seq_length,$4,$5,left_softclipped_seq_start,left_softclipped_seq_end,left_softclipped_seq,left_softclipped_seq_quality,left_softclipped_seqlength,right_softclipped_seq_start,right_softclipped_seq_end,right_softclipped_seq,right_softclipped_seq_quality,right_softclipped_seqlength }' OFS="\t" $output_directory/chimeric.tsv > $output_directory/tmp && mv $output_directory/tmp $output_directory/chimeric.tsv
    
    # Make separate left_softclipped.fasta and right_softclipped.fasta, discard empty sequences
    awk -F'\t' '$10 != "-" {print "@"$1":"$10"-"$11"\n"$12"\n+\n"$13}' $output_directory/chimeric.tsv >  $output_directory/left_softclipped.fastq
    awk -F'\t' '$15 != "-" {print "@"$1":"$15"-"$16"\n"$17"\n+\n"$18}' $output_directory/chimeric.tsv >  $output_directory/right_softclipped.fastq
    
    # Send to clean FASTQ
    if [ ! -z $input_reads ] && [ ! -z $input_ref ] ; then
        cat  $output_directory/left_softclipped.fastq  $output_directory/right_softclipped.fastq  >> $output_directory/$input_reads_filename.ZWA2_cleaned.fastq
        
        gzip $output_directory/$input_reads_filename.ZWA2_cleaned.fastq &
        zip_clean_fastq_process_id=$!
    elif [ ! -z $mapped_input ] ; then
        cat  $output_directory/left_softclipped.fastq  $output_directory/right_softclipped.fastq  >> $output_directory/$mapped_input_filename.ZWA2_cleaned.fastq
        
        gzip $output_directory/$mapped_input_filename.ZWA2_cleaned.fastq &
        zip_clean_fastq_process_id=$!
    fi
    ) 3>&2 2>$output_directory/cleaning_time.txt
    
    chimeric_reads_cleaning_execution_time=$(awk '$1 == "real" {print $NF}' $output_directory/cleaning_time.txt | awk -F'm|s' '{total=($1*60)+$2 ; print total}')

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
    echo "Mapped reads:    $total_mapped_reads_count [$fully_mapped_reads_count ($percent_fully_mapped_reads_count%) fully mapped + $softclipped_reads_count ($percent_softclipped_reads_count%) partially mapped/chimeric)]"
    echo "Unmapped reads:  $total_unmapped_reads_count"
        
}
###


### FUNCTION WRITE FINAL REPORT FILE
write_report() {
    
    average_mapped_bases_of_softclipped_reads=$(awk -F'\t' '{mapped+=$7} END {print mapped/NR}' $output_directory/chimeric.tsv )
    percent_average_mapped_bases_of_softclipped_reads=$(awk -F'\t' '{percent+=$7/$5*100} END {print percent/NR}' $output_directory/chimeric.tsv )

    zwa_discarded_softclipped_reads_count=$(awk -F'\t' '$10 == "-" && $15 == "-"' $output_directory/chimeric.tsv | wc -l | bc )
    percent_zwa_discarded_softclipped_reads_count=$(LC_NUMERIC="en_US.UTF-8" printf "%.2f" $(bc -l <<< $zwa_discarded_softclipped_reads_count/$softclipped_reads_count*100))
    total_discarded_reads_count=$((zwa_discarded_softclipped_reads_count+fully_mapped_reads_count))

    zwa2_cleaned_softclipped_reads_count=$((softclipped_reads_count-zwa_discarded_softclipped_reads_count))
    percent_zwa2_cleaned_softclipped_reads_count=$(LC_NUMERIC="en_US.UTF-8" printf "%.2f" $(bc -l <<< $zwa2_cleaned_softclipped_reads_count/$softclipped_reads_count*100))
    total_clean_reads_count=$((zwa2_cleaned_softclipped_reads_count+total_unmapped_reads_count))

    echo -e "\nCleaning results"
    echo "Discarded reads: $zwa_discarded_softclipped_reads_count ($percent_zwa_discarded_softclipped_reads_count% of chimeric reads)"
    echo "Cleaned reads:   $zwa2_cleaned_softclipped_reads_count ($percent_zwa2_cleaned_softclipped_reads_count% of chimeric reads)"
    echo "ZWA clean reads: $total_clean_reads_count"

    zwa2_execution_time=$(echo "$bwa_mapping_execution_time + $chimeric_reads_cleaning_execution_time" | bc -l)
    
    header=$(echo -e "Read_ID\tRefID\tCIGAR\tRead_seq\tRead_seqlength\tMapped_seq\tMapped_seq_length\tMapped_start\tMapped_end\tLeft_unmapped_seq_start\tLeft_unmapped_seq_end\tLeft_unmapped_seq\tLeft_unmapped_seq_quality\tLeft_unmapped_seqlength\tRight_unmapped_seq_start\tRight_unmapped_seq_end\tRight_unmapped_seq\tRight_unmapped_seq_quality\tRight_unmapped_seqlength" )
    footer=$(echo -e "(-) Sequence discarded\nBWA alignment stringency\t$alignment_stringency_value\nTotal input reads\t$total_input_reads_count\nTotal unmapped reads\t$total_unmapped_reads_count\nTotal mapped reads\t$total_mapped_reads_count\nFully mapped reads\t$fully_mapped_reads_count\nFully mapped reads/Total mapped reads (%)\t$percent_fully_mapped_reads_count\nPartially mapped (chimeric) reads\t$softclipped_reads_count\nPartially mapped (chimeric) reads/Total mapped reads (%)\t$percent_softclipped_reads_count\nAverage mapped bases\t$average_mapped_bases_of_softclipped_reads\nAverage mapped bases/Average read length (%)\t$percent_average_mapped_bases_of_softclipped_reads\nZWA2 cleaned chimeric reads\t$zwa2_cleaned_softclipped_reads_count\nZWA2 cleaned chimeric reads/Chimeric reads (%)\t$percent_zwa2_cleaned_softclipped_reads_count\nTotal clean reads (Unmapped+ZWA2 cleaned)\t$total_clean_reads_count\nZWA2 discarded chimeric reads\t$zwa_discarded_softclipped_reads_count\nZWA2 discarded chimeric reads/Chimeric reads (%)\t$percent_zwa_discarded_softclipped_reads_count\nTotal discarded reads (Fully mapped+ZWA2 discarded)\t$total_discarded_reads_count\nExecution time (seconds)\t$zwa2_execution_time" )

    cat <(echo "$header") $output_directory/fully_mapped.tsv $output_directory/chimeric.tsv <(echo "$footer") > $output_directory/ZWA2_cleaning_report.out

    gzip $output_directory/ZWA2_cleaning_report.out &
    zip_zwa_report_process_id=$!
    
    wait $zip_zwa_report_process_id
    wait $zip_clean_fastq_process_id

    chmod 777 $output_directory/*.gz
}
###



### MAIN - CALL FUNCTIONS
echo -e "\nExecuting ZWA2..."
echo -e "\nVerifying installation of ZWA2 prerequites (bwa & samtools), please wait..."

verify_zwa2_installation "bwa" "0.7.17"
verify_zwa2_installation "samtools" "1.13"

if [ ! -z $input_reads ] && [ ! -z $input_ref ] ; then
    bwa_mapping $input_ref $input_reads
elif [ ! -z $mapped_input ] ; then
    if [ -z $unmapped_input ] ; then
        bwa_mapping $mapped_input
    else
        bwa_mapping $mapped_input $unmapped_input
    fi
# Check if test flag was input
elif [[ -n $test_flag ]] ; then

    echo -e "\n!!! ZWA2 test mode !!!"
    echo "!!! INPUT READS: 10 reads from Anopheles sacharovi mosquito sample (SRA: SRR13449040) !!!"
    echo "!!! INPUT REF: Anopheles sacharovi 28S (GenBank: MT808434) and 18S (GenBank: MT808462) rRNAs !!!"
    test_reads="@H6FZJ:00138:04153
ATCTATAGGCCTCAAATAATGTGAGACTACCCCCTAAATTTAAGCATATTAATAAGGGGAGGAAAAGAAACCAACCGGGATTCCCTGAGTAGCTGCGAGCGAAACGGGAGAAGCTCAGCACGTAGGGATGGCGCGAATGAACGCGTCTATCCGATTCCGTGTACTGGTACGAACCATC
+
88:<<<<@8=9=>?@9==9<=<;;;<<<<=@@@3=<=8==8=8=<;;;<7=9<=9<@@7<<9>CC7CCC39196;09808=8<=8>>==<==<<<====<<<>8>>>7<<<299<<==>>=899<=7=>>7<<=<<6<>BB@>=<998<;;5;<<7<8==;;;=<<7<<<;<6;7<<<
@H6FZJ:08307:02957
ACAATAGGCCTCAAATAATGTGAGACTACCCCCTAAATTTAAGCATATTAATAAGGGGAGGAAAAGAAACCAACCGGGATTCCCTGAGTAGCTGCGAGCGAAACGGGAGAAGCTCAGCACGTAGGGATGGCGCGAATGAACGCGTCTATCCGATTCCGTGTACTGGTACGAACCATCATCT
+
///)4985;8<:;;3;;1///:<@<<<<<===1==@7<<8><?>=<<<3735:79::099)///(//919*/./5;?49968;6;;<<?<=<;;;<<<<<<<1<=<5<?A9=>=><=@@=?;>BC8><=8999<;6;8918;;<<====<9=<<9=9=;<<<<<<6<<<<<8=6;;<<888
@H6FZJ:07968:01470
CAGTAGGCCTCAAATAATGTGTGGGTACCCCCTAAATTTAAGCATATTAATAAGGGGAGGAAGAGAAACTAACAAGGATTCCC
+
:<<<>?9=9=<<=8<<7<==@==>8=<<<<<1<<<7<>7=9=A=<88188<<5;;<1;<7<9>><<<7<<A;><8<9=>6;<7
@H6FZJ:08751:06531
CAGTAGGCCTCAAATAATGTGTGGGTACCCCCTAAATTTAAGCATATTAATAAGGGGAGGAAGAGAAACTAACAAGGATTCCCTGAGTAGCTGCGAGCGAAACGGGAAGAGCTCAGCACGTAGGGGTGG
+
88<==@9=9===B8==9===<<<A8<<>???3<<@8@@7<7<<;:88083::6;==5==9=8==?>A7<9908<0828>9>?9><<<<;<;;;<;;;<;<;6;<=8=:===><<<<==<;;8888*9>8
@H6FZJ:00917:02215
ATAGGCCTCAAATAATGTGAGACTACCCCCTAAATTTAAGCATATTAATAAGGGGAGGAAAAGAAACCAACCGGGATTCCCTGAGTAGCTGCGAGCGAAACGGGAGAAGCTCAGCACGTAGGGATGGCGCGAATGAACGCGTCTATCCGATTCCGTGTACTGGTACGAACCATCATCTACTGCCTTTGGTGTAAACAGTT
+
>==<9?9<>==9=A>@<<<=>===<@<==3<=@9>=9=8;;;<=>9>=A=9=?>0880888)875.78?8=8<@7<<8<<6<<<<===;<<<=?>===B8<<<6<<<6<<<>@>=><?<===8==<8<=<;<6<<<7<>?>===;>:8===9?9>=====<=<><<;<7<8<;;<855;<===9==8=9>A88829==>9
@H6FZJ:08310:11139
AAGAAAGACACAAAAACCGAAGACAGTGAGAGAATGGTCGCCATGGCTAGGTGCCGGTACATGCCGCAATGGCATGCGCTTGCAATTTAATACCATGCTCTACCAGCGCGTCCAACCATATCTCTCTA
+
8=<5<;864551<===7<95;55659896;<:455-5...)..;6.77=9===9<9=====?>9=<>8;:5<<<667::5;880;4;;6===9==<<<====9@====?@>9<8A8@>==<==<<<?=
@H6FZJ:05825:11003
CGAGATCTGTCGTCGGTGCAAGACCGTACGATCGGCATCATTATCCAGACTTCAACTCAATGACACGGGGCACGAGTCCCCGCGATTACAGAAGCCCGAACTTGTTCTGACCCGATATCCGGCAGACTGTACT
+
==>===?<<;<===9==<<9===9888====A=9==>>==9=<=9===>=9==9<==>@C>@<==;4<<<<>=====7===<>>>9@>><<8>>8C>?9?;7==9<<<<=7?>==<<<8<8>>>>======<<
@H6FZJ:06366:08617 
AAGCAAAATTCACAAAGCGTAGGATTGTTCACCCTTCAAGGGAACGTGAGCTGGGTTTAGACCGTCGTGAGACAGGTTAGTTTTACAATCATCCAGGACAGAAGCCCGAACTTGTTCTGACCCGATATCCGGCAGACTGTACTGCTGAGGTGATTGCTGAAACTATTATGTGATTTCTGCCCAGTGCTCTGAATGTCAACGTGAAGAAATTCAAGCAAGCG
+
;6<;;<<2:4;;788*78779;6;=69;6;<<<*817:48<4<8;;;<<<<;;;4;<7<=>?9=>==><<<<<;;6;7;;<<<2<<<5777:<7::59;;:<8;<<2<<5:;9?><@>>=>>7=<>8888<8==><<888>==<<<;;:7;;;<4:899:?5=<<>7<<:<<8880...571864337578959::;;8;;;:9-533&3+194:;=.433
@H6FZJ:00597:02095
GCGTTCCCAGTTAACGCTCCTATGTCGAACAAGATGTTCAGAGGGGGAATGCCAGACCGCCCGGTGCAGCAATTCAAAGCACCCGCTAAGGCGCACGGAGAGTACGCTGGAGATTGGTTCA
+
==>992889=9<6<<?==;A>>>C>>A9?=9===<=9=<<<<1=<=<8<><8<<<;6::0;85;;<<>;<7=9==9====<6<<<<<7<8<<<<;>9><<<>@>==;;7><::8=9=9@><
@H6FZJ:00760:12129 
TATGTCGAACAAGATGTTCAGAGGGGGAATGCCAGACCGCCCGGTGCAGCAATTCAAAGCACCCGCTAAGGCGCACGGAGAGTACGCTGGAGATTGGTTCATCAATCATCCAGGACAGAAGCCCGAACTTGTTCTGACCCGATA
+
<<;<<996::7<9888388555,???;7;;=7;;;9595*550:9:;:853<7>>7A=<<;5;<<::48187<==>8=<<<<=>>===9>==<7<8<8<>A<<;=>=<<8B>9=B=<<7=<4<<<8==8=<9>=>><3:8889/"

    test_ref=">MT808434 Anopheles sacharovi 28S
ATCAATAGGCCTCAAATAATGTGAGACTACCCCCTAAATTTAAGCATATTAATAAGGGGAGGAAAAGAAACYAACMRGGATTCCCTGAGTAGCTGCGAGCGAAACGGGAGAAGCTCAGCACGTAGGGATGGCGCGAATGAACGCGTCTATCCGATTCCGTGTACTGGTACGAACCATCATCTACTGCCTTTGGTGTAAACAGTTCAAGTTCAACTTGAATGTGGCCTCGCTCCCATAGAGGGTGACAGGCCCGTAGAACGGCACGTGATTGGCAGTAGACGGGCGTACCATGGAGTCGTGTTGCTTGATAGTGCAGCACTAAGTGGGAGGTAAACTCCTTCTAAAGCTAAATACAACCATGAGACCGATAGCGAACAAGTACCGTGAGGGAAAGTTGAAAAGCACTCTGAATAGAGAGTCAAAGAGTACGTGAAACTGCCTAGGGGAACAAACCCGTTGAACTCAATAGACCGGGGCGGCGACATTCAGCCGCGCGTCAGTGCGCCTCCGGGCGTGCAGGCCGCGGTGCACTTGTCGACCTGCAGCGTACGGACATCGCGATCCATTACGAACGGGGCATTGGGGGTGCGCAAGCGCCTCCTAGCAATCCAACACTTGGTCCCAGACTCGTGCGGTCGACCCTCCAGTAGTGGCACTTAGCTCAGAAGGCCTGTGCCGCAAACGGGGGATTCGGAGGGCCTCCGGGCCTTCCGGAGTTCGGCCGAGTTCGGTGTACCGTTGGATGCGTGATGGACTCACACGGAACGGGGGTAGATGGAAGCGCATGCCATTGCGGCATGTACCGGCACCTAGCCATGGGCGACCATTCTCCTGATCGGCGATGTATAACACTTATTGAGGTACCTTCGGGACCCGTCTTGAAACACGGACCAAGAAGTCTATCTTGCGCGCAAGTCAATGGGCACTCTGGAGAAAACCCAAAGGCGAAGATAACACAACTGCTGTTGCGGGATTACGGGTGCACCACGGTCCTTCGCGGGACCGGCTAGCTGTGCGCCCCTCCATCCCCGGGTGTTGCACCAAATGGGGACCGTTCCGGCGGCGACCATGCGACATACCGTGAGCGCGTAGGATGTGACCCGAAAGATGGTGAACTATGCCTGATCAGGTTGAAGTCAGGGGAAACCCTGATGGAGGACCGAAGCAATTCTGACGTGCAAATCGATTGTCAGAGTTGGGCATAGGGGCGAAAGACCAATCGAACCATCTAGTAGCTGGTTCCCTCCGAAGTTTCCCTCAGGATAGCTGGAGCACGTAACATTTCGAGCCTTATTCTTATCTGGTAAAGCGAATGATTAGAGGCCTTAGGTTCGAAATGATCTTAACCTATTCTCAAACTATAAATGGGTACGGGATTGGGTAGCATGCTTTGATGATGCTACCCTCAAATCGATGAGTCGAAGCGAACGGTGCACCCGTCGCCCCCGGGGTGGCGGAATGCACCGGCTAGATATCGGTGTGCTTAGTGGGCCAAGTTTTGGTAAGCAGAACTGGTGCTGTGGGATGAACCAAACGCAATGTTAAGGCGCCCAAATAAACGACGCATCATAGATACCATAAAAGGTGTTGATTGCTAAAGACAGCAGGACGGTGGACATGGAAGTCGTCATCCGCTAAGGAGTGTGTAACAACTCACCTGCCGAAGCAATTAGCCCTGAAAATGGATGGCGCTTAAGTCGTTTGCCTATACATCGCCGCTAGCGGTAAAACGGGTAGCAAGCCGGCGTGCTGTGCTACTTCGAGACCCTAGTGAGTAGGAGGGTACGGTGGTGGCGTAGAAGTGCTTGGCGCAAGCCAACATGGAGCCGCCACTGGCACAGATCTTGGTGGTAGTAGCAAATATTCGAATGAGATCTTGGATGACTGAAGTGGAGGAGGGTTTCGTGTCAACAGCAGTTGAACACGAGTTAGCCAACCCTAAGCTATATGGGAAACCTGATTCATACGCGATCGCGATCAAGCGAAAGGGAATCCGGTTACAATTCCGGAGCCTGTTGAGTATACGTTTGCCTGGCGTGTTCGGTTCCTTCCGGGGGGTCGTACCGCCTTGCGATCATGGTAACATGAATCCTTTTCTTCGAGAAGCCAACGGGAGGTACTGGAAGAGTTTTCTTTTCTGTTTTACAGCCACCACTGACCATGGAAGTCTTTCGTAGAGAGATATGGTTGGACGCGCTGGTAGAGCATGGTATTAAATTGCTGTGTCGGTACTCTCCTCTTGGACCGTGAAAATCGAAGACTGGGGCACGCAAACTCTCAACAGCTTGTACCGAATCCGCAGCAGGTCTCCAAGGTTTAGAGTCTCTAGTCGATAGATCAATGTAGGTAAGGGAAGTCGGCAAACTAGATCCGTAACTTCGGGATAAGGATTGGCTCTGAAGGCTGAGCCGGCACGGTGTGTCGCAACGGTAACGGGCGTGTCCCCAACCCTCCGGGGGCGGGTGACTAGCGCCTGGCCCTGCGGACCCGGTCGGCACTGAACAGCCAGTTCAGAACTGGCACGGCTGAGGGAATCCGACTGTCTAATTAAAACAAAGCATTGTGATGGCCTTCAAAGGTATTGACACAATGTGATTTCTGCCCAGTGCTCTGAATGTCAACGTGAAGAAATTCAAGCAAGCGCGGGTAAACGGCGGGAGTAACTATGACTCTCTTAAGGTAGCCAAATGCCTCGTCATCTAATTAGTGACGCGCATGAATGGATTAACGAGATTCCCTCTGTCCCTATCTACTATCTAGCGAAACCACAGCCAAGGGAACGGGCTTGGAAACACTAGCGGGGAAAGAAGACCCTGTTGAGCTTGACTCTAGTCTGGCATTGTAAGGCGATATAAGAGGTGCAGAATAGGTGGGAGATCGGGTAAAACATTAACTCCCGTTCGCCAATGAGATACCACCACTCTTACTGTTGCCTTACTTACGTGATCGGGTGGAACAAGTGCGGGCCGCGTCCCTTGGTTCCGGCGCGCGTGCGCCCCAGCTCACGCTGGCGGCCGTACCGTCGTCGTCGGGGCCAGACCGGCCCAATGCACCGGGTTTCTCGTTCAGCGTTCAGCCATGTCGCCGCCCAGGCCCTGGCGTGCACGCGGCGCGGCGGTCACAATGCGGCCGGTGCCGGTGGAAACGCCGTCGCCTGCTGCAGTACGCCCCGCGCTGCTCACGCGCGCCGGCCAGCGGCACCCAAGACATCTGAACATCATACAGTATCCAAGTCATGGACATTGCCAGGTGCGGAGTTTGACTGGGGCGGTACATCTCCAAAACGATAACGGAGGTGTCCAAAGGTCAGCTCAGTGTGGACAGAAACCACACGCTGAGCATAAGGACAAAAGCTGGCTTGATCTCGAAGTTCAGTACACATTGAGACAGCGTAAGCTAGGCCTCACGATCCTTTTGGTTTAACGAGTTTTTAGCAAGAGGTGTCAGAAAAGTTACCACAGGGATAACTGGCTTGTGGCCGCCAAGCGTTCATAGCGACGTGGCTTTTTGATCCTTCGATGTCGGCTCTTCCTATCATTGTGAAGCAAAATTCACAAAGCGTAGGATTGTTCACCCTTTCAAGGGAACGTGAGCTGGGTTTAGACCGTCGTGAGACAGGTTAGTTTTACCCTACTGGTGTGCAAAGAGTAAGCTGCCTTAATGGAATTCCTGTGCAGTACGAGAGGAACCACAGGTACGGACCAATGGCTCAATACTAGTCCGACCGGACTTTGGTATGACGCTACGTCCGTCGGATTATGCCTGAACGCCTCTAAGGTCGTAACCGAACCAAGCCGGTAGCATTACTATAGGTGTTGGAAATTAAGTGGCCGCATAAATCTACAAGACTCGATAGCGTTATTATAACACTGTCGTCTTATTGAACACTCTAATACAGAGCCTTACCGAGCGGGACCATACGGGTAGTACCTAGATACGGGAACCCCGGTGGAACTGCCGATCCTCAATACATGATTTCGATACCTAAGACCACCTACACACGATAGGTTTACAGGCTGGGAGCTGCGCATTGCAGAGAGATGTACATTTCGATCCTTTCATGCTACCCACGCTTGCTGGTTGA
>MT808462 Anopheles sacharovi 18S
ATTCTGGTTGATCCTACCAGTAATATACGCTCGTCTCAAAGGTTAAGCCATGCATGTCTAAGTACAAACAGATTTAATGTGAAACCGCATAAGGCTCAGTATAACAGCTATAATTTACGAGATCATCACCTAAGTTACTTGGATAACTGTGGAAAATCTAGAGCTAATACATGCAAAATGCCAGGACCTCGCGGGACTGGTGCACTTATTAGTCAAACCAATCGCGGGGCTCGCGCCCCGTGCCATTGAGTTGAAGTCTGGATAATGATGCCGATCGTATGGTCTTGCACCGACGACAGATCTCGCAAATGTCTGCCCTATCAACTATTGATGGTAGTATCGAGGACTACCATGGTTACAACGGGTAACGGGGAATCAGGGTTCGATTCCGGAGAGGGAGCCTGAGAAATGGCTACCACATCCAAGGAAGGCAGCAGGCGCGTAAATTACCCAATCCCGGCACGGGGAGGTAGTGACGAGAAATAACAATATGAAACTCTTTAATGATGTTTCATAATTGGAATGAGTTGAGCATAAATCCTTTAGCAAGGATCAAGTGGAGGGCAAGTCTGGTGCCAGCAGCCGCGGTAATTCCAGCTCCACTAGCGTATATTAAAATTGTTGCGGTTAAAACGTTCGAAGTTGATTCTTGTCCAACACAGGCCGACACTGTCGACCCGGATCCGTCCGTGGTAGGTAGGTTCGATCGGATTCTGGTTGAGACTCAAATGGTGCGGTCGGGCGCGAAACCATTAGCATCGTGCCCTTCAACGGGTGCCTTCAAGTATGGAGCCCGACCGTTCTCGTTTACCTTGAACAAATTAGAGTGCTTCAAGCAGGCTCATGAATATATGGCCGAGAATAATCTTGCATGGAATAATGGAATATGACCTTGGTCTAAATGTTTCGTTGGTTTGTATACAGACTCAGAGGTAATGATTAACAGAAGTGGTTGGGGGCATTAGTATTACGGCGCGAGAGGTGAAATTCGTAGACCGTCGTAAGACTAACTGAAGCGAAAGCGTTTGCCATGGACACTTTCATTAATCAAGAACGAAAGTTAGAGTATCGAAGGCGATTAGATACCGCCCTAGTTCTAACCGTAAACGATGCCAGCTAGCAATTGGGAGACGCTACAACATAGGTGCTCTCAGTAGCTTCCGGGAAACCAAAGCTAGGTTCCGGGGGAAGTATGGTTGCAAAGTTGAAACTTAAAGGAATTGACGGAAAGGCACCACAATTGAAGTGGAGCCTGCGGCTTAATTTGACCCAACACGGGAAAACTTACCAGGTCCGAACTTATTGAGGTAAGACAGATTGAGAGCTCTTTCTCAAACTTAAGGGTAGTGGTGCATGGCCGTTCTTAGTTCGTGGATTGATTTGTCTGGTTTATTCCGATAACGAACGTGACTCACTCATGCTAACTAGAATACCAGTCAGCCTGTTGCGTTTTGATCTCTGTCCGGAGTGCCCCCGGGTGCGAAGGTAGAGGGAGTGCGACCTGACGTTCCGGCCCTGTGTGCGCAAGCATACTTGGCTAAGCTGCTTAGCAGGACAATTTGTGTTTAGCAAAATGAGACTGAGCGATAACAGGTCCGTGATGCCCTTAGATGTCCTGGGCTGCACGCGCGCTACAATGTGGGTATCAGCGTGTCTCCTATTCCGAAAGGAACGGGTAATCACTGAAACACTCACTTAGTGGGGATTATGGATTGCAATGGTCCATATGAACTCGGAATTTCTTGTAAGCGCTGGTCATTAGCTAGCGCTGAATACGTCCCTGCCTTTTGTACACACCGCCCGTCGCTACTACCGATGGATTATTTAGTGAGGTCTCTGGAGGTGATCGTTCGCATGCTCCCTCGCGGAGTAGCGTCTGCTTTGCTGAAGTTGACCGAACTTGATGATTTAGAGGAAGTAAAAGTCGTAACAAGGTTTCCGTAGGTGAACCTGCGGAAGGATCATTA"

    input_reads=$output_directory/test_reads.fastq
    input_ref=$output_directory/test_ref.fasta

    input_reads_extension=$(echo ${input_reads##*.} | tr '[[:upper:]]' '[[:lower:]]' )
    input_reads_filename=$(basename $input_reads .$input_reads_extension)

    echo "$test_reads" > $input_reads
    echo "$test_ref" > $input_ref

    bwa_mapping $input_ref $input_reads
    rm -rf $input_ref.*

fi
reads_count_analysis

# if there are chimeric reads, then clean
if [[ $softclipped_reads_count -gt 0 ]] ; then

    chimeric_reads_cleaning
    write_report

    echo -e "\nZWA2 script completed successfully !!!"
    echo -e "\nResults in $output_directory"
    
    # Cleanup unnecessary files 
    rm -rf $output_directory/*softclipped* $output_directory/*mapped*
    rm -rf $output_directory/*.bam* $output_directory/*.sam $output_directory/*.tsv $output_directory/*.txt            

# if there are no chimeric reads but only unmapped, then keep only unmapped as clean
elif [[ $softclipped_reads_count -eq 0 && $total_unmapped_reads_count -gt 0 ]] ; then
    echo -e "\nAll reads unmapped against $input_ref_filename database, no chimeric reads for ZWA2 cleaning !!!"

    # Cleanup unnecessary files 
    rm -rf $output_directory/*softclipped* $output_directory/*mapped*
    rm -rf $output_directory/*.bam* $output_directory/*.sam $output_directory/*.tsv $output_directory/*.txt            

# if all reads are fully mapped with no chimeric, then no need to clean
elif [[ $softclipped_reads_count -eq 0 && $total_unmapped_reads_count -eq 0 ]] ; then
    echo -e "\nAll reads fully aligned against $input_ref_filename database, no chimeric reads for ZWA2 cleaning !!!"
    rm -rf $output_directory
    exit
fi
