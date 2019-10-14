#!/bin/bash

db_name=gmall

export_data() {
/root/sqoop-1.4.6.bin/bin/sqoop export \
--connect "jdbc:mysql://192.168.8.11:3306/gmall_visualization?useUnicode=true&characterEncoding=utf-8"  \
--username root \
--password lx@6688 \
--table $1 \
--num-mappers 1 \
--export-dir /user/hive/warehouse/$db_name/ads/$1 \
--input-fields-terminated-by "\t" \
--update-mode allowinsert \
--update-key "tm_id,category1_id,stat_mn,stat_date" \
--input-null-string '\\N'    \
--input-null-non-string '\\N'
}

case $1 in
  "ads_uv_count")
     export_data "ads_uv_count"
;;
  "ads_user_action_convert_day")
     export_data "ads_user_action_convert_day"
;;
  "ads_gmv_sum_day")
     export_data "ads_gmv_sum_day"
;;
   "all")
	 export_data "ads_uv_count"
	 export_data "ads_user_action_convert_day"
     export_data "ads_gmv_sum_day"
;;
esac
