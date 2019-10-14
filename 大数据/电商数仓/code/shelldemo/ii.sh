#!/bin/bash

for x in $*
 do

  echo "整体：$x"

 done



for y in $@
 do

  echo "分割：$y"

 done


echo "#################################"




for x in "$*"
 do

  echo "整体：$x"

 done



for y in "$@"
 do

  echo "分割：$y"

 done
