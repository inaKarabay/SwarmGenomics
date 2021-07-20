#!/bin/bash

working_dir='/vol/storage/VulpesLagupos'

#IGV: ~/Downloads/IGV_Linux_2.10.0 ./igv.sh
#load fasta (fna) and index (fai) for genome and bam, bai, vcf as track


#histogram of chromosome length
#grep "chromosome" reference.fna
#-> first 25 lines of reference.fna.fai
#-> use histogram.py

#sort reference into chromosomes
#25 because of 25 chromosomes
#head -25 reference.fna.fai | sudo faidx -x reference.fna

#get chromosomes bigger than 1MB
cd $working_dir/chromosomes/
: '
sudo mkdir big
for file in NC*
do
words=`wc -w $file | awk '{print $1}'`
#echo $words
if [ $words -gt 1000000 ]
then	
	mv $file big/$file
fi
done
'
cd big/

#repeatmasker (save database!)
#install: https://www.repeatmasker.org/RepeatMasker/
#database https://www.dfam.org/releases/Dfam_3.2/families/Dfam.h5.gz
#search engine: RMBlast http://www.repeatmasker.org/RMBlast.html

#remove repeats (repeats are lower case)
for chromosome in NC*
do
tr -d [:lower:] < $chromosome > new$chromosome
done

#mkdir vcf
#cp output.vcf /vcf
#bcftools view -h output.vcf -> where are chromosomes?
#bcftools index -f output.vcf 
#index: "output.vcf" is in a format that cannot be usefully indexed


#coverage of chromosomes -> exvlude low coverage regions and repetitionss

#compute heterozygose positions
#RoH runs of homozygosity: bcftools roh-calling http://samtools.github.io/bcftools/howtos/roh-calling.html
#PSMC on each chromosome https://github.com/lh3/psmc

#use heterozygosity to estimate diversity (hardy weinberg: one genome is enough to estimate diversity)
#PSMC demography (get data from database: size, size when infant leaves parents (correlation: bigger= less diversity))
# -> question: is demography linked with runs of homozygosity?
#ref seq (annotations -> get coding areas -> relation of silent and non_silent mutations
#remove sex chromosomes?


questions:
vcf file indexen -> gekuerztes file?

warum nur ein consensus file? consensus von bcftools diploid?

warumso viele n bei vcfutils?

ist bcftools most frequent und vcfutils nur wenns geich ist?

PSMC Bild
roh output


#count variants
#bcftools view -H output.vcf.gz | wc -l
#7.839.513 variants

#index vcf
#bcftools index output.vcf.gz 
#normalize indels
# split multiallelic sites into multiple rows
#bcftools norm -f reference.fna output.vcf.gz -Ob -o output.norm.bcf
#bcftools filter --IndelGap 5 output.norm.bcf -Ob -o output.norm.flt-indels.bcf
#cat reference.fna | bcftools consensus output.vcf.gz > consensus.fa
#The site NW_024571163.1:21951 overlaps with another variant, skipping... -> a lot
#PROBLEM consensus not diploid

#call -c for consensus
#samtools mpileup -uf reference.fna  bwa.sorted.bam | bcftools call -c | vcfutils.pl vcf2fq -d 10 -D 100 > diploid_consensus.fq


#PSMC
#utils/fq2psmcfa -q20 ../VulpesLagupos/diploid.fq > diploid.psmcfa
#psmc-master/psmc -N25 -t15 -r5 -p "4+25*2+4+6" -o psmc-master/diploid.psmc psmc-master/diploid.psmcfa
#utils/psmc2history.pl diploid.psmc | utils/history2ms.pl > ms-cmd.sh
#utils/psmc_plot.pl diploid diploid.psmc
#open image
#gv diploid.eps


#ROH
#bcftools roh -G30 --AF-dflt 0.4 output.vcf > roh.txt







