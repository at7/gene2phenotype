RENAME TABLE genomic_feature_disease TO genomic_feature_disease_old;

CREATE TABLE genomic_feature_disease (
  genomic_feature_disease_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_id int(10) unsigned NOT NULL,
  disease_id int(10) unsigned NOT NULL,
  DDD_category_attrib set('31', '32', '33', '34', '35') DEFAULT NULL,
  is_visible tinyint(1) unsigned NOT NULL DEFAULT '1',
  panel_attrib tinyint(1) DEFAULT NULL,
  PRIMARY KEY (genomic_feature_disease_id),
  UNIQUE KEY genomic_feature_disease (genomic_feature_id, disease_id, panel_attrib),
  KEY genomic_feature_idx (genomic_feature_id),
  KEY disease_idx (disease_id)
);

INSERT INTO genomic_feature_disease SELECT * FROM genomic_feature_disease_old;

