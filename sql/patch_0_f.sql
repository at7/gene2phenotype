DROP table genomic_feature_disease_phenotype;

CREATE TABLE genomic_feature_disease_phenotype (
  GFD_phenotype_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  phenotype_id int(10) unsigned NOT NULL,
  PRIMARY KEY (GFD_phenotype_id),
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);
