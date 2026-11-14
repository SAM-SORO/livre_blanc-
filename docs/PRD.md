# PRD — Livre Blanc Citoyen

> **Thème du projet :** Conception et réalisation d'une application web de gestion des livres blancs régionaux compilés en vue de l'établissement d'un livre blanc national : cas de la Côte d'Ivoire.

| Champ | Valeur |
|---|---|
| Document | Product Requirements Document (PRD) |
| Version | 1.2 — version web en ligne et version mobile hors connexion, 13 novembre 2026 ; voir l'historique en fin de document |
| Date | 12 novembre 2026 |
| Équipe projet | SORO Koromiwonah Segneniguetenin Samuel · AZOUASSI Ômonlôla Sara Océane · GLEDE Dekongnon Henri Joël · WOGNIN Noé Phinées — ING2 STIC, ESI / INP-HB |
| Encadreur | Dr APPOH (nom complet et titre à confirmer) |
| Nom de travail du produit | **Livre Blanc Citoyen** |
| Documents liés | `TRD.md`, `APP_FLOW.md`, `DATABASE_SCHEMA.md`, `API_SPECIFICATIONS.md`, `MERISE_TRAITEMENTS.md`, `UX_SPECIFICATIONS.md`, `UI_DESIGN_SYSTEM.md`, `IMPLEMENTATION_PLAN.md` |

**Convention de lecture.** Les identifiants servent de fil conducteur à tous les livrables :
`RG-xx` règle de gestion · `F-xx` fonctionnalité · `NF-xx` exigence non fonctionnelle · `D-xx` décision · `H-xx` hypothèse · `R-xx` risque · `Q-xx` question ouverte.
Les règles de gestion `RG` alimenteront directement le dictionnaire de données et le MCD MERISE du rapport.

---

## 1. Résumé

Livre Blanc Citoyen est une application web qui permet aux populations ivoiriennes, à titre individuel ou au travers de leurs organisations, d'exprimer leurs problèmes et leurs propositions de développement. Le système organise ces contributions par territoire et par secteur. Il détecte les contributions similaires, calcule des priorités et compose un livre blanc pour chaque région. Il propose ensuite une consolidation nationale, que les administrateurs arbitrent lors des états généraux, puis génère le livre blanc national en version web, PDF et Word.

Les candidats aux élections s'appuient sur ce document pour déclarer publiquement leurs engagements. Le suivi de ces engagements permet d'évaluer les élus en fin de mandat.

Le logiciel facilite et assiste le travail, mais **il ne décide pas** : chaque priorité retenue l'est par une décision humaine tracée.

---

## 2. Contexte et problème

### 2.1 Le constat

En période électorale, chaque candidat élabore un programme et un calendrier de projets. Une fois élu, il sollicite des financements auprès de bailleurs de fonds dont les conditions modifient souvent ce calendrier. Le résultat ne correspond pas toujours aux attentes les plus pressantes des populations.

### 2.2 L'idée : inverser le sens d'élaboration du plan

| Approche classique | Approche proposée |
|---|---|
| Les dirigeants définissent les orientations | Les populations expriment problèmes et propositions |
| Les programmes sont planifiés au sommet | Les contributions sont organisées par région (livres blancs régionaux) |
| Les populations bénéficient (ou non) des projets | Les livres blancs régionaux sont consolidés en livre blanc national |
| — | Les candidats s'engagent sur ce document et sont évalués sur ses réalisations |

### 2.3 Le problème que résout le logiciel

Mener cette démarche manuellement à l'échelle de la Côte d'Ivoire n'est pas réaliste. Il faudrait recueillir des dizaines de milliers de contributions, les classer, repérer les doublons et les besoins communs, les hiérarchiser, rédiger 33 documents régionaux puis un document national, tout en gardant la preuve de l'origine de chaque proposition.

Sans outil, trois défauts sont inévitables :
- **la perte de traçabilité :** on ne peut plus démontrer d'où vient une priorité nationale ;
- **la subjectivité du classement :** les priorités dépendent de la personne qui compile ;
- **la lenteur :** le document arrive après le début de la campagne électorale, quand il ne sert plus.

---

## 3. Vision, proposition de valeur et principes directeurs

**Vision.** Faire du livre blanc national un « appel d'offres citoyen » : un document construit par les populations, auquel les candidats répondent par des engagements publics et vérifiables.

**Proposition de valeur.** De la parole du village au schéma directeur national, chaque engagement peut être retracé jusqu'aux contributions qui l'ont fait naître.

**Principes directeurs** (ils tranchent les arbitrages de conception) :

| # | Principe | Conséquence concrète |
|---|---|---|
| P1 | **La voix d'abord** | Une contribution n'est jamais supprimée parce qu'elle ressemble à une autre. Elle est regroupée et compte comme une voix. |
| P2 | **La machine assiste, l'humain décide** | Regroupements, scores et consolidations sont des *propositions*. Leur adoption est un acte d'administrateur, journalisé. |
| P3 | **Traçabilité de bout en bout** | Tout élément publié est relié aux éléments qui l'ont produit, et une version publiée est figée. |
| P4 | **Équité territoriale** | Les scores sont normalisés par région et pondérés par la population, pour qu'une région très connectée n'écrase pas les autres. |
| P5 | **Calculs explicables** | Chaque score affiche le détail de son calcul, et la méthode figure en annexe des documents. |
| P6 | **Sobriété et simplicité** | L'interface reste utilisable sur un smartphone d'entrée de gamme avec une connexion lente, par des personnes peu familières du numérique. |
| P7 | **Neutralité** | Aucun parti, candidat ou institution n'est mis en avant par l'interface. Les engagements sont présentés de façon identique pour tous. |

---

## 4. Objectifs et indicateurs de succès

### 4.1 Objectifs (repris du sujet)

| Objectif | Traduction produit |
|---|---|
| OG — Réaliser un logiciel web de constitution d'un livre blanc national partant des populations | Chaîne complète, de la contribution au livre blanc national exporté |
| OS1 — Cibler les données par des procédés de recherche et d'acquisition | Formulaire guidé de contribution, import des consultations de terrain, recherche plein texte et filtres (F-30, F-35, F-104) |
| OS2 — Réaliser les modèles conceptuels et d'implémentation | Modèles MERISE (MCC, MCT, MOT, MCD, MLD, MPD) cohérents avec les règles de gestion de ce PRD |
| OS3 — Réaliser un prototype d'application | Application Nuxt fonctionnelle en local, avec un jeu de données de démonstration |
| R1 — Une base de données de livres blancs constituée | Base PostgreSQL contenant éditions, contributions, préoccupations et versions de livres blancs |
| R2 — Inférer et générer un livre blanc national à partir des régionaux | Moteur de consolidation (§10) et générateur de documents (F-80) |
| R3 — Interfaces web réalisées | Portail public, espace contributeur, back-office des administrateurs |

### 4.2 Critères de réussite du prototype

- **CS1 :** le scénario de démonstration complet (§14.3) s'exécute de bout en bout sans manipulation en base de données.
- **CS2 :** pour toute priorité du livre blanc national, on remonte en trois clics au plus jusqu'aux contributions d'origine.
- **CS3 :** sur le jeu de démonstration, au moins 80 % des paires de contributions doublons, étiquetées à la main, sont signalées par le système (rappel ≥ 0,8).
- **CS4 :** le livre blanc national (PDF et DOCX) est généré en moins de 60 secondes sur le poste de démonstration.
- **CS5 :** un utilisateur novice dépose une contribution en moins de 5 minutes sans aide (test avec au moins 5 personnes).

### 4.3 Indicateurs de suivi (en exploitation réelle, hors périmètre de l'évaluation académique)

- Taux de participation par région, en contributions pour 10 000 habitants.
- Part des contributions d'organisations.
- Répartition par sexe et par tranche d'âge des contributeurs (indicateur de représentativité).
- Délai entre la clôture de la collecte et la publication du livre blanc national.
- Taux de réalisation des engagements par élu.

---

## 5. Glossaire métier

Ce vocabulaire est **normatif** : il s'impose aux interfaces, au code (en anglais, voir la correspondance dans le TRD), à la base de données et au rapport.

