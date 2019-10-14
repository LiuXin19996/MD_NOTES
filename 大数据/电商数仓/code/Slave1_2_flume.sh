

#! /bin/bash

case $1 in
"start"){
        for i in Slave1 Slave2
        do
                echo " --------启动 $i 采集flume-------"
                ssh $i "nohup /root/apache-flume-1.7.0/bin/flume-ng agent --conf-file /root/apache-flume-1.7.0/conf/file-flume-kafka.conf --name a1 -Dflume.root.logger=INFO,LOGFILE >/dev/null 2>&1 &"
        done
};;
"stop"){
        for i in Slave1 Slave2
        do
                echo " --------停止 $i 采集flume-------"
                ssh $i "ps -ef | grep file-flume-kafka | grep -v grep |awk '{print \$2}' | xargs kill"
        done

};;
esac
