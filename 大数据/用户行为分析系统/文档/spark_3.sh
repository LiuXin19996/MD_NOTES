./spark-submit \
--class com.lx.sparkproject.spark.product.AreaTop3ProductSpark \
--num-executors 1 \
--driver-memory 100m \
--executor-memory 100m \
--executor-cores 1 \
--files /root/hive-0.13.1/conf/hive-site.xml \
--driver-class-path /root/hive-0.13.1/lib/mysql-connector-java-5.1.17.jar \
/usr/local/spark-study/spark-project.jar \
${1}


				DataTypes.createStructField("date", DataTypes.StringType, true),
				DataTypes.createStructField("user_id", DataTypes.LongType, true),
				DataTypes.createStructField("session_id", DataTypes.StringType, true),
				DataTypes.createStructField("page_id", DataTypes.LongType, true),
				DataTypes.createStructField("action_time", DataTypes.StringType, true),
				DataTypes.createStructField("search_keyword", DataTypes.StringType, true),
				DataTypes.createStructField("click_category_id", DataTypes.LongType, true),
				DataTypes.createStructField("click_product_id", DataTypes.LongType, true),
				DataTypes.createStructField("order_category_ids", DataTypes.StringType, true),
				DataTypes.createStructField("order_product_ids", DataTypes.StringType, true),
				DataTypes.createStructField("pay_category_ids", DataTypes.StringType, true),
				DataTypes.createStructField("pay_product_ids", DataTypes.StringType, true),
				DataTypes.createStructField("city_id", DataTypes.LongType, true)));

				
				create table user_visit_action{
				date string,
				user_id bigint,
				session_id string,
				page_id bigint,
				action_time string,
				search_keyword string,
				click_category_id bigint
				click_product_id bigint,
				order_category_ids string,
				order_product_ids string,
				pay_category_ids string,
				pay_product_ids string,
				city_id bigint
				}