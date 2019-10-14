# Scala安装

## 1.解压

```
[root@Master software-package]# tar -zxvf  scala-2.11.8.tgz   -C /root/
```

## 2.配置环境变量

```
export SCALA_HOME=/root/scala-2.11.8
export PATH=$PATH:$SCALA_HOME/bin

[root@Master scala-2.11.8]# source  /etc/profile
[root@Master scala-2.11.8]# 
```

## 3.拷贝

```
[root@Master scala-2.11.8]# scp -r scala-2.11.8/ SlaveNode01:/root/

[root@Master scala-2.11.8]# scp -r /etc/profile  SlaveNode01:/etc/
```

## 4.验证

```
[root@Master scala-2.11.8]# scala
Welcome to Scala 2.11.8 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_11).
Type in expressions for evaluation. Or try :help.

scala> 
```

# Spark集群安装

## 1.解压

```
[root@Master software-package]# tar -zxvf spark-1.5.1-bin-hadoop2.4.tgz  -C /root/
[root@Master ~]# mv spark-1.5.1-bin-hadoop2.4/  spark-1.5.1
```

## 2.配置文件

```
[root@Master spark-1.5.1]# vim /etc/profile

export SPARK_HOME=/root/spark-1.5.1
export PATH=$PATH:$SPARK_HOME/bin

[root@Master conf]# pwd
/root/spark-1.5.1/conf
[root@Master conf]# mv spark-env.sh.template spark-env.sh
[root@Master conf]# vim spark-env.sh 

export JAVA_HOME=/root/jdk1.8.0_11/
export SCALA_HOME=/root/scala-2.11.8 
export HADOOP_HOME=/root/hadoop-2.5.0/
export HADOOP_CONF_DIR=/root/hadoop-2.5.0/etc/hadoop
export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=Master:2181,SlaveNode01:2181,SlaveNode01:2181 -Dspark.deploy.zookeeper.dir=/root/spark-1.5.1/data/spark"
export SPARK_MASTER_PORT=7077

################################################################################################
[root@Master conf]# cp slaves.template  slaves    ##在该文件中添加子节点所在的位置（Worker节点）

# A Spark Worker will be started on each of the machines listed below.


SlaveNode01
SlaveNode02        
```

## 3.拷贝到其他机器

```
[root@Master ~]# scp -r spark-1.5.1/  SlaveNode01:/root/

[root@Master ~]# scp -r spark-1.5.1/  SlaveNode02:/root/

[root@Master ~]# scp -r /etc/profile  SlaveNode01:/etc/
  
[root@Master ~]# scp -r /etc/profile  SlaveNode02:/etc/

[root@Master ~]# source /etc/profile
```

## 4.编写zk脚本

    #!/bin/bash
    
    case $1 in
      "start")


​    
        for i in Master SlaveNode01 SlaveNode02
          do
    
          echo "-----------启动zk集群-------------------"
          ssh $i "/root/zookeeper-3.4.5/sbin/zkServer.sh  start"
    
          done
       ;;
    
       "stop")
    
         for i in Master SlaveNode01 SlaveNode02
          do
          echo "-----------关闭zk集群-------------------"
          ssh $i "/root/zookeeper-3.4.5/sbin/zkServer.sh  stop"
          done
        ;;
    
       "status")
    
         for i in Master SlaveNode01 SlaveNode02
          do
          echo "-----------查看zk状态-------------------"
          ssh $i "/root/zookeeper-3.4.5/sbin/zkServer.sh  status"
          done
        ;;
    esac

## 5.编写Spark脚本

```
#!/bin/bash

case $1 in
  "start")
    /root/spark-1.5.1/sbin/start-all.sh

  ;;

  "stop")
   /root/spark-1.5.1/sbin/stop-all.sh
  ;;
esac
```

## 6.编写jps脚本

```
#!/bin/bash

for i in Master SlaveNode01 SlaveNode02
   do
   echo "---------$i--------------"
   ssh $i "$*"
   done
~           
```

## 7.启动

```
[root@Master bin]# ./zk.sh  start
 
[root@Master bin]# ./Master_spark.sh  start
 
[root@Master bin]# ./xcall.sh  jps
---------Master--------------
18470 Master
18281 QuorumPeerMain
18618 Jps
---------SlaveNode01--------------
3236 Worker
3086 QuorumPeerMain
3310 Jps
---------SlaveNode02--------------
3265 Worker
3130 QuorumPeerMain
3339 Jps
```

## 8.求PI

```
/root/spark-1.5.1/bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master spark://Master:7077 \
--executor-memory 500m \
--total-executor-cores 2 \
/root/spark-1.5.1/lib/spark-examples-1.5.1-hadoop2.4.0.jar \
10
 

############################################################################################

基本语法
bin/spark-submit \
--class <main-class>
--master <master-url> \
--deploy-mode <deploy-mode> \
--conf <key>=<value> \
... # other options
<application-jar> \
[application-arguments]
（2）参数说明：
--master 指定Master的地址，默认为Local
--class: 你的应用的启动类 (如 org.apache.spark.examples.SparkPi)
--deploy-mode: 是否发布你的驱动到worker节点(cluster) 或者作为一个本地客户端 (client) (default: client)*
--conf: 任意的Spark配置属性， 格式key=value. 如果值包含空格，可以加引号“key=value” 
application-jar: 打包好的应用jar,包含依赖. 这个URL在集群中全局可见。 比如hdfs:// 共享存储系统， 如果是 file:// path， 那么所有的节点的path都包含同样的jar
application-arguments: 传给main()方法的参数
--executor-memory 1G 指定每个executor可用内存为1G
--total-executor-cores 2 指定每个executor使用的cup核数为2个

###############################################################################################

错误：
Initial job has not accepted any resources; check your cluster UI to ensure
原因是--executor-memory设置过大。

```

## 9.spark shell

spark-shell是Spark自带的交互式Shell程序，方便用户进行交互式编程，用户可以在该命令行下用scala编写spark程序。

### 9.1启动shell

```
启动shell之前要启动spark集群

[root@Master bin]# pwd
/root/spark-1.5.1/bin
[root@Master bin]# /root/spark-1.5.1/bin/spark-shell   \
--master spark://Master:7077  \
--executor-memory 500m  \
--total-executor-cores 1

参数说明：
--master spark://Master:7077  指定Master的地址
--executor-memory 500m  指定每个worker可用内存为2G
--total-executor-cores 1 指定整个集群使用的cup核数为2个

出现问题：
akka.actor.ActorNotFound: Actor not found for: ActorSelection[Anchor(akka.tcp://sparkMaster@Master:7077/), Path(/user/Master)]
```

### 9.2验证

```
1. 作用：返回一个新的RDD，该RDD由每一个输入元素经过func函数转换后组成
2. 需求：创建一个1-10数组的RDD，将所有元素*2形成新的RDD
（1）创建
scala> var source  = sc.parallelize(1 to 10)
source: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[8] at parallelize at <console>:24
（2）打印
scala> source.collect()
res7: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
（3）将所有元素*2
scala> val mapadd = source.map(_ * 2)
mapadd: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[9] at map at <console>:26
（4）打印最终结果
scala> mapadd.collect()
res8: Array[Int] = Array(2, 4, 6, 8, 10, 12, 14, 16, 18, 20)
```

### 9.3帮助

```
scala> :help
All commands can be abbreviated, e.g. :he instead of :help.
Those marked with a * have more detailed help, e.g. :help imports.

:cp <path>                 add a jar or directory to the classpath
:help [command]            print this summary or command-specific help
:history [num]             show the history (optional num is commands to show)
:h? <string>               search the history
:imports [name name ...]   show import history, identifying sources of names
:implicits [-v]            show the implicits in scope
:javap <path|class>        disassemble a file or class name
:load <path>               load and interpret a Scala file
:paste                     enter paste mode: all input up to ctrl-D compiled together
:quit                      exit the repl
:replay                    reset execution and replay all previous commands
:reset                     reset the repl to its initial state, forgetting all session entries
:sh <command line>         run a shell command (result is implicitly => List[String])
:silent                    disable/enable automatic printing of results
:fallback                  
disable/enable advanced repl changes, these fix some issues but may introduce others. 
This mode will be removed once these fixes stablize
:type [-v] <expr>          display the type of an expression without evaluating it
:warnings                  show the suppressed warnings from the most recent line which had any

scala> :
```

# RDD编程

```
2.spark 算子列表
2.1.Value 数据类型的 Transformation 算子
2.1.1. 输入分区与输出分区一对一类型的算子
（1）map 算子
（2）flatMap 算子
（3）mapPartitions 算子
（4）mapPartitionsWithIndex 算子
（5）glom 算子
（6）randomSplit 算子

2.1.2. 输入分区与输出分区多对一类型的算子
（1）union 算子
（2）cartesian 算子

2.1.3. 输入分区与输出分区多对多类型的算子
（1）groupBy 算子
（2）coalesce 算子
（3）repartition 算子

2.1.4. 输出分区为输入分区子集型的算子
（1）filter 算子
（2）distinct 算子
（3）intersection 算子
（4）subtract 算子
（5）sample 算子
（6）takeSample 算子

2.1.5.Cache 型的算子
（1）persist 算子
（2）cache 算子

2.2.Key-Value 数据类型的 Transformation 算子
2.2.1. 输入分区与输出分区一对一类型的算子
（1）mapValues 算子
（2）flatMapValues 算子
（3）sortByKey 算子
（4）sortBy 算子
（5）zip 算子
（6）zipPartitions 算子
（7）zipWithIndex 算子
（8）zipWithUniqueId 算子

2.2.2. 对单个 RDD 或两个 RDD 聚集的算子
单个 RDD 聚集
（1）combineByKey 算子
（2）reduceByKey 算子
（3）partitionBy 算子
（4）groupByKey 算子
（5）foldByKey 算子
（6）reduceByKeylocally 算子

两个 RDD 聚集
（7）Cogroup 算子
（8）subtractByKey 算子

2.2.3. 连接类型的算子
（1）join 算子
（2）leftOutJoin 算子
（3）rightOutJoin 算子

2.3.Action 算子
2.3.1. 无输出的算子
（1）foreach 算子
（2）foreachPartition 算子

2.3.2. 输出到 HDFS 的算子
（1）saveAsTextFile 算子
（2）saveAsObjectFile 算子
（3）saveAsHadoopFile 算子
（4）saveAsSequenceFile 算子
（5）saveAsHadoopDataset 算子
（6）saveAsNewAPIHadoopFile 算子
（7）saveAsNewAPIHadoopDataset 算子

2.3.3. 输出 scala 集合和数据类型的算子
（1）first 算子
（2）count 算子
（3）reduce 算子
（4）collect 算子
（5）take 算子
（6）top 算子
（7）takeOrdered 算子
（8）aggregate 算子
（9）fold 算子
（10）lookup 算子
（11）countByKey 算子

作者：18582596683
链接：https://hacpai.com/article/1543743495823
来源：黑客派
协议：CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0/
```





## 转换操作

### value类型

#### map(func)

map是对RDD中的每个元素都执行一个指定的函数来产生一个新的RDD。任何原RDD中的元素在新RDD中都有且只有一个元素与之对应。

 ![](assets/map.png)



```
scala> var source  = sc.parallelize(1 to 10)
source: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[8] at parallelize at <console>:24

scala> source.collect()
res7: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

scala> val mapadd = source.map(_ * 2)
mapadd: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[9] at map at <console>:26

scala> mapadd.collect()
res8: Array[Int] = Array(2, 4, 6, 8, 10, 12, 14, 16, 18, 20)
```

#### flatMap(func)

flatmap()是将函数应用于RDD中的每个元素，将返回的迭代器的所有内容构成新的RDD。这样就得到了一个由各列表中的元素组成的RDD，而不是一个列表组成的RDD。

  ![1566374597957](assets/1566374597957.png)

```
scala> var source  = sc.parallelize(List("a b c", "w x y", "d"))
source: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[3] at parallelize at <console>:21

scala> val rdd1=source.flatMap(_.split(" ")) 
rdd1: org.apache.spark.rdd.RDD[String] = MapPartitionsRDD[4] at flatMap at <console>:23

scala> rdd1.collect()
res2: Array[String] = Array(a, b, c, w, x, y, d)

["a b c", "w x y", "d"] => [["a","b","c"],["w","x","y"],["d"]] => ["a","b","w","x","y","c","d"]

################################################################################################

scala> val rdd2=source.map(_.split(" "))
rdd2: org.apache.spark.rdd.RDD[Array[String]] = MapPartitionsRDD[5] at map at <console>:23

scala> rdd2.collect()
res3: Array[Array[String]] = Array(Array(a, b, c), Array(w, x, y), Array(d))
```

map(func)函数会对每一条输入进行指定的func操作，然后为每一条输入返回一个对象，而flatMap(func)也会对每一条输入进行执行的func操作，然后每一条输入返回一个对象，但是最后会将所有的对象再合成为一个对象；从返回的结果的数量上来讲，map返回的数据对象的个数和原来的输入数据是相同的，而flatMap返回的个数则是不同的。请参考下图进行理解：

![img](assets/spark-map-flatmap.jpg) 

#### mapPartitions(func)

与map类似，map每次对RDD中每一个元素进行运算，而mapPartitions则是把一分区的数据作为一个整体来处理，处理效率更高。假设一个partition有一万条数据，那么map中算子func需要执行一万次；而用mapPartitions算子，一个task处理一个分区执行一次func，func一次接收分区内的所有数据，效率比较高。

但这个分区的数据处理完后，原RDD中分区的数据才能释放，可能导致OOM（内存溢出），一般在内存空间较大时用mapPartitions

在Executor中，map每次处理一条数据，每一条数据用完引用就释放，然后GC。而mapPartitions只有把一个分区的数据全部处理完才会释放引用，然后GC，当内存空间不够大时可能导致内存溢出。

![img](assets/855959-20160731202140622-1302550096.png) 

```
scala> val rdd = sc.parallelize(Array(1,2,3,4))
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.mapPartitions(x=>x.map(_*2))
res0: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[1] at mapPartitions at <console>:24

scala> res0.collect()
res2: Array[Int] = Array(2, 4, 6, 8)                                            
```

#### mapPartitionsWithIndex(func)

类似于mapPartitions，但func带有一个整数参数表示分片的索引值，因此在类型为T的RDD上运行时，func的函数类型必须是(Int, Interator[T]) => Iterator[U]。

```
scala> val rdd = sc.parallelize(Array(1,2,3,4))
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> val indexRdd = rdd.mapPartitionsWithIndex((index,items)=>(items.map((index,_))))
indexRdd: org.apache.spark.rdd.RDD[(Int, Int)] = MapPartitionsRDD[1] at mapPartitionsWithIndex at <console>:23

scala> indexRdd.collect()
res0: Array[(Int, Int)] = Array((0,1), (0,2), (1,3), (1,4))                     
```

#### glom

将每一个分区形成一个数组，形成新的RDD类型是RDD[Array[T]]。

![img](assets/855959-20160731220004841-310104312.png) 

```

scala> val rdd = sc.parallelize(1 to 16,4)   ##4个分区
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.collect()
res0: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) 

scala> rdd.glom().collect()
res1: Array[Array[Int]] = Array(Array(1, 2, 3, 4), Array(5, 6, 7, 8), Array(9, 10, 11, 12), Array(13, 14, 15, 16))
```

