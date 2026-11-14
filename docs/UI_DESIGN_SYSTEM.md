# UI_DESIGN_SYSTEM — Système de design « Livre Blanc Citoyen »

| Champ | Valeur |
|---|---|
| Version | 1.0 — **proposition de départ**, à confirmer, ajuster ou remplacer à la tâche 0.8 du plan (direction d'interface) |
| Référence vivante | Système de design publié : https://claude.ai/artifact/DfXqub2mvjMZioUEtu46aZ (charte, jetons, composants avec aperçus) |
| Sources dans le dépôt | `design/design-system/project/` (tokens.json, README.md, components/), `design/cartogramme_utr.json` |
| Documents liés | `UX_SPECIFICATIONS.md`, `APP_FLOW.md`, `TRD.md` (T-06, T-07, T-08, §12) |

**Règle pour Claude Code :** les premières maquettes n'ont pas été retenues ; la présentation est à concevoir (skill `lbc-interface`). Ce document fixe des valeurs de départ vérifiées (contrastes, licences, neutralité) que la direction validée peut modifier. Une fois la direction validée, `design/design-system/project/tokens.json` devient la source des valeurs. Le fichier `app/assets/css/main.css` les reprend dans un bloc `@theme` (§6) ; aucune couleur, taille ou espacement n'est écrit en dur dans un composant.

---

## 1. Direction artistique

L'application sert à la fois des citoyens sur des téléphones d'entrée de gamme et une administration qui produit des documents officiels. La direction retenue est **sobre, territoriale et documentaire** :

- **Territoriale** : la palette vient du paysage ivoirien (bleu-vert de la lagune, ocre des pistes et de la savane, vert de la forêt), sans reprendre le drapeau ni aucune couleur de parti (décision D-15, principe de neutralité).
- **Documentaire** : un serif de lecture (Literata) donne aux titres et aux livres blancs le registre d'un document public ; une sans-serif conçue pour la lisibilité (Atkinson Hyperlegible Next) porte toute l'interface.
- **Un motif propre, le fil** : un trait ocre qui relie la contribution à la préoccupation, au livre blanc, à la priorité nationale et à l'engagement. C'est le seul usage étendu de la couleur chaude, et l'élément dont on se souvient.
- **Le cartogramme en tuiles** : les 33 territoires en carrés égaux. Il traduit visuellement le principe « chaque territoire compte autant » et sert d'image d'accueil.

Écarté volontairement : fonds crème, dégradés, cartes à ombre portée répétées, étiquettes en majuscules, émoji, illustrations de personnes.

## 2. Couleurs

| Jeton | Valeur | Usage |
|---|---|---|
| `papier` | `#F4F6F3` | Fond de page de toute l'application. Volontairement froid et légèrement vert : ni crème, ni blanc pur. |
| `surface` | `#FFFFFF` | Panneaux, formulaires, tableaux et pages des livres blancs posés sur le papier. |
| `surface-2` | `#EBEFEB` | Zones secondaires : en-têtes de tableaux, barre latérale d'administration, encarts. |
| `encre` | `#14323A` | Texte principal et titres (12,5:1 sur papier). Remplace le noir partout. |
| `texte-2` | `#4A5B5E` | Texte secondaire : dates, lieux, aides de saisie (6,5:1 sur papier). |
| `trait` | `#D5DCD6` | Séparateurs et contours décoratifs. Jamais seul pour signaler un élément interactif. |
| `trait-fort` | `#7C8A84` | Contour des champs, cases et boutons secondaires (3,3:1 sur papier, seuil des contrôles). |
| `lagune-700` | `#1C5D68` | Couleur d'action : bouton principal, onglet actif, élément sélectionné. Texte blanc dessus : 7,5:1. |
| `lagune-600` | `#22707C` | Liens et anneau de focus (5,3:1 sur papier). |
| `lagune-100` | `#E3F0F1` | Fond d'un élément sélectionné ou survolé ; texte encre ou lagune-700 dessus. |
| `ocre-500` | `#A9740F` | Le fil : trait de traçabilité, repères de progression, indicateurs graphiques (3,7:1 sur papier). Jamais en texte courant. |
| `ocre-700` | `#87590A` | Texte ocre : classe « spécifique », mentions de version (5,6:1 sur papier). |
| `ocre-100` | `#F6ECD6` | Fond des encarts liés au fil (version publiée, rappel de phase). |
| `foret-600` | `#2F6B45` | Validé, publié, réalisé. Texte et icônes. |
| `foret-100` | `#E4EFE6` | Fond des messages de réussite et des badges « validée ». |
| `alerte-600` | `#B23A2E` | Erreurs, refus, retrait. Toujours accompagné d'un texte qui dit quoi faire. |
| `alerte-100` | `#F8E4E1` | Fond des messages d'erreur. |
| `carto-1` | `#E6F0EF` | Cartographie, échelle séquentielle, classe la plus faible. Texte encre. |
| `carto-2` | `#B7D6D6` | Cartographie, 2e classe. Texte encre. |
| `carto-3` | `#7FB3B5` | Cartographie, 3e classe. Texte encre. |
| `carto-4` | `#3A7880` | Cartographie, 4e classe. Texte blanc en gras. |
| `carto-5` | `#1C5D68` | Cartographie, 5e classe. Texte blanc. |
| `carto-6` | `#14323A` | Cartographie, classe la plus forte. Texte blanc. |
| `classe-nationale` | `{encre}` | Priorité nationale (5 UTR et plus) : pastille pleine encre, texte blanc. |
| `classe-partagee` | `{lagune-600}` | Priorité partagée (2 à 4 UTR) : contour et texte lagune. |
| `classe-specifique` | `{ocre-700}` | Spécificité régionale (1 UTR) : contour et texte ocre. |

Règles d'usage :

- un écran a **au plus un bouton principal** (`lagune-700`) ;
- l'ocre ne sert qu'au fil, aux versions publiées et à la progression ; jamais à décorer ;
- un état (validé, erreur, modération) est toujours dit par un texte en plus de la couleur ;
- les classes de priorité se distinguent aussi en niveaux de gris (pleine, contour lagune, contour ocre) ;
- la cartographie utilise une seule échelle séquentielle (`carto-1` à `carto-6`), le texte passe en blanc à partir de `carto-4`.

Contrastes vérifiés (WCAG 2.1) : texte ≥ 4,5:1 sur `papier` et `surface` ; contours de contrôles, anneau de focus et graphiques ≥ 3:1 ; texte blanc sur `lagune-700` 7,5:1, sur `carto-4` 5,0:1.

## 3. Typographie

| Famille | Rôle | Licence |
|---|---|---|
| Literata | Titres, chiffres clés, corps des livres blancs et des synthèses | SIL Open Font License |
| Atkinson Hyperlegible Next | Interface : formulaires, boutons, tableaux, métadonnées | SIL Open Font License |

| Style | Famille | Taille / interligne | Graisse | Usage |
|---|---|---|---|---|
| `affiche` | Literata | 56px / 60px | 600 | Une seule fois par page publique : la phrase d'accueil, le titre d'un livre blanc. |
| `titre-1` | Literata | 40px / 46px | 600 | Titre de page. |
| `titre-2` | Literata | 30px / 36px | 600 | Section de page, chapitre d'un livre blanc. |
| `titre-3` | Literata | 23px / 30px | 600 | Intitulé d'une préoccupation ou d'une priorité. |
| `chiffre` | Literata | 44px / 48px | 500 | Chiffres clés (contributions, voix). Toujours suivis d'un libellé en interface. |
| `lecture` | Literata | 19px / 31px | 400 | Corps des livres blancs et des synthèses, lecture longue (65 à 72 caractères par ligne). |
| `corps` | Atkinson Hyperlegible Next | 17px / 26px | 400 | Texte courant de l'interface, formulaires, contributions. |
| `corps-fort` | Atkinson Hyperlegible Next | 17px / 26px | 700 | Mise en évidence d'une information dans une phrase ; jamais un mot isolé dans un titre. |
| `ui` | Atkinson Hyperlegible Next | 15px / 22px | 500 | Boutons, onglets, menus, en-têtes de tableaux. |
| `petit` | Atkinson Hyperlegible Next | 13px / 18px | 400 | Métadonnées, légendes, aides. Jamais en dessous de 13 px. |

Les polices sont **auto-hébergées** (fichiers woff2 dans `public/fonts/`, sous-ensemble latin étendu, `font-display: swap`) : l'application ne dépend d'aucun service en ligne autre que notre serveur (C-02), la version mobile s'ouvre sans réseau (D-16), et aucune donnée n'est transmise à un service tiers. Literata est chargée avec son axe de taille optique.

## 4. Espacements, rayons, ombres et traits

| Jeton | Valeur | Usage |
|---|---|---|
| `espace-1` | `4px` | Écart entre une icône et son texte. |
| `espace-2` | `8px` | Écart à l'intérieur d'un groupe (badge, libellé et champ). |
| `espace-3` | `12px` | Marge intérieure verticale des boutons et des lignes de liste. |
| `espace-4` | `16px` | Marge intérieure des champs ; gouttière mobile. |
| `espace-5` | `24px` | Marge intérieure des panneaux ; écart entre champs d'un formulaire. |
| `espace-6` | `32px` | Écart entre blocs d'une page ; gouttière bureau. |
| `espace-7` | `48px` | Écart entre sections. |
| `espace-8` | `64px` | Respiration des pages publiques autour des grands titres. |
| `rayon-s` | `4px` | Champs, boutons, cases : les objets que l'on manipule. |
| `rayon-m` | `10px` | Panneaux, encarts, tuiles du cartogramme : les objets qui contiennent. |
| `rayon-pastille` | `999px` | Badges de statut et de classe, nœuds du fil. |
| `ombre-flottante` | `0 6px 20px rgba(20, 50, 58, 0.14)` | Uniquement ce qui flotte au-dessus de la page : menus, fenêtres, notifications. Les panneaux posés n'ont pas d'ombre, seulement un trait. |
| `trait-fin` | `1px` | Contours et séparateurs. |
| `trait-fil` | `3px` | Le fil de traçabilité. |
| `trait-focus` | `3px` | Anneau de focus clavier, décalé de 2 px. |

## 5. Composants

| Composant du système | Réalisation dans Nuxt | Usage |
|---|---|---|
| Bouton | `UButton` (Nuxt UI) habillé : `color="primary"` = `lagune-700`, variantes `outline`, `ghost`, `color="error"` | Une action par libellé ; un seul principal par écran |
| Champ | `UFormField` + `UInput` / `UTextarea`, validation Zod partagée | Libellé toujours visible, aide, compteur, erreur sous le champ |
| Badge | `UBadge` habillé | Statuts et classes de priorité |
| JaugeScore | Composant propre `JaugeScore.vue` | Score avec décomposition V, U, E, C ou T, P, S |
| FilTracabilite | Composant propre `FilTracabilite.vue` | Panneau « D'où vient cette priorité ? », « Mes contributions », marge des livres blancs |
| Etapes | Composant propre `EtapesContribution.vue` | Formulaire de contribution en 7 étapes |
| LigneContribution | Composant propre `LigneContribution.vue` | Listes publiques, suggestions avant dépôt |
| Cartogramme | Composant propre `Cartogramme.vue` (positions dans `cartogramme_utr.json`) | Accueil, tableau de bord national, choix d'un territoire |
| Carte précise | `CarteTerritoires.vue` (D3 + TopoJSON, TRD T-07) | Page Carte, fiche d'un territoire |

Les composants propres réutilisent les classes `lbc-` de `components/bundle.css` du système de design, transposées en composants Vue avec les mêmes jetons.

## 6. Mise en œuvre dans Nuxt UI et Tailwind CSS 4

Extrait de `app/assets/css/main.css` (les valeurs viennent de `tokens.json`) :

```css
@import "tailwindcss";
@import "@nuxt/ui";

@theme {
  --font-sans: "Atkinson Hyperlegible Next", system-ui, sans-serif;
  --font-serif: "Literata", Georgia, serif;
  --color-papier: #F4F6F3;
  --color-encre: #14323A;
  --color-lagune-700: #1C5D68;
  --color-lagune-600: #22707C;
  --color-lagune-100: #E3F0F1;
  --color-ocre-500: #A9740F;
  --color-ocre-700: #87590A;
  /* … toutes les couleurs, espacements et rayons de tokens.json */
  --radius-s: 4px;
  --radius-m: 10px;
}
```

Et dans `app.config.ts`, la couleur primaire de Nuxt UI est reliée à l'échelle lagune, la couleur neutre à une échelle dérivée de l'encre ; les rayons par défaut des composants sont ramenés à `rayon-s`.

## 7. Iconographie

Icônes Lucide (collection Iconify `lucide`, disponible hors ligne par le paquet `@iconify-json/lucide`), trait 1,75, 20 px en interface, 24 px dans le parcours mobile. Une icône accompagne un texte ; seules les actions universelles (fermer, menu, rechercher) peuvent être sans texte, avec un libellé accessible.

Pas de logo à ce stade : le nom est composé en Literata semi-grasse. Un logotype éventuel ne reprendra ni le drapeau ni les armoiries.

## 8. Mouvement

| Situation | Durée | Technique |
|---|---|---|
| Survol, focus, ouverture d'un menu | 150 ms | CSS |
| Panneau, fenêtre, notification | 200 à 250 ms | CSS (`transform`, `opacity`) |
| Séquence d'accueil : le fil se tend de la contribution à l'engagement | 1,2 s au plus, une fois | GSAP, chargé seulement sur l'accueil |
| Chiffres clés qui apparaissent | Aucun décompte animé | — |

Tout mouvement est désactivé avec `prefers-reduced-motion: reduce` (`gsap.matchMedia()` côté GSAP).

## 9. Accessibilité

- Focus visible partout : anneau de 3 px `lagune-600`, décalé de 2 px.
- Cibles tactiles de 44 px au moins ; corps de texte de 17 px dans les champs (pas de zoom automatique sur mobile).
- Libellés de formulaire toujours visibles ; erreurs reliées au champ (`aria-describedby`), focus sur le premier champ en erreur.
- Cartogramme et carte doublés d'un tableau ; graphiques accompagnés d'un résumé textuel.
- Vérification automatique par axe à chaque page principale (TRD §13).
