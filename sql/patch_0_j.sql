INSERT INTO attrib(attrib_id, attrib_type_id, value) values(35, 3, 'child IF');
ALTER TABLE `genomic_feature_disease` CHANGE `DDD_category_attrib` `DDD_category_attrib` SET('31','32','33','34','35');
ALTER TABLE `genomic_feature_disease_log` CHANGE `DDD_category_attrib` `DDD_category_attrib` SET('31','32','33','34','35');
