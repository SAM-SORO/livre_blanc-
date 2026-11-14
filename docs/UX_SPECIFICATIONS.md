# UX_SPECIFICATIONS — Spécifications d'expérience utilisateur

| Champ | Valeur |
|---|---|
| Version | 1.0 — phase 4 (conception des interfaces), soumise à validation |
| Présentation | Conçue par Claude Code (direction d'interface validée par l'équipe à la tâche 0.8 du plan, skill `lbc-interface`). Les premières maquettes n'ont pas été retenues. |
| Charte de départ | `UI_DESIGN_SYSTEM.md` (révisable à la tâche 0.8) |
| Références | `PRD.md` v1.1 (personas §7.2, fonctionnalités §11, NF-30 à NF-33), `APP_FLOW.md` (plan des écrans, parcours), `API_SPECIFICATIONS.md` |

`APP_FLOW.md` dit quels écrans existent et comment on passe de l'un à l'autre. Ce document précise **ce que chaque écran clé doit permettre** : contenu, ordre d'importance, règles de saisie, états, textes. Il ne fixe pas la mise en forme : celle-ci relève de la direction d'interface. Les mentions de couleur ou de composant ci-dessous sont des indications, à reprendre ou à remplacer par la direction retenue.

---

## 1. Principes d'expérience

| Principe | Ce qu'il impose à l'interface |
|---|---|
| Contribuer doit être plus simple que se taire | Parcours mobile en sept écrans courts, un seul champ principal par écran, brouillon conservé sur l'appareil, aucune donnée demandée qui ne serve pas |
| Soutenir plutôt que répéter | Les contributions proches sont montrées **avant** la publication, avec « Soutenir celle-ci » comme première action |
| Montrer ce que devient la parole | Chaque contribution a une frise d'état ; chaque priorité a son fil de traçabilité |
| Expliquer les chiffres | Pas de score sans sa décomposition ; pas de carte sans tableau |
| L'administration décide, le système propose | Les suggestions (fusion, rattachement, classe) sont présentées comme telles, avec la donnée qui les justifie, et un bouton pour les ignorer |
| Neutralité | Aucun candidat n'est mis en avant : ordre alphabétique ou aléatoire stable, présentation identique pour tous |

## 2. Publics et contextes d'usage

| Persona (PRD §7.2) | Appareil et contexte | Conséquences |
|---|---|---|
| Awa, contributrice | Android d'entrée de gamme, réseau irrégulier, peu habituée aux formulaires | Version mobile installée, utilisable sans réseau pour contribuer (F-38) ; textes courts, aucun jargon |
| Kouassi, représentant d'association | Téléphone, parfois ordinateur d'un cybercafé | Choix « au nom de l'association » à la relecture ; consultations collectives transmises à l'administration |
| Mme Gnahoré, administratrice régionale | Ordinateur, longues sessions de traitement | Écrans denses en liste et détail, actions par lot, file de travail claire |
| M. Diabaté, administrateur national | Ordinateur, séances d'états généraux parfois projetées | Écran d'arbitrage lisible à distance (texte 15 px minimum, contrastes élevés), décisions motivées |
| Équipe d'un candidat | Ordinateur | Parcours court : lire, s'engager, suivre |
| Fatou, visiteuse | Téléphone ou ordinateur | Pages publiques indexables, liens partageables vers une priorité ou une contribution |

## 3. Version web et version mobile

L'équipe a fixé deux façons d'utiliser l'application (D-16) :

| | Version web | Version mobile |
|---|---|---|
| Accès | Navigateur, sur ordinateur, tablette ou téléphone | Installée sur le téléphone depuis le site |
| Réseau | Connexion nécessaire | Fonctionne sans réseau pour contribuer, voir ses envois et relire ce qui a déjà été ouvert (F-38) |
| Conception | Pensée d'abord pour l'ordinateur (portail, administration), et lisible sur un téléphone | Pensée pour le téléphone (à partir de 360 px), une main, un champ principal par écran |
| Publics | Tous | Contributeurs, surtout dans les zones à réseau irrégulier |

Mise en page de la version web selon la largeur :

