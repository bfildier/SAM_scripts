#!/global/homes/b/bfildier/anaconda3/bin/python

import sys,os,glob
import fileinput

scriptdir = os.path.dirname(os.path.realpath(__file__))

def sed(filename,word1,word2):

    for line in fileinput.input(filename):
        # inside this loop the STDOUT will be redirected to the file
        # the comma after each print statement is needed to avoid double line breaks
        print(line.replace(word1,word2),end='')

#convertscript=os.path.join(scriptdir,"convert2nc.sh")

convertscript='test.sh'

for keyword in 'currentsim','doout2d','dooutstat','overwrite':

    sed(convertscript,
        "%s=*"%keyword,
        "%s=false"%keyword)

sed(convertscript,"doout3d=*","doout3d=true")

sed(convertscript,"hello.*","byebye")
# !!! Problem with regular expression
# !!! Problem: when embedding for loop inside sed function, the STDOUT is not redirected to the file anymore

# # Calculate stepmin and stepmax
# suffix = 