#### groupBy(func)

groupBy算子接收一个函数，这个函数返回的值作为key，然后通过这个key来对里面的元素进行分组。 

![img](assets/855959-20160731203150309-1392947847.png) 

```
根据传进来的函数，生成对应的key,在有这个key多数据进行聚合，生成(K, Iterable[T])格式的数据。
scala> val rdd = sc.parallelize(1 to 9, 3)
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> val group = rdd.groupBy(_%2)
group: org.apache.spark.rdd.RDD[(Int, Iterable[Int])] = ShuffledRDD[2] at groupBy at <console>:23

scala> group.collect()
res0: Array[(Int, Iterable[Int])] = Array((0,CompactBuffer(2, 4, 6, 8)), (1,CompactBuffer(1, 3, 5, 7, 9)))

scala> val group1=rdd.groupBy(x => { if (x % 2 == 0) "even" else "odd" })
group1: org.apache.spark.rdd.RDD[(String, Iterable[Int])] = ShuffledRDD[4] at groupBy at <console>:23

scala> group1.collect()
res1: Array[(String, Iterable[Int])] = Array((even,CompactBuffer(2, 4, 6, 8)), (odd,CompactBuffer(1, 3, 5, 7, 9)))
```

#### filter(func)

filter 函数功能是对元素进行过滤，对每个 元 素 应 用 f 函 数， 返 回 值 为 true 的 元 素 在RDD 中保留，返回值为 false 的元素将被过滤掉。 内 部 实 现 相 当 于 生 成 FilteredRDD(this，sc.clean(f))。

![img](assets/855959-20160731224355278-1057893706.png) 

```
scala> var sourceFilter = sc.parallelize(Array("xiaoming","xiaojiang","xiaohe","dazhi"))
sourceFilter: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> sourceFilter.collect()
res0: Array[String] = Array(xiaoming, xiaojiang, xiaohe, dazhi)                 

scala> val filter = sourceFilter.filter(_.contains("xiao"))
filter: org.apache.spark.rdd.RDD[String] = MapPartitionsRDD[1] at filter at <console>:23

scala> filter.collect()
res1: Array[String] = Array(xiaoming, xiaojiang, xiaohe)                        

scala> val filter = sourceFilter.filter(_.contains("jiang"))
filter: org.apache.spark.rdd.RDD[String] = MapPartitionsRDD[2] at filter at <console>:23

scala> filter.collect()
res2: Array[String] = Array(xiaojiang)
```

#### sample(withReplacement, fraction, seed)

以指定的随机种子随机抽样出数量为fraction的数据，withReplacement表示是抽出的数据是否放回，true为有放回的抽样，false为无放回的抽样，seed用于指定随机数生成器种子。

如图每个方框一个RDD 分 区。 通 过sample函数，采样50%的数据。V1、 V2、 U1、 U2、U3、U4 采样出数据 V1 和 U1、 U2 形成新的 RDD。

![img](assets/855959-20160731204116606-30482327.png) 

```
scala> val rdd = sc.parallelize(1 to 16,4)
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.collect()
res0: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)

放回抽样
scala> var sample1 = rdd.sample(true,0.4,2)
sample1: org.apache.spark.rdd.RDD[Int] = PartitionwiseSampledRDD[1] at sample at <console>:23

scala> sample1.collect()
res1: Array[Int] = Array(7, 10, 11, 11, 11, 14)                                 

不放回抽样
scala> var sample2 = rdd.sample(false,0.2,3)
sample2: org.apache.spark.rdd.RDD[Int] = PartitionwiseSampledRDD[2] at sample at <console>:23

scala> sample2.collect()
res2: Array[Int] = Array(2)

scala> rdd.collect()
res3: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
```

#### distinct([numTasks]))

对源RDD进行去重后返回一个新的RDD。默认情况下，只有8个并行任务来操作，但是可以传入一个可选的numTasks参数改变它。

```
scala> val distinctRdd = sc.parallelize(List(5,9,4,7,2,5,5,3,6,4,6,1,1,4,2,85,9,5,2,3,5,6,7,6))
distinctRdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21
对RDD进行去重（不指定并行度）
scala> val unionRDD = distinctRdd.distinct()
unionRDD: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[3] at distinct at <console>:23

scala> unionRDD.collect()
res0: Array[Int] = Array(4, 6, 2, 1, 3, 7, 9, 85, 5)                            
对RDD（指定并行度为4）
scala> val unionRDD1 = distinctRdd.distinct(4)
unionRDD1: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[6] at distinct at <console>:23

scala> unionRDD1.collect()
res1: Array[Int] = Array(4, 1, 9, 85, 5, 6, 2, 3, 7)

scala> val unionRDD2 = distinctRdd.distinct(5)
unionRDD2: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[9] at distinct at <console>:23

scala> unionRDD2.collect()
res2: Array[Int] = Array(85, 5, 1, 6, 7, 2, 3, 4, 9)
```

#### coalesce(numPartitions)

缩减分区数，用于大数据集过滤后，提高小数据集的执行效率。

```
scala> val rdd = sc.parallelize(1 to 16,4)
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.partitions.size
res0: Int = 4

scala> val coalesceRDD = rdd.coalesce(3)
coalesceRDD: org.apache.spark.rdd.RDD[Int] = CoalescedRDD[1] at coalesce at <console>:23

scala> coalesceRDD.partitions.size
res1: Int = 3
```

#### repartition(numPartitions,shuffle)

根据分区数，重新通过网络随机洗牌所有数据。

```
scala> val rdd = sc.parallelize(1 to 16,4)
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.partitions.size
res0: Int = 4

scala> val rerdd = rdd.repartition(2)
rerdd: org.apache.spark.rdd.RDD[Int] = MapPartitionsRDD[4] at repartition at <console>:23

scala> rerdd.partitions.size
res1: Int = 2
```

 总结：

```
区别：
1. coalesce重新分区，可以选择是否进行shuffle过程。由参数shuffle: Boolean = false/true决定。
2. repartition实际上是调用的coalesce，默认是进行shuffle的。
源码如下：
def repartition(numPartitions: Int)(implicit ord: Ordering[T] = null): RDD[T] = withScope {
  coalesce(numPartitions, shuffle = true)
}

################################################################################################

我们常认为coalesce不产生shuffle会比repartition 产生shuffle效率高，而实际情况往往要根据具体问题具体分析，coalesce效率不一定高，有时还有大坑，大家要慎用。

coalesce 与 repartition 他们两个都是RDD的分区进行重新划分，repartition只是coalesce接口中shuffle为true的实现（假设源RDD有N个分区，需要重新划分成M个分区）

1）如果N<M。一般情况下N个分区有数据分布不均匀的状况，利用HashPartitioner函数将数据重新分区为M个，这时需要将shuffle设置为true(repartition实现,coalesce也实现不了)。

2）如果N>M并且N和M相差不多，(假如N是1000，M是100)那么就可以将N个分区中的若干个分区合并成一个新的分区，最终合并为M个分区，这时可以将shuff设置为false（coalesce实现），如果M>N时，coalesce是无效的，不进行shuffle过程，父RDD和子RDD之间是窄依赖关系，无法使文件数(partiton)变多。

总之如果shuffle为false时，如果传入的参数大于现有的分区数目，RDD的分区数不变，也就是说不经过shuffle，是无法将RDD的分区数变多的

3）如果N>M并且两者相差悬殊，这时你要看executor数与要生成的partition关系，如果executor数 <= 要生成partition数，coalesce效率高，反之如果用coalesce会导致(executor数-要生成partiton数)个excutor空跑从而降低效率。如果在M为1的时候，为了使coalesce之前的操作有更好的并行度，可以将shuffle设置为true。
```

#### sortBy(func,[ascending], [numTasks])

使用func先对数据进行处理，按照处理后的数据比较结果排序，默认为正序。

与sortByKey类似，但是更灵活第一个参数是根据什么排序。第二个是怎么排序升序还是降序，false倒序。第三个排序后分区数，默认与原RDD一样。

```
scala> val rdd = sc.parallelize(List(2,1,3,4))
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

按照自身大小排序
scala>  rdd.sortBy(x => x).collect()
res0: Array[Int] = Array(1, 2, 3, 4)                                            

按照对3余数排序
scala> rdd.sortBy(x => x%3).collect()
res1: Array[Int] = Array(3, 1, 4, 2)                                                          

降序
scala> rdd.sortBy(x => x%3,false).collect()
res3: Array[Int] = Array(2, 1, 4, 3)

升序
scala> rdd.sortBy(x => x%3,true).collect()
res4: Array[Int] = Array(3, 1, 4, 2)

设置分区数
scala> rdd.sortBy(x => x%3,false,3).collect()
res6: Array[Int] = Array(2, 1, 4, 3)
```

#### pipe(command, [envVars])

管道，用来调用外部程序。针对每个分区，都执行一个shell脚本，返回输出的RDD。

Shell脚本

```
#!/bin/sh
echo "AA"
while read LINE; 
do
   echo ">>>"${LINE}
done
```

```
创建一个只有一个分区的RDD
scala> val rdd1 = sc.parallelize(List("hi","Hello","how","are","you"),1)
rdd: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[50] at parallelize at <console>:24
将脚本作用该RDD并打印
scala> rdd1.pipe("/opt/pipe.sh").collect()
res18: Array[String] = Array(AA, >>>hi, >>>Hello, >>>how, >>>are, >>>you)
创建一个有两个分区的RDD
scala> val rdd2 = sc.parallelize(List("hi","Hello","how","are","you"),2)
rdd: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[52] at parallelize at <console>:24
将脚本作用该RDD并打印
scala> rdd2.pipe("/opt/pipe.sh").collect()
res19: Array[String] = Array(AA, >>>hi, >>>Hello, AA, >>>how, >>>are, >>>you)
```

### 双Value类型

#### union(otherDataset)

对源RDD和参数RDD求并集后返回一个新的RDD。

```
scala>  val rdd1 = sc.parallelize(1 to 5)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[3] at parallelize at <console>:21

scala> val rdd2 = sc.parallelize(5 to 10)
rdd2: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[4] at parallelize at <console>:21

scala> val rdd3 = rdd1.union(rdd2)
rdd3: org.apache.spark.rdd.RDD[Int] = UnionRDD[5] at union at <console>:25

scala> rdd3.collect()
res2: Array[Int] = Array(1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10)

scala> val rdd4 = sc.parallelize(List(("a",1),("b",2)))
rdd4: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[6] at parallelize at <console>:21

scala> rdd4.collect()
res3: Array[(String, Int)] = Array((a,1), (b,2))

scala> val rdd5 = sc.parallelize(List(("c",3),("d",4),("a",1)))
rdd5: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[7] at parallelize at <console>:21

scala> rdd5.collect()
res4: Array[(String, Int)] = Array((c,3), (d,4), (a,1))

scala> rdd4.union(rdd5).collect()
res6: Array[(String, Int)] = Array((a,1), (b,2), (c,3), (d,4), (a,1))
```

#### subtract (otherDataset)

计算差的一种函数，去除两个RDD中相同的元素，不同的RDD将保留下来。返回的是前rdd元素不在后rdd里面的rdd。

```
scala> val rdd1 = sc.parallelize(3 to 8)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd1.collect()
res0: Array[Int] = Array(3, 4, 5, 6, 7, 8)                                      

scala> val rdd2 = sc.parallelize(1 to 5)
rdd2: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd2.collect()
res1: Array[Int] = Array(1, 2, 3, 4, 5)

scala> rdd1.subtract(rdd2).collect()
res2: Array[Int] = Array(6, 8, 7)                                               

scala> val rdd3 = sc.parallelize(List(("c",3),("c",2),("h",3),("a",1),("b",2)))
rdd3: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[6] at parallelize at <console>:21

scala> rdd3.collect()
res3: Array[(String, Int)] = Array((c,3), (c,2), (h,3), (a,1), (b,2))

scala> val rdd4 = sc.parallelize(List(("c",3),("d",4),("a",1)))
rdd4: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[7] at parallelize at <console>:21

scala> rdd4.collect()
res4: Array[(String, Int)] = Array((c,3), (d,4), (a,1))

scala> rdd3.subtract(rdd4).collect()
res5: Array[(String, Int)] = Array((b,2), (c,2), (h,3))                         
```

#### intersection(otherDataset)

对源RDD和参数RDD求交集后返回一个新的RDD

```
scala> val rdd1 = sc.parallelize(3 to 8)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala>  rdd1.collect()
res0: Array[Int] = Array(3, 4, 5, 6, 7, 8)                                      

scala> val rdd2 = sc.parallelize(1 to 5)
rdd2: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd2.collect()
res1: Array[Int] = Array(1, 2, 3, 4, 5)

scala> rdd1.intersection(rdd2).collect()
res2: Array[Int] = Array(4, 3, 5)

scala> val rdd3 = sc.parallelize(List(("c",3),("c",2),("h",3),("a",1),("b",2)))
rdd3: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[8] at parallelize at <console>:21

scala> rdd3.collect()
res3: Array[(String, Int)] = Array((c,3), (c,2), (h,3), (a,1), (b,2))

scala> val rdd4 = sc.parallelize(List(("c",3),("d",4),("a",1)))
rdd4: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[9] at parallelize at <console>:21

scala> rdd4.collect()
res4: Array[(String, Int)] = Array((c,3), (d,4), (a,1))

scala> rdd3.intersection(rdd4).collect()
res5: Array[(String, Int)] = Array((c,3), (a,1))
```

#### cartesian(otherDataset)   

笛卡尔积（尽量避免使用）

```
scala> val rdd1 = sc.parallelize(3 to 8)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd1.collect()
res0: Array[Int] = Array(3, 4, 5, 6, 7, 8)                                      

scala> val rdd2 = sc.parallelize(1 to 5)
rdd2: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd2.collect()
res1: Array[Int] = Array(1, 2, 3, 4, 5)

scala> rdd1.cartesian(rdd2).collect()
res2: Array[(Int, Int)] = Array((3,1), (3,2), (4,1), (4,2), (5,1), (5,2), (3,3), (3,4), (3,5), (4,3), (4,4), (4,5), (5,3), (5,4), (5,5), (6,1), (6,2), (7,1), (7,2), (8,1), (8,2), (6,3), (6,4), (6,5), (7,3), (7,4), (7,5), (8,3), (8,4), (8,5))

scala> val rdd3 = sc.parallelize(List(("c",3),("c",2),("h",3),("a",1),("b",2)))
rdd3: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[3] at parallelize at <console>:21

scala> rdd3.collect()
res3: Array[(String, Int)] = Array((c,3), (c,2), (h,3), (a,1), (b,2))

scala> val rdd4 = sc.parallelize(List(("c",3),("d",4),("a",1)))
rdd4: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[4] at parallelize at <console>:21

scala> rdd4.collect()
res4: Array[(String, Int)] = Array((c,3), (d,4), (a,1))

scala> rdd3.cartesian(rdd4).collect()
res5: Array[((String, Int), (String, Int))] = Array(((c,3),(c,3)), ((c,2),(c,3)), ((c,3),(d,4)), ((c,3),(a,1)), ((c,2),(d,4)), ((c,2),(a,1)), ((h,3),(c,3)), ((a,1),(c,3)), ((b,2),(c,3)), ((h,3),(d,4)), ((h,3),(a,1)), ((a,1),(d,4)), ((a,1),(a,1)), ((b,2),(d,4)), ((b,2),(a,1)))

scala> :quit
Stopping spark context.
[root@Master bin]# 
```

