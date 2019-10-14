#!/bin/bash

case $1 in
"start"){
        for i in Slave1 Slave2 Master
        do
                echo " --------启动 $i Kafka-------"
                # 用于KafkaManager监控
                ssh $i "export JMX_PORT=9988 && /root/kafka_2.11/bin/kafka-server-start.sh -daemon /root/kafka_2.11/config/server.properties "
        done
};;
"stop"){
        for i in  Slave1 Slave2 Master
        do
                echo " --------停止 $i Kafka-------"
                ssh $i "/root/kafka_2.11/bin/kafka-server-stop.sh stop"
        done
};;
esac
