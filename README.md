ZWA2
=======

[![Downloads](https://img.shields.io/github/downloads/konskons11/ZWA2/total?style=flat-square)](https://github.com/konskons11/ZWA2/releases)

ZWA2 is a context-based trimming bioinformatics tool for virus genome RNA-seq read decontamination based on a given reference. The tool dissects chimera reads that arise during NGS, removing chimeric moieties with sequences from the user input reference. The clean output reads are then ready to be fed into _de novo_ assemblers, increasing the availability of reads for more accurate and more efficacious _de novo_ virus genome assembly.

Installation of the standalone application
---------------
ZWA2 standalone application may be exetuced in Linux and MacOS systems, but firstly requires the installation of the following prerequisites in order to work properly.

_Dependencies:_
- [bwa](http://bio-bwa.sourceforge.net/)
- [samtools](http://www.htslib.org/)

Usage
---------------

ZWA2 standalone application may be fully or partially deployed upon execution. In the case of ZWA2 full deployment, the directories of NGS reads (FASTQ format) and an appropriate reference (FASTA format) must be provided as arguments after the -i and -r flags respectively, in order to be able to perform all necessary alignments. For the alternative and faster partial deployment of ZWA2, the directory of a BAM file can only be passed as an argument after the -m flag, instead of FASTQ and FASTA files, as the user may have already carried out the desired alignment with the mapping software of preference. Alongside the input BAM file, the user may also pass as an argument - if available - the output unmapped reads of the performed alignment in FASTQ or BAM format after the -u flag, for later use by the algorithm. Lastly, the user has the ability to adjust the mapping sensitivity of the incorporated BWA software by passing the desired level of alignment stringency as an integer number after the -l flag (default value: 30).

### Run examples
Full ZWA2 deployment run examples:
```sh
./ZWA2.sh -i reads.fastq -r ref.fasta -o ./
./ZWA2.sh -i reads.fq.gz -r ref.fasta.gz -o ./
```
Partial ZWA2 deployment run example:
```sh
./ZWA2.sh -m mapped.bam -o ./
./ZWA2.sh -m mapped.bam -u unmapped.bam -o ./
./ZWA2.sh -m mapped.bam -u unmapped.fq.gz -o ./
```

_!!!**LIMITATIONS**!!!_
> The ZWA tool has been tested on single-end reads ONLY. However, this does not suggest that it will not work for paired-end reads after pairing them so use with caution.