| Largeur | Disposition |
|---|---|
| Plus de 1 024 px | Disposition de référence : pages publiques en colonnes ; administration avec menu latéral et liste-détail |
| 640 à 1 024 px | Colonnes réduites ; menu d'administration repliable |
| Moins de 640 px | Une colonne ; le portail reste consultable et le formulaire de contribution utilisable ; un bandeau propose d'installer la version mobile |

Largeur de lecture : 72 caractères au plus.

### 3.1 Règles propres à la version mobile sans réseau

- Un indicateur discret signale l'absence de réseau ; il disparaît au retour du réseau.
- Rien ne se perd : toute saisie est gardée sur le téléphone ; une contribution terminée passe « En attente d'envoi » et part seule au retour du réseau.
- Les actions qui exigent le serveur (soutenir, signaler, suggestions de contributions proches) ne sont pas proposées ; une phrase dit qu'elles reviendront avec le réseau.
- L'écran « En attente d'envoi » montre pour chaque contribution : son titre, sa date de rédaction, son état (en attente, envoyée avec sa référence, refusée avec le motif), et la date limite de la collecte.
- Les données affichées sans réseau indiquent leur date (« Mis à jour le 12 novembre à 18 h 40 »).

## 4. Écran : accueil du portail

**But.** Faire comprendre la démarche en une page et amener à contribuer.

**Ordre d'importance** (proposition).
1. En-tête : nom, navigation, « Se connecter », « Contribuer ».
2. Bandeau de phase (`ocre-100`) : une phrase qui dit où en est l'édition. Son texte dépend de la phase (§8).
3. Titre et promesse : « Le plan du pays commence par ce que vous demandez. », puis une phrase d'explication.
4. Deux actions : « Contribuer pour ma région » (principale), « Comprendre la démarche ».
5. Trois chiffres clés, chacun suivi de son libellé.
6. La participation des 33 territoires (sous une forme à concevoir : carte, cartogramme ou liste classée). Choisir un territoire montre son nom, ses contributions, le taux pour 10 000 habitants et le besoin le plus exprimé ; le même classement existe en tableau.
7. « De votre contribution à l'engagement d'un candidat » : les cinq étapes de la démarche.
8. « Ce qui revient le plus souvent » : les préoccupations qui réunissent le plus de personnes.

**Comportements.**
- Le choix d'un territoire est accessible au clavier et annoncé aux lecteurs d'écran.
- Toute animation est facultative, courte, et désactivée avec « réduire les animations ».
- Le bouton « Contribuer » mène à la connexion si nécessaire, puis revient au formulaire (§5).

## 5. Écrans : contribuer

### 5.1 Les sept étapes

| Étape | Question posée | Contenu | Validation |
|---|---|---|---|
| 1 | Où se trouve le problème ? | Recherche du lieu (sous-préfecture ou commune), lieu de résidence proposé par défaut ; localité précise facultative | Lieu sélectionnable obligatoire |
| 2 | De quoi s'agit-il ? | 14 secteurs illustrés ; suggestion mise en avant si un texte existe | Obligatoire |
| 3 | Qu'est-ce qui ne va pas ? | Titre court (10 à 120 caractères), constat (30 à 1 500) | Compteurs ; erreurs à la sortie du champ |
| 4 | Que proposez-vous ? | Proposition (20 à 1 500) | Compteur |
| 5 | C'est urgent ? | Quatre niveaux décrits en mots simples ; tranche de population facultative | Urgence obligatoire |
| 6 | Avez-vous des photos ? | Jusqu'à 3, compressées sur l'appareil avant l'envoi ; « Passer » bien visible | 5 Mo par photo, JPEG, PNG ou WebP |
| 7 | Relecture | Contributions proches, puis récapitulatif repliable, choix « à titre personnel » ou « au nom de [organisation] » si la personne en représente une | — |

Niveaux d'urgence affichés : « Peut attendre », « À traiter dans l'année », « Urgent », « Danger immédiat » (valeurs `FAIBLE` à `CRITIQUE`).

### 5.2 Règles transversales

