Viral Reads Assembly Enhancer (ViRAE)
=======

[![Downloads](https://img.shields.io/github/downloads/konskons11/ViRAE/total?style=flat-square)](https://github.com/konskons11/ViRAE/releases)

## Overview
ViRAE (Viral Reads Assembly Enhancer) is a bioinformatics pipeline designed to optimize the _de novo_ assembly of viral genomes from metagenomic data. It represents a significant evolution of the [Zero-Waste Algorithm (ZWA)](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009304), specifically engineered to address and mitigate artificial chimeric reads, which arise during Short-Read Sequencing (SRS) library preparation due to PCR amplification and Reverse Transcription steps. These artificial chimeras are in essense hybrids, where unrelated genomic regions between viral and non-viral sequences are erroneously fused together, therefore creating contamination with an SRS dataset. 

## Scope and Purpose
The primary scope of ViRAE is RNA viral metagenomics, a field critical for identifying pathogenic and symbiotic interactions in eukaryotic hosts. Its purpose is to recover valuable viral genetic information that is typically lost during standard quality control and state-of-the-art decontamination processes. By refining the input data before assembly, ViRAE aims to produce significantly longer and more complete viral contigs, enhancing the identification and characterization of viral communities.

## ViRAE vs. State-of-the-Art Methods
Current state-of-the-art decontamination methods (e.g., mapping via the desired software on a a given reference) typically employ an "all-or-nothing" filtering approach. If a read maps partially to a candidate contaminant reference-indicating that is a chimeric read-, then the entire read is discarded, even if it contains genuine viral sequences. 

ViRAE differentiates itself by applying a "surgical" trimming approach:
1) Identification: It detects reads that are chimeric or "soft-clipped" (i.e partially mapped) to a contaminant reference (like rRNA).
2) Recycling: Instead of discarding the whole read, ViRAE removes only the non-viral (contaminant) moiety.
3) Enhancement: The remaining viral fragment is retained and utilized for _de novo_ assembly, upcycling data that other methods throw away.

The concept behind the ViRAE pipeline is outlined in the figure below:

