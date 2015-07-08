CREATE TABLE genomic_feature_disease_organ (
  GFD_organ_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  organ_id int(10) unsigned NOT NULL,
  PRIMARY KEY (GFD_organ_id),
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);
