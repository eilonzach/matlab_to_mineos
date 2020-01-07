#!/bin/bash

shopt -s nullglob

files=( *.asc* )
if (( ${#files[@]} )); then


for i in *.asc*
 do
 j=`echo $i | sed s/.asc//g`
 echo $j
 rm $j*
done


fi