- **Brouillon** : enregistré dans le navigateur à chaque changement d'étape ; mention « Brouillon enregistré » sous la progression ; reprise proposée au retour (« Reprendre votre contribution commencée le 12 novembre ? »).
- **Navigation** : « Retour » et « Continuer » fixés en bas de l'écran ; la touche retour du téléphone revient à l'étape précédente sans perte ; la croix « Quitter » garde le brouillon.
- **Contributions proches** : demandées dès que le constat est saisi (étape 3), affichées à l'étape 7 sans attente. Au plus 5. Si aucune n'est assez proche, l'écran passe directement au récapitulatif avec la phrase « Personne n'a encore décrit ce besoin dans votre région. ».
- **Publication** : bouton « Ma situation est différente, publier » quand des contributions proches existent, « Publier ma contribution » sinon. Pendant l'envoi, le bouton indique « Publication… » et reste désactivé. En cas de coupure : « La connexion a été interrompue. Votre contribution est gardée sur ce téléphone. » avec « Réessayer ».
- **Confirmation** : référence de la contribution, préoccupation de rattachement et nombre de personnes (« 54 personnes ont exprimé ce besoin dans le Gôh »), lien « Suivre ma contribution ».
- **Sans réseau (version mobile)** : l'étape 7 remplace les contributions proches par la phrase « Sans réseau, nous ne pouvons pas vous montrer les contributions semblables. Votre contribution sera regroupée avec elles à l'envoi. » ; le bouton devient « Garder pour l'envoi » et la confirmation « Contribution gardée : elle partira dès que le réseau reviendra. »
- **Hors collecte** : le formulaire n'est pas proposé ; une page explique la phase en cours et renvoie à l'avancement du livre blanc de la région.

## 6. Écran : priorité nationale et fil de traçabilité

**But.** Prouver qu'une priorité vient du terrain et montrer qui s'y engage.

**Contenu.** Classe et rang ; intitulé ; synthèse en Literata (registre de lecture) ; propositions retenues ; score national et sa décomposition (T, P, S) ; mini-cartogramme des territoires concernés ; engagements des candidats (tableau) ; panneau latéral « D'où vient cette priorité ? » avec le fil : priorité, livres blancs régionaux, préoccupations (liens), contributions.

**Règles.**
- Toutes les valeurs affichées viennent de la version publiée (contenu figé) ; la date et le numéro de version sont rappelés en bas du panneau.
- Les candidats sont listés dans un ordre neutre et stable ; les engagements retirés restent visibles avec la mention « Retiré le … ».
- Sur mobile, le panneau du fil passe sous la synthèse, avant les engagements.

## 7. Écrans d'administration

### 7.1 Préoccupations d'une région

- **Disposition** : barre latérale (territoire, menu avec compteurs de travail), bandeau de phase qui dit ce qui empêche la publication, puis liste et fiche côte à côte.
- **Liste** : filtres par statut (avec effectifs), secteur, tri par score ; la ligne choisie est surlignée `lagune-100`.
- **Fiche** : intitulé et synthèse modifiables ; jauge de score ; suggestion de fusion avec sa similarité et deux actions (« Fusionner ici », « Ignorer ») ; contributions rattachées avec leur mode de rattachement (automatique et similarité, ou manuel) et l'action « Déplacer » ; actions « Valider la préoccupation », « Scinder », « Écarter avec un motif ».
- **Enchaînement** : après validation, la fiche suivante de la liste filtrée s'ouvre ; un message bref confirme (« Préoccupation validée »).
- **Garde-fous** : écarter et fusionner ouvrent une confirmation qui rappelle l'effet (« Les 4 contributions rejoindront “Maternités du Gôh sous-équipées”. Leurs auteurs seront prévenus. ») ; une préoccupation verrouillée (livre blanc publié) affiche pourquoi et propose d'ouvrir une nouvelle version.
- **Écritures concurrentes** : si une autre personne a modifié la fiche, le message « Cette préoccupation a été modifiée par Mme N. à 10 h 42 » propose de recharger, sans perdre la saisie.

### 7.2 Arbitrage d'une convergence