#### zip(otherDataset)

将两个RDD组合成Key/Value形式的RDD，这里默认两个RDD的partition数量以及元素数量都相同，否则会抛出异常。

```
scala> val rdd1 = sc.parallelize(Array(1,2,3),3)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd1.collect()
res0: Array[Int] = Array(1, 2, 3)

scala> val rdd2 = sc.parallelize(Array("a","b","c"),3)
rdd2: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd2.collect()
res1: Array[String] = Array(a, b, c)                                            

scala> rdd1.zip(rdd2).collect()
res2: Array[(Int, String)] = Array((1,a), (2,b), (3,c))

scala> rdd2.zip(rdd1).collect()
res3: Array[(String, Int)] = Array((a,1), (b,2), (c,3))

scala> val rdd3 = sc.parallelize(Array("a","b","c"),2)
rdd3: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[4] at parallelize at <console>:21

因为分区数量不一样，所以不能zip
scala> rdd1.zip(rdd3).collect
java.lang.IllegalArgumentException: Can't zip RDDs with unequal numbers of partitions
        at org.apache.spark.rdd.ZippedPartitionsBaseRDD.getPartitions(ZippedPartitionsRDD.scala:57)
```

### Key-Value类型

#### partitionBy（partitioner）

如果原有RDD的分区器和现有分区器（partitioner）一致，则不重新分区，如果不一致，则相当于根据分区器生成一个新的ShuffledRDD，即会产生shuffle过程。 partitioner是分区器，例如new HashPartition(2)，同时我们也可以根据需要自定义分区。

![img](assets/00036.jpeg) 

```
scala>  val rdd = sc.parallelize(Array((1,"aaa"),(2,"bbb"),(3,"ccc"),(4,"ddd")),4)
rdd: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.partitions.size
res0: Int = 4

scala> rdd.glom.collect()
res1: Array[Array[(Int, String)]] = Array(Array((1,aaa)), Array((2,bbb)), Array((3,ccc)), Array((4,ddd)))

scala> var rdd1 = rdd.partitionBy(new org.apache.spark.HashPartitioner(2))
rdd1: org.apache.spark.rdd.RDD[(Int, String)] = ShuffledRDD[2] at partitionBy at <console>:23

scala> rdd1.glom.collect()
res2: Array[Array[(Int, String)]] = Array(Array((2,bbb), (4,ddd)), Array((1,aaa), (3,ccc)))

scala> rdd1.partitions.size
res4: Int = 2

scala> :quit
Stopping spark context.
[root@Master ~]# 
```

#### groupByKey([numTasks])

当键值对(K,V)数据集调用此方法，会返回一个键值对(K, Iterable)数据集，其中键值是原来键值组成的、可遍历的集合。我们也可以通过num Tasks参数指定任务执行的次数。

![img](assets/20160514090524_98484.png)

```

scala> val words = Array("one", "two", "two", "three", "three", "three")
words: Array[String] = Array(one, two, two, three, three, three)

scala>  val wordPairsRDD = sc.parallelize(words,3).map(word => (word, 1))
wordPairsRDD: org.apache.spark.rdd.RDD[(String, Int)] = MapPartitionsRDD[1] at map at <console>:23

scala> wordPairsRDD.glom.collect()
res0: Array[Array[(String, Int)]] = Array(Array((one,1), (two,1)), Array((two,1), (three,1)), Array((three,1), (three,1)))

scala> val group = wordPairsRDD.groupByKey()
group: org.apache.spark.rdd.RDD[(String, Iterable[Int])] = ShuffledRDD[3] at groupByKey at <console>:25

scala> group.glom.collect()
res1: Array[Array[(String, Iterable[Int])]] = Array(Array(), Array((two,CompactBuffer(1, 1)), (one,CompactBuffer(1))), Array((three,CompactBuffer(1, 1, 1))))

scala> group.map(t => (t._1, t._2.sum))
res2: org.apache.spark.rdd.RDD[(String, Int)] = MapPartitionsRDD[5] at map at <console>:28

scala> res2.glom.collect()
res3: Array[Array[(String, Int)]] = Array(Array(), Array((two,2), (one,1)), Array((three,3)))

scala> :quit
Stopping spark context.
```

#### reduceByKey(func, [numTasks])

在一个(K,V)的RDD上调用，返回一个(K,V)的RDD，使用指定的reduce函数，将相同key的值聚合到一起。reduce任务的个数可以通过第二个可选的参数来设置。

![img](assets/reduce_by.png) 

```
scala> val rdd = sc.parallelize(List(("female",1),("male",3),("male",3),("female",3),("female",6),("female",7),("male",5),("female",5),("male",2)),3)
rdd: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.glom.collect()
res0: Array[Array[(String, Int)]] = Array(Array((female,1), (male,3), (male,3)), Array((female,3), (female,6), (female,7)), Array((male,5), (female,5), (male,2)))

scala> val reduce = rdd.reduceByKey((x,y) => x-y)
reduce: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[2] at reduceByKey at <console>:23

scala> reduce.glom.collect()
res1: Array[Array[(String, Int)]] = Array(Array(), Array((male,-3)), Array((female,6)))

scala> val reduce1 = rdd.reduceByKey((x,y) => x-y)
reduce1: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[4] at reduceByKey at <console>:23

scala> reduce1.glom.collect()
res2: Array[Array[(String, Int)]] = Array(Array(), Array((male,-3)), Array((female,6)))

scala> val reduce1 = rdd.reduceByKey((x,y) => x+y)
reduce1: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[6] at reduceByKey at <console>:23

scala> reduce1.glom.collect()
res3: Array[Array[(String, Int)]] = Array(Array(), Array((male,13)), Array((female,22)))

scala> val reduce2 = rdd.reduceByKey((x,y) => x*y)
reduce2: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[8] at reduceByKey at <console>:23

scala> reduce2.glom.collect()
res4: Array[Array[(String, Int)]] = Array(Array(), Array((male,90)), Array((female,630)))

scala> :quit
Stopping spark con
```

总结：

```
1.reduceByKey：按照key进行聚合，在shuffle之前有combine（预聚合）操作，返回结果是RDD[k,v].

2.groupByKey：按照key进行分组，直接进行shuffle。

开发指导：reduceByKey比groupByKey，建议使用。但是需要注意是否会影响业务逻辑。
```

#### **aggregateByKey**(zeroValue)(seqOp, combOp, [numTasks]) 

将每个分区里面的元素进行聚合，然后用combine函数将每个分区的结果和初始值(zeroValue)进行combine操作。这个函数最终返回的类型不需要和RDD中元素类型一致。

seqOp操作会聚合各分区中的元素，然后combOp操作把所有分区的聚合结果再次聚合，两个操作的初始值都是zeroValue。 seqOp的操作是遍历分区中的所有元素(T)，第一个T跟zeroValue做操作，结果再作为与第二个T做操作的zeroValue，直到遍历完整个分区。combOp操作是把各分区聚合的结果，再聚合。

参数描述

zeroValue：给每一个分区中的每一个key一个初始值；
seqOp：函数用于在每一个分区中用初始值逐步迭代value；
combOp：函数用于合并每个分区中的结果。

 ![1566404480760](assets/1566404480760.png)

```
scala> val rdd = sc.parallelize(List(("a",3),("a",2),("c",4),("b",3),("c",6),("c",8)),2)
rdd: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.glom.collect()
res0: Array[Array[(String, Int)]] = Array(Array((a,3), (a,2), (c,4)), Array((b,3), (c,6), (c,8)))

scala> val agg = rdd.aggregateByKey(0)(math.max(_,_),_+_)
agg: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[2] at aggregateByKey at <console>:23

scala>  agg.glom.collect()
res1: Array[Array[(String, Int)]] = Array(Array((b,3)), Array((a,3), (c,12)))

scala> val agg1 = rdd.aggregateByKey(10)(math.max(_,_),_+_)
agg1: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[4] at aggregateByKey at <console>:23

scala> agg1.glom.collect()
res2: Array[Array[(String, Int)]] = Array(Array((b,10)), Array((a,10), (c,20)))
```

#### foldByKey(zeroValue)(seqOp)

foldByKey是aggregateByKey的简化操作，只是foldByKey的seqop和combop是相同的。也就是说aggregateByKey在分区内和分区间所做的操作可以是一样的，也可以不一样。而foldByKey分区间和分区内的操作完全相同。

```
scala> val rdd = sc.parallelize(List(("a",3),("d",2),("b",4),("d",3),("b",6),("a",8)),3)
rdd: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.glom.collect()
res0: Array[Array[(String, Int)]] = Array(Array((a,3), (d,2)), Array((b,4), (d,3)), Array((b,6), (a,8)))

scala> val agg = rdd.foldByKey(0)(_+_)
agg: org.apache.spark.rdd.RDD[(String, Int)] = ShuffledRDD[2] at foldByKey at <console>:23

scala> agg.glom.collect()
res1: Array[Array[(String, Int)]] = Array(Array(), Array((d,5), (a,11)), Array((b,10)))

scala> :quit
Stopping spark context.
[root@Master ~]#
```

#### combineByKey[C] 

对相同K，把V合并成一个集合。

    combineByKey[C] (createCombiner: V => C,               ###转换输入结构，比如v=>(v,1)
     
                      mergeValue: (C, V) => C,             ###分区内操作 
    
                      mergeCombiners: (C, C) => C)         ###分区间操作 
                                          
      1.createCombiner: combineByKey() 会遍历分区中的所有元素，因此每个元素的键要么还没有遇到过，要么就和之前的某个元素的键相同。如果这是一个新的元素，combineByKey()会使用一个叫作createCombiner()的函数来创建这个键对应的累加器的初始值。
    
    2.mergeValue: 如果这是一个在处理当前分区之前已经遇到的键，它会使用mergeValue()方法将该键的累加器对应的当前值与这个新的值进行合并。
    
    3.mergeCombiners: 由于每个分区都是独立处理的， 因此对于同一个键可以有多个累加器。如果有两个或者更多的分区都有对应同一个键的累加器， 就需要使用用户提供的 mergeCombiners() 方法将各个分区的结果进行合并。


​    

![1566407863316](assets/1566407863316.png)

```
scala> val input = sc.parallelize(Array(("a", 88), ("b", 95), ("a", 91), ("b", 93), ("a", 95), ("b", 98)),2)
input: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> input.glom.collect()
res0: Array[Array[(String, Int)]] = Array(Array((a,88), (b,95), (a,91)), Array((b,93), (a,95), (b,98)))

scala> val combine = input.combineByKey((_,1),(acc:(Int,Int),v)=>(acc._1+v,acc._2+1),(acc1:(Int,Int),acc2:(Int,Int))=>(acc1._1+acc2._1,acc1._2+acc2._2))
combine: org.apache.spark.rdd.RDD[(String, (Int, Int))] = ShuffledRDD[2] at combineByKey at <console>:23

scala> combine.glom.collect()
res1: Array[Array[(String, (Int, Int))]] = Array(Array((b,(286,3))), Array((a,(274,3))))

scala> val result = combine.map{case (key,value) => (key,value._1/value._2.toDouble)}
result: org.apache.spark.rdd.RDD[(String, Double)] = MapPartitionsRDD[4] at map at <console>:25

scala> result.collect()
res2: Array[(String, Double)] = Array((b,95.33333333333333), (a,91.33333333333333))

scala> :quit
Stopping spark context.
[root@Master ~]# 
```

#### sortByKey([ascending], [numTasks])

在一个(K,V)的RDD上调用，K必须实现Ordered接口，返回一个按照key进行排序的(K,V)的RDD。

```
scala> val rdd = sc.parallelize(Array((3,"aa"),(6,"cc"),(2,"bb"),(1,"dd")))
rdd: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd.sortByKey(true).collect()
res0: Array[(Int, String)] = Array((1,dd), (2,bb), (3,aa), (6,cc))              

scala> rdd.sortByKey(false).collect()
res1: Array[(Int, String)] = Array((6,cc), (3,aa), (2,bb), (1,dd))

scala> val rdd1 = sc.parallelize(Array((3,"aa"),(6,"cc"),(2,"bb"),(1,"dd")),2)
rdd1: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[7] at parallelize at <console>:21

scala> rdd1.glom.collect()
res2: Array[Array[(Int, String)]] = Array(Array((3,aa), (6,cc)), Array((2,bb), (1,dd)))

scala> rdd1.sortByKey(true).glom.collect()
res8: Array[Array[(Int, String)]] = Array(Array((1,dd), (2,bb), (3,aa)), Array((6,cc)))

scala> rdd1.sortByKey(false).glom.collect()
res9: Array[Array[(Int, String)]] = Array(Array((6,cc)), Array((3,aa), (2,bb), (1,dd)))

scala> :quit
Stopping spark context.
[root@Master ~]# 
```

#### mapValues(func)

mapValues顾名思义就是输入函数应用于RDD中Kev-Value的Value，应用之后原RDD中的Key保持不变，与新的Value一起组成新的RDD中的元素。因此，该函数只适用于元素为KV对的RDD。

```
scala>  val rdd1 = sc.parallelize(Array((1,"a"),(1,"d"),(2,"b"),(3,"c")))
rdd1: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd1.glom.collect()
res0: Array[Array[(Int, String)]] = Array(Array((1,a), (1,d)), Array((2,b), (3,c)))

scala> rdd1.mapValues(_+"|||").glom.collect()
res1: Array[Array[(Int, String)]] = Array(Array((1,a|||), (1,d|||)), Array((2,b|||), (3,c|||)))

scala> val rdd2 = sc.parallelize(Array((1,"a"),(1,"d"),(2,"b"),(3,"c")),3)
rdd2: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[4] at parallelize at <console>:21

scala> rdd2.glom.collect()
res2: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((1,d)), Array((2,b), (3,c)))

scala> rdd2.mapValues(_+"|||").collect()
res3: Array[(Int, String)] = Array((1,a|||), (1,d|||), (2,b|||), (3,c|||))

scala> rdd2.mapValues(_+"|||").glom.collect()
res4: Array[Array[(Int, String)]] = Array(Array((1,a|||)), Array((1,d|||)), Array((2,b|||), (3,c|||)))

scala> val rdd3 = sc.parallelize(List("dog", "tiger", "lion", "cat", "panther", " eagle"), 2)
rdd3: org.apache.spark.rdd.RDD[String] = ParallelCollectionRDD[9] at parallelize at <console>:21

scala> rdd3.glom.collect()
res5: Array[Array[String]] = Array(Array(dog, tiger, lion), Array(cat, panther, " eagle"))

scala> val rdd4 = rdd3.map(x => (x.length, x))
rdd4: org.apache.spark.rdd.RDD[(Int, String)] = MapPartitionsRDD[11] at map at <console>:23

scala> rdd4.glom.collect()
res6: Array[Array[(Int, String)]] = Array(Array((3,dog), (5,tiger), (4,lion)), Array((3,cat), (7,panther), (6," eagle")))

scala> rdd4.mapValues("x" + _ + "x").glom.collect()
res7: Array[Array[(Int, String)]] = Array(Array((3,xdogx), (5,xtigerx), (4,xlionx)), Array((3,xcatx), (7,xpantherx), (6,x eaglex)))

scala> :quit
```

