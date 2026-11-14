# Livre Blanc Citoyen

Système de design de l'application **Livre Blanc Citoyen**, qui recueille les contributions des populations de Côte d'Ivoire, les organise en livres blancs régionaux et les consolide en un livre blanc national sur lequel les candidats s'engagent.

L'application sert deux publics très différents. D'un côté, des citoyens qui contribuent depuis un téléphone d'entrée de gamme, sur une connexion irrégulière, parfois sans habitude des formulaires en ligne. De l'autre, des administrateurs qui traitent des centaines de contributions sur un ordinateur et produisent des documents officiels. Le système doit être **lisible d'abord, institutionnel ensuite, et ne jamais ressembler à un tract** : il sert une démarche publique, neutre vis-à-vis des partis.

## Principes

1. **La voix d'abord.** Une contribution est la parole d'une personne. On l'affiche telle qu'elle a été écrite, avec son lieu et sa date, avant toute synthèse.
2. **Tout se relie.** Chaque priorité nationale remonte jusqu'aux contributions qui l'ont fait naître. Le *fil* (voir plus bas) rend ce lien visible partout où il existe.
3. **Chaque territoire compte autant.** Les 33 unités territoriales (31 régions et 2 districts autonomes) sont toujours montrées ensemble, à poids visuel égal, avant d'être comparées.
4. **On explique les chiffres.** Un score s'affiche toujours avec sa décomposition ; une carte, avec un tableau équivalent.
5. **Sobriété territoriale.** Les couleurs viennent du paysage ivoirien (la lagune, l'ocre des pistes et de la savane, la forêt), jamais du drapeau ni des couleurs d'un parti.

## Voix et ton

- Français simple, phrases courtes, vouvoiement. On écrit pour une personne qui lit sur un petit écran.
- Les boutons disent ce qui va se passer : « Publier ma contribution », « Soutenir cette contribution », « Valider la préoccupation ». Le même verbe suit toute l'action : un bouton « Publier » produit le message « Contribution publiée ».
- Les messages d'erreur disent quoi faire, sans s'excuser : « Décrivez le problème en 30 caractères au moins. » plutôt que « Erreur de saisie ».
- Un écran vide invite à agir : « Aucune préoccupation à valider. Les nouvelles contributions apparaîtront ici. »
- Pas de jargon administratif dans le parcours citoyen : on dit « votre région », pas « votre UTR » ; « les personnes qui ont exprimé ce besoin », pas « les voix agrégées ». Les termes du glossaire (préoccupation, convergence, priorité nationale) sont réservés aux écrans d'administration et aux livres blancs, où ils sont définis.
- Pas de majuscules d'imprimerie pour les étiquettes, pas de point médian pour séparer des métadonnées : on écrit des phrases (« Déposée le 12 novembre à Gagnoa »).

## Couleurs

La palette est froide et calme, avec une seule couleur chaude réservée au fil.

| Rôle | Jeton | Règle |
|---|---|---|
| Fond | `papier`, `surface`, `surface-2` | Le papier est le fond ; les surfaces blanches portent le contenu. Pas de dégradé. |
| Texte | `encre`, `texte-2` | Jamais de noir ni de gris neutre : l'encre est un bleu-vert très sombre. |
| Action | `lagune-700`, `lagune-600`, `lagune-100` | Une seule couleur d'action. Un écran a au plus un bouton principal. |
| Le fil | `ocre-500`, `ocre-700`, `ocre-100` | Réservé à la traçabilité, aux versions publiées et à la progression. Jamais pour décorer. |
| États | `foret-600`, `alerte-600` et leurs fonds `-100` | Toujours doublés d'un texte ou d'une icône : la couleur seule ne porte pas l'information. |
| Cartographie | `carto-1` à `carto-6` | Échelle séquentielle unique, de la lagune claire à l'encre. Les classes se distinguent par la clarté, pas par la teinte. |
| Classes de priorité | `classe-nationale`, `classe-partagee`, `classe-specifique` | Pleine, contour lagune, contour ocre : distinguables aussi en niveaux de gris. |

Contrastes vérifiés : texte courant ≥ 4,5:1 sur `papier` et `surface` ; contours des contrôles et graphiques ≥ 3:1.

## Typographie

Deux familles, aux rôles nettement séparés, toutes deux sous licence libre (SIL OFL) et **auto-hébergées** dans l'application, qui ne dépend d'aucun service tiers et dont la version mobile s'ouvre sans réseau :

- **Literata** (serif) pour ce qui se *lit* et se *publie* : titres, chiffres clés, corps des livres blancs. Dessinée pour la lecture longue à l'écran, elle donne aux livres blancs le registre d'un document.
- **Atkinson Hyperlegible Next** (sans empattement) pour ce qui se *fait* : formulaires, boutons, tableaux, métadonnées. Elle a été conçue pour distinguer les caractères qui se confondent (I, l, 1 ; O, 0), ce qui compte pour des lecteurs peu à l'aise et des écrans médiocres.

Échelle : 13 · 15 · 17 · 19 · 23 · 30 · 40 · 56 px. Le corps d'interface est à 17 px (et non 14 ou 16) parce que le premier usage est mobile. Une ligne de lecture ne dépasse pas 72 caractères. Les chiffres clés sont en Literata, suivis d'un libellé en Atkinson : « **12 480** contributions ».

Interdits : mettre un seul mot d'un titre en couleur ou en italique ; utiliser une troisième famille ; descendre sous 13 px.

## Mise en page

- **Portail public** : une colonne de lecture de 680 px au plus, alignée à gauche, avec une marge latérale qui accueille le fil et les notes. Les grands titres respirent (`espace-8` au-dessus).
- **Parcours de contribution dans la version mobile** : conçu pour un téléphone de 360 px de large ; un seul champ principal par écran, le bouton d'action fixé en bas de l'écran.
- **Administration** : barre latérale de 248 px, zone de travail en liste et détail (la liste à gauche, la fiche à droite), tableaux denses en `ui` 15 px.
- Grille de 4 px ; les écarts suivent `espace-1` à `espace-8`.

## Formes

Deux rayons pour deux natures d'objets : `rayon-s` (4 px) pour ce que l'on manipule (champs, boutons), `rayon-m` (10 px) pour ce qui contient (panneaux, tuiles). Les pastilles (`rayon-pastille`) sont réservées aux badges et aux nœuds du fil. Les panneaux posés sur la page n'ont **pas d'ombre** : un trait de 1 px suffit. Seul ce qui flotte (menus, fenêtres) porte `ombre-flottante`.

## Le fil

Le motif propre au produit. Un trait continu de 3 px en `ocre-500` relie les étapes par lesquelles passe une parole citoyenne : contribution, préoccupation régionale, livre blanc régional, priorité nationale, engagement d'un candidat. Chaque étape est un nœud :

| Étape | Nœud |
|---|---|
| Contribution | petit disque plein (8 px) |
| Préoccupation | anneau (14 px) |
| Livre blanc régional, livre blanc national | carré à coins `rayon-s` (14 px), comme une page |
| Priorité nationale | disque plein (18 px) |
| Engagement | anneau double |

Une étape pas encore atteinte est un nœud en pointillés `trait-fort`, sans fil plein jusqu'à elle. Le fil apparaît dans le panneau « D'où vient cette priorité ? », dans « Mes contributions » et en marge des livres blancs. Ailleurs, l'ocre n'est pas utilisé.

## Cartographie

Deux représentations complémentaires :

- le **cartogramme en tuiles** : les 33 territoires en carrés égaux (`rayon-m`), placés selon leur position approximative. C'est l'image d'accueil du portail : chaque territoire y pèse autant, quelle que soit sa superficie ;
- la **carte précise**, tracée à partir des limites administratives officielles (jeu COD-AB), pour situer et zoomer.

Les deux utilisent l'échelle `carto-1` à `carto-6` et sont toujours accompagnées d'un tableau équivalent pour les lecteurs d'écran.

## Iconographie

Icônes au trait de la famille Lucide (via Iconify, intégrée à Nuxt UI), épaisseur 1,75, taille 20 px en interface et 24 px dans le parcours mobile. Une icône accompagne un texte, elle ne le remplace pas, sauf pour les actions universelles (fermer, menu, rechercher) qui portent alors un libellé accessible. Pas d'émoji, pas d'illustration de personnes.

**Pas de logo à ce stade** : le nom « Livre Blanc Citoyen » est composé en Literata semi-grasse, en encre. Un logotype pourra être dessiné plus tard ; il ne devra reprendre ni le drapeau ni les armoiries.

## Mouvement

Le mouvement explique un changement, il ne décore pas. Transitions d'interface de 150 à 250 ms ; une seule séquence narrative, sur la page d'accueil (le fil qui se tend d'une contribution jusqu'à un engagement), au plus 1,2 s. Tout est désactivé si l'utilisateur a demandé à réduire les animations.

## Accessibilité

Niveau visé : WCAG 2.1 AA. Focus clavier visible partout (`trait-focus` en `lagune-600`, décalé de 2 px) ; cibles tactiles de 44 px au moins ; libellés de champs toujours visibles (jamais remplacés par un texte indicatif) ; états signalés par un texte en plus de la couleur.

## Composants

`Bouton`, `Champ`, `Badge`, `JaugeScore`, `FilTracabilite`, `Etapes`, `LigneContribution`, `Cartogramme`. Leurs styles sont dans `components/bundle.css`, préfixés `lbc-` ; l'application les réalise avec Nuxt UI, habillé par ces jetons.
