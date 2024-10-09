#!/bin/bash
##           (\.---./)
##            /.-.-.\
##           /| 0_0 |\
##          |_`-(v)-'_|
##          \`-._._.-'/      .-.
##    -~-(((.`-\_|_/-'.)))-~' <_
##           `.     .'
##             `._.'
##
##    -----~--~---~~~----~-`.-;~
##            GEBVeR

#requires an input dir with uncompressed vcf files
# designed to take the *.vcf files from starIntersect or starCombine etc. anything which has been processed with bcftools merge -force

# Extract a set of lines from a vcf by setting a variable, which allows some wildcards.
#eg: keepKey="^BM1743-..*"

#activate an environment with:
#rtgtools
#bcftools
#vcftools
#parallel

# USER: set the key to match against the lines in the input vcf. Grep wildcards are allowed. only these are tested.
# ^ start of line
# $ end of line
# . any single character
# .* any character or none
keepKey="^BM1743-..*"

echo "Begin: Line Finder"

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

echo "<<< copy inputs to data >>>"
(cd input || exit
 files=$(ls -1 *.vcf)
 parallel \
	   echo {}';' \
	   cp  {} ../data \
     ::: ${files}
)

echo "<<< filter for repeat names >>>"
(cd data || exit
 for f in *.vcf
 do
     echo ${f}
     allNames=$(bcftools query -l ${f} 2>/dev/null)
     dropNames=""
     keepNames=""

     #subset keeps
     for i in ${allNames}
     do
         match=$(echo "${i}" | grep "${keepKey}")
         if [[ "${match}" == "" ]]; then
             dropNames+="${i} "
         else
             echo keep: "${i}"
         fi
     done

     #remove dropNames from allNames to get keepNames
     for i in ${allNames}
     do
         drop="false"
         for j in ${dropNames}
         do
             #test if kicking out
             if [[ "${i}" == "${j}" ]]; then
                 drop="true"
                 echo "drop: ${i}"
             fi
         done
         if [ "${drop}" == "false" ]; then
             keepNames+="${i},"
         fi
     done

     #drop last comma, and handle empty list case
     if [ "${keepNames}" == "" ]; then
         echo "ALERT: No matches found"
     else
         keepNames=${keepNames::-1}
         doSubset="true"
     fi

     if [ "${doSubset}" == "true" ]; then

         #clean keepKey
         cleanKey=$(echo "${keepKey}" | tr -dc '[:alnum:]\n\r')

         #process original .vcf to retain keepNames
	       rtg bgzip ${f}
	       bcftools index -cf --threads 4 ${f}.gz
         bcftools view \
                  -O v \
                  -o "${f}.find${cleanKey}" \
                  --threads 4 \
                  -s ${keepNames} \
                  ${f}.gz

         #count lines retained
         countNames=$(bcftools query -l ${f}.find${cleanKey} 2>/dev/null)
         count=$(echo "${countNames}" | wc -l)
         echo "Count of lines retained: ${count}"
     fi
 done # end files loop
)

#copy result to output
(cd data || exit
files=$(ls -1 *.vcf.find*)
parallel \
    cp {} ../output \
    ::: ${files}
)

(cd output || exit
for f in *.vcf.find*; do
    bcftools stats -v --threads 4 ${f} > ${f}_bcf_stats.txt
    rtg vcfstats ${f} > ${f}_rtg_stats.txt
done
)

echo "Complete"
exit