#### join(otherDataset, [numTasks])

在类型为(K,V)和(K,W)的RDD上调用，返回一个相同key对应的所有元素对在一起的(K,(V,W))的RDD。该操作是对于相同K的V和W集合进行笛卡尔积 操作，也即V和W的所有组合。

```
scala> val rdd1 = sc.parallelize(Array((1,"a"),(2,"b"),(3,"c")))
rdd1: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> val rdd2 = sc.parallelize(Array((1,4),(2,5),(3,6)))
rdd2: org.apache.spark.rdd.RDD[(Int, Int)] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd1.glom.collect()
res1: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((2,b), (3,c)))

scala> rdd2.glom.collect()
res2: Array[Array[(Int, Int)]] = Array(Array((1,4)), Array((2,5), (3,6)))

scala> rdd1.join(rdd2).glom.collect()
res3: Array[Array[(Int, (String, Int))]] = Array(Array((2,(b,5))), Array((1,(a,4)), (3,(c,6))))

scala> val rdd3 = sc.parallelize(Array((1,"a"),(1,"AAA"),(2,"b"),(3,"c")))
rdd3: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[12] at parallelize at <console>:21

scala>  val rdd4= sc.parallelize(Array((1,5),(1,4),(1,3),(1,2),(1,1),(1,4),(2,5),(3,6)))
rdd4: org.apache.spark.rdd.RDD[(Int, Int)] = ParallelCollectionRDD[13] at parallelize at <console>:21

scala> rdd3.join(rdd4).glom.collect()
res5: Array[Array[(Int, (String, Int))]] = Array(Array((2,(b,5))), Array((1,(a,5)), (1,(a,4)), (1,(a,3)), (1,(a,2)), (1,(a,1)), (1,(a,4)), (1,(AAA,5)), (1,(AAA,4)), (1,(AAA,3)), (1,(AAA,2)), (1,(AAA,1)), (1,(AAA,4)), (3,(c,6))))

scala> rdd3.join(rdd4).collect()
res6: Array[(Int, (String, Int))] = Array((2,(b,5)), (1,(a,5)), (1,(a,4)), (1,(a,3)), (1,(a,2)), (1,(a,1)), (1,(a,4)), (1,(AAA,5)), (1,(AAA,4)), (1,(AAA,3)), (1,(AAA,2)), (1,(AAA,1)), (1,(AAA,4)), (3,(c,6)))                            

scala>  val rdd5 = sc.parallelize(Array((8,"a"),(8,"AAA"),(10,"b"),(10,"c")))
rdd5: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[24] at parallelize at <console>:21

scala> val rdd6= sc.parallelize(Array((1,5),(1,4),(1,3),(2,5),(3,6)))
rdd6: org.apache.spark.rdd.RDD[(Int, Int)] = ParallelCollectionRDD[25] at parallelize at <console>:21

scala> rdd5.join(rdd6).glom.collect()
res7: Array[Array[(Int, (String, Int))]] = Array(Array(), Array())

scala> :quit
Stopping spark context.
```

#### cogroup(otherDataset, [numTasks])

在类型为(K,V)和(K,W)的RDD上调用，返回一个(K,(Iterable<V>,Iterable<W>))类型的RDD。也就是将key相同的数据聚合到一个迭代器里面。

```
scala> val rdd = sc.parallelize(Array((1,"a"),(2,"b"),(3,"c")))
rdd: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> val rdd1 = sc.parallelize(Array((1,4),(2,5),(3,6)))
rdd1: org.apache.spark.rdd.RDD[(Int, Int)] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd.cogroup(rdd1).collect()
res0: Array[(Int, (Iterable[String], Iterable[Int]))] = Array((2,(CompactBuffer(b),CompactBuffer(5))), (1,(CompactBuffer(a),CompactBuffer(4))), (3,(CompactBuffer(c),CompactBuffer(6))))

scala> rdd.cogroup(rdd1).glom.collect()
res1: Array[Array[(Int, (Iterable[String], Iterable[Int]))]] = Array(Array((2,(CompactBuffer(b),CompactBuffer(5)))), Array((1,(CompactBuffer(a),CompactBuffer(4))), (3,(CompactBuffer(c),CompactBuffer(6)))))
```

## 行动操作

#### reduce(func)

通过func函数聚集RDD中的所有元素，先聚合分区内数据，再聚合分区间数据。

```
scala> val rdd1 = sc.makeRDD(1 to 10,2)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at makeRDD at <console>:21

scala> rdd1.collect()
res0: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)                         

scala> rdd1.glom.collect()
res1: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5), Array(6, 7, 8, 9, 10))

scala> rdd1.reduce(_+_)
res2: Int = 55

scala> val rdd2 = sc.makeRDD(Array(("a",1),("a",3),("c",3),("d",5)),3)
rdd2: org.apache.spark.rdd.RDD[(String, Int)] = ParallelCollectionRDD[2] at makeRDD at <console>:21

scala> rdd2.glom.collect()
res4: Array[Array[(String, Int)]] = Array(Array((a,1)), Array((a,3)), Array((c,3), (d,5)))

scala> rdd2.reduce((x,y)=>(x._1+y._1,x._2+y._2))
res5: (String, Int) = (aacd,12)                                                        ^

scala> :quit
Stopping spark context.
[root@Master ~]# 
```

#### collect()

在驱动程序中，以数组的形式返回数据集的所有元素。

```
scala> val rdd = sc.parallelize(1 to 10)

rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:24

scala> rdd.collect()

res0: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
```

#### count()

返回RDD中元素的个数 

```
Array里面的元组不能放字母，只能放数字。

scala> val rdd2 = sc.parallelize(Array((b,"a")))
<console>:21: error: not found: value b
Error occurred in an application involving default arguments.
       val rdd2 = sc.parallelize(Array((b,"a")))
                                        ^

scala> val rdd2 = sc.parallelize(Array((1,"a")))
rdd2: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[0] at parallelize at <console>:21

################################################################################################

scala> val rdd1 = sc.parallelize(1 to 10)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[1] at parallelize at <console>:21

scala> rdd1.count()
res0: Long = 10                                                                 

scala> val rdd2 = sc.parallelize(Array((1,"a"),(3,"f"),(45,"ad"),(3,"ad"),(1,"acc")),3)
rdd2: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[2] at parallelize at <console>:21

scala> rdd2.glom.collect()
res1: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((3,f), (45,ad)), Array((3,ad), (1,acc)))

scala> rdd2.count()
res2: Long = 5

scala> :quit
Stopping spark context.
[root@Master ~]# 
```

#### first()

返回RDD中的第一个元素

```
scala> val rdd1 = sc.parallelize(1 to 10)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd1.glom.collect()
res0: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5), Array(6, 7, 8, 9, 10))    

scala> rdd1.first()
res1: Int = 1

scala>  val rdd2 = sc.parallelize(Array((1,"a"),(3,"f"),(45,"ad"),(3,"ad"),(1,"acc")),3)
rdd2: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[2] at parallelize at <console>:21

scala> rdd2.glom.collect()
res2: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((3,f), (45,ad)), Array((3,ad), (1,acc)))

scala> rdd2.glom.first()
res3: Array[(Int, String)] = Array((1,a))

scala> rdd2.first()
res4: (Int, String) = (1,a)

scala> :quit
Stopping spark context.
[root@Master ~]# 
```

#### take(n)

返回一个由RDD的前n个元素组成的数组

```
scala> val rdd1 = sc.parallelize(1 to 10)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala> rdd1.collect()
res6: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

scala> rdd1.glom.collect()
res0: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5), Array(6, 7, 8, 9, 10))    

scala> rdd1.take(1)
res1: Array[Int] = Array(1)

scala> rdd1.glom.take(1)
res2: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5))

scala> val rdd2 = sc.parallelize(Array((1,"a"),(3,"f"),(45,"ad"),(3,"ad"),(1,"acc")),3)
rdd2: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[3] at parallelize at <console>:21

scala> rdd2.collect()
res7: Array[(Int, String)] = Array((1,a), (3,f), (45,ad), (3,ad), (1,acc))

scala> rdd2.glom.collect()
res3: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((3,f), (45,ad)), Array((3,ad), (1,acc)))

scala> rdd2.take(2)
res4: Array[(Int, String)] = Array((1,a), (3,f))

scala> rdd2.glom.take(2)
res5: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((3,f), (45,ad)))
```

#### takeOrdered(n)

返回该RDD排序后的前n个元素组成的数组

```
scala> val rdd1 = sc.parallelize(1 to 10)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at parallelize at <console>:21

scala>  rdd1.collect()
res0: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

scala> rdd1.glom.collect()
res1: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5), Array(6, 7, 8, 9, 10))

scala> rdd1.takeOrdered(1)
res2: Array[Int] = Array(1)                                                     

##不能对数组排序，取前n个
scala> rdd1.glom.takeOrdered(1)
<console>:24: error: No implicit Ordering defined for Array[Int].
              rdd1.glom.takeOrdered(1)
                                   ^

scala> val rdd2 = sc.parallelize(Array((1,"a"),(3,"f"),(45,"ad"),(3,"ad"),(1,"acc")),3)
rdd2: org.apache.spark.rdd.RDD[(Int, String)] = ParallelCollectionRDD[3] at parallelize at <console>:21

scala> rdd2.collect()
res4: Array[(Int, String)] = Array((1,a), (3,f), (45,ad), (3,ad), (1,acc))

scala> rdd2.glom.collect()
res5: Array[Array[(Int, String)]] = Array(Array((1,a)), Array((3,f), (45,ad)), Array((3,ad), (1,acc)))

##以元组的key进行排序，取前n个
scala> rdd2.takeOrdered(2)
res6: Array[(Int, String)] = Array((1,a), (1,acc))

scala> rdd2.takeOrdered(4)
res7: Array[(Int, String)] = Array((1,a), (1,acc), (3,ad), (3,f))

scala> rdd2.glom.takeOrdered(2)
<console>:24: error: No implicit Ordering defined for Array[(Int, String)].
              rdd2.glom.takeOrdered(2)
                                   ^
```

#### aggregate

aggregate函数将每个分区里面的元素通过seqOp和初始值进行聚合，然后用combine函数将每个分区的结果和初始值(zeroValue)进行combine操作。这个函数最终返回的类型不需要和RDD中元素类型一致。

```
aggregate(zeroValue: U)(seqOp: (U, T) ⇒ U, combOp: (U, U) ⇒ U)
seqOp: (U, T) ⇒ U：作用于分区内
combOp: (U, U) ⇒ U：作用于分区间


scala> var rdd1 = sc.makeRDD(1 to 10,2)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at makeRDD at <console>:21

scala> rdd1.glom.collect()
res0: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5), Array(6, 7, 8, 9, 10))

分区内：15 40
分区间：55
scala> rdd1.aggregate(0)(_+_,_+_)
res5: Int = 55

分区内：15 40
分区间：zeroValue-15-40=0-15-40=-55
scala> rdd1.aggregate(0)(_+_,_-_)
res2: Int = -55                                                                 


scala> rdd1.aggregate(5)(_+_,_+_)
res6: Int = 70

分区内：20 45  
分区间：zeroValue-15-40=5-20-45=-60
scala> rdd1.aggregate(5)(_+_,_-_)
res8: Int = -60

scala> rdd1.aggregate(10)(_+_,_+_)
res7: Int = 85

scala> rdd1.aggregate(10)(_+_,_-_)
res9: Int = -65
```

#### fold(num)(func)

折叠操作，aggregate的简化操作，seqop和combop一样。

```
scala> var rdd1 = sc.makeRDD(1 to 10,2)
rdd1: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[0] at makeRDD at <console>:21

scala> rdd1.glom.collect()
res0: Array[Array[Int]] = Array(Array(1, 2, 3, 4, 5), Array(6, 7, 8, 9, 10))

scala>  rdd1.fold(0)(_+_)
res1: Int = 55                                                                  

scala>  rdd1.fold(5)(_+_)
res2: Int = 70

scala>  rdd1.fold(10)(_+_)
res3: Int = 85
```

#### saveAsTextFile(path)

将数据集的元素以textfile的形式保存到HDFS文件系统或者其他支持的文件系统，对于每个元素，Spark将会调用toString方法，将它装换为文件中的文本。

#### saveAsSequenceFile(path) 

将数据集中的元素以Hadoop sequencefile的格式保存到指定的目录下，可以使HDFS或者其他Hadoop支持的文件系统。

#### saveAsObjectFile(path)

用于将RDD中的元素序列化成对象，存储到文件中。

#### countByKey()

针对(K,V)类型的RDD，返回一个(K,Int)的map，表示每一个key对应的元素个数。

```
scala> val rdd = sc.parallelize(List((1,3),(1,2),(1,4),(2,3),(3,6),(3,8)),3)
rdd: org.apache.spark.rdd.RDD[(Int, Int)] = ParallelCollectionRDD[95] at parallelize at <console>:24

scala> rdd.countByKey()
res63: scala.collection.Map[Int,Long] = Map(3 -> 2, 1 -> 3, 2 -> 1)
```

#### foreach(func)

在数据集的每一个元素上，运行函数func进行更新。

```
scala> var rdd = sc.makeRDD(1 to 5,2)
rdd: org.apache.spark.rdd.RDD[Int] = ParallelCollectionRDD[107] at makeRDD at <console>:24

对该RDD每个元素进行打印
scala> rdd.foreach(println(_))
3
4
5
1
2
```

# 自定义排序

1.使用一个自定义一个普通的类继承Ordered[User] with Serializable

```
package com.lx

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}
object CustomSort1 {

  //排序规则：首先按照颜值的降序，如果颜值相等，再按照年龄的升序
  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName("CustomerSort1").setMaster("local[2]")
    val sc = new SparkContext(conf)
    //定义一个数组类型的值
    val user = Array("laoduan 30 99", "laozhao 29 9999", "laozhang 28 98", "laoyang 28 99")
    //转换成RDD的类型
    val lines = sc.parallelize(user)
    //将整个字符串切分为元组的形式
    val sorted: RDD[User] = lines.map(x => {
      val line = x.split(" ")
      val name = line(0)
      val age = line(1).toInt
      val face = line(2).toInt
      new User(name, age, face)
    })
    //实现自定义排序需要调用sortBy才可以自动调用自定义排序
    val r = sorted.sortBy(u=>u)
    println(r.collect().toBuffer)  //重写了toString方法，可以直接打印。

  }
  class User(val name:String,val age:Int,val face:Int)extends Ordered[User] with Serializable{
    override def compare(that: User): Int = {
      if (this.face == that.face){
        this.age-that.age
      }else{
        - (this.face-that.face)
      }
    }
    override def toString: String = s"name :$name,age: $age,face:$face"
  }
}

################################################################################################

ArrayBuffer(name :laozhao,age: 29,face:9999, name :laoyang,age: 28,face:99, name :laoduan,age: 30,face:99, name :laozhang,age: 28,face:98)
```

2.和上面的差不多只是new 的位置是不太一样的