- **Contenu** : statut et classe calculée ; intitulé ; tableau des préoccupations sources par territoire (score régional, personnes, cases à cocher pour scinder) ; cohésion du groupe ; synthèse et propositions consolidées modifiables ; jauge du score national ; mini-cartogramme ; formulaire de décision.
- **Décision** : quatre choix exclusifs (retenir, retenir et reclasser, fusionner, rejeter). Le champ « Motif » apparaît et devient obligatoire pour tout choix autre que « Retenir » ; il est publié en annexe.
- **Progression** : le bandeau indique combien de convergences restent à arbitrer ; « Convergence suivante » enchaîne ; une convergence de cohésion faible est signalée « à vérifier » dans la liste.
- **Projection en séance** : l'écran reste lisible projeté (pas de texte sous 15 px, contrastes élevés).

## 8. Textes de référence

### 8.1 Bandeau de phase (portail)

| Phase | Texte |
|---|---|
| `COLLECTE` | Édition 2030 : la collecte des contributions est ouverte dans les 33 territoires jusqu'au [date]. |
| `CONSOLIDATION_REGIONALE` | La collecte est terminée. Les régions préparent leurs livres blancs : [n] sur 33 sont publiés. |
| `ETATS_GENERAUX` | Les états généraux préparent le livre blanc national à partir de [n] livres blancs régionaux. |
| `ENGAGEMENTS` | Le livre blanc national est publié. Découvrez les engagements des candidats. |
| `SUIVI` | Suivez la réalisation des engagements des élus. |

### 8.2 Vocabulaire

| Dans l'administration et les livres blancs | Dans le parcours citoyen |
|---|---|
| UTR | votre région, votre district |
| Préoccupation | un besoin exprimé par plusieurs personnes |
| Voix | personnes qui ont exprimé ou soutenu ce besoin |
| Convergence, priorité nationale | priorité nationale |
| Modération, masquage | contribution mise de côté, avec le motif |

### 8.3 Messages types

| Situation | Message |
|---|---|
| Champ trop court | Décrivez le problème en 30 caractères au moins. |
| Limite quotidienne | Vous avez publié 10 contributions aujourd'hui. Vous pourrez en publier d'autres demain. |
| Courriel non vérifié | Confirmez d'abord votre adresse : nous vous avons envoyé un lien. Renvoyer le lien |
| Contribution mise de côté | Votre contribution « … » a été mise de côté car elle contient des données personnelles. Vous pouvez la modifier et la republier. |
| Liste vide (administration) | Aucune préoccupation à valider. Les nouvelles contributions apparaîtront ici. |
| Publication bloquée | 4 préoccupations sont encore à traiter. Voir la liste |

## 9. Règles communes aux autres écrans

- Chaque page a un seul titre de niveau 1 et un bouton principal au plus.
- Les listes publiques sont des lignes séparées par un trait, pas des cartes.
- Les tableaux d'administration ont un en-tête fixe, un tri par colonne et une pagination par curseur (« Afficher 20 de plus »).
- Les confirmations de suppression, de retrait ou de publication rappellent la conséquence et reprennent le verbe du bouton (« Publier », « Retirer »).
- Les écrans vides, de chargement et d'erreur suivent `APP_FLOW.md` §5.

## 10. Test d'utilisabilité prévu

Avant la soutenance, cinq à huit personnes extérieures au projet réalisent, sur téléphone et sur ordinateur, les tâches suivantes à partir du prototype et du jeu de démonstration. On note la réussite, le temps et les hésitations.

| Tâche | Persona | Critère de réussite |
|---|---|---|
| Déposer une contribution pour sa commune | Awa | Publiée en moins de 5 minutes, sans aide |
| Préparer une contribution sans réseau, puis vérifier qu'elle est partie | Awa (version mobile) | État « envoyée » retrouvé sans aide |
| Soutenir une contribution proche au lieu d'en créer une | Awa | Choix compris et effectué à l'étape de relecture |
| Retrouver ce qu'est devenue sa contribution | Awa | Frise d'état trouvée depuis « Mon espace » |
| Vérifier d'où vient une priorité nationale | Fatou | Au moins une contribution source ouverte depuis la priorité |
| Valider une préoccupation et fusionner deux préoccupations | Mme Gnahoré | Réalisé sans erreur, motif compris |
| Arbitrer une convergence en la reclassant | M. Diabaté | Motif saisi, décision enregistrée |

Les résultats alimenteront le chapitre V du rapport.
