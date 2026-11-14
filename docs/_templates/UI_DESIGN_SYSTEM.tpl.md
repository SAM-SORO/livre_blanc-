# UI_DESIGN_SYSTEM — Système de design « Livre Blanc Citoyen »

| Champ | Valeur |
|---|---|
| Version | 1.0 — phase 4 (conception des interfaces), soumise à validation |
| Référence vivante | Système de design publié : https://claude.ai/artifact/DfXqub2mvjMZioUEtu46aZ (charte, jetons, composants avec aperçus) |
| Maquettes | https://claude.ai/artifact/X6kd7pKY6dWMFdvwH5hjqg (6 écrans) |
| Sources dans le dépôt | `design/design-system/project/` (tokens.json, README.md, components/), `design/cartogramme_utr.json` |
| Documents liés | `UX_SPECIFICATIONS.md`, `APP_FLOW.md`, `TRD.md` (T-06, T-07, T-08, §12) |

**Règle pour Claude Code :** `design/design-system/project/tokens.json` est la source des valeurs. Le fichier `app/assets/css/main.css` les reprend dans un bloc `@theme` (§6) ; aucune couleur, taille ou espacement n'est écrit en dur dans un composant.

---

## 1. Direction artistique

L'application sert à la fois des citoyens sur des téléphones d'entrée de gamme et une administration qui produit des documents officiels. La direction retenue est **sobre, territoriale et documentaire** :

- **Territoriale** : la palette vient du paysage ivoirien (bleu-vert de la lagune, ocre des pistes et de la savane, vert de la forêt), sans reprendre le drapeau ni aucune couleur de parti (décision D-15, principe de neutralité).
- **Documentaire** : un serif de lecture (Literata) donne aux titres et aux livres blancs le registre d'un document public ; une sans-serif conçue pour la lisibilité (Atkinson Hyperlegible Next) porte toute l'interface.
- **Un motif propre, le fil** : un trait ocre qui relie la contribution à la préoccupation, au livre blanc, à la priorité nationale et à l'engagement. C'est le seul usage étendu de la couleur chaude, et l'élément dont on se souvient.
- **Le cartogramme en tuiles** : les 33 territoires en carrés égaux. Il traduit visuellement le principe « chaque territoire compte autant » et sert d'image d'accueil.

Écarté volontairement : fonds crème, dégradés, cartes à ombre portée répétées, étiquettes en majuscules, émoji, illustrations de personnes.

## 2. Couleurs

{{COULEURS}}

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

{{TYPO}}

Les polices sont **auto-hébergées** (fichiers woff2 dans `public/fonts/`, sous-ensemble latin étendu, `font-display: swap`) : l'application fonctionne hors connexion (C-02) et ne transmet aucune donnée à un service tiers. Literata est chargée avec son axe de taille optique.

## 4. Espacements, rayons, ombres et traits

{{ESPACES}}

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
