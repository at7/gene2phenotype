CREATE TABLE genomic_feature_disease_log (
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  genomic_feature_id int(10) unsigned NOT NULL,
  disease_id int(10) unsigned NOT NULL,
  DDD_category_attrib set('32', '33', '34', '35', '36', '37', '38', '39') DEFAULT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  user_id int(10) unsigned NOT NULL,
  action varchar(128) NOT NULL,
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);


INSERT INTO genomic_feature_disease_log(genomic_feature_disease_id, genomic_feature_id, disease_id, DDD_category_attrib, created, user_id, action) SELECT gfd.genomic_feature_disease_id, gfd.genomic_feature_id, gfd.disease_id, gfd.DDD_category_attrib, CURRENT_TIMESTAMP, 4, 'create' FROM genomic_feature_disease gfd; 