```
package com.lx

import org.apache.spark.{SparkConf, SparkContext}

object CustomSort2 {
  //排序规则：首先按照颜值的降序，如果颜值相等，再按照年龄的升序
  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName("CustomSort2").setMaster("local[2]")
    val sc = new SparkContext(conf)
    val user = Array("laoduan 30 99", "laozhao 29 9999", "laozhang 28 98", "laoyang 28 99")
    val lines = sc.parallelize(user)
    val tpRdd=lines.map(x=>{
      val line = x.split(" ")
      val name = line(0)
      val age = line(1).toInt
      val face = line(2).toInt
      (name, age, face)
    })
    val sorted = tpRdd.sortBy(x=>new User1(x._2,x._3))
    sorted.foreach(println)
  }
  //这里定义的参数必须添加类型,传的参数只是自己需要比较的参数，没有重写toString()方法
  class User1(val age:Int,val face:Int)extends Ordered[User1] with Serializable {
    override def compare(that: User1): Int = {
      if (this.face == that.face){
        this.age-that.age
      }else{
        - (this.face-that.face)
      }
    }
  }
}

################################################################################################
(laozhao,29,9999)
(laoduan,30,99)
(laoyang,28,99)
(laozhang,28,98)

```

3.使用了样例类的方式此时可以不用实现序列化

    package com.lx
    
    import org.apache.spark.{SparkConf, SparkContext}
    
    object CustomSort3 {
      //排序规则：首先按照颜值的降序，如果颜值相等，再按照年龄的升序
      def main(args: Array[String]): Unit = {
    
        val conf = new SparkConf().setAppName("CustomSort3").setMaster("local[2]")
        val sc = new SparkContext(conf)
        val user = Array("laoduan 30 99", "laozhao 29 9999", "laozhang 28 98", "laoyang 28 99")
        val lines = sc.parallelize(user)
        val tpRdd=lines.map(x=>{
          val line = x.split(" ")
          val name = line(0)
          val age = line(1).toInt
          val face = line(2).toInt
          (name, age, face)
        })
        val sorted = tpRdd.sortBy(x=> Man(x._2,x._3))
         sorted.foreach(println)
        // sc.stop()
        //不能使用foreach
        println(sorted.collect().toBuffer)
      }
      //这里定义的参数必须添加类型,传的参数只是自己需要比较的参数，没有重写toString()方法
      case class Man(age:Int,face:Int) extends Ordered[Man]  {
        override def compare(that: Man): Int = {
          if (this.face == that.face){
            this.age-that.age
          }else{
            - (this.face-that.face)
          }
        }
      }
    
    }
    
    ################################################################################################
    
    (laoduan,30,99)
    (laozhang,28,98)
    (laozhao,29,9999)
    (laoyang,28,99)
    
    ArrayBuffer((laozhao,29,9999), (laoyang,28,99), (laoduan,30,99), (laozhang,28,98))
4.利用隐式转换的方式

```
package com.lx

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}
/**
  * 利用隐式转换时，类可以不实现Ordered的特质，普通的类或者普通的样例类即可。
    隐式转换支持，隐式方法，  隐式函数，  隐式的object  和隐式的变量，
    如果都同时存在，优先使用隐式的object，隐式方法和隐式函数中，会优先使用隐式函数。
    隐式转换可以写在任意地方（当前对象中，外部的类中，外部的对象中），如果写在外部，需要导入到当前的对象中即可。
  */
object CustomSort4 {
  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName("CustomSort4").setMaster("local[*]")
    val sc = new SparkContext(conf)
    //排序规则:首先按照颜值的降序,如果颜值相等,再按照年龄的升序
    val users= Array("laoduan 30 99", "laozhao 29 9999", "laozhang 28 98", "laoyang 28 99")
    //将Driver端的数据并行化变成RDD
    val lines: RDD[String] = sc.parallelize(users)
    //切分整理数据
    val tpRDD: RDD[(String, Int, Int)] = lines.map(line => {
      val fields = line.split(" ")
      val name = fields(0)
      val age = fields(1).toInt
      val fv = fields(2).toInt
      (name, age, fv)
    })
    
    //隐式的object方式
    implicit object OrderingXiaoRou extends Ordering[XianRou]{
      override def compare(x: XianRou, y: XianRou): Int = {
        if(x.fv == y.fv) {
          x.age - y.age
        } else {
          y.fv - x.fv
        }
      }
    }

    // 如果类没有继承 Ordered 特质
    // 可以利用隐式转换  隐式方法  隐式函数  隐式值  隐式object都可以  implicit ord: Ordering[K]
    implicit def ordMethod(p: XianRou): Ordered[XianRou] = new Ordered[XianRou] {
      override def compare(that: XianRou): Int = {
        if (p.fv == that.fv) {
          -(p.age - that.age)
        } else {
          that.fv - p.fv
        }
      }
    }

    //利用隐式的函数方式
    implicit val ordFunc = (p: XianRou) => new Ordered[XianRou] {
      override def compare(that: XianRou): Int = {
        if (p.fv == that.fv) {
          -(p.age - that.age)
        } else {
          that.fv - p.fv
        }
      }
    }

    //排序(传入了一个排序规则,不会改变数据的格式,只会改变顺序)
    val sorted: RDD[(String, Int, Int)] = tpRDD.sortBy(tp => XianRou(tp._2, tp._3))
    println(sorted.collect().toBuffer)
    sc.stop()
  }
}
case class XianRou(age: Int, fv: Int)

```

5.利用Ordering的on方法

无需借助任何的类或者对象，只需要利用Ordering特质的on方法即可。

    package com.lx
    
    import org.apache.spark.rdd.RDD
    import org.apache.spark.{SparkConf, SparkContext}
    object CustomSort5 {
      def main(args: Array[String]): Unit = {
        val conf = new SparkConf()
          .setMaster("local")
          .setAppName(this.getClass.getSimpleName)
        val sc = new SparkContext(conf)
    
        val users= Array("laoduan 30 99", "laozhao 29 9999", "laozhang 28 98", "laoyang 28 99")
        //将Driver端的数据并行化变成RDD
        val lines: RDD[String] = sc.parallelize(users)
        // 获得的数据类型是 元组
        val prdd = lines.map(t => {
          val strings = t.split(" ")
          val name = strings(0)
          val age = strings(1).toInt
          val fv = strings(2).toInt
          (name, age, fv)
        })
        implicit  val obj = Ordering[(Int,Int)].on[(String,Int,Int)](t=>(-t._3,t._2))
    
        val sortedrd: RDD[(String, Int, Int)] = prdd.sortBy(t => t)
        sortedrd.foreach(println)
      }
    }


​    
6.利用元组封装排序条件 

```
package com.lx

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}
object CustomSort6 {
  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName("CustomSort5").setMaster("local[*]")
    val sc = new SparkContext(conf)
    //排序规则:首先按照颜值的降序,如果颜值相等,再按照年龄的升序
    val users= Array("laoduan 30 99", "laozhao 29 9999", "laozhang 28 98", "laoyang 28 99")
    //将Driver端的数据并行化变成RDD
    val lines: RDD[String] = sc.parallelize(users)
    //切分整理数据
    val tpRDD: RDD[(String, Int, Int)] = lines.map(line => {
      val fields = line.split(" ")
      val name = fields(0)
      val age = fields(1).toInt
      val fv = fields(2).toInt
      (name, age, fv)})
    //充分利用元组的比较规则,元组的比较规则:先比第一,相等再比第二个
    val sorted: RDD[(String, Int, Int)] = tpRDD.sortBy(tp => (-tp._3, tp._2))
    println(sorted.collect().toBuffer)
    sc.stop()
  }
}


```

# 二次排序(Java)

二次排序就是首先按照第一字段排序，然后再对第一字段相同的行按照第二字段排序，注意不能破坏第一次排序的结果。

测试数据

![1566543245168](assets/1566543245168.png)

输出结果

![1566543283414](assets/1566543283414.png)

实现思路：

```
1.实现自定义的key，要实现Ordered接口和Serializable接口，在key中实现自己对多个列的排序算法 
2.将包含文本的RDD，映射成key为自定义key，value为文本的JavaPariRDD 
3.使用sortByKey算子按照自定义的key进行排序 
4.再次映射，剔除自定义的key，而只保留文本行
```

自定义key

    package com.lx;
    
    import java.io.Serializable;
    
    import scala.math.Ordered;
    
    /**
     * 自定义的二次排序key
     * @author Administrator
     *
     */
    public class SecondarySortKey_12 implements Ordered<SecondarySortKey_12>,Serializable{
    
        private static final long serialVersionUID = 1L;
    
        //首先在自定义的key里面，定义需要进行排序的列
        private int first;
        private int second;
    
        public SecondarySortKey_12(int first, int second) {
            this.first = first;
            this.second = second;
        }
    
        @Override
        public boolean $greater(SecondarySortKey_12 other) {
            if(this.first > other.getFirst()){
                return true;
            }
            else if (this.first == other.getFirst() && this.second>other.getSecond()){
                return true;
            }
            return false;
        }
    
        @Override
        public boolean $greater$eq(SecondarySortKey_12 other) {
            if(this.$greater(other)){
                return true;
            }
            else if (this.first == other.getFirst() && this.second == other.getSecond()){
                return true;
            }
            return false;
        }
    
        @Override
        public boolean $less(SecondarySortKey_12 other) {
            if(this.first<other.getFirst()){
                return true;
            }
            else if (this.first == other.getFirst() && this.second<other.getSecond()){
                return true;
            }
            return false;
        }
    
        @Override
        public boolean $less$eq(SecondarySortKey_12 other) {
            if(this.$less(other)){
                return true;
            }
            else if(this.first == other.getFirst() && this.second == other.getSecond()) {
                return true;
            }
            return false;
        }
    
        @Override
        public int compare(SecondarySortKey_12 other) {
            if (this.first - other.getFirst() != 0){
                return this.first - other.getFirst();
            }
            else {
                return this.second - other.getSecond();
            }
        }
    
        @Override
        public int compareTo(SecondarySortKey_12 other) {
            if (this.first - other.getFirst() != 0){
                return this.first - other.getFirst();
            }
            else {
                return this.second - other.getSecond();
            }
        }

        //为要进行排序的多个列，提供getter和setter方法，以及hascode 和equals方法
        public int getFirst() {
            return first;
        }
    
        public void setFirst(int first) {
            this.first = first;
        }
    
        public int getSecond() {
            return second;
        }
    
        public void setSecond(int second) {
            this.second = second;
        }
    
        @Override
        public int hashCode() {
            final int prime = 31;
            int result = 1;
            result = prime * result + first;
            result = prime * result + second;
            return result;
        }
    
        @Override
        public boolean equals(Object obj) {
            if (this == obj)
                return true;
            if (obj == null)
                return false;
            if (getClass() != obj.getClass())
                return false;
            SecondarySortKey_12 other = (SecondarySortKey_12) obj;
            if (first != other.first)
                return false;
            if (second != other.second)
                return false;
            return true;
        }
    }

SecondarySort_12类

    package com.lx;
    import org.apache.spark.SparkConf;
    import org.apache.spark.api.java.JavaPairRDD;
    import org.apache.spark.api.java.JavaRDD;
    import org.apache.spark.api.java.JavaSparkContext;
    import org.apache.spark.api.java.function.Function;
    import org.apache.spark.api.java.function.PairFunction;
    import org.apache.spark.api.java.function.VoidFunction;
    
    import scala.Tuple2;
    
    public class SecondarySort_12 {
        public static void main(String[] args) {
            SparkConf conf = new SparkConf().setAppName("SecondarySort").setMaster("local");
    
            JavaSparkContext sc = new JavaSparkContext(conf);
    
            JavaRDD<String> lines = sc.textFile("E:\\Iproject\\scalademo\\src\\test\\java\\data.txt");
    
            JavaPairRDD<SecondarySortKey_12, String> pairs = lines.mapToPair(
                    new PairFunction<String, SecondarySortKey_12, String>() {
    
                        private static final long serialVersionUID = 1L;
    
                        @Override
                        public Tuple2<SecondarySortKey_12, String> call(String line) throws Exception {
                            String[] lineSplited = line.split(" ");
                            SecondarySortKey_12 key = new SecondarySortKey_12(
                                    Integer.valueOf(lineSplited[0]),
                                    Integer.valueOf(lineSplited[1]));
    
                            return new Tuple2<SecondarySortKey_12, String>(key, line);
                        }
                    });
    
            JavaPairRDD<SecondarySortKey_12, String> sortedPairs = pairs.sortByKey();
    
            JavaRDD<String> sortedLines = sortedPairs.map(
                    new Function<Tuple2<SecondarySortKey_12,String>, String>() {
    
                        private static final long serialVersionUID = 1L;
    
                        @Override
                        public String call(Tuple2<SecondarySortKey_12, String> v) throws Exception {
                            return v._2;
                        }
                    });
    
            sortedLines.foreach(new VoidFunction<String>() {
    
                private static final long serialVersionUID = 1L;
    
                @Override
                public void call(String t) throws Exception {
                    System.out.println(t);
                }
            });
    
            sc.close();
    
        }
    }

# 自定义分区

我们都知道Spark内部提供了HashPartitioner和RangePartitioner两种分区策略，这两种分区策略在很多情况下都适合我们的场景。但是有些情况下，Spark内部不能符合咱们的需求，这时候我们就可以自定义分区策略。为此，Spark提供了相应的接口，我们只需要扩展Partitioner抽象类，然后实现里面的三个方法：

![1566544975538](assets/1566544975538.png)

```
def numPartitions: Int：这个方法需要返回你想要创建分区的个数；

def getPartition(key: Any): Int：这个函数需要对输入的key做计算，然后返回该key的分区ID，范围一定是0到numPartitions-1；

equals()：这个是Java标准的判断相等的函数，之所以要求用户实现这个函数是因为Spark内部会比较两个RDD的分区是否一样。
```

测试数据：

```
20170721101954	http://sport.sina.cn/sport/race/nba.shtml
20170721101954	http://sport.sina.cn/sport/watch.shtml
20170721101954	http://car.sina.cn/car/fps.shtml
20170721101954	http://sport.sina.cn/sport/watch.shtml
```

代码如下：

    package com.lx
    import java.net.URL
    import org.apache.spark.{Partitioner, SparkConf, SparkContext}
    import scala.collection.mutable
    /**
      * 功能: 演示 程序代码中的自定义分区
      *
      */
    class NewPartiton(fornum:Array[String]) extends Partitioner{
      val partmap=new mutable.HashMap[String,Int]()
      var count= 0  // 表示分区号
    
      // 对for循环的目的是使 每个host 作为一个分区
      for( i <- fornum){
        partmap += (i->count)
        count += 1
      }
    
      // 为了保证每一个域名有一个分区,就用fornum.length的形式  源码用到
      override def numPartitions: Int = fornum.length
    
      //获得每个key的分区号  源码用到
      override def getPartition(key: Any): Int = {
        partmap.getOrElse(key.toString,0)
      }
      
      //equals()：这个是Java标准的判断相等的函数，之所以要求用户实现这个函数是因为Spark内
      //部会比较两个RDD的分区是否一样。
      override def equals(other: Any): Boolean = other match {
        case mypartition: MySparkPartition =>
          mypartition.numPartitions == numPartitions
        case _ =>
          false
      }
    }
    
    object Partition{
      def main(args: Array[String]): Unit = {
        val conf=new SparkConf().setAppName("UrlCount").setMaster("local[2]")
        val sc=new SparkContext(conf)
        val lines=sc.textFile("E:\\Iproject\\scalademo\\src\\test\\java\\URL.txt")
        // 20170721101954	http://sport.sina.cn/sport/race/nba.shtml
        val text=lines.map(line=>{
          val f=line.split("\t")
          (f(1),1)  //最后一行作为返回值的  先给每个域名  后面增加1
        })
        val text1=text.reduceByKey(_+_) //统计每个域名的个数
        //    println(text1.collect.toBuffer)
        // http://sport.sina.cn/sport/race/nba.shtml   1
        val text2=text1.map(t=>{
          val url=t._1  //每个url
          val host=new URL(url).getHost()
          (host,(url,t._2))  //返回每个host
        })
    
        val fornum=text2.map(_._1).distinct().collect()
        //    println(fornum)
        val np=new NewPartiton(fornum)
        //后面的partitionBy也是一个固定写法
        text2.partitionBy(np).saveAsTextFile("E:\\Iproject\\scalademo\\src\\test\\java\\output2")
    
        sc.stop()  //关闭
      }
    
    }

