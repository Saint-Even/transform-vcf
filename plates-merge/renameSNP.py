#!/usr/bin/env python3

# %%
import pandas
import sys
import re
import os
import glob
import math

# NOTE: around line 40 there is a check which often needs manual setting

# %%
#standalone usage: renameSNP.py <fileName.vcf> <outfileName.vcf>
fileName = sys.argv[1]
outName = sys.argv[2]

#get count of chromosomes
numChromosomes = 7



# %%
#take header off the top
maxHeader = 70
header = list()
i=0
with open(fileName, 'r') as reader:
    while i < maxHeader:
        line = reader.readline()
        if line.startswith('#'):
            header.append(line)
        else:
            i += 1

# %%
#keep body without header
f = open(fileName, 'r')
vcf = pandas.read_table(f, skiprows= len(header),
                        sep=r"\s+",
                        skip_blank_lines=True)

# %%
#identify the chromosome indicator character position
# this changes sometimes and should be checked often

#known: in one case col 0 is 1 based and a numpy.int64 type
#in another case the 1s place digit is 0-6 with a +1 offset
#in another case
# LR890096.1
# LR890097.1
# LR890098.1
# LR890098.1
# LR890099.1
# LR890100.1
# LR890100.1
# LR890101.1
# LR890102.1
# LR890 102.1
# 01234 5678
# reduces to positions 5 to 8
# and maps to the chr count with a -95 offset
# 096 1
# 097 2
# 098 3
# 098 3
# 099 4
# 100 5
# 100 5
# 101 6
# 102 7
# 102 7

#peek
nrows=vcf.shape[0]
ntenth=math.floor(nrows/10)

print(vcf.head(n=1))
print(vcf.iloc[1*ntenth,0])
print(vcf.iloc[2*ntenth,0])
print(vcf.iloc[3*ntenth,0])
print(vcf.iloc[4*ntenth,0])
print(vcf.iloc[5*ntenth,0])
print(vcf.iloc[6*ntenth,0])
print(vcf.iloc[7*ntenth,0])
print(vcf.iloc[8*ntenth,0])
print(vcf.iloc[9*ntenth,0])
print(vcf.iloc[10*ntenth,0])
print(vcf.tail(n=1))
print(type(vcf.iloc[0,0]))

#print("early exit")
#exit()

# %%
#convert SNP name col to only chr num

#convert
start=5
stop=8
offset=-95

vcf.iloc[:,0] = vcf.iloc[:,0].str[start:stop] # substring
vcf.iloc[:,0] = vcf.iloc[:,0].astype('int') # convert to int
vcf.iloc[:,0] = vcf.iloc[:,0]+offset # offset

print(vcf.head(n=1))
print(vcf.iloc[1*ntenth,0])
print(vcf.iloc[2*ntenth,0])
print(vcf.iloc[3*ntenth,0])
print(vcf.iloc[4*ntenth,0])
print(vcf.iloc[5*ntenth,0])
print(vcf.iloc[6*ntenth,0])
print(vcf.iloc[7*ntenth,0])
print(vcf.iloc[8*ntenth,0])
print(vcf.iloc[9*ntenth,0])
print(vcf.iloc[10*ntenth,0])
print(vcf.tail(n=1))
print(type(vcf.iloc[0,0]))

# %%
#make full SNP name
vcf.iloc[:,2] = "Chr" + vcf.iloc[:,0].astype(str) + "H_" + vcf.iloc[:,1].astype(str)

# %%
#write header and dataframe to new file
with open(outName, 'w') as writer:
    for line in header:
        writer.write(line)
    writer.write(vcf.to_csv(sep="\t", index=False, header=False))
