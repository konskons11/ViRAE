ZWA2
=======

[![Downloads](https://img.shields.io/github/downloads/konskons11/ZWA2/total?style=flat-square)](https://github.com/konskons11/ZWA2/releases)

ZWA2 is a context-based trimming bioinformatics tool, especially developed for viral metagenomics, which allows Next Generation Sequencing (NGS) read decontamination based on any given reference sequence(s). ZWA2 incorporates ready-to-use well-established bioinformatics software to detect and dissect partially mapped reads (chimeric reads) by specifically removing the moieties, which align to the given reference sequence(s). The clean output reads enhance _de novo_ assembly performance, increasing the availability of reads for more accurate and more efficacious _de novo_ virus genome assembly.

The concept behind the ZWA2 pipeline is outlined in the figure below:

![ZWA2_pipeline](https://i.imgur.com/SXzPHW9.png "ZWA2_pipeline")

_**IMPORTANT NOTE:**_
ZWA2 focuses on the identification and decontamination of partially mapped (chimeric) NGS reads on any given reference sequence(s). For optimum decontamination, we highly recommend downloading and inputting our [custom SILVA rRNA database](https://github.com/konskons11/ZWA2/blob/main/Software/Offline/SILVA_LSU%2BSSU_rRNA.prinseq-ns_max_p1.fasta.gz) (603370 seqs of 16S, 18S, 23S and 28S rRNA from a wide variety of _Archaea_, _Bacteria_ and _Eukarya_ organisms) as reference file. Noteworthy, _de novo_ assembly of the clean output reads after decontamination is optional, and therefore is not included in the main ZWA2 pipeline or the program's prerequisites. If this is the case, the user may separately perform _de novo_ assembly on the clean output reads using the software of preference, though we highly recommend using [MEGAHIT _de novo_ assembler](https://github.com/voutcn/megahit/releases/tag/v1.2.9).

User's manual
=======

## ZWA2 standalone application

### Installation 

The ZWA2 standalone application is a Bash shell script distributed for Linux and MacOS systems and may be executed directly after making the downloaded ZWA2.sh file executable (e.g. command `chmod +x`). The prerequisites of ZWA2 ([bwa 0.7.17](https://github.com/lh3/bwa/releases/tag/v0.7.17) and [samtools 1.13](https://github.com/samtools/samtools/releases/tag/1.13)) will be verified for installation upon ZWA2 execution and if not installed, they will be downloaded automatically by the program.

### Execution

The parameters of the ZWA2 standalone application are summarised in the following table:
|Required argument flags|Description|Deployment|
|:---|:---|:---|
|`-i <string>`|directory of INPUT NGS READS file (.fastq, .fq or .gz extension)|Full|
|`-r <string>`|directory of INPUT REFERENCE file (.fasta, .fa, .fna, .fsta or .gz extension)|Full|
|`-m <string>`|directory of MAPPED NGS READS on REFERENCE file (.bam extension)|Partial|
|`-o <string>`|directory of OUTPUT folder|Full & Partial|

|Optional argument flags|Description|Deployment|
|:---|:---|:---|
|`-l <integer>`|alignment stringency value (default value 30 \| <30 loose, >30 stringent)|Full|
|`-u <string>`|directory of UNMAPPED NGS READS on REFERENCE file (.bam, .fastq, .fq or .gz extension)|Partial|
|`-t`|run ZWA2 on a test dataset to verify installation|TEST MODE|

### Run examples

In order to better comprehend the use and output of the ZWA2 standalone application, we highly recommend inputting the -t flag only the first time you run it so as to deploy ZWA2 on a small test dataset, wchih also verifies the installation of all prerequisites and downloads them automatically if needed.

ZWA2 test mode run example:
```sh
./ZWA2.sh -t
```

For non-test run, the ZWA2 standalone application may be fully or partially deployed upon execution depending on the available user input files. In the case of ZWA2 full deployment, the directories of NGS reads (FASTQ format) and appropriate reference file (FASTA format) must be provided as arguments after the -i and -r flags respectively, in order to be able to perform all necessary alignments. The user also has the ability to adjust the mapping sensitivity of the incorporated BWA software by passing the desired level of alignment stringency as an integer number after the -l flag (default value 30 \| <30 loose, >30 stringent). 

Full ZWA2 deployment run examples:
```sh
./ZWA2.sh -i reads.fastq -r ref.fasta -o ./
./ZWA2.sh -i reads.fq.gz -r ref.fasta.gz -o ./
./ZWA2.sh -i reads.fq.gz -r ref.fasta.gz -l 40 -o ./
```

For the alternative and faster partial deployment of ZWA2, in which the user may have already carried out the desired alignment with the mapping software of preference, the directory of a BAM file may only be provided after the -m flag, instead of FASTQ and FASTA files. Alongside the input BAM file, the user may optionally pass the output unmapped reads of the performed alignment in FASTQ or BAM format after the -u flag, for later use by the algorithm. 

Partial ZWA2 deployment run example:
```sh
./ZWA2.sh -m mapped.bam -o ./
./ZWA2.sh -m mapped.bam -u unmapped.bam -o ./
./ZWA2.sh -m mapped.bam -u unmapped.fq.gz -o ./
```

### Output

ZWA2 outputs 2 files, which are: i) the clean reads after processing as a GZIPPED FASTQ file with the suffix "_ZWA2_cleaned.fastq.gz_", and ii) a detailed cleaning report file named "_ZWA2_cleaning_report.out.gz_". The generated GZIPPED FASTQ file contains all the clean reads by ZWA2 and may be used separately for _de novo_ assembly or other downstream analysis. The generated report file is a multi-column file, which provides further information and details on the cleaning performed by ZWA2, in the following format:
|Column header|Description|
|:---|:---|
|Read_ID|Unique read sequence identifier|
|RefID|Unique reference sequence identifier|
|CIGAR|Compact Idiosyncratic Gapped Alignment Report string|
|Read_seq|Complete read sequence|
|Read_seqlength|Total read sequence length|
|Mapped_seq|Mapped sequence of read|
|Mapped_seq_length|Mapped sequence length of read|
|Mapped_start|Mapping start position of read|
|Mapped_end|Mapping end position of read|
|Left_unmapped_seq_start|New start position of read sequence after left-side trimming|
|Left_unmapped_seq_end|New end position of read sequence after left-side trimming|
|Left_unmapped_seq|New read sequence after left-side trimming|
|Left_unmapped_seq_quality|New read sequence quality after left-side trimming|
|Left_unmapped_seqlength|New read sequence length after left-side trimming|
|Right_unmapped_seq_start|New start position of read sequence after right-side trimming|
|Right_unmapped_seq_end|New end position of read sequence after right-side trimming|
|Right_unmapped_seq|New read sequence after right-side trimming|
|Right_unmapped_seq_quality|New read sequence quality after right-side trimming|
|Right_unmapped_seqlength|New read sequence length after right-side trimming|

An overall summary of the ZWA2 analysis is also provided at the end of the generated report file, which has the following line-by-line format:
|Line header|Description|
|:---|:---|
|BWA alignment stringency|Alignment stringency value of BWA (default value 30 \| <30 loose, >30 stringent)|
|Total input reads|Total number of user input reads|
|Total unmapped reads|Total number of unmapped reads|
|Total mapped reads|Total number of mapped reads|
|Fully mapped reads|Total number of fully mapped reads only|
|Fully mapped reads/<br />Total mapped reads (%)|Percentage of the total number of fully mapped reads <br />to total number of mapped reads|
|Partially mapped (chimeric) reads|Total number of chimeric reads only|
|Partially mapped (chimeric) reads/<br />Total mapped reads (%)|Percentage of the total number of chimeric reads <br /> to total number of mapped reads|
|Average mapped bases|Numnber of average mapped bases in chimeric reads|
|Average mapped bases/<br />Average read length (%)|Percentage of the number of average mapped bases in chimeric reads <br /> to average length of chimeric reads|
|ZWA2 cleaned chimeric reads|Number of chimeric reads cleaned by ZWA2|
|ZWA2 cleaned chimeric reads/<br />Chimeric reads (%)|Percentage of the number of chimeric reads cleaned by ZWA2 <br /> to total number of chimeric reads|
|Total clean reads <br />(Unmapped+ZWA2 cleaned)|Total number of clean reads <br />(equal to the sum of unmapped reads + chimeras cleaned by ZWA2)|
|ZWA2 discarded chimeric reads|Number of chimeric reads discarded by ZWA2|
|ZWA2 discarded chimeric reads/<br />Chimeric reads (%)|Percentage of the number of chimeric reads discarded by ZWA2 <br /> to total number of chimeric reads|
|Total discarded reads <br />(Fully mapped+ZWA2 discarded)|Total number of discarded reads <br />(equal to the sum of fully mapped reads + chimeras discarded by ZWA2)|
|Execution time (seconds)|Total execution time of ZWA2 (wall clock run time)|

## ZWA2 online guide

Apart from the ZWA2 standalone application, the user may utilize the ZWA2 online tool (https://srv-inseqt.med.duth.gr/ZWA2/HTML/ZWA2_method_selection.html), which does not require the installation of any software but solely the provision of the appropriate input files according to the following 3 steps:

**A) Deployment method selection:** Similarly to the standalone application, the user may choose to fully or partially deploy ZWA2 depending on the available input through our online platform. If NGS reads and reference files are available in FASTQ and FASTA formats respectively, then the user should choose “Method 1” as displayed below, which corresponds to full ZWA2 deployment. Alternatively, if the user has already performed the desired alignment between the NGS reads and reference file of preference, then “Method 2” should be selected, which stands for the faster partial deployment of ZWA2, with the sole input of the appropriate BAM file.

![ZWA2_online guide](https://i.imgur.com/VEDsTmV.png "ZWA2 online - Deployment method selection")

**B) Input files upload:** Clicking on the ZWA2 deployment method of preference, redirects the user to the upload webpage. Upon selection of full ZWA2 deployment (Method 1), the webpage displays three different upload options to choose from, for the necessary FASTQ and FASTA files separately. These upload options, as displayed below, are: 
1) selection of FASTQ or FASTA input file from a prompt file dialog,
2) submission of a valid SRA accession number (in the case of FASTQ input) or selection from a dropdown menu list of recommended reference files (in the case of FASTA input), or
3) provision of the appropriate link address, where the FASTQ or FASTA input file is stored.

![ZWA2_online guide](https://i.imgur.com/WrGnmVz.png "ZWA2 online - Method 1 upload selection")

As regards to the partial ZWA2 deployment (Method 2), there are two available upload options, which are: 
1) selection of the necessary BAM input file from a prompt file dialog, or
2) provision of the appropriate link address, where the necessary BAM input file is stored.

![ZWA2_online guide](https://i.imgur.com/OBRQJ7z.png "ZWA2 online - Method 2 upload selection")

Submission of the required input files triggers the upload process and redirects to a new webpage, where the user is informed about the upload progression in real time. In case of upload failure, the user is redirected automatically back to the upload webpage after clicking "OK" on the prompted warning message.

**C) ZWA2 implementation and output:** After successful upload of the appropriate input files, the back-end script execution of ZWA2 begins and the user is informed about its progression in real time as displayed below. Upon ZWA2 run completion, an overall summary is displayed at the current webpage, along with a download link corresponding to a zipped folder containing the clean reads and generated report files by ZWA2.

![ZWA2_online guide](https://i.imgur.com/g3pWaUG.png "ZWA2 online - ZWA2 execution and download page")
