#!/bin/bash



case "$1" in
  
  "start")
     
     echo "---------------启动yarn---------------------"
   
     ssh   Master "/root/hadoop-2.7.2/sbin/start-yarn.sh"

   ;;

  "stop")
   
   echo "----------------关闭yarn------------------------"
   
    ssh   Master "/root/hadoop-2.7.2/sbin/stop-yarn.sh" 

   ;;


esac