| Terme | Définition |
|---|---|
| **Édition** | Cycle complet d'élaboration d'un livre blanc, rattaché à une échéance électorale (exemple : « Édition 2030 »). Elle traverse des phases successives (§8.1). |
| **Unité territoriale de rédaction (UTR)** | Territoire pour lequel est produit un livre blanc régional : chacune des 31 régions et chacun des 2 districts autonomes (Abidjan, Yamoussoukro). Total : 33 (voir §6). |
| **Contributeur** | Personne physique inscrite qui dépose des contributions ou soutient celles des autres. |
| **Organisation** | Personne morale (association, ONG, collectivité territoriale, organisation professionnelle, coopérative, autre) représentée sur la plateforme par un contributeur désigné. |
| **Contribution** | Expression d'un problème (*constat*) et d'une solution souhaitée (*proposition*), localisée et rattachée à un secteur. C'est l'unité de base du système. |
| **Soutien** | Adhésion d'un contributeur à une contribution existante (« j'ai le même problème »). Un soutien compte comme une voix, sans créer de nouveau texte. |
| **Voix** | Unité de comptage de l'expression populaire : une contribution ou un soutien, à raison d'une seule voix par personne et par préoccupation. |
| **Secteur** | Domaine de développement (santé, éducation, eau…), issu d'un référentiel administrable. |
| **Préoccupation (régionale)** | Groupe de contributions similaires d'une même UTR et d'un même secteur, doté d'un intitulé, d'une synthèse, de propositions et d'un score de priorité. C'est l'unité qui apparaît dans le livre blanc régional. |
| **Score de priorité régional** | Indicateur de 0 à 100 calculé pour chaque préoccupation (§10.3). |
| **Livre blanc régional (LBR)** | Document d'une UTR pour une édition, composé à partir de ses préoccupations. Il existe en versions successives ; une version publiée est figée. |
| **Convergence** | Groupe de préoccupations régionales similaires provenant d'une ou plusieurs UTR, proposé par le système lors de la consolidation nationale. |
| **Priorité nationale / partagée / spécificité régionale** | Classement d'une convergence retenue, selon le nombre d'UTR concernées (§10.4). |
| **États généraux** | Phase de concertation pendant laquelle l'administration nationale examine les convergences proposées et les retient, fusionne ou rejette. Chaque décision est tracée. |
| **Livre blanc national (LBN)** | Document consolidé de l'édition. C'est le schéma directeur national issu des populations. |
| **Engagement** | Déclaration publique d'un candidat portant sur une priorité du LBN (présidentielle) ou sur une préoccupation d'un LBR (régionales). |
| **Suivi de réalisation** | Historique des états d'avancement d'un engagement, avec ses justificatifs. |

---

## 6. Périmètre territorial (Côte d'Ivoire)

### 6.1 Hiérarchie retenue

```
District (14, dont 2 autonomes)
 └─ Région (31) ............................ UTR — livre blanc régional
     └─ Département
         └─ Sous-préfecture / Commune ...... maille minimale obligatoire d'une contribution
             └─ Localité (village, quartier) .. texte libre facultatif
District autonome (Abidjan, Yamoussoukro) .. UTR — livre blanc régional
```

### 6.2 Points d'attention

- **Le dénombrement officiel varie selon les sources et les années.** Un communiqué gouvernemental relayé par Abidjan.net fait état de 31 régions, 107 départements et 510 sous-préfectures ; d'autres sources citent 108 départements, 509 sous-préfectures et 201 ou 204 communes. **Décision D-07 :** le référentiel territorial n'est jamais codé en dur. Il est importé (CSV) et administrable, avec une date de validité.
- **Les districts autonomes ne font partie d'aucune région.** Abidjan, qui concentre une part importante de la population, doit donc avoir son propre livre blanc. Sinon, ses habitants n'auraient aucun document de rattachement.
- **La population de chaque UTR** est nécessaire à la pondération nationale (§10.4). Elle sera saisie à partir des résultats publiés du RGPH 2021 (Institut National de la Statistique) et restera modifiable (H-04).
- Le jeu de démonstration couvrira l'intégralité des 33 UTR pour le référentiel, mais des contributions sur un sous-ensemble seulement (H-05).

---

## 7. Acteurs, rôles et personas

### 7.1 Rôles

| Rôle | Qui ? | Périmètre | Responsabilités principales |
|---|---|---|---|
| **Visiteur** | Tout internaute non connecté | National | Consulte le portail public, les livres blancs publiés, la carte, les engagements |
| **Contributeur** | Personne physique inscrite (18 ans et plus, voir D-09) | National | Dépose, modifie ou retire ses contributions, soutient celles des autres, suit leur devenir, signale un contenu |
| **Représentant d'organisation** | Contributeur rattaché à une organisation | National | Dépose des contributions *au nom de* l'organisation et gère la fiche de l'organisation |
| **Administrateur régional** | Agent désigné pour une UTR | Une ou plusieurs UTR | Modère, traite les doublons, valide les préoccupations, importe les consultations de terrain, compose et publie le LBR, vérifie les organisations de son territoire |
| **Administrateur national** | Secrétariat de l'autorité de gouvernance | National | Gère les référentiels, les éditions et les comptes d'administration ; conduit les états généraux ; publie le LBN ; valide les candidats ; renseigne le suivi des réalisations |
| **Candidat** | Candidat déclaré (ou son équipe), compte créé par l'administrateur national | Selon l'élection | Consulte les livres blancs, déclare et commente ses engagements |

Un même compte peut cumuler plusieurs rôles. Par exemple, un administrateur régional peut aussi être contributeur, mais il ne peut pas modérer ses propres contributions (RG-44).

Le rôle d'**observateur indépendant** (société civile, presse), qui renseignerait le suivi, est reporté en évolution (§14.2).

### 7.2 Personas (fictifs)

**Awa, 34 ans, commerçante à Gagnoa (Gôh).** Elle a un smartphone Android d'entrée de gamme et une connexion mobile irrégulière. Elle n'a jamais rempli de formulaire administratif en ligne. Elle veut signaler que la maternité de son quartier manque d'équipements. *Besoins :* un formulaire court en français simple ; savoir que d'autres ont dit la même chose ; être informée de ce que devient sa contribution.

**L'Association des jeunes d'Oumé, représentée par Kouassi, 27 ans.** L'association a tenu une réunion avec 60 jeunes au sujet de la formation professionnelle. *Besoins :* déposer une contribution collective qui pèse davantage qu'un avis isolé ; une fiche d'organisation reconnue (« vérifiée »).

**Mme Gnahoré, administratrice régionale du Gôh.** Elle traite plusieurs centaines de contributions en quelques semaines. *Besoins :* une file de travail claire ; des suggestions de doublons et de regroupements qu'elle accepte d'un clic ; un livre blanc régional généré automatiquement qu'elle n'a qu'à relire.

**M. Diabaté, administrateur national (secrétariat des états généraux).** *Besoins :* voir d'un coup d'œil les besoins communs à plusieurs régions ; arbitrer rapidement ; produire un document national présentable et justifiable devant la presse.

**L'équipe d'un candidat à l'élection présidentielle.** *Besoins :* comprendre les priorités par région ; déclarer des engagements précis ; publier les avancées pendant le mandat.

**Fatou, étudiante en journalisme (visiteuse).** *Besoins :* vérifier qu'une priorité nationale correspond réellement à des demandes de terrain ; comparer les engagements des candidats.

### 7.3 Matrice des droits (synthèse)

Légende : ● autorisé · ◐ autorisé dans son périmètre ou sur ses propres objets · — interdit

| Action | Visiteur | Contributeur | Admin régional | Admin national | Candidat |
|---|---|---|---|---|---|
| Consulter les livres blancs publiés, la carte, les engagements | ● | ● | ● | ● | ● |
| Consulter les contributions publiées (sans données personnelles) | ● | ● | ● | ● | ● |
| Déposer, modifier ou retirer une contribution | — | ◐ | ◐ (à titre personnel) | ◐ (à titre personnel) | — |
| Soutenir, signaler | — | ● | ● | ● | — |
| Modérer, traiter les doublons, gérer les préoccupations | — | — | ◐ | ● | — |
| Importer des contributions de terrain | — | — | ◐ | ● | — |
| Composer et publier un LBR | — | — | ◐ | ● | — |
| Vérifier une organisation | — | — | ◐ (siège dans son UTR) | ● | — |
| Conduire les états généraux, publier le LBN | — | — | — | ● | — |
| Gérer les référentiels, éditions et comptes d'administration | — | — | — | ● | — |
| Déclarer un engagement | — | — | — | — | ◐ |
| Renseigner le suivi d'un engagement | — | — | — | ● | ◐ (commentaire seulement) |
| Consulter le journal d'audit | — | — | ◐ | ● | — |

---

## 8. Processus métier

### 8.1 Phases d'une édition

