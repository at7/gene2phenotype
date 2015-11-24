CREATE TABLE `genomic_feature_synonym` (
  `genomic_feature_id` int(10) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  UNIQUE KEY `name` (`genomic_feature_id`,`name`),
  KEY `genomic_feature_idx` (`genomic_feature_id`)
);
