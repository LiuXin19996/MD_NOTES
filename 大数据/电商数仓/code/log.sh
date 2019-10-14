#! /bin/bash

	for i in Slave1 Slave2 
	do
		ssh $i "java -classpath /root/code/log-collector-1.0-SNAPSHOT-jar-with-dependencies.jar com.lx.appclient.AppMain $1 $2 >/opt/module/test.log &"
	done
