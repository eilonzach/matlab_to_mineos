#!/bin/bash

shopt -s nullglob

files=( *.asc1 )
if (( ${#files[@]} )); then
    

for i in *.asc1
 do 
 j=`echo $i | sed s/.asc1//g`
 echo $j
 rm $j*
done


fi
