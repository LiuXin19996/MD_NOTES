#!/bin/bash



case $1 in 


"start")
    
    for i in Slave1
     do
   
     echo  "----------------启动hdfs-------------------"
    
     ssh $i "/root/hadoop-2.7.2/sbin/start-dfs.sh"\
  
    done

   ;;

"stop")

   for i in Slave1
    do
   
    echo  "---------------------关闭hdfs----------------"   
    
    ssh $i "/root/hadoop-2.7.2/sbin/stop-dfs.sh"

    done

   ;;

esac
