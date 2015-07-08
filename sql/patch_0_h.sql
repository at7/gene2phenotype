CREATE TABLE organ (
  organ_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  PRIMARY KEY (organ_id)
);

INSERT INTO organ(organ_id, name) SELECT organ_specificity_id, organ_specificity FROM organ_specificity;
