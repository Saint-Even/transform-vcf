#!/bin/bash

#requires an input dir with uncompressed vcf files

#activate an environment with:
#parallel
#rtgtools
#bcftools

echo "Begin: common marker intersect"
echo "Intersect markers from all. Exclusive lines from each."
opType="IntMarkExcLine"

:<<'MASK'
MASK

#clear data and output
for d in data output
do
	  rm -r ./${d}
	  mkdir ${d}
	  (cd ${d} || exit
	   touch .gitkeep)
done


echo "<<<copy inputs to data>>>"
(cd input || exit
 files=$(ls -1 *.vcf)
 parallel \
	   echo {}';' \
	   cp  {} ../data \
     ::: ${files}
)

echo "<<<compress and index files>>>"
(cd data || exit
files=$(ls -1 *.vcf)
parallel \
	echo {}';' \
	rtg bgzip {}';' \
	bcftools index -cf --threads 4 {}.gz \
::: ${files}
)

echo "<<<ring intersect>>>"
(cd data || exit
 IFS=$'\n'
 files=($(find . -name "*.gz"))
 unset IFS

len=${#files[@]}
last=$((len - 1))
for i in $(seq 0 ${last})
do
	#only once assign arg from array
	if [ ${i} = 0 ]
	then
		a=${files[0]}
	#later assign arg from previous result
	else
		a="./intersect.vcf.gz"
	fi

	#do nothing on last pass, no next value to intersect
	if [ ${i} -lt ${last} ]
	then
		next=$((i+1))
		b=${files[${next}]}
		echo a:${a}
		echo b:${b}
		bcftools isec \
			-c snps \
			-O z \
			-p isec \
			--threads 4 \
			${a} \
			${b}
		rm ./intersect.vcf.gz
		mv isec/0003.vcf.gz ./intersect.vcf.gz
		rm -r isec
		bcftools index -cf --threads 4 intersect.vcf.gz
	fi
done
)

echo "<<<star intersect>>>"
(cd data || exit
 mv intersect.vcf.gz intersect.vcf.hidden
 files=$(ls -1 *.gz)
 mv intersect.vcf.hidden intersect.vcf.gz

parallel \
	echo {}';' \
	bcftools isec \
		-c snps \
		-O z \
		-p {/.} \
		--threads 4 \
		intersect.vcf.gz \
		{}';' \
	cd {/.}';' \
	mv 0003.vcf.gz {.}.common.gz';' \
	mv {.}.common.gz ..';' \
	cd .. ';' \
	rm -r {/.} \
::: ${files}
)

echo "<<<decompress>>>"
(cd data || exit
 files=$(ls *.vcf.common.gz)

 parallel \
	   echo {}';' \
	   rtg bgzip -d {} \
     ::: ${files}
)

echo "<<<rename>>>"
# &&& names are silly long, prob need a sed stack to cut down
(cd data || exit
 files=$(ls *.vcf.common)

 fnames=""
 clean=$(echo ${files} | sed s:.vcf.common::g)
 clean=$(echo ${clean} | sed s:_::g)
 clean=$(echo ${clean} | sed s:filter:fl:g)
 for c in ${clean}
 do
 	   fnames+="${c}_"
 done
 fnames+="${opType}"

 for f in ${files}; do
     echo ${f}
     n=$(echo ${f} | sed s:.common::g)
     n=$(echo ${n} | sed s:_::g)
     n=$(echo ${n} | sed s:filter:fl:g)
     mv ${f} ${fnames}_${n}
 done
)

echo "<<<copy to output>>>"
(cd data || exit
 files=$(ls -1 *.vcf)
 parallel \
	   echo {}';' \
	   cp  {} ../output \
     ::: ${files}
)

echo "Complete"
exit
