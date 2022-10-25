#!/bin/bash
#/bin/sbin

#accept tow files absolute path
file1=$1
file2=$2

if [[ $# -eq 0 ]];then
    echo "No parameters provided."
    exit
fi

file1_lines=`wc -lc $file1 | awk -F ' ' '{print $1}'`
file2_lines=`wc -lc $file2 | awk -F ' ' '{print $1}'`
if [ $file1_lines != $file2_lines ]; then
	echo "line count of $file1 is $file1_lines,but line count of $file2 is $file2_lines"
	exit 1
fi

#sort the files content
#sed 's/\s+//g;/^$/d' $file1
sort -b $file1 > $file1+temp.txt
sort -b $file2 > $file2+temp.txt
result=`diff $file1+temp.txt $file2+temp.txt`
if [ -z "$result" ]; then
  rm -rf $file1+temp.txt
  rm -rf $file2+temp.txt
	exit 0
else
	echo $result
  rm -rf $file1+temp.txt
  rm -rf $file2+temp.txt
	exit 1
fi