# Spark SQL







# Scala编程

## 配置scala

1.打开IDEA工具，如图：点击Configure->pulgins 

 ![1566448294802](assets/1566448294802.png)

 ![1566449722517](assets/1566449722517.png)

2.点击Install plugin from disk

 ![1566449803917](assets/1566449803917.png)

 ![1566449862106](assets/1566449862106.png)

3.重启idea

 ![1566449924248](assets/1566449924248.png)

## idea开发scala项目

1.创建maven项目

 ![1566443971867](assets/1566443971867.png)

 ![1566444027161](assets/1566444027161.png)

  ![1566444052812](assets/1566444052812.png)

2.项目添加scala的framework

创建的maven项目默认是不支持scala的，需要为项目添加scala的framework，如图：

 ![1566444137166](assets/1566444137166.png)

在这里选择Scala后，在右边的Use library中配置你的安装目录即可，最后点击OK。

 ![1566444163006](assets/1566444163006.png)

说明： 第一次引入scala framework时，需要去配置一下，就是选择一下scala的安装目录，这时，会导入 scala 的sdk，以后再创建时，就不用再配置了。

3.在项目的目录结构中，创建scala文件夹，并标记为source。

 ![1566444250172](assets/1566444250172.png)

输入：文件夹的名字 scala

 ![1566444291146](assets/1566444291146.png)

4.以上配置都完成后，就可以在scala上点击右键创建scala class了。

 ![1566444324522](assets/1566444324522.png)

在弹出的窗口输入内容: [注意: 如果直接输入Hello, 则不会创建包]

 ![1566444356553](assets/1566444356553.png)

对的项目目录：

 ![1566444404790](assets/1566444404790.png)

5.编写代码如下

 ![1566444432760](assets/1566444432760.png)

6.右键 run Hello 运行结果

 ![1566444457063](assets/1566444457063.png)

说明：scala 编译时间比java要长(因为步骤较多)，并且运行时间也略大于java。

7.配置pom.xml


​    
       <properties>
            <maven.compiler.source>1.8</maven.compiler.source>
            <maven.compiler.target>1.8</maven.compiler.target>
            <scala.version>2.11.8</scala.version>
            <spark.version>2.2.0</spark.version>
            <hadoop.version>2.7.3</hadoop.version>
            <encoding>UTF-8</encoding>
        </properties>
    
        <dependencies>
            <!-- 导入scala的依赖 -->
            <dependency>
                <groupId>org.scala-lang</groupId>
                <artifactId>scala-library</artifactId>
                <version>${scala.version}</version>
            </dependency>
    
            <!-- 导入spark的依赖 -->
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-core_2.11</artifactId>
                <version>${spark.version}</version>
            </dependency>
    
            <!--spark sql依赖-->
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-sql_2.11</artifactId>
                <version>${spark.version}</version>
            </dependency>
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-streaming_2.11</artifactId>
                <version>${spark.version}</version>
            </dependency>
    
            <!-- 指定hadoop-client API的版本 -->
            <dependency>
                <groupId>org.apache.hadoop</groupId>
                <artifactId>hadoop-client</artifactId>
                <version>${hadoop.version}</version>
            </dependency>
    
            <!-- https://mvnrepository.com/artifact/mysql/mysql-connector-java -->
            <dependency>
                <groupId>mysql</groupId>
                <artifactId>mysql-connector-java</artifactId>
                <version>6.0.6</version>
            </dependency>
    
            <!-- https://mvnrepository.com/artifact/org.apache.kafka/kafka -->
            <dependency>
                <groupId>org.apache.kafka</groupId>
                <artifactId>kafka_2.11</artifactId>
                <version>0.8.2.1</version>
            </dependency>
            <!--spark streaming 和 -->
            <dependency>
                <groupId>org.apache.spark</groupId>
                <artifactId>spark-streaming-kafka-0-8_2.11</artifactId>
                <version>${spark.version}</version>
            </dependency>
    
            <dependency>
                <groupId>redis.clients</groupId>
                <artifactId>jedis</artifactId>
                <version>2.9.0</version>
            </dependency>
        </dependencies>
    
        <build>
            <pluginManagement>
                <plugins>
                    <!-- 编译scala的插件 -->
                    <plugin>
                        <groupId>net.alchim31.maven</groupId>
                        <artifactId>scala-maven-plugin</artifactId>
                        <version>3.2.2</version>
                    </plugin>
                    <!-- 编译java的插件 -->
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-compiler-plugin</artifactId>
                        <version>3.5.1</version>
                    </plugin>
                </plugins>
            </pluginManagement>
            <plugins>
                <plugin>
                    <groupId>net.alchim31.maven</groupId>
                    <artifactId>scala-maven-plugin</artifactId>
                    <executions>
                        <execution>
                            <id>scala-compile-first</id>
                            <phase>process-resources</phase>
                            <goals>
                                <goal>add-source</goal>
                                <goal>compile</goal>
                            </goals>
                        </execution>
                        <execution>
                            <id>scala-test-compile</id>
                            <phase>process-test-resources</phase>
                            <goals>
                                <goal>testCompile</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
    
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <executions>
                        <execution>
                            <phase>compile</phase>
                            <goals>
                                <goal>compile</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
                <!-- 打jar插件 -->
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-shade-plugin</artifactId>
                    <version>2.4.3</version>
                    <executions>
                        <execution>
                            <phase>package</phase>
                            <goals>
                                <goal>shade</goal>
                            </goals>
                            <configuration>
                                <filters>
                                    <filter>
                                        <artifact>*:*</artifact>
                                        <excludes>
                                            <exclude>META-INF/*.SF</exclude>
                                            <exclude>META-INF/*.DSA</exclude>
                                            <exclude>META-INF/*.RSA</exclude>
                                        </excludes>
                                    </filter>
                                </filters>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
8.报错

```
java.io.IOException: Could not locate executable null\bin\winutils.exe in the Hadoop binaries.

解决：
windows下运行hadoop的程序报错java.io.IOException: Could not locate executable null\bin\winutils.exe in the Hadoop binaries.

这是因为windows环境变量不兼容的原因.

解决办法：

下载winutils地址https://github.com/srccodes/hadoop-common-2.2.0-bin下载解压

配置环境变量
增加用户变量HADOOP_HOME，值是下载的zip包解压的目录，然后在系统变量path里增加%HADOOP_HOME%\bin 即可。　

然后重启IDEA。
```

## 数据类型

![1566451654964](assets/1566451654964.png)

scala继承关系图：

 ![img](assets/scala-extends.png) 

## 变量

Scala有两种变量，val和var。val类似于Java里的final变量，一旦初始化了，val就不能再被赋值。相反，var如同Java里面的非final变量，可以在它的生命周期中被多次赋值。

变量声明基本语法

```
var | val 变量名 [: 变量类型] = 变量值
```

```
  def main(args: Array[String]): Unit = {
    //使用val定义的变量值是不可变的，相当于java里用final修饰的变量
    val i = 1
    //使用var定义的变量是可变得，在Scala中鼓励使用val
    var s = "hello"
    //Scala编译器会自动推断变量的类型，必要的时候可以指定类型
    //变量名在前，类型在后
    val str: String = "hello scala"
  }
```

## 条件表达式

    def main(args: Array[String]) {
        val x = 1
        //判断x的值，将结果赋给y
        val y = if (x > 0) 1 else -1
        //打印y的值
        println(y)
    
        //支持混合类型表达式
        val z = if (x > 1) 1 else "error"
        //打印z的值
        println(z)
    
        //如果缺失else，相当于if (x > 2) 1 else ()
        val m = if (x > 2) 1
        println(m)
    
        //在scala中，每个表达式都应该有某种值，因此scala引入一个Unit类，写做()，相当于Java中的void。
        val n = if (x > 2) 1 else ()
        println(n)
    
        //if和else if
        val k = if (x < 0)  0
        else if (x >= 1) 1 else -1
        println(k) 
      }


​    
## 块表达式

      def main(args: Array[String]): Unit = {
        val x = 0
        //在scala中，{}中块包含一系列表达式，其结果也是一个表达式。块中最后一个表达式的值就是块的值
        val result = {
          if (x < 0){
            -1
          } else if(x >= 1) {
            1
          } else {
            "error"
          }
        }
        //result的值就是块表达式的结果
        println(result)
    
        val sum={
          var a:Int=4
          var b:Int=5
          a+b  //将最后一个表达式的值，返回回去
        }
    
        println(sum)
    
      }

##  循环

      def main(args: Array[String]): Unit = {
    
        var  n:Int=5
        while (n>0){
          print(n+" ")
          n-=1
        }
        println()
    
        //for(i <- 表达式),表达式1 to 10返回一个Range（区间）
        //每次循环将区间中的一个值赋给i
        for (i <- 1 to 10)
          println(i)
    
        //for(i <- 数组)
        val arr = Array("a", "b", "c")
        for (i <- arr)
          println(i)
    
        //我们可以以变量<-表达式的形式提供多个生成器，用分号将它们隔开。
        for(i <- 1 to 3; j <- 1 to 3)
          print((10 * i + j) + " ")
        println()
    
        //每个生成器都可以带一个条件(守卫)，注意：if前面没有分号
        for(i <- 1 to 3; j <- 1 to 3 if i != j)
          print((10 * i + j) + " ")
        println()
    
        //for推导式：如果for循环的循环体以yield开始，则该循环会构建出一个集合。
        //每次迭代生成集合中的一个值，最后结果为Vector(10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
        val v = for (i <- 1 to 10) yield i * 10
        println(v)
    
      }

## 方法和函数

Scala中的+ - * / %等操作符的作用与Java一样，位操作符 & | ^ >> <<也一样。只是有一点特别的：这些操作符实际上是方法。a 方法 b 可以写成 a.方法(b)

例如：

```
a + b
```

是如下方法调用的简写：

```
a.+(b)
```

### 定义方法

 ![1566455948534](assets/1566455948534.png)

方法的返回值类型可以不写，编译器可以自动推断出来，但是对于递归函数，必须指定返回类型。

### 定义函数

  ![1566456076809](assets/1566456076809.png)

### 方法和函数的区别

在函数式编程语言中，函数是“头等公民”，它可以像任何其他数据类型一样被传递和操作。案例：首先定义一个方法，再定义一个函数，然后将函数传递到方法里面。

 ![1566456631758](assets/1566456631758.png)

    object demo {
    
      //定义一个方法
      //方法m2参数要求是一个函数，函数的参数必须是两个Int类型
      //返回值类型也是Int类型
      def m1(f: (Int, Int) => Int) : Int = {
        f(2, 6)
      }
      
      //定义一个函数f1，参数是两个Int类型，返回值是一个Int类型
      val f1 = (x: Int, y: Int) => x + y
      
      //再定义一个函数f2
      val f2 = (m: Int, n: Int) => m * n
    
      //main方法
      def main(args: Array[String]) {
      
        //调用m1方法，并传入f1函数
        val r1 = m1(f1)
        println(r1)
    
        //调用m1方法，并传入f2函数
        val r2 = m1(f2)
        println(r2)
      }
    
    }
### 神奇的下划线

通过下划线可以将方法转换成函数

 ![1566457051136](assets/1566457051136.png)

## 数组

### 定长数组和数组缓冲

      def main(args: Array[String]) {
    
        //初始化一个长度为8的定长数组，其所有元素均为0
        val arr1 = new Array[Int](8)
        //直接打印定长数组，内容为数组的hashcode值
        println(arr1)
        //将数组转换成数组缓冲，就可以看到原数组中的内容了
        //toBuffer会将数组转换长数组缓冲
        println(arr1.toBuffer)
    
        //注意：如果new，相当于调用了数组的apply方法，直接为数组赋值
        //初始化一个长度为1的定长数组
        val arr2 = Array[Int](10)
        println(arr2.toBuffer)
    
        //定义一个长度为3的定长数组
        val arr3 = Array("hadoop", "storm", "spark")
        //使用()来访问元素
        println(arr3(2))
    
        //////////////////////////////////////////////////
        //变长数组（数组缓冲）
        //如果想使用数组缓冲，需要导入import scala.collection.mutable.ArrayBuffer包
        val ab = ArrayBuffer[Int]()
        //向数组缓冲的尾部追加一个元素
        //+=尾部追加元素
        ab += 1
        //追加多个元素
        ab += (2, 3, 4, 5)
        //追加一个数组++=
        ab ++= Array(6, 7)
        //追加一个数组缓冲
        ab ++= ArrayBuffer(8,9)
        //打印数组缓冲ab
    
        //在数组某个位置插入元素用insert
        ab.insert(0, -1, 0)
        //删除数组某个位置的元素用remove
        ab.remove(8, 2)
        
        println(ab)
      }
### 遍历数组

```
1.增强for循环
2.好用的until会生成脚标，0 until 10 包含0不包含10
```

 ![1566458346151](assets/1566458346151.png)

      def main(args: Array[String]) {
        //初始化一个数组
        val arr = Array(1,2,3,4,5,6,7,8)
        //增强for循环
        for(i <- arr)
          println(i)
    
        //好用的until会生成一个Range
        //reverse是将前面生成的Range反转
        for(i <- (0 until arr.length).reverse)
          println(arr(i))
      }
### 数组转换

yield关键字将原始的数组进行转换会产生一个新的数组，原始的数组不变。

      def main(args: Array[String]) {
        //定义一个数组
        val arr = Array(1, 2, 3, 4, 5, 6, 7, 8, 9)
        //将偶数取出乘以10后再生成一个新的数组
        val res = for (e <- arr if e % 2 == 0) yield e * 10
        println(res.toBuffer)
        
        //filter是过滤，接收一个返回值为boolean的函数
        //map相当于将数组中的每一个元素取出来，应用传进去的函数
        val r = arr.filter(_ % 2 == 0).map(_ * 10)
        println(r.toBuffer)
      }
### 常用的算法

 ![1566459060253](assets/1566459060253.png)

## 映射

在Scala中，把哈希表这种数据结构叫做映射。

### 构建映射

 ![1566459405885](assets/1566459405885.png)

### 获取和修改映射中的值

 ![1566459480269](assets/1566459480269.png)

 ![1566459510286](assets/1566459510286.png)

在Scala中，有两种Map：

```
1.一个是immutable包下的Map，该Map中的内容不可变。

2.一个是mutable包下的Map，该Map中的内容可变。
```

 ![1566459642002](assets/1566459642002.png)

## 元组

映射是K/V对偶的集合，对偶是元组的最简单形式，元组可以装着多个不同类型的值。

### 创建元组

 ![1566459984331](assets/1566459984331.png)

### 获取元组中的值

 ![1566460002234](assets/1566460002234.png)

### 将对偶的集合转换成映射

 ![1566460016067](assets/1566460016067.png)

### 拉链操作

 ![1566460027345](assets/1566460027345.png)

如果两个数组的元素个数不一致，拉链操作后生成的数组的长度为较小的那个数组的元素个数。

## 集合

Scala的集合有三大类：序列Seq、集Set、映射Map，所有的集合都扩展自Iterable特质。在Scala中集合有可变（mutable）和不可变（immutable）两种类型，immutable类型的集合初始化后就不能改变了（注意与val修饰的变量进行区别）

### 序列

#### 不可变的序列

      def main(args: Array[String]) {
        //创建一个不可变的集合
        val lst1 = List(1,2,3)
        
        //将0插入到lst1的前面生成一个新的List
        //注意：:: 操作符是右结合的，如9 :: 5 :: 2 :: Nil相当于 9 :: (5 :: (2 :: Nil))
        val lst2 = 0 :: lst1
        val lst3 = lst1.::(0)
        println("lst3: "+lst3)
    
        val lst4 = 0 +: lst1
        val lst5 = lst1.+:(0)
    
        println("lst5: "+lst5)
    
        //将一个元素添加到lst1的后面产生一个新的集合
        val lst6 = lst1 :+ 3
    
        println("lst6: "+lst6)
    
        val lst0 = List(4,5,6)
        
        //将2个list合并成一个新的List
        val lst7 = lst1 ++ lst0
    
        println("lst7: "+lst7)
    
        //将lst1插入到lst0前面生成一个新的集合
        val lst8 = lst1 ++: lst0
    
        //将lst0插入到lst1前面生成一个新的集合
        val lst9 = lst1.:::(lst0)
    
        println("lst9: "+lst9)
    
      }
    
    ################################################################################################
    lst3: List(0, 1, 2, 3)
    lst1: List(1, 2, 3)
    lst5: List(0, 1, 2, 3)
    lst6: List(1, 2, 3, 3)
    lst7: List(1, 2, 3, 4, 5, 6)
    lst9: List(4, 5, 6, 1, 2, 3)


#### 可变序列

      def main(args: Array[String]) {
    
        //构建一个可变列表，初始有3个元素1,2,3
        val lst0 = ListBuffer[Int](1,2,3)
        //创建一个空的可变列表
        val lst1 = new ListBuffer[Int]
        //向lst1中追加元素，注意：没有生成新的集合
        lst1 += 4
        println("lst1: "+lst1)
        lst1.append(5)
        println("lst1: "+lst1)
    
        //将lst1中的元素最近到lst0中， 注意：没有生成新的集合
        lst0 ++= lst1
        println("lst0: "+lst0)
    
        //将lst0和lst1合并成一个新的ListBuffer 注意：生成了一个集合
        val lst2= lst0 ++ lst1
        println("lst2: "+lst2)
    
        //将元素追加到lst0的后面生成一个新的集合
        val lst3 = lst0 :+ 5
    
        println("lst0: "+lst0)
        println("lst3: "+lst3)
    
      }

### Set

#### 不可变的Set

```
object demo extends  App {
  val set1 = new HashSet[Int]()
  //将元素和set1合并生成一个新的set，原有set不变
  val set2 = set1 + 4
  //set中元素不能重复
  val set3 = set1 ++ Set(5, 6, 7)
  val set0 = Set(1,3,4) ++ set1
  println(set0.getClass)
  println("set0: "+set0)
  println("set1: "+set1)
  println("set2: "+set2)
  println("set3: "+set3)
}

################################################################################################

class scala.collection.immutable.Set$Set3
set0: Set(1, 3, 4)
set1: Set()
set2: Set(4)
set3: Set(5, 6, 7)
```

#### 可变的Set

```
object demo extends  App {
  //创建一个可变的HashSet
  val set1 = new mutable.HashSet[Int]()
  //向HashSet中添加元素
  set1 += 2
  println("set1: "+set1)
  //add等价于+=
  set1.add(4)
  println("set1: "+set1)
  set1 ++= Set(1,3,5)
  println("set1: "+set1)
  //删除一个元素
  set1 -= 5
  println("set1: "+set1)
  set1.remove(2)
  println("set1: "+set1)
}

################################################################################################

set1: Set(2)
set1: Set(2, 4)
set1: Set(1, 5, 2, 3, 4)
set1: Set(1, 2, 3, 4)
set1: Set(1, 3, 4)
```

### Map

```
object demo extends  App {
  val map1 = new mutable.HashMap[String, Int]()
  //向map中添加数据
  map1("spark") = 1
  println("map1"+map1)
  map1 += (("hadoop", 2))
  println("map1"+map1)
  map1.put("storm", 3)
  println("map1"+map1)

  //从map中移除元素
  map1 -= "spark"
  println("map1"+map1)
  map1.remove("hadoop")
  println("map1"+map1)
}

################################################################################################

map1Map(spark -> 1)
map1Map(hadoop -> 2, spark -> 1)
map1Map(hadoop -> 2, spark -> 1, storm -> 3)
map1Map(hadoop -> 2, storm -> 3)
map1Map(storm -> 3)
```

## 类、对象、继承、特质

### 类的定义

```
//在Scala中，类并不用声明为public。
//Scala源文件中可以包含多个类，所有这些类都具有公有可见性。
class Person {
  //用val修饰的变量是只读属性，有getter但没有setter
  //（相当与Java中用final修饰的变量）
  val id = "9527"

  //用var修饰的变量既有getter又有setter
  var age: Int = 18

  //类私有字段,只能在类的内部使用
  private var name: String = "唐伯虎"

  //对象私有字段,访问权限更加严格的，Person类的方法只能访问到当前对象的字段，而不能访问同样是Person类的   //其他对象的该字段
  private[this] var pet = "小强"
}
```

### 构造器

```
package com.lx
import java.io.IOException

/**
  *每个类都有主构造器，主构造器的参数直接放置类名后面，与类交织在一起
  */
