-- Corpus de calibration : groupes de contributions rédigées différemment pour un même besoin.
DROP TABLE IF EXISTS calib;
CREATE TABLE calib(id int primary key, groupe text, titre text, corps text);
INSERT INTO calib VALUES
(1,'MATERNITE','Maternité sous-équipée à Gagnoa','La maternité du quartier manque de lits, de couveuses et de matériel d''accouchement. Équiper la maternité en lits, couveuses et matériel adapté.'),
(2,'MATERNITE','Maternité de Gagnoa : matériel insuffisant','Les femmes accouchent dans des conditions difficiles faute de matériel à la maternité. Doter la maternité de matériel moderne et de lits supplémentaires.'),
(3,'MATERNITE','Pas assez de lits pour les accouchements','À l''hôpital, les femmes enceintes dorment parfois par terre après l''accouchement. Il faut agrandir la maternité et acheter des lits et des couveuses.'),
(4,'EAU','Pas d''eau potable dans notre village','Les femmes parcourent plusieurs kilomètres pour chercher de l''eau au marigot, l''eau est sale. Construire un forage avec une pompe dans le village.'),
(5,'EAU','Accès difficile à l''eau potable à Oumé','Les quartiers périphériques ne sont pas raccordés au réseau d''eau, les coupures sont fréquentes. Étendre le réseau SODECI et installer des bornes fontaines.'),
(6,'EAU','Forage en panne depuis deux ans','L''unique pompe hydraulique du village est en panne, nous buvons l''eau du marigot. Réparer la pompe et construire un deuxième forage.'),
(7,'ROUTE','Route Gagnoa-Oumé impraticable','La route est pleine de nids-de-poule, les camions de cacao ne passent plus en saison des pluies. Bitumer la route et entretenir les ponts.'),
(8,'ROUTE','État dégradé des pistes rurales','Les pistes qui relient les villages aux marchés sont coupées pendant la saison des pluies. Reprofiler les pistes rurales et construire des ponceaux.'),
(9,'FORMATION','Manque de formation professionnelle pour les jeunes','Beaucoup de jeunes sortent de l''école sans métier et restent au chômage. Créer un centre de formation professionnelle aux métiers.'),
(10,'FORMATION','Pas de centre de formation aux métiers à Bayota','Les jeunes doivent partir à Gagnoa ou Abidjan pour apprendre un métier. Ouvrir un centre de formation en menuiserie, couture et mécanique.'),
(11,'PERSONNEL','Manque de médecins au centre de santé','Le centre de santé n''a qu''un infirmier pour tout le village, il n''y a pas de médecin. Affecter des médecins et des sages-femmes au centre de santé.'),
(12,'PERSONNEL','Centre de santé sans personnel qualifié','Les malades attendent des heures car le personnel soignant est insuffisant. Recruter des infirmiers et affecter un médecin permanent.');
