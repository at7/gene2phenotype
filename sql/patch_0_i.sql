ALTER TABLE genomic_feature_disease ADD is_visible tinyint(1) unsigned NOT NULL DEFAULT '1' AFTER DDD_category_attrib;
ALTER TABLE genomic_feature_disease_log ADD is_visible tinyint(1) unsigned NOT NULL DEFAULT '1' AFTER DDD_category_attrib;
