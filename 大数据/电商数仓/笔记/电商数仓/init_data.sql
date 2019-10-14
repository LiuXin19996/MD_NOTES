DELIMITER $$

DROP PROCEDURE IF EXISTS `init_data`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `init_data`( do_date_string VARCHAR(20) ,order_incr_num INT,user_incr_num INT ,sku_num INT ,if_truncate BOOLEAN  )
BEGIN  
     DECLARE user_count INT DEFAULT 0; 
     DECLARE sku_count INT DEFAULT 0; 
     DECLARE do_date VARCHAR(20) DEFAULT do_date_string;
     IF if_truncate  THEN 
        TRUNCATE TABLE order_info ;
        TRUNCATE TABLE order_detail ;
        TRUNCATE TABLE sku_info ;
        TRUNCATE TABLE user_info ;
     END IF ;     
     CALL insert_sku(do_date,sku_num );
     SELECT COUNT(*) INTO sku_count FROM  sku_info;
     CALL insert_user(do_date,user_incr_num );
     SELECT COUNT(*) INTO user_count FROM  user_info;
     CALL update_order(do_date);
     CALL insert_order(do_date,order_incr_num,user_count,sku_count);
     CALL insert_payment(do_date);
 END$$

DELIMITER ;