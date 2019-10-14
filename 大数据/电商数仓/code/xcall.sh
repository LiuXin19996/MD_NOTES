#! /bin/bash

for i in Slave1 Slave2 Master
do
        echo --------- $i ----------
        ssh $i "$*"
done
