#!/bin/bash
#/bin/sbin

#accept tow files absolute path
file1=$1
file2=$2

if [[ $# -eq 0 ]];then
    echo "No parameters provided."
    exit
fi
file1_lines='wc -lc $file1 | grep "total"'
file2_lines='wc -lc $file2 | grep "total"'
if [ file1_lines != file2_lines ]; then
	echo "1"
	exit
fi
#sort the files content
sed 's/\s+//g;/^$/d' $file1
sort -b $file1 > $file1+temp.txt
sort -b $file2 > $file2+temp.txt
diff $file1+temp.txt $file2+temp.txt > /dev/null
if [ $? == 0 ]; then
	echo "0"
else
	echo "1"
fi
rm -rf $file1+temp.txt
rm -rf $file2+temp.txt