class Student(val name: String, val age: Int){
  //主构造器会执行类定义中的所有语句
  println("执行主构造器")

  try {
    println("读取文件")
    throw new IOException("io exception")
  } catch {
    case e: NullPointerException => println("打印异常Exception : " + e)
    case e: IOException => println("打印异常Exception : " + e)
  } finally {
    println("执行finally部分")
  }

  private var gender = "male"
  
  //用this关键字定义辅助构造器
  def this(name: String, age: Int, gender: String){
    //每个辅助构造器必须以主构造器或先前已定义的其他的辅助构造器的调用开始
    this(name, age)  //调用的是主构造器
    println("执行辅助构造器")
    this.gender = gender
  }
}

################################################################################################

/**
  *构造器参数可以不带val或var，如果不带val或var的参数至少被一个方法所使用，
  *那么它将会被提升为字段
  */
//在类名后面加private就变成了私有的
class Queen private(val name: String, prop: Array[String], private var age: Int = 18){
  
  println(prop.size)

  //prop被下面的方法使用后，prop就变成了不可变的对象私有字段，等同于private[this] val prop
  //如果没有被方法使用该参数将不被保存为字段，仅仅是一个可以被主构造器中的代码访问的普通参数
  def description = name + " is " + age + " years old with " + prop.toBuffer
}

object Queen{
  def main(args: Array[String]) {
    //私有的构造器，只有在其伴生对象中使用
    val q = new Queen("hatano", Array("蜡烛", "皮鞭"), 20)
    println(q.description())
  }
}
```

### 对象

#### 单例对象

在Scala中没有静态方法和静态字段，但是可以使用object这个语法结构来达到同样的目的。

```
package com.lx
import scala.collection.mutable.ArrayBuffer

object SingletonDemo {
  def main(args: Array[String]) {
    //单例对象，不需要new，用【类名.方法】调用对象中的方法
    val session = SessionFactory.getSession()
    println(session)
    println(SessionFactory.counts)
  }
}

object SessionFactory{
  //该部分相当于java中的静态块
  var counts = 5
  val sessions = new ArrayBuffer[Session]()
  while(counts > 0){
    sessions += new Session
    counts -= 1
  }

  //在object中的方法相当于java中的静态方法
  def getSession(): Session ={
    counts+=1
    sessions.remove(0)
  }
}

class Session{

}
```

#### 伴生对象

在Scala的类中，与类名相同的对象叫做伴生对象，类和伴生对象之间可以相互访问私有的方法和属性，它们必须存在于同一个源文件中。

```
package com.lx

class Dog {
  val id = 1
  
  //访问私有的字段name
  private var name = "皮卡丘~~~~"

  def printName(): Unit ={
    //在Dog类中可以访问伴生对象Dog的私有属性
    println(Dog.CONSTANT + name )
  }
}

/**

- 伴生对象
  */
  object Dog {

  //伴生对象中的私有属性
  private val CONSTANT = "汪汪汪 : "

  def main(args: Array[String]) {
    val p = new Dog
    //访问类中的私有字段name
    p.name = "123"
    p.printName()
  }
}
```

#### apply方法

将对象以函数的方式进行调用时，scala会隐式地将调用改为在该对象上调用apply方法。例如XXX(“hello”)实际调用的是XXX.apply(“hello”)，因此apply方法又被称为注入方法。apply方法常用于创建类实例的工厂方法。

```
package com.lx

object Person {
  
  def apply(name: String): Unit = {
    println("name: "+name)
  }

  def apply(age:Int): Unit = {
    println("age: "+age)
  }

  def apply(name: String, age: Int): Unit = {
       println("name: "+name+"age: "+age)
  }
  
}

object  hi {
  def main(args: Array[String]): Unit = {
    Person("张三")
    Person(12)
    Person("张三",12)
  }
}

#####################################输出#######################################################
name: 张三
age: 12
name: 张三age: 12

Process finished with exit code 0


```

#### unapply 方法

unapply方法是伴生对象中apply方法的反向操作。apply方法接收构造参数，然后把它们变成对象。而unapply方法接受一个对象，然后从中提取值。


    package com.lx
    
    class  Person(var name:String,var age:Int){
    
    }
    
    object Person {
    
      def apply(name: String, age: Int): Unit = {
           println("name: "+name+"age: "+age)
      }
      def unapply(arg: Person): Option[(String,Int)] = {
        Some(arg.name,arg.age)
      }
    }
    
    object  hi {
      def main(args: Array[String]): Unit = {
    
        val p =new Person("张三",12)
        p match  {
          case  Person(name,age)=>{
            println("name: "+name+"age: "+age)
          }
          case _ =>{
            println("什么鬼哦")
          }
        }
      }
    }
    
    ################################################################################################
    举例来说：
    val author="Cay Horstmann"
    val Name(first,last)=author   //调用 Name.unapply(author)
    
    提供一个对象Name，其unapply方法返回一个Option[(String,String)]。如果匹配成功，返回名字和姓氏的对偶。该对偶的两个组成部分将会分别绑定到模式中的两个变量。
    
    package com.lx
    
    class Name(fisrt:String,last:String){
    
    }
    
    object  Name{
      def unapply(input:String): Option[(String,String)] ={
        val pos=input.indexOf(" ")
        if(pos == -1) None
        else  Some((input.substring(0,pos)),(input.substring(pos+1)))
      }
    }
    
    object  Test{
      def main(args: Array[String]): Unit = {
        val author="cry hostmann"
    
        val Name(first,last)=author
    
        author match {
          case Name(first,last) =>{      //如果匹配成功，返回名字和姓氏的对偶。该对偶的两个组成部分
                                         //将会分别绑定到模式中的两个变量first和last中。
            println("firstname: "+ first)
            println("lastname: "+ last)
          }
        }   
      }
    }

#### 应用程序对象

每个Scala程序都必须从一个对象的main方法开始，除了每次都提供自己的main方法外，还可以通过扩展App特质。

```
package com.lx

object AppDemo extends  App {
  
  println("hello scala!!!")

}
```

### 继承

Scala扩展类的方式和Java一样都是使用extends关键字。

```
class Employee extends  Person{

  var salary=1.0
    ...
}
```

和Java一样，你在定义中给出子类需要而超类没有的字段和方法，或者重写超类的方法。

### 重写方法

在Scala中重写一个非抽象的方法必须使用override修饰符。

### 类型检查和转换

| **Scala**           | **Java**         |
| ------------------- | ---------------- |
| obj.isInstanceOf[C] | obj instanceof C |
| obj.asInstanceOf[C] | (C)obj           |
| classOf[C]          | C.class          |

```
package com.lx

class Employee{

}

object Employee extends  App {
  
  val p=new  Employee
  
  //p.isInstanceOf[Employee] 判断p这个对象是否属于Employee这个类的实例，如果p指向
  //的是Employee类及其子类的对象，则p.isInstanceOf[Employee]将会成功。
  if(p.isInstanceOf[Employee]){
    val  s=p.asInstanceOf[Employee]  //asInstanceOf方法将引用转换为子类的引用。
  }

}

################################################################################################

if(p.getClass==classOf[Employee])  //测试p指向的是一个Employee对象但又不是其子类的话
```

## 模式匹配

Scala有一个十分强大的模式匹配机制，可以应用到很多场合：如switch语句、类型检查等。
并且Scala还提供了样例类，对模式匹配进行了优化，可以快速进行匹配。

### 匹配字符串

```
package com.lx

import scala.util.Random

object Match extends App {

  val arr = Array("YoshizawaAkiho", "YuiHatano", "AoiSola")
  val name = arr(Random.nextInt(arr.length))
  name match {
    case "YoshizawaAkiho" => println("吉泽老师...")
    case "YuiHatano" => println("波多老师...")
    case _ => println("真不知道你们在说什么...")
  }

}
```

### 匹配类型

```
package com.lx

import scala.util.Random

object Match extends App {

  //val v = if(x >= 5) 1 else if(x < 2) 2.0 else "hello"
  val arr = Array("hello", 1, 2.0, Name)
  val v = arr(Random.nextInt(4))

  println(v)
  
  v match {
    case x: Int => println("Int " + x)
    
    case y: Double if(y >= 0) => println("Double "+ y) //模式匹配还可以添加守卫条件：if(y >= 0)                                       
    case z: String => println("String " + z)
    case _ => throw new Exception("not match exception")
  }
}
```

### 匹配数组、列表和元组

```
package com.lx

import scala.util.Random

object Match extends App {
  //数组
  val arr = Array(0, 3, 5)
  arr match {
    case Array(1, x, y) => println(x + " " + y)  //匹配任何带有三个元素且第一个为1的数组
    case Array(0) => println("only 0")           //匹配只有0一个元素的数组
    case Array(0, _*) => println("0 ...")        //_* 可变长度，表示匹配任何以0作为第一个元素的数组
    case _ => println("something else")          //其它情况
  }

  //列表
  val lst = List(3, -1,6)
  lst match {
    case 0 :: Nil => println("only 0")
    case x :: y :: Nil => println(s"x: $x y: $y")
    case 0 :: tail => println("0 ...")
    case _ => println("something else")
  }

  //元组
  val tup = (1, 3, 7)
  tup match {
    case (1, x, y) => println(s"1, $x , $y")
    case (_, z, 5) => println(z)
    case  _ => println("else")
  }

}
```

### 样例类

样例类是一种特殊的类，它们经过优化后以被用于模式匹配。case class是多例的，后面要跟构造参数，case object是单例的。

```
package com.lx

