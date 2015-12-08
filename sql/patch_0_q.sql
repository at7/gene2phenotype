CREATE TABLE `ensembl_variant` (
  `variant_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `genomic_feature_id` int(10) unsigned NOT NULL,
  `seq_region` varchar(128) DEFAULT NULL,
  `seq_region_start` int(11) NOT NULL,
  `seq_region_end` int(11) NOT NULL,
  `seq_region_strand` tinyint(4) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `source` varchar(24) NOT NULL,
  `allele_string` varchar(50000) DEFAULT NULL,
  `consequence` varchar(128) DEFAULT NULL,
  `feature_stable_id` varchar(128) DEFAULT NULL,
  `amino_acid_string` varchar(255) DEFAULT NULL,
  `polyphen_prediction` varchar(128) DEFAULT NULL,
  `sift_prediction` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`variant_id`),
  KEY `genomic_feature_idx` (`genomic_feature_id`)
);
