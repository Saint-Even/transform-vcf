#!/bin/bash

#requires an input dir with uncompressed vcf files
# merge plates to a large training data set
# designed to take the filtered.vcf files from  post processing of cassetteGBS merged.vcf output

#activate an environment with:
#parallel
#rtg-tools
#bcftools
#vcftools
#pandas

echo "Begin: all marker merge"

#first construct final name
cd input/
files=$(ls *.vcf)
echo ${files}
clean=$(echo ${files} | sed s:.vcf::g)

name=""
for n in ${clean}
do
	  name+="${n}_"
done
name+="combined.vcf"
cd ..

:<<'COMMENT'
COMMENT

#clear data and output
for d in data output
do
	rm -r ./${d}
	mkdir ${d}
	(cd ${d} || exit
	touch .gitkeep)
done

echo "<<< copy inputs to data >>>"
(cd input || exit
files=$(ls -1 *.vcf)
parallel \
	echo {}';' \
	cp  {} ../data \
::: ${files}
)

echo "<<< compress and index files >>>"
(cd data || exit
files=$(ls -1 *.vcf)
parallel \
	echo {}';' \
	rtg bgzip {}';' \
	bcftools index -cf --threads 4 {}.gz \
::: ${files}
)

echo "<<< convert >>>"
(cd data || exit
 files=$(ls -1 *.vcf.gz | sed 's/.vcf.gz//g')
 parallel \
	   echo {}';' \
     bcftools convert --threads 4 -O b -o {}.bcf {}.vcf.gz \
     ::: ${files}
)

echo "<<< sort >>>"
(cd data || exit
 files=$(ls -1 *.bcf)
 parallel \
	   echo {}';' \
     bcftools sort -O b -o {}.sort {}';' \
	   bcftools index -cf --threads 4 {}.sort \
     ::: ${files}
)

echo "<<< merge >>>"
#bcftools concat --threads 12 -o variantsMerged.vcf -O v ${files}
(cd data || exit
files=$(ls -1 *.bcf.sort)
bcftools merge --force-samples --threads 12 -o variantsMerged.vcf -O v ${files}
)

echo "<<< cleanup >>>"
(cd data || exit
 rm *.bcf*
 rm *.vcf.*
)

echo "<<< renameVariants >>>"
(cd data || exit
fileName="variantsMerged.vcf"
outName="variantsMergedRenamed.vcf"
rm -f ${outName}
python ../renameSNP.py ${fileName} ${outName}
)

#copy result to output
(cd data || exit
mv variantsMergedRenamed.vcf ${name}
mv ${name} ../output
)

echo "Complete"
exit
