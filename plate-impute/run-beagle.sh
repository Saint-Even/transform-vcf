#!/usr/bin/env bash
#strict mode
set -euo pipefail
IFS=$'\n\t'

#variant imputation

#requires input data and output dir
#input dir containing at least 1 vcf file

#activate and environment containing
# beagle version > 5.0
# parallel

## Setup locations
home=$(pwd)
input=${home}/input
data=${home}/data
output=${home}/output

:<<'MASK'
MASK

#clean
rm -rf ${data}
mkdir ${data}
rm -rf ${output}
mkdir ${output}

#copy input
echo "<<<copy data>>>"
(cd input
 files=$(ls -1 *.vcf)
 parallel \
	   echo {}';' \
	   cp  {} ../data \
     ::: ${files}
)

#impute
echo "<<<impute>>>"
(cd ${data}
 files=$(ls -1 *.vcf)
 parallel \
     echo {}';' \
     beagle -Xmx16G \
     gt={} \
     out={/.}_imputed \
     ne=100000 \
     err=0.001 \
     window=100 \
     burnin=50 \
     iterations=40 \
     '>' {/.}_log 2>&1 \
     ::: ${files}
)

#move to output
echo "<<<copy results>>>"
(cd data
 cp *.log ${output}
 files=$(ls -1 *.vcf.gz)
 parallel \
	   echo {}';' \
     gzip -d {}';' \
     cp -v {/.} ${output} \
 ::: ${files}
)

exit
===========================================================
#https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6945036/
Parameter	default	range-tested	best	overall-impact
BEAGLE 5.1	—	—	default (0.0127%)	—
ne	1,000,000	1 - 1,000,000	100,000 (0.0125%)
err	0.000067	0.01 - 0.00001	0.001 (0.0125%)
window	40	10 - 1,000	100 (0.0125%)
burnin	6	2 - 50	50 (0.0126%)
iterations	12	2 - 40	40 (0.0127%)
phase-states	280	50 - 10,000	default (0.0127%)

beagle.22Jul22.46e.jar (version 5.4)
Copyright (C) 2014-2022 Brian L. Browning
Usage: java -jar beagle.22Jul22.46e.jar [arguments]

data parameters ...
  gt=<VCF file with GT FORMAT field>                 (required)
  ref=<bref3 or VCF file with phased genotypes>      (optional)
  out=<output file prefix>                           (required)
  map=<PLINK map file with cM units>                 (optional)
  chrom=<[chrom] or [chrom]:[start]-[end]>           (optional)
  excludesamples=<file with 1 sample ID per line>    (optional)
  excludemarkers=<file with 1 marker ID per line>    (optional)

phasing parameters ...
  burnin=<max burnin iterations>                     (default=3)
  iterations=<phasing iterations>                    (default=12)
  phase-states=<model states for phasing>            (default=280)

imputation parameters ...
  impute=<impute ungenotyped markers (true/false)>   (default=true)
  imp-states=<model states for imputation>           (default=1600)
  cluster=<max cM in a marker cluster>               (default=0.005)
  ap=<print posterior allele probabilities>          (default=false)
  gp=<print posterior genotype probabilities>        (default=false)

general parameters ...
  ne=<effective population size>                     (default=100000)
  err=<allele mismatch probability>                  (default: data dependent)
  em=<estimate ne and err parameters (true/false)>   (default=true)
  window=<window length in cM>                       (default=40.0)
  overlap=<window overlap in cM>                     (default=2.0)
  seed=<random seed>                                 (default=-99999)
  nthreads=<number of threads>                       (default: machine dependent)