![ViRAE_pipeline](https://imgur.com/T5C1FnR.png?3 "ViRAE pipeline")

_**IMPORTANT NOTE:**_
ViRAE focuses on the identification and decontamination of partially mapped (chimeric) NGS reads on any given reference sequence(s). For optimum decontamination, we highly recommend downloading and inputting our [custom SILVA ribosomal database (RiDB)](https://github.com/konskons11/ViRAE/blob/main/Software/Offline/RiDB.fasta.gz) as reference file, containing 603370 seqs of 16S, 18S, 23S and 28S rRNAs from a wide variety of _Archaea_, _Bacteria_ and _Eukarya_ organisms. Noteworthy, _de novo_ assembly of the clean output reads after decontamination is optional, and therefore is not included in the main ViRAE pipeline or the program's prerequisites. However, the user may separately perform _de novo_ assembly on the clean output reads using the software of preference, with [MEGAHIT _de novo_ assembler](https://github.com/voutcn/megahit/releases/tag/v1.2.9) being highly recommended.

User manual
=======

## ViRAE standalone application (offline)

### Installation 

The ViRAE standalone application is now deployed as a modern, highly scalable **Nextflow DSL2** pipeline compatible with Linux, macOS, and Windows (via WSL2), which requires [Nextflow](https://www.nextflow.io/) (v22.10.0 or later). 

If you have already installed the prerequisites ([bwa 0.7.17](https://github.com/lh3/bwa/releases/tag/v0.7.17) and [samtools 1.13](https://github.com/samtools/samtools/releases/tag/1.13)) in your system's PATH, you can execute the pipeline natively using `-profile local`, which is the fastest execution method. Alternatively, ViRAE comes with built-in profiles in `nextflow.config` file to automatically handle all dependencies seamlessly via Conda/Mamba, Docker or Singularity.

To get started, clone the repository:
```sh
# Clone the repository
git clone https://github.com/konskons11/ViRAE.git
cd ViRAE/Software/Offline
```
_NOTE: If you do not have Nextflow installed on your system, you can quickly set it up via Conda as follows:_
```sh
conda create -n nextflow_env -c conda-forge -c bioconda nextflow mamba
conda activate nextflow_env
```

### Execution

The parameters of the ViRAE Nextflow pipeline are summarized in the following table. You can use standard double-dash parameters (e.g. `--reads1`, `--ref`) or legacy shorthand flags (e.g. `--1`, `--r`):
|Required arguments|Description|Deployment|
|:---|:---|:---|
|`--reads1 (or --1)`|directory of INPUT NGS READS file (Single-end OR 1<sup>st</sup> from Paired-end) (.fastq, .fq or .gz extension)|Full|
|`--ref (or --r)`|directory of INPUT REFERENCE file (.fasta, .fa, .fna, .fsta or .gz extension)|Full|
|`--mapped (or --m)`|directory of MAPPED NGS READS on REFERENCE file (.bam extension)|Partial|
|`--outdir (or --o)`|directory of OUTPUT folder|Full & Partial|

|Optional arguments|Description|Deployment|
|:---|:---|:---|
|`--reads2 (or --2)`|directory of INPUT NGS READS file (2<sup>nd</sup> from Paired-end) (.fastq, .fq or .gz extension)|Full|
|`--l <integer>`|alignment stringency value (range 0-100, default value 30 \| <30 loose, >30 stringent)|Full|
|`--q <integer>`|mapping quality cutoff value (range 0-60, default value 0)|Full|
|`--unmapped (or --u)`|directory of UNMAPPED NGS READS on INPUT REFERENCE file (.bam, .fastq, .fq or .gz extension)|Partial|
|`--test (or --t)`|run ViRAE on a test dataset to verify installation|TEST MODE|

### Run examples

To familiarize yourself with the Nextflow execution, we highly recommend running the test mode first. The test dataset is generated automatically on the fly.

ViRAE test mode run example: 
```sh
nextflow run virae.nf -profile local --t
```
_PROFILE TIP: If you want Nextflow to manage dependencies automatically instead of using local installations, simply replace `-profile local` with `-profile conda`, `-profile docker`, or `-profile singularity` in any of the commands below. (Apple Silicon macOS users running Conda may need to prepend `CONDA_SUBDIR=osx-64` to the command to resolve bwa architecture compatibility)._

For standard data processing, ViRAE may be fully or partially deployed depending on your available inputs.

**Full ViRAE deployment:** Provide the paths to your raw NGS reads and reference file. ViRAE will handle the BWA indexing and mapping automatically. You may pass parameters either as standard Nextflow flags or within a .yaml config file.  

Full ViRAE deployment run examples:
```sh
# Single-end reads
nextflow run main.nf -profile local --1 reads.fastq --r ref.fasta --o ./results

# Paired-end gzipped reads
nextflow run main.nf -profile local --1 R1.fq.gz --2 R2.fq.gz --r ref.fasta.gz --o ./results

# Paired-end reads with custom mapping sensitivity parameters
nextflow run main.nf -profile local --1 reads_1.fq.gz --2 reads_2.fq.gz --r ref.fasta.gz --l 40 --q 10 --o ./results
```

**Partial ViRAE deployment:** If you have already aligned your reads using a mapping software of your choice, you can bypass the alignment step and provide the pre-mapped BAM file directly. You may also provide a separate unmapped sequence file if your mapping tool outputs them independently.

Partial ViRAE deployment run examples:
```sh
# Pre-mapped BAM only
nextflow run main.nf -profile local --m mapped.bam --o ./results

# Pre-mapped BAM with a separate unmapped sequences file
nextflow run main.nf -profile local --m mapped.bam --u unmapped.fq.gz --o ./results
```

**Resuming execution:** If a run is interrupted or fails (e.g. due to system disconnect), simply append the `-resume` flag to your original command. Nextflow will immediately pick up execution exactly where it left off, preventing the need to rerun lengthy mapping steps.

### Output

ViRAE outputs 2 files per execution, stored within a subfolder inside your specified `--outdir`:

1. The clean reads after processing as a GZIPPED FASTQ file with the suffix "ViRAE_cleaned.fastq.gz" (split into _1, _2, and _singletons for paired-end inputs).
2. A detailed cleaning report file named "ViRAE_cleaning_report.out.gz".

The generated GZIPPED FASTQ file contains all the clean reads curated by ViRAE and may be used directly for de novo assembly or other downstream analysis. The generated report file is a multi-column file, which provides further information and details on the cleaning performed by ViRAE, in the following format:
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

An overall summary of the ViRAE analysis is also provided at the end of the generated report file, which has the following line-by-line format:
|Line header|Description|
|:---|:---|
|BWA alignment stringency \| Mapping quality cutoff|Alignment stringency value \| Mapping quality cutoff|
|Total input reads|Total number of user input reads|
|Total unmapped reads|Total number of unmapped reads|
|Total mapped reads|Total number of mapped reads|
|Fully mapped reads|Total number of fully mapped reads only|
|Fully mapped reads/<br />Total mapped reads (%)|Percentage of the total number of fully mapped reads <br />to total number of mapped reads|
|Partially mapped (chimeric) reads|Total number of chimeric reads only|
|Partially mapped (chimeric) reads/<br />Total mapped reads (%)|Percentage of the total number of chimeric reads <br /> to total number of mapped reads|
|Average mapped bases|Numnber of average mapped bases in chimeric reads|
|Average mapped bases/<br />Average read length (%)|Percentage of the number of average mapped bases in chimeric reads <br /> to average length of chimeric reads|
|ViRAE cleaned chimeric reads|Number of chimeric reads cleaned by ViRAE|
|ViRAE cleaned chimeric reads/<br />Chimeric reads (%)|Percentage of the number of chimeric reads cleaned by ViRAE <br /> to total number of chimeric reads|
|Total clean reads <br />(Unmapped+ViRAE cleaned)|Total number of clean reads <br />(equal to the sum of unmapped reads + chimeras cleaned by ViRAE)|
|ViRAE discarded chimeric reads|Number of chimeric reads discarded by ViRAE|
|ViRAE discarded chimeric reads/<br />Chimeric reads (%)|Percentage of the number of chimeric reads discarded by ViRAE <br /> to total number of chimeric reads|
|Total discarded reads <br />(Fully mapped+ViRAE discarded)|Total number of discarded reads <br />(equal to the sum of fully mapped reads + chimeras discarded by ViRAE)|
|Execution time (seconds)|Total execution time of ViRAE (wall clock run time)|

## ViRAE web-based application (online)

Apart from the ViRAE standalone application, the user may utilize the [ViRAE online tool](https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_method_selection.html), which does not require the installation of any software but solely the provision of the appropriate input files according to the following 3 steps:

**A) Deployment method selection:** Similarly to the standalone application, the user may choose to fully or partially deploy ViRAE depending on the available input through our online platform. If NGS reads and reference files are available in FASTQ and FASTA formats respectively, then the user should choose “Method 1” as displayed below, which corresponds to full ViRAE deployment. Alternatively, if the user has already performed the desired alignment between the NGS reads and reference file of preference, then “Method 2” should be selected, which stands for the faster partial deployment of ViRAE, with the sole input of the appropriate BAM file.

![ViRAE_online guide](https://i.imgur.com/71zGdwa.png?1 "ViRAE online - Deployment method selection")

**B) Input files upload:** Clicking on the ViRAE deployment method of preference, redirects the user to the upload webpage. Upon selection of full ViRAE deployment (Method 1), the webpage displays three different upload options to choose from, for the necessary FASTQ and FASTA files separately. These upload options, as displayed below, are: 
1) selection of FASTQ or FASTA input file from a prompt file dialog,
2) submission of a valid SRA accession number (in the case of FASTQ input) or selection from a dropdown menu list of recommended reference files (in the case of FASTA input), or
3) provision of the appropriate link address of the input FASTQ file(s) or FASTA file.

The user also has the ability to adjust the "Alignment stringency" of the mapping software as well as the "Mapping quality cutoff" by setting the desired values at the respective slider menus.

![ViRAE_online guide](https://imgur.com/nDfu99D.png?2 "ViRAE online - Method 1 upload selection")

As regards to the partial ViRAE deployment (Method 2), there are two available upload options, which are: 
1) selection of the necessary BAM input file from a prompt file dialog, or
2) provision of the appropriate link address, where the necessary BAM input file is stored.

![ViRAE_online guide](https://i.imgur.com/xUQG3CO.png "ViRAE online - Method 2 upload selection")

Submission of the required input files triggers the upload process and redirects to a new webpage, where the user is informed about the upload progression in real time. In case of upload failure, the user is redirected automatically back to the upload webpage after clicking "OK" on the prompted warning message.

**C) ViRAE implementation and output:** After successful upload of the appropriate input files, the back-end script execution of ViRAE begins and the user is informed about its progression in real time as displayed below. Upon ViRAE run completion, an overall summary is displayed at the current webpage, along with a download link corresponding to a zipped folder containing the clean reads and generated report files by ViRAE.

![ViRAE_online guide](https://imgur.com/vkihb41.png "ViRAE online - ViRAE execution and download page")
