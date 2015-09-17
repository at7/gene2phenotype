# add new column panel
ALTER TABLE genomic_feature_disease ADD COLUMN `panel` tinyint (1) DEFAULT NULL AFTER `is_visible`;
UPDATE genomic_feature_disease set panel=38;

ALTER TABLE user ADD COLUMN `panel` set('36','37','38','39','40','41') DEFAULT NULL AFTER `email`;
UPDATE user set panel='38';

