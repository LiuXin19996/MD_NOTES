#!/bin/bash

function sum()
{

s=0

s=$(($1 + $2))

echo $s


}


read -t 7 -p "在7内给出n值：" n

read -t 7 -p "在7内给出m值：" m


sum $n $m
