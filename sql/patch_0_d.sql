CREATE TABLE IF NOT EXISTS genomic_feature_disease_publication (
  GFD_publication_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  publication_id int(10) unsigned NOT NULL,
  PRIMARY KEY (GFD_publication_id),
  KEY genomic_feature_disease_idx (genomic_feature_disease_id)
);

CREATE TABLE IF NOT EXISTS GFD_publication_comment (
  GFD_publication_comment_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  GFD_publication_id int(10) unsigned NOT NULL,
  comment_text text DEFAULT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  user_id int(10) unsigned NOT NULL,
  PRIMARY KEY (GFD_publication_comment_id),
  KEY GFD_publication_idx (GFD_publication_id)
);
