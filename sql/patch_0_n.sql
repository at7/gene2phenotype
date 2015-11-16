ALTER TABLE `genomic_feature_disease` CHANGE COLUMN `panel` `panel_attrib` tinyint(1) DEFAULT NULL;
ALTER TABLE `user` CHANGE COLUMN `panel` `panel_attrib` set('36','37','38','39','40','41') DEFAULT NULL;
