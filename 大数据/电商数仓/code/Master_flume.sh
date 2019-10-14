#! /bin/bash

case $1 in
"start"){
        for i in Master
        do
                echo " --------启动 $i 消费flume-------"
                ssh $i "nohup /root/apache-flume-1.7.0/bin/flume-ng agent --conf-file /root/apache-flume-1.7.0/conf/kafka-flume-hdfs.conf --name a1 -Dflume.root.logger=INFO,LOGFILE >/opt/module/flume/log.txt   2>&1 &"
        done
};;
"stop"){
        for i in Master
        do
                echo " --------停止 $i 消费flume-------"
                ssh $i "ps -ef | grep kafka-flume-hdfs | grep -v grep |awk '{print \$2}' | xargs kill"
        done

};;
esac
