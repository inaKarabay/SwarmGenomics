#!/bin/bash

#IGV: ~/Downloads/IGV_Linux_2.10.0 ./igv.sh
#load fasta (fna) and index (fai) for genome and bam, bai, vcf as track


#histogram of chromosome legth
#grep "chromosome" reference.fna
#-> first 25 lines of reference.fna.fai
#-> use histogram.py

#sort reference into chromosomes
#head -25 reference.fna.fai | sudo faidx -x reference.fna


#repeatmasker (save database!)
#install: https://www.repeatmasker.org/RepeatMasker/
#database https://www.dfam.org/releases/Dfam_3.2/families/Dfam.h5.gz
#search engine: RMBlast http://www.repeatmasker.org/RMBlast.html



#coverage of chromosomes -> exvlude low coverage regions and repetitions
#compute heterozygose positions
#RoH runs of homozygosity: bcftools roh-calling http://samtools.github.io/bcftools/howtos/roh-calling.html
#PSMC on each chromosome https://github.com/lh3/psmc

#use heterozygosity to estimate diversity (hardy weinberg: one genome is enough to estimate diversity)
#PSMC demography (get data from database: size, size when infant leaves parents (correlation: bigger= less diversity))
# -> question: is demography linked with runs of homozygosity?
#ref seq (annotations -> get coding areas -> relation of silent and non_silent mutations
#remove sex chromosomes?