import scala.util.Random

case class SubmitTask(id: String, name: String)//样例类
case class HeartBeat(time: Long)
case object CheckTimeOutTask  //单例的样例对象

object Match extends App {

  val arr = Array(CheckTimeOutTask, HeartBeat(12333), SubmitTask("0001", "task-0001"))

  arr(Random.nextInt(arr.length)) match {
    case SubmitTask(id, name) => {
      println(s"$id, $name")//前面需要加上s, $id直接取id的值
    }
    case HeartBeat(time) => {
      println(time)
    }
    case CheckTimeOutTask => {
      println("check")
    }
  }
}
```

### Option类型

标准类库中的Option类型用样例类来表示那种可能存在也有可能不存在的值。样例子类Some包装了某个值，例如：Some("Fred")。而样例对象None表示没有值。Option支持泛型，举例来说就是Some("Fred")的类型为Option[String]。

Map类的get方法返回一个Option。如果对于给定的键没有对应值，则get返回None。如果有值，就会将该值包在Some中返回。

```
package com.lx

import scala.util.Random


object Match  {

  def main(args: Array[String]) {
    val map = Map("a" -> 1,"c" -> 2, "b" -> 2,"f" -> 5,"f" -> 8,"f" -> 10,"k" -> 33)
    val v = map.get("f") match {
      case Some(i) => i
      case None => 0
    }
    println(v)
    //更好的方式
    val v1 = map.getOrElse("c", 0)
    println(v1)
  }

}

################################################################################################
10
2
```

### 偏函数

被包在花括号内没有match的一组case语句是一个偏函数，它是PartialFunction[A, B]的一个实例，A代表参数类型，B代表返回类型，常用作输入模式匹配。

```
package com.lx
import scala.util.Random

object Match  {

  //偏函数
  def func1: PartialFunction[String, Int] = {
    case "one" => 1
    case "two" => 2
    case _ => -1
  }

  //一般的模式匹配
  def func2(num: String) : Int = num match {
    case "one" => 1
    case "two" => 2
    case _ => -1
  }

  def main(args: Array[String]) {
    println(func1("one"))
    println(func2("one"))
  }

}

################################################################################################
1
1
```

## 高阶函数

Scala混合了面向对象和函数式的特性。在函数式编程语言中，函数是“头等公民”，可以像任何其他数据类型一样被传递和操作。高阶函数包含：作为值的函数、匿名函数、带函数参数的函数、闭包、柯里化等等。

### 作为值的函数

可以像任何其他数据类型一样被传递和操作的函数，每当你想要给算法传入具体动作时，这个特性就会变得非常有用。

 ![1566524474416](assets/1566524474416.png)

```
scala> Array(3.14, 1.42).map((x: Double) => 3 * x)
res4: Array[Double] = Array(9.42, 4.26)

scala> def triple = (x: Double) => 3 * x   //无参数的方法
triple: Double => Double

scala> Array(3.14, 1.42).map(triple)   //如果期望出现函数的地方我们提供了一个方法的话，
                                       //该方法就会自动被转换成函数。
res5: Array[Double] = Array(9.42, 4.26)

scala>  val triple1 = (x: Double) => 3 * x
triple1: Double => Double = <function1>

scala> Array(3.14, 1.42).map(triple1)
res6: Array[Double] = Array(9.42, 4.26)

scala> var triple2 = (x: Double) => 3 * x
triple2: Double => Double = <function1>

scala> Array(3.14, 1.42).map(triple2)
res7: Array[Double] = Array(9.42, 4.26)

scala> def triple3(x:Double)=3 * x
triple3: (x: Double)Double

scala> Array(3.14, 1.42).map(triple3)
res8: Array[Double] = Array(9.42, 4.26)

scala> def triple4(x:Double):Double = 3 * x
triple4: (x: Double)Double

scala> Array(3.14, 1.42).map(triple4)
res9: Array[Double] = Array(9.42, 4.26)

scala>
```

### 匿名函数

在Scala中，你不需要给每一个函数命名，没有将函数赋给变量的函数叫做匿名函数。

 ![1566525355660](assets/1566525355660.png)

由于Scala可以自动推断出参数的类型，所有可以写的跟精简一些。

 ![1566525406777](assets/1566525406777.png)

还记得神奇的下划线吗？这才是终极方式

 ![1566525438877](assets/1566525438877.png)

### 带函数参数的函数

```
scala> def fun(f: (Double) => Double) = f(0.25)   //这里的参数可以事任何Double并返回Double的函数。
fun: (f: Double => Double)Double

scala> fun((x: Double) => 3 * x)
res0: Double = 0.75

// 由于fun方法知道会传入一个类型为(Double) => Double的函数，可以简单地写成这样。
scala> fun((x) => 3 * x)
res1: Double = 0.75

// 对于只有一个参数的函数，可以省略参数外围的()
scala> fun(x => 3 * x)
res2: Double = 0.75

// 如果参数在=>右侧只出现一次，可以用_替换掉它
scala> fun(3 * _)
res3: Double = 0.75

scala>
```

### 将方法转换成函数

在Scala中，方法和函数是不一样的，最本质的区别是函数可以做为参数传递到方法中，但是方法可以被转换成函数，神奇的下划线又出场了。

 ![1566527490968](assets/1566527490968.png)

但为什么方法看起来可以作为参数一样传递呢？那是因为如果期望出现函数的地方我们提供了一个方法的话，该方法就会自动被转换成函数。该行为被称为ETA expansion。

### 柯里化

柯里化指的是将原来接收两个参数的函数变成新的接收一个参数的函数的过程。新的函数返回一个以原有第二个参数作为参数的函数。

 ![1566527654843](assets/1566527654843.png)

```
scala> def mul(x: Int, y: Int) = x * y
mul: (x: Int, y: Int)Int

scala> def mulOne(x: Int) = (y: Int) => x * y
mulOne: (x: Int)Int => Int

scala> mul(6,7)
res4: Int = 42

scala> mulOne(6)
res5: Int => Int = <function1>

scala> val func=mulOne(6)
func: Int => Int = <function1>

scala> func(7)
res6: Int = 42

// mulOne(6)的结果是函数(y: Int) => 6 * y，把这个函数又被应用到7，因此得到42。
```

### 闭包

闭包是一个函数，返回值依赖于声明在函数外部的一个或多个变量。闭包通常来讲可以简单的认为是可以访问一个函数里面局部变量的另外一个函数。

```
scala> def mulBy(factor: Double) = (x: Double) => factor * x
mulBy: (factor: Double)Double => Double

scala> val triple = mulBy(3)
triple: Double => Double = <function1>

scala> val half = mulBy(0.5)
half: Double => Double = <function1>

scala> println(triple(14) + " " + half(14))
42.0 7.0


################################################################################################
1.mulBy的首次调用将参数变量factor设置为3，该变量在(x: Double) => factor * x函数的函数体内被引用，该函数被存入triple。

2.接下来，mulBy再次被调用，这次factor设置为0.5，该变量在(x: Double) => factor * x函数的函数体被引用，该函数被存入half。

3.每一个返回的函数都有自己的factor设置，这样一个函数被称做闭包，闭包由代码和代码用到的任何非局变量定义构成。
```

## 隐式转换

在scala语言当中，隐式转换和隐式参数是Scala中两个非常强大的功能，利用隐式转换和隐式参数，你可以提供优雅的类库，对类库的使用者隐匿掉那些枯燥乏味的细节。

### 隐式转换函数

下列赋值如果没有隐式转换的话会报错：

```
scala> val x:Int=3.5
<console>:7: error: type mismatch;
 found   : Double(3.5)
 required: Int
       val x:Int=3.5
                 ^
```

添加隐式转换函数后可以实现Double类型到Int类型的赋值。

```
//定义了一个隐式函数double2Int，将输入的参数
//从Double类型转换到Int类型
scala> implicit def double2Int(x:Double)=x.toInt
warning: there were 1 feature warning(s); re-run with -feature for details
double2Int: (x: Double)Int
//定义完隐式转换后，便可以直接将Double类型赋值给Int类型
scala> val x:Int=3.5
x: Int = 3
```

隐式函数的名称对结构没有影响，即implicit def double2Int(x:Double)=x.toInt函数可以是任何名字，只是采用source2Target这种方式函数的意思比较明确，阅读代码的人可以见名知义，增加代码的可读性。

隐式转换功能十分强大，可以快速地扩展现有类库的功能，例如下面的代码：

```
package com.lx

import java.io.File
import scala.io.Source
//RichFile类中定义了Read方法
class RichFile(val file:File){
  def read=Source.fromFile(file).getLines().mkString
}

object ImplicitFunction extends App{
  implicit def double2Int(x:Double)=x.toInt
  var x:Int=3.5
  //隐式函数将java.io.File隐式转换为RichFile类
  implicit def file2RichFile(file:File)=new RichFile(file)
  val f=new File("file.log").read
  println(f)
}
```

### 隐式转换规则

隐式转换可以定义在目标文件当中，例如：

```
implicit def double2Int(x:Double)=x.toInt
var x:Int=3.5
```

隐式转换函数与目标代码在同一个文件当中，也可以将隐式转换集中放置在某个包中，在使用进直接将该包引入即可，例如：

```
package com.lx
import java.io.File
import scala.io.Source

//在com.lx包中定义了子包implicitConversion
//然后在object ImplicitConversion中定义所有的引式转换方法
package implicitConversion{
  object ImplicitConversion{
    implicit def double2Int(x:Double)=x.toInt
    implicit def file2RichFile(file:File)=new RichFile(file)
  }
}

class RichFile(val file:File){
  def read=Source.fromFile(file).getLines().mkString
}

object ImplicitFunction extends App{
  //在使用时引入所有的隐式方法
  import  com.lx.implicitConversion.ImplicitConversion._    
//  import  com.lx.implicitConversion.ImplicitConversion.double2Int
//  import  com.lx.implicitConversion.ImplicitConversion.file2RichFile
  
  var x:Int=3.5

  val f=new File("file.log").read
  println(f)
}
```

**那什么时候会发生隐式转换呢？主要有以下两种情况：**

当方法中参数的类型与实际类型不一致时，例如：

```
def f(x:Int)=x
//方法中输入的参数类型与实际类型不一致，此时会发生隐式转换
//double类型会转换为Int类型，再进行方法的执行
f(3.14)
```

当调用类中不存在的方法或成员时，会自动将对象进行隐式转换，例如：

```
package com.lx

import java.io.File
import scala.io.Source
//RichFile类中定义了Read方法
class RichFile(val file:File){
  def read=Source.fromFile(file).getLines().mkString
}

object ImplicitFunction extends App{
  implicit def double2Int(x:Double)=x.toInt
  var x:Int=3.5
  //隐式函数将java.io.File隐式转换为RichFile类
  implicit def file2RichFile(file:File)=new RichFile(file)
  //File类的对象并不存在read方法，此时便会发生隐式转换
  //将File类转换成RichFile
  val f=new File("file.log").read
  println(f)
}
```

**前面我们讲了什么情况下会发生隐式转换，下面我们讲一下什么时候不会发生隐式转换：**

编译器可以不在隐式转换的编译通过，则不进行隐式转换，例如 :

```
//这里定义了隐式转换函数
scala> implicit def double2Int(x:Double)=x.toInt
warning: there were 1 feature warning(s); re-run with -feature for details
double2Int: (x: Double)Int

//下面几条语句，不需要自己定义隐式转换编译就可以通过
//因此它不会发生前面定义的隐式转换
scala> 3.0*2
res0: Double = 6.0

scala> 2*3.0
res1: Double = 6.0

scala> 2*3.7
res2: Double = 7.4
```

如果转换存在二义性，则不会发生隐式转换，例如:

```
package implicitConversion{
  object ImplicitConversion{
    implicit def double2Int(x:Double)=x.toInt
    //这里定义了一个隐式转换
    implicit def file2RichFile(file:File)=new RichFile(file)
    //这里又定义了一个隐式转换，目的与前面那个相同
    implicit def file2RichFile2(file:File)=new RichFile(file)
  }

}

class RichFile(val file:File){
  def read=Source.fromFile(file).getLines().mkString
}

object ImplicitFunction extends App{
  import com.lx.implicitConversion.ImplicitConversion._
  var x:Int=3.5

  //下面这条语句在编译时会出错，提示信息如下：
  //type mismatch; found : java.io.File required:
  // ?{def read: ?} Note that implicit conversions 
  //are not applicable because they are ambiguous: 
  //both method file2RichFile in object 
  //ImplicitConversion of type (file: 
  //java.io.File)cn.scala.xtwy.RichFile and method 
  //file2RichFile2 in object ImplicitConversion of 
  //type (file: java.io.File)cn.scala.xtwy.RichFile 
  //are possible conversion functions from java.io.File to ?{def read: ?}
value read is not a member of java.io.File

  val f=new File("file.log").read
  println(f)
}
```

隐式转换不会嵌套进行，例如:

```
package com.lx
import java.io.File
import scala.io.Source

package implicitConversion{
  object ImplicitConversion{
    implicit def double2Int(x:Double)=x.toInt
    implicit def file2RichFile(file:File)=new RichFile(file)
    //implicit def file2RichFile2(file:File)=new RichFile(file)
    implicit def richFile2RichFileAnother(file:RichFile)=new RichFileAnother(file)
  }

}

class RichFile(val file:File){
  def read=Source.fromFile(file).getLines().mkString
}

//RichFileAnother类，里面定义了read2方法
class RichFileAnother(val file:RichFile){
  def read2=file.read
}

object ImplicitFunction extends App{
  import com.lx.implicitConversion.ImplicitConversion._
  var x:Int=3.5

  //隐式转换不会多次进行，下面的语句会报错
  //不能期望会发生File到RichFile，然后RifchFile到RichFileAnthoer的转换
  val f=new File("file.log").read2
  println(f)
}
```

### 隐式参数

在一般的函数据定义过程中，需要明确传入函数的参数，代码如下：

```
package com.lx

class Student(var name:String){
  //将Student类的信息格式化打印
  def formatStudent(outputFormat:OutputFormat)={
    outputFormat.first+" "+this.name+" "+outputFormat.second
  }
}

class OutputFormat(var first:String,val second:String)

object ImplicitParameter {
  def main(args: Array[String]): Unit = {
    val outputFormat=new OutputFormat("<<",">>")
    println(new Student("john").formatStudent(outputFormat))
  }
}

################################################################################################
//执行结果
//<< john >>
```

如果给函数定义隐式参数的话，则在使用时可以不带参数，代码如下：

```
package com.lx
class Student(var name:String){
  //利用柯里化函数的定义方式，将函数的参数利用
  //implicit关键字标识
  //这样的话，在使用的时候可以不给出implicit对应的参数
  def formatStudent()(implicit outputFormat:OutputFormat)={
    outputFormat.first+" "+this.name+" "+outputFormat.second
  }
}

class OutputFormat(var first:String,val second:String)

object ImplicitParameter {
  def main(args: Array[String]): Unit = {
    //程序中定义的变量outputFormat被称隐式值
    implicit val outputFormat=new OutputFormat("<<",">>")
    //在.formatStudent()方法时，编译器会查找类型
    //为OutputFormat的隐式值,本程序中定义的隐式值
    //为outputFormat
    println(new Student("john").formatStudent())
  }
}
```

