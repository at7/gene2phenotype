INSERT IGNORE INTO attrib_type (attrib_type_id, code, name, description) VALUES (1, 'allelic_requirement', 'Allelic requirement', 'Allelic requirement');
INSERT IGNORE INTO attrib_type (attrib_type_id, code, name, description) VALUES (2, 'mutation_consequence', 'Mutation consequence', 'Mutation consequence');
INSERT IGNORE INTO attrib_type (attrib_type_id, code, name, description) VALUES (3, 'DDD_Category', 'DDD category', 'DDD category');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (1, 1, 'monoallelic (autosome)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (2, 1, 'monoallelic (autosome; obligate mosaic)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (3, 1, 'biallelic');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (4, 1, 'monoallelic (X; heterozygous)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (5, 1, 'monoallelic (X; hemizygous)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (6, 1, 'monoallelic (Y)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (7, 1, 'mtDNA (homoplasmic)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (8, 1, 'mtDNA (heteroplasmic)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (9, 1, 'digenic (biallelic)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (10, 1, 'digenic (triallelic)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (11, 1, 'digenic (tetra-allelic)');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (12, 1, 'imprinted');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (13, 1, 'mosaic');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (14, 1, 'monoallelic');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (15, 1, 'hemizygous');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (16, 1, 'both');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (17, 1, 'digenic');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (18, 1, 'X-linked dominant');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (19, 1, 'uncertain');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (20, 2, '5_prime or 3_prime UTR mutation');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (21, 2, 'all missense/in frame');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (22, 2, 'cis-regulatory or promotor mutation');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (23, 2, 'dominant negative');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (24, 2, 'loss of function');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (25, 2, 'uncertain');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (26, 2, 'activating');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (27, 2, 'increased gene dosage');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (28, 2, 'part of contiguous gene duplication');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (29, 2, 'part of contiguous genomic interval deletion');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (30, 3, 'both DD and IF');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (31, 3, 'child IF');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (32, 3, 'confirmed DD gene');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (33, 3, 'IF Gene: Adult No Rx');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (34, 3, 'IF Gene: Adult Rx');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (35, 3, 'not DD Gene');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (36, 3, 'possible DD gene');
INSERT IGNORE INTO attrib (attrib_id, attrib_type_id, value) VALUES (37, 3, 'probable DD gene');