| Phase | Code | Ce qui se passe | Déclencheur de sortie |
|---|---|---|---|
| Préparation | `PREPARATION` | Paramétrage : dates, secteurs, pondérations, comptes d'administration | Ouverture manuelle par l'admin national |
| Collecte | `COLLECTE` | Dépôt de contributions et de soutiens ; regroupement automatique en continu ; modération a posteriori ; imports de terrain | Date de fin atteinte, ou clôture manuelle |
| Consolidation régionale | `CONSOLIDATION_REGIONALE` | Chaque admin régional finalise ses préoccupations, puis compose et publie son LBR | Admin national, quand les LBR attendus sont publiés (RG-61) |
| États généraux | `ETATS_GENERAUX` | Le système propose les convergences ; l'admin national arbitre ; le LBN est composé | Publication du LBN |
| Publication et engagements | `ENGAGEMENTS` | LBN public ; les candidats déclarent leurs engagements | Date de l'élection, saisie par l'admin national |
| Suivi du mandat | `SUIVI` | Les élus sont identifiés ; le suivi des réalisations est renseigné | Clôture manuelle en fin de mandat |
| Clôturée | `CLOTUREE` | Édition archivée, consultable en lecture seule | — |

Les phases s'enchaînent dans cet ordre. Le retour en arrière est interdit, sauf pour réouvrir la collecte avant la clôture de la consolidation régionale (RG-03).

### 8.2 Chaîne de traitement

1. **Collecte.** Le contributeur dépose une contribution. Avant l'envoi, le système lui présente les contributions proches de la même UTR et lui propose de les soutenir plutôt que d'en créer une nouvelle (F-32). La contribution est publiée immédiatement (D-02).
2. **Regroupement automatique.** À chaque dépôt, le système rattache la contribution à la préoccupation la plus proche de la même UTR et du même secteur si la similarité dépasse le seuil. Sinon, il crée une préoccupation *proposée* (§10.2).
3. **Traitement régional.** L'administrateur régional :
   - retire les doublons stricts (même auteur, même contenu) ;
   - fusionne les préoccupations redondantes ;
   - corrige les rattachements ;
   - valide les préoccupations en leur donnant un intitulé et une synthèse.
