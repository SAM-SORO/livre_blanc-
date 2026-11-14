---
name: lbc-interface
description: Procédure pour concevoir et réaliser les interfaces du Livre Blanc Citoyen (portail public, contribution, espaces d'administration et de candidat) sans aspect « généré par une IA » : direction d'interface à faire valider, règles de présentation, liste des tics à éviter, vérifications.
---

# Concevoir les interfaces du Livre Blanc Citoyen

L'équipe a écarté les premières maquettes parce que leur présentation faisait « IA ». La présentation est maintenant ta responsabilité : tu la conçois, avec tes compétences de conception d'interface (dont la compétence de conception front-end si elle est disponible), et l'équipe la valide. Le but n'est pas d'être spectaculaire, mais qu'un Ivoirien qui ouvre l'application ait l'impression d'un service public sérieux, pensé pour lui, et qu'un enseignant du jury n'y reconnaisse pas un gabarit.

Deux contextes à concevoir (D-16) : la **version web**, utilisée en ligne et pensée d'abord pour l'ordinateur (portail, administration) tout en restant lisible sur un téléphone ; la **version mobile** installable, pensée pour le téléphone et utilisable sans réseau pour contribuer (`docs/UX_SPECIFICATIONS.md` §3).

## 1. Comprendre ce qu'on présente

Avant de dessiner quoi que ce soit, relire :
- `docs/PRD.md` §2, §3, §7 (le problème, les principes, les personas : Awa sur un téléphone d'entrée de gamme, Mme Gnahoré qui traite des centaines de contributions, M. Diabaté en séance d'états généraux, Fatou qui vérifie) ;
- `docs/APP_FLOW.md` (écrans, accès, parcours) et `docs/UX_SPECIFICATIONS.md` (ce que chaque écran doit permettre, textes, états) ;
- `design/design-system/project/README.md` (proposition de départ : palette, polices, voix ; à garder, ajuster ou remplacer).

Le contenu réel commande la forme : des contributions écrites par des citoyens (texte court, lieu, date), des préoccupations avec un nombre de personnes et un score à expliquer, des documents officiels (livres blancs) à lire et à télécharger, des décisions motivées. Partir de ces objets, pas d'un gabarit de site.

## 2. Tâche 0.8 : fixer une direction d'interface (avant tout autre écran)

1. Écrire en une page la **direction** : à quoi doit ressembler l'application et pourquoi (le registre d'un service public et d'un document officiel ; la lecture à l'écran ; la densité d'un outil de travail pour l'administration ; la simplicité de la version mobile). Nommer les références réelles dont elle s'inspire par leur genre (journal officiel, rapport public, formulaire administratif bien conçu, outil de traitement de dossiers), jamais en copiant un produit existant.
2. Réaliser **deux directions différentes**, chacune sur trois écrans vrais (codés, avec les données de démonstration) : l'accueil du portail, une étape du formulaire de contribution, la liste et la fiche des préoccupations pour l'administration régionale. La version mobile (lot 6) reprend ensuite la direction choisie, adaptée au téléphone. Deux directions qui diffèrent par la mise en page et la hiérarchie, pas seulement par la couleur.
3. Prendre des captures à 390 px et 1 440 px et les présenter à l'équipe avec trois lignes par direction : ce qu'elle privilégie, ce qu'elle sacrifie, les risques.
4. Après le choix de l'équipe : mettre à jour `design/design-system/project/tokens.json` et `README.md`, `docs/UI_DESIGN_SYSTEM.md`, puis le thème Nuxt UI. Noter la décision dans `docs/TRD.md` (décision T-xx).

Ne rien construire d'autre que ces écrans d'essai tant que la direction n'est pas validée.

## 3. Règles de présentation

**Hiérarchie et mise en page**
- Une page = une intention principale, visible sans faire défiler. Le reste se lit dans l'ordre d'importance, aligné à gauche.
- La mise en page suit le contenu : une liste se lit comme une liste (lignes, séparateurs), un document comme un document (colonne de lecture, sommaire), un tableau de travail comme un tableau (colonnes, tri, densité). Pas de cartes pour tout.
- Varier les tailles et les poids selon l'importance réelle ; ne pas donner à chaque bloc le même gabarit.
- Administration : dense et calme, conçue pour des heures de travail ; texte de 15 px au moins ; actions à côté de ce qu'elles modifient.

**Contenu et textes**
- Contenus réels du jeu de démonstration (noms de régions, départements et localités ivoiriens, contributions plausibles), jamais de faux chiffres flatteurs ni de texte de remplissage.
- Textes en français simple, au vouvoiement, qui disent ce qui va se passer (« Publier ma contribution »), en suivant `UX_SPECIFICATIONS.md` §8. Pas de slogans ni de formules creuses.
- Les nombres sont toujours accompagnés de ce qu'ils comptent et, pour un score, de sa décomposition.

**Couleur, typographie, formes**
- Peu de couleurs, chacune avec un rôle (fond, texte, action, états) ; neutralité absolue (ni drapeau, ni couleur de parti).
- Deux familles de caractères au plus, libres et auto-hébergées ; la lisibilité sur petit écran passe avant l'effet.
- Rayons, ombres et bordures avec parcimonie et selon la nature de l'objet.

**Mouvement**
- Le mouvement répond à une action (ouvrir, valider, déplacer) ou montre un changement. Pas d'apparition décorative au défilement. Respecter « réduire les animations ».

## 4. Les tics qui font « IA » — à éviter

Relire chaque écran contre cette liste avant de le montrer :

- grand titre centré avec un chiffre géant, un sous-titre et un dégradé derrière ;
- fond crème, titre en serif et accent terracotta ; ou fond noir avec un seul accent fluo ;
- contenu découpé en cartes identiques, même arrondi partout, même ombre grise douce ;
- grille de trois « avantages » avec une icône dans un cercle coloré au-dessus de chaque titre ;
- petites étiquettes en MAJUSCULES espacées au-dessus de chaque titre ; un seul mot du titre coloré ou en italique ;
- numéros 01, 02, 03 sur des éléments qui ne sont pas une suite ;
- métadonnées collées avec des points médians (« Santé · Gagnoa · 12 nov. ») au lieu d'une phrase ;
- flèche « → » ajoutée aux boutons et aux liens ;
- émoji, illustrations de personnes génériques, photos d'archives, effets de verre dépoli, dégradés bleu-violet ;
- textes de remplissage (« Ensemble, construisons l'avenir », « Une expérience fluide ») et chiffres inventés ;
- apparition en fondu et glissement de chaque section au défilement ;
- tout centré, tout symétrique, toutes les sections de même hauteur.

Si un écran ressemble à ce qu'on obtiendrait pour n'importe quel autre site, le reprendre à partir du contenu propre au projet.

## 5. Réaliser et vérifier

1. Réaliser avec Nuxt UI habillé par les jetons de la direction validée ; composants propres dans `app/components/` ; textes dans `shared/utils/libelles.ts`.
2. Prévoir les états : chargement (squelettes à la forme du contenu), vide (une phrase qui invite à agir), erreur (ce qui s'est passé, quoi faire).
3. Vérifier : captures à 390 px et 1 440 px, navigation au clavier, `@axe-core/playwright` sans violation, contrastes ≥ 4,5:1 pour le texte.
4. Relire contre la liste du §4, puis montrer les captures à l'équipe avant de considérer l'écran fini.
