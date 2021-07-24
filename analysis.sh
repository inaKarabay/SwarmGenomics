#!/bin/bash

#IGV: ~/Downloads/IGV_Linux_2.10.0 ./igv.sh
#load fasta (fna) and index (fai) for genome and bam, bai, vcf as track

#ON REFERENCE
#histogram of chromosome length
#grep "chromosome" reference.fna
#-> first 25 lines of reference.fna.fai
#-> use histogram.py

#repeatmasker (save database!)
#install: https://www.repeatmasker.org/RepeatMasker/
#database https://www.dfam.org/releases/Dfam_3.2/families/Dfam.h5.gz
#search engine: RMBlast http://www.repeatmasker.org/RMBlast.html

#remove repeats (repeats are lower case)
for chromosome in NC*
do
tr -d [:lower:] < $chromosome > new$chromosome
done


#CONSENSUS BCFTOOLS
#index vcf
#bcftools index output.vcf.gz 
#normalize indels
# split multiallelic sites into multiple rows
#bcftools norm -f reference.fna output.vcf.gz -Ob -o output.norm.bcf
#bcftools filter --IndelGap 5 output.norm.bcf -Ob -o output.norm.flt-indels.bcf
#cat reference.fna | bcftools consensus output.vcf.gz > consensus.fa
#The site NW_024571163.1:21951 overlaps with another variant, skipping... -> a lot
#PROBLEM consensus not diploid


questions:
call mit???
   -A, --keep-alts                 keep all possible alternate alleles at variant sites

bcftools call mit -c (-mv funktioniert nicht)

vcf file ueberspringen? (direkt consensus file?)

warum nur ein consensus file? consensus von bcftools diploid?

warumso viele n bei vcfutils?

ist bcftools most frequent und vcfutils nur wenns gleich ist?

PSMC demographic woher?

wann repeats entfernen? aus consensus.fq? whrend psmc?


coverage in psmc korrigieren? wie hoch FN rate?

PSMC Bild
roh output



#coverage of chromosomes -> exvlude low coverage regions and repetitionss

#compute heterozygose positions
#RoH runs of homozygosity: bcftools roh-calling http://samtools.github.io/bcftools/howtos/roh-calling.html
#PSMC on each chromosome https://github.com/lh3/psmc

#use heterozygosity to estimate diversity (hardy weinberg: one genome is enough to estimate diversity)
#PSMC demography (get data from database: size, size when infant leaves parents (correlation: bigger= less diversity))
# -> question: is demography linked with runs of homozygosity?
#ref seq (annotations -> get coding areas -> relation of silent and non_silent mutations
#remove sex chromosomes?







