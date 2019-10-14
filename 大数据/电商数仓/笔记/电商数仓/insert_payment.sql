DELIMITER$$

 DROP PROCEDURE IF EXISTS `insert_payment`$$
 ## 只要订单状态更新为2 ，给当天插入一条支付信息 
 CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_payment`( do_date_str VARCHAR(200)   )
BEGIN      
 INSERT INTO payment_info (out_trade_no,order_id,user_id,alipay_trade_no,total_amount,`subject`,payment_type,payment_time  ) 
  SELECT o.out_trade_no,o.id,user_id,
   CONCAT( rand_string(4),'-',rand_nums(0,9,8,'')) alipay_trade_no,
   o.total_amount,
   rand_string(8) `subject`,
  ( CASE rand_num(1,3) WHEN 1 THEN  'wechatpay' WHEN 2 THEN 'alipay' WHEN 3 THEN 'unionpay' END) payment_type , 
  IF(o.operate_time IS NULL,o.create_time,o.operate_time) payment_time
  FROM order_info  o 
  WHERE (DATE_FORMAT(o.create_time,'%Y-%m-%d')= do_date_str OR DATE_FORMAT(o.operate_time,'%Y-%m-%d')= do_date_str ) AND o.order_status='2';
  COMMIT;
 END$$

DELIMITER ;