#!/bin/bash

log_date=$1

for i in Slave1 Slave2 Master
do
	ssh -t $i "sudo date -s $log_date"
done
