CREATE TABLE genomic_feature_disease_action_log (
  genomic_feature_disease_action_id int(10) unsigned NOT NULL,
  genomic_feature_disease_id int(10) unsigned NOT NULL,
  allelic_requirement_attrib set('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21') DEFAULT NULL,
  mutation_consequence_attrib set('22', '23', '24', '25', '26', '27', '28', '29', '30', '31') DEFAULT NULL,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  user_id int(10) unsigned NOT NULL,
  action varchar(128) NOT NULL,
  PRIMARY KEY (genomic_feature_disease_action_id)
);

INSERT INTO genomic_feature_disease_action_log(genomic_feature_disease_action_id, genomic_feature_disease_id, allelic_requirement_attrib, mutation_consequence_attrib, created, user_id, action ) SELECT gfda.genomic_feature_disease_action_id, gfda.genomic_feature_disease_id, gfda.allelic_requirement_attrib, gfda.mutation_consequence_attrib, CURRENT_TIMESTAMP, 4, 'create' FROM genomic_feature_disease_action gfda;