4. **Composition du LBR.** Le système génère le document. L'administrateur relit, complète l'introduction, renseigne la validation (date et lieu de l'atelier, procès-verbal facultatif), puis publie.
5. **Consolidation nationale.** Le système compare les préoccupations de toutes les UTR et propose des convergences classées (§10.4).
6. **États généraux.** L'administrateur national retient, fusionne, scinde ou rejette chaque convergence, avec un motif obligatoire pour les rejets.
7. **Composition et publication du LBN**, avec exports PDF et DOCX.
8. **Engagements.** Les candidats déclarent leurs engagements ; l'administrateur national renseigne ensuite le suivi des réalisations.

### 8.3 Cycles de vie

**Contribution**
```
PUBLIEE ──(signalée ou filtre automatique)──> EN_MODERATION ──> PUBLIEE | MASQUEE
PUBLIEE ──(retrait par l'auteur, pendant la collecte)──> RETIREE_AUTEUR
PUBLIEE ──(retrait par un admin : doublon strict, hors sujet)──> RETIREE_ADMIN
* ──(clôture de l'édition)──> ARCHIVEE   (le statut précédent est conservé dans l'historique)
```
Le *rattachement* à une préoccupation est indépendant du statut : une contribution `PUBLIEE` est toujours rattachée à exactement une préoccupation (RG-24).

**Préoccupation**
```
PROPOSEE (créée par le système) ──> VALIDEE (admin régional : intitulé et synthèse vérifiés)
PROPOSEE | VALIDEE ──> FUSIONNEE (absorbée par une autre préoccupation de la même UTR)
PROPOSEE | VALIDEE ──> ECARTEE (motif obligatoire ; ses contributions restent consultables)
```

**Version de livre blanc (régional ou national)**
```
BROUILLON ──(publication)──> PUBLIEE ──(publication d'une version suivante)──> REMPLACEE
```
Une seule version peut être `BROUILLON` à la fois, et une seule `PUBLIEE` à la fois, par livre blanc.

**Convergence (états généraux)**
```
PROPOSEE ──> RETENUE | FUSIONNEE | REJETEE
```

**Engagement**
```
DECLARE ──(retrait par le candidat avant la date de l'élection)──> RETIRE
DECLARE ──(phase SUIVI, candidat élu)──> états de suivi successifs :
          NON_DEMARRE → EN_COURS → REALISE | PARTIELLEMENT_REALISE | ABANDONNE
```

---

## 9. Règles de gestion

### 9.1 Éditions et référentiels

- **RG-01.** Une seule édition peut être active (phase autre que `PREPARATION` ou `CLOTUREE`) à un instant donné.
- **RG-02.** Le référentiel des secteurs et les pondérations de scores d'une édition sont modifiables uniquement en phase `PREPARATION`. Ils sont ensuite figés pour garantir la reproductibilité des calculs.
- **RG-03.** Les phases s'enchaînent dans l'ordre du §8.1. Seule la réouverture de la collecte est permise, et uniquement tant qu'aucun LBR de l'édition n'est publié.
- **RG-04.** Toute unité territoriale appartient à exactement une unité de niveau supérieur, sauf les districts.
- **RG-05.** Une UTR est soit une région, soit un district autonome. Chaque UTR possède une population de référence strictement positive avant l'ouverture de la phase `ETATS_GENERAUX`.
- **RG-06.** Un secteur ne peut pas être supprimé s'il est utilisé ; il peut seulement être désactivé.

### 9.2 Comptes et organisations

- **RG-10.** L'inscription exige : nom, prénoms, adresse e-mail unique, mot de passe, année de naissance, lieu de résidence (maille la plus fine disponible du référentiel : sous-préfecture ou commune, à défaut département), acceptation de la charte et consentement au traitement des données. Le téléphone et le sexe sont facultatifs.
- **RG-11.** Un compte ne peut contribuer qu'après vérification de son adresse e-mail.
- **RG-12.** Le contributeur doit avoir 18 ans à la date d'inscription (D-09). Seule l'année de naissance étant collectée (NF-21), le contrôle porte sur l'année : année de naissance ≤ année d'inscription − 18. Une personne qui aura 18 ans plus tard dans l'année civile peut donc s'inscrire ; cette approximation est assumée.
- **RG-13.** Les comptes d'administration et de candidat sont créés exclusivement par l'administrateur national ; ils ne sont pas accessibles par l'inscription publique.
- **RG-14.** Une organisation a exactement un représentant principal. Un contributeur représente au plus une organisation (MVP).
- **RG-15.** Une organisation est d'abord `NON_VERIFIEE`. Seul un administrateur de l'UTR de son siège, ou l'administrateur national, peut la passer à `VERIFIEE`. Une organisation non vérifiée peut contribuer, mais ne compte pas dans la composante « portée collective » du score (§10.3).
- **RG-16.** La suppression d'un compte à la demande de son titulaire anonymise ses données personnelles. Ses contributions et soutiens sont conservés sans lien vers une identité, pour ne pas altérer les livres blancs publiés.
- **RG-17.** Après 5 échecs de connexion consécutifs, le compte est verrouillé pendant 15 minutes.

### 9.3 Contributions et soutiens

- **RG-20.** Une contribution ne peut être déposée que pendant la phase `COLLECTE` de l'édition active.
- **RG-21.** Une contribution comporte obligatoirement : un titre (10 à 120 caractères), un constat (30 à 1 500 caractères), une proposition (20 à 1 500 caractères), un secteur, un lieu concerné choisi à la maille la plus fine disponible du référentiel (sous-préfecture ou commune ; à défaut, département), et un niveau d'urgence perçue (`FAIBLE`, `MOYENNE`, `ELEVEE`, `CRITIQUE`). La localité précise, la tranche de population concernée et jusqu'à 3 photos sont facultatives.
- **RG-22.** L'UTR d'une contribution est déduite du lieu concerné. Elle peut différer de la résidence du contributeur, et cette différence est enregistrée.
- **RG-23.** Une contribution est déposée soit à titre personnel, soit au nom de l'organisation que le contributeur représente.
- **RG-24.** Toute contribution `PUBLIEE` ou `EN_MODERATION` est rattachée à exactement une préoccupation de la même UTR et du même secteur.
- **RG-25.** L'auteur peut modifier ou retirer sa contribution tant que la phase `COLLECTE` est ouverte. Chaque modification est historisée, et un changement de secteur ou de lieu provoque un nouveau rattachement automatique.
- **RG-26.** Un contributeur ne peut pas déposer plus de 10 contributions par jour (valeur paramétrable).
- **RG-27.** Un contributeur soutient au plus une fois une même contribution, ne peut pas soutenir sa propre contribution, et peut retirer son soutien pendant la collecte.
- **RG-28.** Les contributions importées depuis une consultation de terrain (F-35) n'ont pas de compte auteur. Elles portent la référence de la consultation (lieu, date, nombre de participants) et la mention de l'administrateur qui les a importées. L'import est possible pendant les phases `COLLECTE` et `CONSOLIDATION_REGIONALE`, pour tenir compte des comptes rendus d'ateliers qui arrivent après la clôture de la collecte en ligne.
- **RG-29.** Sur le portail public, une contribution individuelle est attribuée à « Citoyen·ne de *[commune ou sous-préfecture]* », sauf si l'auteur choisit d'afficher son nom. Une contribution d'organisation affiche le nom de l'organisation.
- **RG-30.** Une contribution préparée hors connexion dans la version mobile (F-38) n'est enregistrée qu'à sa réception par le serveur : les règles RG-20 à RG-26 s'appliquent à ce moment-là. Si la collecte s'est terminée entre-temps, l'envoi est refusé et la contribution reste sur l'appareil, avec un message qui l'explique. Un identifiant attribué par l'appareil garantit qu'un nouvel envoi de la même contribution ne crée pas de doublon.

### 9.4 Modération et doublons

- **RG-40.** Une contribution est publiée dès son dépôt. Elle passe `EN_MODERATION` si le filtre automatique (liste de termes interdits) la signale, ou si elle reçoit au moins 3 signalements distincts. Ces deux seuils sont paramétrables.
- **RG-41.** Seul un administrateur peut masquer ou retirer une contribution, avec un motif choisi dans une liste (`HORS_CHARTE`, `HORS_SUJET`, `DOUBLON_STRICT`, `DONNEES_PERSONNELLES`, `AUTRE`) et un commentaire. L'auteur est notifié.
- **RG-42.** **Doublon strict** : deux contributions du même auteur dont la similarité dépasse le seuil de doublon. Seul un doublon strict peut être retiré pour motif de doublon. Deux contributions d'auteurs différents décrivant le même problème ne sont **jamais** des doublons à retirer : elles sont regroupées dans la même préoccupation (principe P1, décision D-03).
- **RG-43.** La fusion de préoccupations transfère toutes les contributions de la préoccupation absorbée vers la préoccupation cible. La préoccupation absorbée devient `FUSIONNEE` et conserve un lien vers sa cible.
- **RG-44.** Un administrateur ne peut pas modérer une contribution dont il est l'auteur.
- **RG-45.** Toute action de modération, de fusion, de rattachement manuel ou d'écartement est inscrite au journal d'audit avec son auteur, sa date, l'état avant et après, et son motif.

### 9.5 Préoccupations et livres blancs régionaux

- **RG-50.** Une préoccupation appartient à exactement une UTR, un secteur et une édition.
- **RG-51.** Le nombre de voix d'une préoccupation est le nombre de personnes distinctes (auteurs et soutiens), plus les contributions importées de terrain, chacune comptant pour une voix pondérée par son nombre de participants (D-10). Une même personne ne compte qu'une fois par préoccupation.
- **RG-52.** Une préoccupation `ECARTEE` ou `FUSIONNEE` ne figure pas dans le corps du LBR. Les préoccupations écartées sont listées en annexe avec leur motif.
- **RG-53.** Un LBR ne peut être publié que si l'édition est en phase `CONSOLIDATION_REGIONALE`, qu'aucune contribution de l'UTR n'est `EN_MODERATION`, et que toutes ses préoccupations sont `VALIDEE`, `FUSIONNEE` ou `ECARTEE`.
- **RG-54.** La publication fige la version : contenu, scores, pondérations et liens vers les préoccupations et contributions sont enregistrés tels qu'au moment de la publication. Une correction ultérieure crée une nouvelle version, avec un résumé des changements obligatoire.
- **RG-55.** La publication d'un LBR exige la date de la validation régionale (atelier ou réunion). Le lieu et le procès-verbal (PDF) sont facultatifs.
- **RG-56.** La publication d'un LBR verrouille les préoccupations de son UTR : elles ne peuvent plus être modifiées, fusionnées ni recevoir de nouvelles contributions par déplacement. La création d'une nouvelle version du LBR les déverrouille ; sa publication les verrouille de nouveau. Une contribution de terrain importée pendant le verrouillage forme une nouvelle préoccupation, traitée dans la version suivante.

### 9.6 Consolidation nationale et livre blanc national

- **RG-60.** La consolidation nationale ne prend en compte que les préoccupations des versions **publiées** des LBR.
- **RG-61.** La phase `ETATS_GENERAUX` peut être ouverte si au moins 80 % des UTR ont publié leur LBR (seuil paramétrable). Les UTR manquantes sont mentionnées explicitement dans le LBN.
- **RG-62.** Une préoccupation régionale appartient à au plus une convergence retenue.
- **RG-63.** Le rejet ou la fusion d'une convergence exige un motif, journalisé.
- **RG-64.** Le classement d'une convergence retenue (`NATIONALE`, `PARTAGEE`, `SPECIFIQUE`) est calculé (§10.4). L'administrateur national peut le modifier, avec un motif.
- **RG-65.** Le LBN est publié par l'administrateur national seul. Les règles de figement RG-54 s'appliquent.

### 9.7 Candidats et engagements

- **RG-70.** Un candidat est rattaché à une édition et à un type d'élection (`PRESIDENTIELLE` ou `REGIONALE` dans le MVP). Un candidat aux régionales est rattaché à une UTR.
- **RG-71.** Un candidat à la présidentielle s'engage sur des priorités du LBN publié. Un candidat aux régionales s'engage sur des préoccupations du LBR publié de son UTR.
- **RG-72.** Un engagement comporte une échéance (année) et un texte d'engagement (20 à 1 000 caractères). Un candidat ne prend qu'un engagement par élément du livre blanc.
- **RG-73.** Un engagement peut être retiré par le candidat jusqu'à la date de l'élection. Au-delà, il est définitif. Les engagements retirés restent visibles comme tels.
- **RG-74.** En phase `SUIVI`, seuls les engagements des candidats marqués `ELU` font l'objet d'un suivi. Chaque mise à jour du suivi exige un état, une date, une description et au moins un justificatif (lien ou fichier). L'historique est conservé.
- **RG-75.** Le taux de réalisation d'un élu = (réalisés + 0,5 × partiellement réalisés) / engagements suivis.

---

## 10. Moteur d'analyse (spécification fonctionnelle)

Le moteur répond à l'attente « inférer et générer ». Il est **déterministe et explicable** dans le MVP (D-05). Le TRD précisera les algorithmes et les index ; ce chapitre définit le comportement attendu.

### 10.1 Similarité textuelle

- **Texte comparé :** titre, constat et proposition, normalisés (minuscules, accents retirés, mots vides français retirés).
- **Mesure :** similarité de 0 à 1, calculée par la base de données. C'est la moyenne de deux indicateurs : la part de racines de mots communes (après retrait des mots vides et réduction des mots à leur racine, par exemple « équipements » et « équiper » → « equip ») et la similarité par trigrammes de caractères, qui tolère les fautes de frappe. La version 1.0 ne prévoyait que les trigrammes ; les essais de calibration ont montré que cette mesure seule sépare mal les reformulations (voir `DATABASE_SCHEMA.md` §6).
- **Seuils initiaux**, paramétrables par édition et à recalibrer sur le jeu de démonstration (CS3) :

| Usage | Seuil initial | Portée |
|---|---|---|
| Suggestion au contributeur avant dépôt (F-32) | 0,20 | Même UTR (et même secteur, si choisi) |
| Rattachement automatique à une préoccupation | 0,30 | Même UTR et même secteur |
| Suspicion de doublon strict | 0,60 | Même auteur |
| Rapprochement inter-régional (convergence) | 0,28 | Même secteur, UTR différentes |

### 10.2 Regroupement en préoccupations

1. À chaque dépôt (ou modification de secteur ou de lieu), le système calcule la similarité de la contribution avec la contribution *représentative* de chaque préoccupation non écartée de la même UTR et du même secteur.
2. Si le meilleur score atteint le seuil de rattachement, la contribution est rattachée à cette préoccupation. Sinon, une nouvelle préoccupation `PROPOSEE` est créée, avec pour intitulé provisoire le titre de la contribution.
3. La contribution représentative d'une préoccupation est celle qui a le plus de soutiens ; en cas d'égalité, la plus ancienne.
4. L'administrateur régional dispose de suggestions de **fusion de préoccupations** : les paires de préoccupations de la même UTR et du même secteur dont les représentatives dépassent le seuil de rattachement.
5. Les rattachements manuels ne sont jamais défaits par un recalcul automatique.

### 10.3 Score de priorité régional

Pour une préoccupation *P* de l'UTR *R* :

```
Score_R(P) = 100 × ( 0,40·V + 0,25·U + 0,20·E + 0,15·C )

V  (voix)            = ln(1 + voix(P)) / ln(1 + max des voix parmi les préoccupations de R)
U  (urgence)         = (moyenne des urgences – 1) / 3      avec FAIBLE=1 … CRITIQUE=4
E  (étendue)         = départements de R concernés par P / nombre de départements de R
                       (pour un district autonome : sous-préfectures ou communes concernées / total)
C  (portée collective) = min(1, organisations vérifiées distinctes ayant contribué à P / 3)
```

- La normalisation logarithmique des voix limite l'effet d'une mobilisation massive sur un seul sujet. La normalisation *par UTR* rend les scores comparables d'une région à l'autre.
- Les pondérations (0,40 / 0,25 / 0,20 / 0,15) et le diviseur de C (3) sont des **valeurs par défaut** que l'administrateur national peut modifier en phase `PREPARATION` (RG-02). Elles figurent en annexe de chaque livre blanc.
- Chaque fiche de préoccupation affiche la décomposition de son score (principe P5).

### 10.4 Consolidation nationale

1. **Candidates :** toutes les préoccupations `VALIDEE` des LBR publiés.
2. **Regroupement :** dans chaque secteur, le système regroupe les préoccupations de différentes UTR dont la similarité dépasse le seuil inter-régional (regroupement par liens successifs). Une préoccupation sans voisine forme une convergence à elle seule. Comme les liens successifs peuvent réunir deux préoccupations peu semblables par l'intermédiaire d'une troisième, chaque convergence porte un indicateur de **cohésion** (moyenne des similarités entre toutes ses préoccupations) ; une cohésion faible la signale « à vérifier » lors de l'arbitrage.
3. **Score national** d'une convergence *K* :

```
Score_N(K) = 100 × ( 0,45·T + 0,30·P + 0,25·S )

T = nombre d'UTR concernées / nombre d'UTR couvertes par un LBR publié
P = population des UTR concernées / population totale des UTR couvertes
S = moyenne des Score_R des préoccupations de K / 100
```

4. **Classement proposé :**
   - `NATIONALE` si au moins 5 UTR sont concernées (seuil paramétrable) ;
   - `PARTAGEE` de 2 à 4 UTR ;
   - `SPECIFIQUE` pour 1 UTR. Seules les 3 premières spécificités de chaque UTR (par Score_R) sont reprises dans le LBN, et les autres restent dans les LBR.
5. **Proposition de texte :** l'intitulé proposé est celui de la préoccupation au Score_R le plus élevé. La synthèse proposée liste les propositions des préoccupations sources, classées par score et dédoublonnées. L'administrateur national réécrit librement.
6. **Assistance par modèle de langage (optionnelle, désactivée par défaut, D-05) :** rédaction d'un projet de synthèse à partir des propositions sources. Le texte généré est marqué « proposition automatique » jusqu'à sa validation humaine.

---

## 11. Fonctionnalités détaillées

Priorités : **M** = indispensable au MVP · **S** = prévu au MVP si le planning le permet · **É** = évolution.

### M1 — Comptes, inscription et connexion

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-10 | Inscription d'une personne physique (RG-10, RG-12), avec contrôle des champs à la saisie | M |
| F-11 | Vérification de l'adresse e-mail par lien à usage unique (validité 24 h) | M |
| F-12 | Connexion par e-mail et mot de passe ; déconnexion ; verrouillage temporaire (RG-17) | M |
| F-13 | Mot de passe oublié (lien de réinitialisation valable 1 h) | M |
| F-14 | Profil : modification des informations, préférences d'affichage du nom (RG-29), export de ses données, suppression du compte (RG-16) | M |
| F-15 | Création et rattachement d'une organisation par un contributeur (il en devient le représentant) | M |
| F-16 | Création des comptes d'administration et de candidat par l'admin national, avec invitation par e-mail | M |

**Critères d'acceptation (extraits)**
- *Étant donné* un visiteur qui s'inscrit avec un e-mail déjà utilisé, *quand* il valide, *alors* un message neutre l'invite à se connecter ou à réinitialiser son mot de passe, sans révéler l'existence du compte.
- *Étant donné* un compte non vérifié, *quand* il tente de contribuer, *alors* il est redirigé vers un écran proposant de renvoyer l'e-mail de vérification.
- *Étant donné* une année de naissance donnant moins de 18 ans, *quand* l'utilisateur valide, *alors* l'inscription est refusée avec un message expliquant que les jeunes peuvent s'exprimer via une organisation de jeunesse.

### M2 — Référentiels et éditions (admin national)

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-20 | Import CSV et consultation du référentiel territorial (districts, régions, départements, sous-préfectures et communes), avec population des UTR | M |
| F-21 | Gestion des secteurs : libellé, description, icône, ODD de rattachement indicatif, mots-clés d'aide au classement, activation | M |
| F-22 | Création d'une édition : nom, échéance électorale, dates prévues des phases, paramètres (seuils §10.1, pondérations §10.3 et §10.4, limites RG-26 et RG-40) | M |
| F-23 | Passage d'une phase à la suivante, avec contrôle des préconditions et écran de confirmation listant leurs effets | M |
| F-24 | Gestion de la liste de termes du filtre de modération | S |

**Référentiel initial des secteurs** (proposition modifiable ; le rattachement aux ODD est indicatif) :

| Secteur | ODD indicatif |
|---|---|
| Santé | 3 |
| Éducation et formation | 4 |
| Eau potable et assainissement | 6 |
| Énergie et électrification | 7 |
| Routes, transports et mobilité | 9, 11 |
| Agriculture, élevage et pêche | 2 |
| Emploi, jeunesse et entrepreneuriat | 8 |
| Habitat, urbanisme et cadre de vie | 11 |
| Environnement et climat | 13, 15 |
| Numérique et télécommunications | 9 |
| Sécurité, justice et cohésion sociale | 16 |
| Femmes, inclusion et protection sociale | 5, 10 |
| Culture, sport et loisirs | — |
| Administration et services publics locaux | 16 |

### M3 — Contributions

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-30 | Formulaire guidé en étapes : 1) lieu concerné, 2) secteur, 3) constat, 4) proposition, 5) urgence et population concernée, 6) photos facultatives, 7) relecture. Le brouillon est conservé sur l'appareil en cas de coupure. | M |
| F-31 | Suggestion du secteur à partir des mots-clés du texte (l'utilisateur garde le choix final) | S |
| F-32 | Avant l'envoi, affichage des contributions proches (§10.1) avec la possibilité de « soutenir » l'une d'elles au lieu de créer un doublon | M |
| F-33 | Choix « à titre personnel » ou « au nom de *[organisation]* » (RG-23) | M |
| F-34 | Espace « Mes contributions » : statut, préoccupation de rattachement, nombre de soutiens, historique (modération, regroupement, inclusion dans un LBR), modification et retrait (RG-25) | M |
| F-35 | Import de contributions collectées lors de consultations de terrain (modèle CSV ou XLSX fourni ; contrôle ligne par ligne ; rapport d'erreurs) par l'admin régional (RG-28) | S |
| F-36 | Soutenir et retirer son soutien (RG-27) depuis une fiche de contribution ou de préoccupation | M |
| F-37 | Signaler une contribution (motif obligatoire) | M |
| F-38 | Version mobile installable sur le téléphone, utilisable hors connexion : préparer des contributions et les garder en attente d'envoi, consulter ses contributions et les livres blancs déjà ouverts ; envoi automatique au retour du réseau (RG-30) | M |

**Critères d'acceptation (extraits)**
- *Étant donné* une contribution en cours de saisie dont le texte ressemble à une contribution existante de la même UTR (similarité ≥ 0,20), *quand* l'utilisateur arrive à l'étape de relecture, *alors* jusqu'à 5 contributions proches sont proposées, avec un bouton « Soutenir celle-ci » et un bouton « Ma situation est différente, publier ».
- *Étant donné* une contribution publiée, *quand* le regroupement automatique s'exécute, *alors* elle est rattachée à une préoccupation en moins de 2 secondes (RG-24) et son auteur voit cette préoccupation dans « Mes contributions ».
- *Étant donné* la version mobile sans réseau, *quand* un contributeur termine une contribution, *alors* elle est gardée sur le téléphone avec la mention « En attente d'envoi », et elle est envoyée sans autre action dès le retour du réseau ; un deuxième envoi de la même contribution ne crée pas de doublon.
- *Étant donné* la phase `CONSOLIDATION_REGIONALE`, *quand* un contributeur ouvre le formulaire, *alors* il voit un message indiquant la fin de la collecte et un lien vers l'état d'avancement du LBR de sa région.

### M4 — Modération et doublons (admin régional)

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-40 | File de modération : contributions `EN_MODERATION` et signalées, avec les actions maintenir, masquer ou retirer (RG-41) | M |
| F-41 | File « doublons stricts suspects » (RG-42) : comparaison côte à côte, retrait en un clic avec motif `DOUBLON_STRICT` | M |
| F-42 | Notification à l'auteur de toute décision le concernant, avec le motif | M |

### M5 — Analyse régionale (admin régional)

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-50 | Liste des préoccupations de l'UTR : filtres (secteur, statut, département), tri par score ou par voix, détail du score (§10.3) | M |
| F-51 | Fiche de préoccupation : intitulé, synthèse et propositions retenues (modifiables), contributions rattachées, carte des localités, voix, score | M |
| F-52 | Suggestions de fusion (§10.2, point 4) : accepter, ignorer, ou fusionner manuellement deux préoccupations ou plus | M |
| F-53 | Déplacement d'une contribution vers une autre préoccupation, ou scission d'une préoccupation | M |
| F-54 | Validation et écartement de préoccupations (individuellement ou par lot) | M |
| F-55 | Tableau de bord régional : participation par département, par secteur et dans le temps ; profil des contributeurs (sexe, tranches d'âge) ; avancement du traitement | M |

### M6 — Livre blanc régional

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-60 | Génération automatique du brouillon du LBR selon la structure ci-dessous | M |
| F-61 | Éditeur de l'introduction et des synthèses (texte enrichi simple : titres, gras, listes) ; prévisualisation web | M |
| F-62 | Publication : saisie de la validation régionale (RG-55), contrôle des préconditions (RG-53), figement (RG-54) | M |
| F-63 | Nouvelle version d'un LBR publié, avec résumé des changements et comparaison entre versions | S |

**Structure du LBR généré**
1. Page de titre : UTR, édition, numéro de version, date de publication.
2. Introduction (texte libre de l'administrateur régional).
3. La participation en chiffres : contributions, voix, contributeurs, organisations, répartition par département, par secteur, par sexe et par tranche d'âge.
4. Les priorités de la région : les 10 préoccupations au score le plus élevé, tous secteurs confondus.
5. Un chapitre par secteur : pour chaque préoccupation validée, l'intitulé, la synthèse, les propositions, les localités concernées, les voix, le score détaillé et les références des contributions.
6. Annexes : méthode et pondérations, liste des contributions (référence, titre, localité), préoccupations écartées et motifs, procès-verbal de validation.

### M7 — Consolidation nationale et états généraux (admin national)

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-70 | Tableau d'avancement des 33 UTR (statut du LBR, date de publication, volumes) | M |
| F-71 | Lancement du calcul des convergences (§10.4), avec un rapport : nombre de convergences par classe et par secteur | M |
| F-72 | Matrice secteurs × UTR (intensité = score) permettant de repérer visuellement les besoins communs | M |
| F-73 | Écran d'arbitrage : pour chaque convergence, préoccupations sources par UTR, carte, score détaillé ; actions retenir, fusionner, scinder, rejeter, reclasser ; modification de l'intitulé et de la synthèse | M |
| F-74 | Journal des décisions des états généraux (qui, quand, quoi, motif), exportable en annexe | M |
| F-75 | Projet de synthèse assisté par un modèle de langage (§10.4, point 6) | É |

### M8 — Livre blanc national et exports

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-80 | Génération du LBN selon la structure ci-dessous, puis publication avec figement | M |
| F-81 | Exports PDF et DOCX des LBR et du LBN (générés en tâche de fond, avec notification à la fin) | M |
| F-82 | Lecture web des livres blancs, avec sommaire navigable et liens de traçabilité | M |

**Structure du LBN généré**
1. Page de titre et préambule (texte de l'administrateur national).
2. Méthode : la démarche, les chiffres de participation nationale, la carte de participation pour 10 000 habitants, les UTR non couvertes.
3. Priorités nationales, classées par Score_N : intitulé, synthèse, propositions consolidées, UTR concernées (liste et carte), population couverte, score détaillé, préoccupations régionales sources.
4. Priorités partagées (interrégionales).
5. Spécificités régionales : les 3 premières par UTR.
6. Annexes : méthode et pondérations, décisions des états généraux, index par UTR et par secteur.

### M9 — Candidats, engagements et suivi

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-90 | Gestion des candidats par l'admin national : identité, type d'élection, UTR (régionales), parti ou mention « indépendant », photo officielle facultative, statut `CANDIDAT`, `ELU` ou `NON_ELU` | M |
| F-91 | Espace candidat : parcours du livre blanc applicable, déclaration d'un engagement (RG-71, RG-72), retrait (RG-73) | M |
| F-92 | Page publique de comparaison : pour une priorité, la liste des candidats engagés et leurs échéances ; pour un candidat, la liste de ses engagements | M |
| F-93 | Suivi des réalisations par l'admin national (RG-74) ; commentaire public du candidat sur chaque mise à jour | M |
| F-94 | Tableau de bord public des élus : taux de réalisation (RG-75), par secteur et par échéance | M |
| F-95 | Types d'élection législative et municipale | É |

### M10 — Portail public

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-100 | Page d'accueil narrative expliquant la démarche (de la contribution à l'engagement), avec les chiffres clés de l'édition active et un appel à contribuer | M |
| F-101 | Carte interactive de la Côte d'Ivoire par UTR : participation (pour 10 000 habitants), secteur dominant, statut du LBR ; zoom vers une UTR | M |
| F-102 | Page d'UTR : chiffres, préoccupations principales, accès au LBR | M |
| F-103 | Fil de traçabilité « D'où vient cette priorité ? » : priorité nationale → préoccupations régionales → contributions, dans les deux sens | M |
| F-104 | Recherche plein texte (contributions publiées, préoccupations, livres blancs) avec filtres : édition, UTR, secteur, période | M |
| F-105 | Pages d'information : charte de participation, méthode de calcul, mentions légales et protection des données, foire aux questions | M |
| F-106 | Archives des éditions clôturées | S |

### M11 — Tableaux de bord et statistiques

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-110 | Tableau de bord national : participation par UTR (en valeur et pour 10 000 habitants), par secteur et dans le temps ; alerte « UTR sous-représentée » si le taux est inférieur à 50 % de la médiane nationale | M |
| F-111 | Indicateurs de représentativité : sexe, tranches d'âge, part des organisations, part des imports de terrain | M |
| F-112 | Export CSV des statistiques agrégées (sans données personnelles) | S |

### M12 — Notifications

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-120 | Notifications dans l'application et par e-mail : vérification du compte, décision de modération, contribution regroupée ou fusionnée, LBR de sa région publié, LBN publié, organisation vérifiée | M |
| F-121 | Préférences de notification par e-mail | S |

### M13 — Audit

| ID | Fonctionnalité | Prio |
|---|---|---|
| F-130 | Journal d'audit non modifiable de toutes les actions d'administration et de toutes les transitions de statut (RG-45) | M |
| F-131 | Consultation filtrée du journal : par acteur, par type d'objet, par période ; périmètre selon le rôle | M |
| F-132 | Compteurs publics de transparence par UTR : contributions masquées ou retirées par motif, fusions effectuées | S |

---

## 12. Exigences non fonctionnelles

### 12.1 Performance et volumétrie

- **NF-01.** Hypothèses de dimensionnement pour une édition réelle : 33 UTR, jusqu'à 500 000 contributions et 5 millions de soutiens. Le prototype est testé avec un jeu d'au moins 5 000 contributions.
- **NF-02.** Pages publiques : LCP inférieur à 2,5 s sur un profil réseau « 4G lente » simulé ; JavaScript initial inférieur à 250 Ko compressé.
- **NF-03.** API de lecture : temps de réponse au 95ᵉ centile inférieur à 500 ms sur le jeu de test.
- **NF-04.** Suggestions de similarité avant dépôt : moins de 1 s pour une UTR de 50 000 contributions.
- **NF-05.** Génération d'un document (LBR ou LBN) en tâche de fond : moins de 60 s ; l'interface reste utilisable pendant ce temps.

### 12.2 Sécurité

- **NF-10.** Contrôles d'accès appliqués **côté serveur** à chaque requête, selon le rôle *et* le périmètre territorial.
- **NF-11.** Mots de passe hachés avec un algorithme adapté (scrypt, retenu dans le TRD ; Argon2id et bcrypt sont des alternatives équivalentes), d'au moins 10 caractères, refusés s'ils figurent dans une liste de mots de passe courants.
- **NF-12.** Sessions en cookie `HttpOnly`, `Secure` et `SameSite`, avec protection CSRF sur les requêtes modifiant des données.
- **NF-13.** Limitation du débit sur la connexion, l'inscription, la réinitialisation et le dépôt.
- **NF-14.** Fichiers téléversés : contrôle du type réel et de la taille (5 Mo par photo), métadonnées EXIF supprimées (dont la géolocalisation), stockage hors de la racine web.
- **NF-15.** Protection contre les vulnérabilités de l'OWASP Top 10, vérifiée par une liste de contrôle dans la stratégie de tests.

### 12.3 Données personnelles

- **NF-20.** Le traitement relève de la loi ivoirienne n° 2013-450 du 19 juin 2013 relative à la protection des données à caractère personnel, dont l'autorité de contrôle est l'ARTCI. Un déploiement réel exigerait les formalités préalables auprès de l'ARTCI. Le prototype local en est dispensé, mais il est conçu pour s'y conformer.
- **NF-21.** Minimisation : aucune donnée personnelle n'est exigée au-delà de RG-10. Les données affichées publiquement respectent RG-29.
- **NF-22.** Droits d'accès, de rectification et de suppression exercés depuis le profil (F-14).
- **NF-23.** Aucune donnée personnelle dans les journaux techniques. Le journal d'audit référence les comptes par identifiant.
- **NF-24.** Durée de conservation des données d'identification : jusqu'à la clôture de l'édition plus un an, puis anonymisation (paramétrable).
- **NF-25.** Dans les statistiques publiques et les exports, toute case regroupant moins de 5 personnes est masquée, pour éviter la réidentification d'un contributeur dans une petite localité.

### 12.4 Accessibilité et ergonomie

- **NF-30.** Conformité visée : WCAG 2.1 niveau AA (contrastes, navigation au clavier, libellés de formulaires, alternatives textuelles, préférence « réduire les animations » respectée).
- **NF-31.** Français simple : phrases courtes, pas de jargon administratif dans le parcours contributeur ; messages d'erreur qui disent comment corriger.
- **NF-32.** Deux façons d'utiliser l'application (D-16) : la **version web**, utilisée en ligne, adaptée à l'ordinateur, à la tablette et au téléphone ; la **version mobile** installable (F-38), conçue pour le téléphone (à partir de 360 px) et utilisable hors connexion pour les usages de F-38.
- **NF-33.** Les animations servent la compréhension, ne bloquent jamais une action et sont désactivées si l'utilisateur le demande.

### 12.5 Compatibilité, exploitation et maintenabilité

- **NF-40.** Navigateurs : les deux dernières versions de Chrome, Firefox, Edge et Safari, ainsi que Chrome pour Android.
- **NF-41.** Exécution locale reproductible : une commande de démarrage (conteneurs) et un jeu de données de démonstration chargé par script.
- **NF-42.** Code TypeScript en mode strict, découpé en modules métier correspondant aux modules M1 à M13 ; tests automatisés sur les règles de gestion et le moteur d'analyse (seuils de couverture définis dans le TRD).
- **NF-43.** Sauvegarde : script d'export et de restauration complète de la base.
- **NF-44.** Langue : interface en français uniquement (D-08). Les textes sont toutefois centralisés pour permettre une traduction ultérieure.

---

## 13. Contraintes et dépendances

| # | Contrainte ou dépendance | Origine |
|---|---|---|
| C-01 | Frontend Nuxt, Vue et TypeScript | Imposé par l'équipe |
| C-02 | Déploiement local uniquement pour la démonstration | Décision Q14 |
| C-03 | Rapport académique conforme au modèle ESI / INP-HB, méthode MERISE exclusivement (MCC, MCT, MOT, MCD, MLD, MPD) | Décision Q3 |
| C-04 | Référentiel territorial et populations : sources publiques (ministère de l'Intérieur, INS / RGPH 2021), à saisir ou importer | §6 |
| C-05 | Aucune donnée réelle de contribution : jeu de démonstration fictif | H-05 |
| C-06 | Envoi d'e-mails simulé en local (serveur SMTP de test) | C-02 |
| C-08 | La version web suppose une connexion au serveur ; seule la version mobile fonctionne hors connexion, dans les limites de F-38 | D-16 |
| C-07 | Calendrier : du 15 octobre 2026 au 15 janvier 2027 (soutenance) ; planning dans `planning/` | Q-03 |

---

## 14. Périmètre MVP et évolutions

### 14.1 MVP

Toutes les fonctionnalités **M** des modules M1 à M13. Les fonctionnalités **S** sont intégrées dans l'ordre suivant si le planning le permet : F-35 (import de terrain), F-31 (suggestion de secteur), F-63 (versions comparées), F-24, F-106, F-112, F-121, F-132.

### 14.2 Évolutions identifiées

| Évolution | Pourquoi plus tard |
|---|---|
| Hors connexion étendu (soutiens, signalements, modération) et application de collecte pour agents de terrain | Complexité de synchronisation ; le MVP couvre la préparation des contributions hors connexion (F-38) et l'import CSV des consultations (F-35) |
| Canaux SMS, USSD et messagerie vocale | Nécessite des partenariats avec des opérateurs |
| Langues nationales et transcription audio | Nécessite des ressources linguistiques |
| Regroupement sémantique par plongements vectoriels et synthèses par modèle de langage (F-75) | Coût, hébergement et souveraineté ; le MVP déterministe suffit à démontrer la chaîne |
| Rôle d'observateur indépendant pour le suivi des réalisations | Gouvernance à définir |
| Législatives et municipales (F-95) | Découpages électoraux spécifiques (circonscriptions) |
| Vote citoyen pour la priorisation | Questions d'intégrité et d'identification forte |
| Contestation des décisions de modération | Circuit de recours à définir |
| Ouverture aux 15–17 ans | Consentement parental (D-09) |
| API publique de données ouvertes | Après stabilisation du modèle de données |
| Signature électronique des versions publiées | Infrastructure de certificats |

### 14.3 Scénario de démonstration de référence

1. L'admin national ouvre l'« Édition 2030 » (référentiel des 33 UTR et 14 secteurs chargé).
2. Awa s'inscrit, vérifie son e-mail et dépose une contribution sur la maternité de Gagnoa. Le système lui montre une contribution proche ; elle la soutient puis dépose aussi la sienne, qui concerne une autre localité.
3. Kouassi crée l'Association des jeunes d'Oumé et dépose une contribution collective ; l'admin du Gôh vérifie l'organisation.
4. Le jeu de démonstration ajoute environ 5 000 contributions réparties sur 8 UTR.
5. L'admin national clôt la collecte. L'admin du Gôh traite un doublon strict, fusionne deux préoccupations, valide, compose et publie le LBR du Gôh. Les autres LBR de démonstration sont publiés par script.
6. L'admin national ouvre les états généraux, calcule les convergences, arbitre (retient, fusionne, rejette avec motif), compose et publie le LBN, puis l'exporte en PDF et DOCX.
7. Un candidat à la présidentielle déclare 5 engagements ; la page publique les compare à ceux d'un autre candidat.
8. Passage en phase de suivi : le candidat est marqué élu, l'admin met à jour 2 engagements, le taux de réalisation s'affiche.
9. Fatou, visiteuse, part d'une priorité nationale et remonte jusqu'à la contribution d'Awa.

---

## 15. Hypothèses et risques

### 15.1 Hypothèses

| # | Hypothèse | Impact si fausse |
|---|---|---|
| H-01 | Une autorité de gouvernance indépendante et fictive opère la plateforme ; aucune institution réelle n'est désignée (réponse par défaut à Q5) | Rôles d'administration à revoir |
| H-02 | La démarche concerne en priorité l'élection présidentielle et les régionales | Ajout de découpages électoraux |
| H-03 | Les contributeurs disposent d'une adresse e-mail. L'inscription par téléphone et SMS est une évolution | Exclusion d'une partie des populations : à compenser par l'import de terrain (F-35) |
| H-04 | Les populations de référence des UTR sont disponibles (RGPH 2021) | Le Score_N repose alors sur la seule composante T |
| H-05 | Le prototype utilise un jeu de données fictif et réaliste, généré par script | — |
| H-06 | Deux niveaux d'administration (régional et national) suffisent | Ajout d'un niveau départemental |

### 15.2 Risques

| # | Risque | Prob. | Impact | Parade |
|---|---|---|---|---|
| R-01 | Sous-représentation des populations rurales, âgées ou non connectées | Élevée | Élevé | Import de terrain (F-35), normalisation par UTR, indicateurs de représentativité (F-111), alerte de sous-représentation (F-110) |
| R-02 | Mobilisation organisée pour gonfler un sujet | Moyenne | Moyen | Une voix par personne et par préoccupation (RG-51), échelle logarithmique (§10.3), limite quotidienne (RG-26), vérification e-mail |
| R-03 | Contestation de la neutralité des arbitrages | Moyenne | Élevé | Motifs obligatoires, journal d'audit, décisions des états généraux publiées en annexe (F-74) |
| R-04 | Mauvais regroupements automatiques | Moyenne | Moyen | Seuils calibrés et paramétrables ; correction manuelle prioritaire (§10.2, point 5) ; critère CS3 |
| R-05 | Contenus injurieux ou données personnelles de tiers publiés | Moyenne | Moyen | Filtre automatique, signalements, modération a posteriori (RG-40) |
| R-06 | Périmètre trop ambitieux pour le calendrier académique | Élevée | Élevé | Priorités M/S/É ; plan d'implémentation par incréments démontrables |
| R-07 | Évolution du découpage administratif | Faible | Moyen | Référentiel importable et daté (D-07) |

---

## 16. Journal des décisions

| # | Décision | Statut | Justification |
|---|---|---|---|
| D-01 | Contributeurs : personnes physiques et organisations (associations, ONG, collectivités, organisations professionnelles, autres) | Validée par l'équipe | Réponse à la question 1 de cadrage |
| D-02 | Les contributions sont publiées dès leur dépôt, sans validation préalable ; la modération se fait a posteriori | Validée par l'équipe (interprétation à confirmer) | « On ajoute pour éviter trop d'interventions » |
| D-03 | La responsabilité des doublons revient à l'administrateur. Seuls les doublons *stricts* (même auteur) sont retirés ; les contributions semblables d'auteurs différents sont **regroupées**, pas supprimées. Les doublons *dans le livre blanc* sont traités par fusion de préoccupations (régional) et de convergences (national) | Validée par l'équipe (12/11/2026) | Supprimer la contribution d'un autre citoyen effacerait sa voix et fausserait les priorités (principe P1) |
| D-04 | Deux niveaux d'administration : régional (périmètre UTR) et national | Validée par l'équipe (12/11/2026) | Un administrateur unique ne peut pas traiter 33 territoires ; le périmètre régional renforce aussi la légitimité locale |
| D-05 | Automatisation : similarité, regroupement, priorisation et proposition de consolidation nationale, déterministes et explicables ; modèle de langage optionnel et désactivé par défaut | Validée par l'équipe (Q8, question 3 de cadrage) | Reproductibilité, explicabilité, fonctionnement entièrement local |
| D-06 | Unités de rédaction : 31 régions et 2 districts autonomes, soit 33 LBR | Validée par l'équipe (12/11/2026) | Les districts autonomes n'appartiennent à aucune région (§6.2) |
| D-07 | Référentiel territorial importable et non codé en dur | Proposée | Les sources divergent et le découpage évolue |
| D-08 | Interface en français uniquement | Validée par l'équipe | Réponse Q6 / Q7 |
| D-09 | Inscription réservée aux 18 ans et plus ; les jeunes s'expriment aussi via les organisations | Validée par l'équipe (12/11/2026) | Évite le consentement parental exigé pour les mineurs ; correspond à l'âge électoral |
| D-10 | Une contribution importée de terrain compte pour 1 voix plus 1 voix par tranche de 10 participants déclarés, dans la limite de 10 voix | Validée par l'équipe (12/11/2026) | Donne du poids aux consultations collectives sans permettre une inflation non vérifiable |
| D-11 | Accès par inscription et connexion (e-mail et mot de passe) ; pas de contribution anonyme | Validée par l'équipe (Q7) | Intégrité des voix |
| D-12 | Module candidats et engagements dans le MVP, avec un suivi simplifié (état, date, justificatif) | Validée par l'équipe (Q9) | — |
| D-13 | Nuxt full-stack (routes serveur), PostgreSQL, monolithe modulaire | Validée par l'équipe (Q13) ; détails dans le TRD | — |
| D-14 | Méthode d'analyse du rapport : étude comparative, puis MERISE exclusivement | Validée par l'équipe (Q3) | Conformité au modèle du rapport |
| D-15 | Nom de travail « Livre Blanc Citoyen » ; palette institutionnelle sobre inspirée du territoire, sans reprendre le drapeau | Validée par l'équipe (Q15) | Neutralité (P7) |
| D-16 | Version web en ligne (pas d'exigence hors connexion) ; version mobile installable qui fonctionne hors connexion pour préparer des contributions et relire ce qui a déjà été ouvert. La version mobile est réalisée une fois la version web terminée, et proposée depuis une page « Télécharger l'application mobile » du portail | Décidée par l'équipe (13/11/2026) | Couvrir les zones à réseau irrégulier sans compliquer la version web |

---

## 17. Questions ouvertes

Toutes les questions de la version 0.1 ont été tranchées le 12 novembre 2026 :

| # | Réponse |
|---|---|
| Q-01 | Décisions D-03, D-04, D-06, D-09 et D-10 validées |
| Q-02 | « Dr APPOH » conservé ; l'équipe complète elle-même le nom et le titre |
| Q-03 | Projet du 15 octobre 2026 au 15 janvier 2027 (soutenance) ; année académique 2026-2027 |
| Q-04 | Tous les logos de la page de garde sont conservés ; page de garde et rapport réunis dans un seul document Word |
| Q-05 | Lecture confirmée : Q6 = langue française, Q7 = inscription et connexion |

## 18. Correspondance avec les livrables suivants

| Élément du PRD | Exploité dans |
|---|---|
| Glossaire (§5), règles RG (§9) | Dictionnaire de données, MCD, MLD et MPD (`DATABASE_SCHEMA.md`, rapport chapitre III) |
| Acteurs et matrice des droits (§7) | MCC (rapport), autorisations (`TRD.md`), menus (`UX_SPECIFICATIONS.md`) |
| Processus et cycles de vie (§8) | MCT et MOT (rapport), `APP_FLOW.md`, machines à états dans le code |
| Moteur d'analyse (§10) | `TRD.md` (algorithmes, index), stratégie de tests |
| Fonctionnalités F (§11) | `API_SPECIFICATIONS.md`, `UX_SPECIFICATIONS.md`, `IMPLEMENTATION_PLAN.md` |
| Exigences NF (§12) | `TRD.md`, `UI_DESIGN_SYSTEM.md` (accessibilité, budget de performance) |

---

## Historique des versions

| Version | Date | Modifications |
|---|---|---|
| 1.0 | 12/11/2026 | Version validée par l'équipe (décisions D-03, D-04, D-06, D-09, D-10) |
| 1.1 | 12/11/2026 | Ajustements issus de la conception technique (phase 3) : mesure de similarité composite et nouveaux seuils (§10.1, critère de F-32) ; indicateur de cohésion des convergences (§10.4) ; maille la plus fine disponible pour la résidence et le lieu concerné (RG-10, RG-21, RG-22) ; contrôle de l'âge sur l'année de naissance (RG-12) ; imports de terrain possibles en consolidation régionale (RG-28) ; nouvelle règle de verrouillage des préoccupations (RG-56) ; hachage scrypt (NF-11) ; masquage des petits effectifs (NF-25) |
| 1.2 | 13/11/2026 | Décision D-16 : version web en ligne, version mobile installable hors connexion ; nouvelle fonctionnalité F-38 et règle RG-30 ; NF-32 réécrite ; contrainte C-08 ; évolution « hors connexion » limitée à ce que F-38 ne couvre pas |
