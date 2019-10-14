#! /bin/bash

case $1 in
"start"){
	for i in Slave1 Slave2 Master
	do
		ssh $i "/root/zookeeper-3.4.10/bin/zkServer.sh start"
	done
};;
"stop"){
	for i in Slave1 Slave2 Master
	do
		ssh $i "/root/zookeeper-3.4.10/bin/zkServer.sh stop"
	done
};;
"status"){
	for i in Slave1 Slave2 Master
	do
		ssh $i "/root/zookeeper-3.4.10/bin/zkServer.sh status"
	done
};;
esac
