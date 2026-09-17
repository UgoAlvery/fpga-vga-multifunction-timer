# Spécification d'interface — Contrôleur VGA (TP Chronomètre/Minuteur)

## Contexte

Le chronomètre/minuteur est déjà fonctionnel sur carte (FSM de contrôle, compteur BCD,
affichage 7-segments, tout validé en simulation et testé physiquement). Il ne reste que
le contrôleur VGA à écrire. Ce bloc est volontairement conçu pour être **développé et
simulé de façon totalement indépendante** du reste du design : il ne consomme que deux
signaux déjà stables, décrits ci-dessous.

## Ce qu'affiche l'écran (rappel du cahier des charges)

Pas d'affichage numérique du temps — uniquement un indicateur visuel :

| État FSM | Fond d'écran | Barre de progression |
|----------|--------------|----------------------|
| STOP     | Bleu pur (`R=0x0, G=0x0, B=0xF`) | Masquée (largeur 0) |
| RUN      | Vert pur (`R=0x0, G=0xF, B=0x0`) | Blanche (`RGB=0xFFF`), s'allonge de 0 à 594 px, 6 px par centième de seconde, repart de zéro à 99 |
| PAUSE    | Rouge pur (`R=0xF, G=0x0, B=0x0`) | Figée à sa largeur exacte au moment du passage en pause |

Résolution cible : **640×480 @ 60 Hz**, pixel clock **25 MHz** (généré par une PLL, voir
note en fin de document — pour l'instant, il suffit de simuler avec une horloge à 25 MHz
directement).

La barre occupe les lignes **401 à 439** de l'écran (hauteur ~39 px), largeur maximale
594 px sur 640, positionnée à partir du bord gauche.

## Interface à respecter

```vhdl
entity vga_controller is
  port (
    pixel_clk   : in  std_logic;                     -- 25 MHz
    reset_n     : in  std_logic;                     -- actif bas, async

    -- Entrées venant du reste du design (deja stables et testees)
    etat        : in  std_logic_vector(1 downto 0);  -- "00"=STOP, "01"=RUN, "10"=PAUSE
    cent_tens   : in  std_logic_vector(3 downto 0);  -- dizaine des centiemes (BCD, 0-9)
    cent_units  : in  std_logic_vector(3 downto 0);  -- unite des centiemes (BCD, 0-9)

    -- Sorties vers le port VGA physique
    VGA_R       : out std_logic_vector(3 downto 0);  -- DAC R-2R 4 bits
    VGA_G       : out std_logic_vector(3 downto 0);
    VGA_B       : out std_logic_vector(3 downto 0);
    VGA_HS      : out std_logic;                     -- sync horizontale
    VGA_VS      : out std_logic                       -- sync verticale
  );
end entity;
```

**Important sur `cent_tens`/`cent_units`** : ce sont des digits BCD indépendants
(0-9 chacun), pas une valeur binaire combinée. La valeur en centièmes à reconstituer pour
le calcul de largeur de barre est `cent_tens * 10 + cent_units` (0 à 99). Ce calcul est à
faire en interne dans le contrôleur VGA (un simple `to_integer` après reconstruction, ou
une table de correspondance — au choix).

## Timings VGA 640×480@60Hz (standard VESA, à respecter pour les compteurs de balayage)

| Paramètre | Horizontal (pixels) | Vertical (lignes) |
|-----------|---------------------|--------------------|
| Zone active | 640 | 480 |
| Front porch | 16 | 10 |
| Sync pulse | 96 | 2 |
| Back porch | 48 | 33 |
| Total | 800 | 525 |

Polarité des synchros : négative (`HS`/`VS` actifs bas pendant l'impulsion) pour ce
standard 640×480@60Hz.

## Ce qui reste hors du périmètre de ce bloc

- La génération du pixel clock à 25 MHz elle-même (ALTPLL) — sera branchée après coup,
  pas la responsabilité de ce bloc.
- L'intégration dans `TP_chrono_top.vhd` — je m'en charge une fois le bloc livré et
  simulé.

## Attendu en retour

- Le fichier `.vhd` de l'entité `vga_controller` telle que décrite ci-dessus.
- Un testbench qui injecte directement des valeurs sur `etat` et `cent_tens`/`cent_units`
  (pas besoin du reste du design) et vérifie au minimum :
  - la couleur de fond correcte pour chaque état
  - la largeur de la barre pour quelques valeurs de centièmes (0, 50, 99)
  - que la barre est bien masquée en STOP et figée en PAUSE
