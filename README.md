\# FPGA VGA Multifunction Timer



Chronomètre / minuteur numérique implémenté en VHDL sur FPGA (Terasic DE10-Lite,

Intel MAX 10), avec affichage 7-segments et sortie vidéo VGA synchronisée sur l'état

du système.



\## Aperçu



\- Comptage ascendant (chronomètre) ou descendant (minuteur), sélectionnable

\- Affichage MM:SS:CC sur 6 afficheurs 7-segments

\- Sortie VGA 640×480@60Hz : fond de couleur et barre de progression reflétant en

&#x20; temps réel l'état du système (arrêt / en cours / pause)

\- Anti-rebond et détection de front matériels pour les boutons physiques

\- Architecture entièrement modulaire, chaque bloc validé par testbench avant intégration



\## Statut du projet



| Bloc | État |

|------|------|

| FSM de contrôle (STOP/RUN/PAUSE) | ✅ Simulé + validé sur carte |

| Anti-rebond / détection de front | ✅ Simulé + validé sur carte |

| Compteur BCD 3 étages (MM:SS:CC) | ✅ Simulé + validé sur carte |

| Décodeur 7-segments | ✅ Simulé + validé sur carte |

| Contrôleur VGA | 🔧 En cours |

| PLL (pixel clock 25 MHz) | 🔧 En cours |

| Contraintes temporelles (.sdc / STA) | ⏳ À faire |

| Instrumentation SignalTap | ⏳ À faire |

| Programmation Flash (boot autonome) | ⏳ À faire |



\## Architecture



```

&#x20;                   ┌──────────────┐

&#x20;  KEY(1) ───────▶  │  debounce +  │

&#x20;                   │ edge detect  │──▶ key1\_pulse

&#x20;                   └──────────────┘         │

&#x20;                                             ▼

&#x20;  KEY(0) ──────────────────────────▶ ┌──────────────┐

&#x20;  (reset async)         ┌──────────▶ │ fsm\_controle │──▶ etat (STOP/RUN/PAUSE)

&#x20;                        │            └──────────────┘         │

&#x20;                        │                                     │

&#x20;             ┌──────────────┐                                 │

&#x20;             │  tick\_gen    │──▶ tick\_10ms (gate sur RUN)      │

&#x20;             └──────────────┘         │                       │

&#x20;                                       ▼                       ▼

&#x20;                             ┌──────────────────┐    ┌──────────────────┐

&#x20;               SW(0) ───────▶│  chrono\_counter  │    │  vga\_controller  │──▶ VGA\_R/G/B

&#x20;             (mode)          │ (3 x BCD chaîné) │───▶│  (en cours)      │    VGA\_HS/VS

&#x20;                             └──────────────────┘    └──────────────────┘

&#x20;                                       │

&#x20;                                       ▼

&#x20;                             ┌──────────────────┐

&#x20;                             │ seg7\_decoder\_array│──▶ HEX0-HEX5

&#x20;                             └──────────────────┘

```



\## Matériel



\- Carte Terasic DE10-Lite (FPGA Intel MAX 10, `10M50DAF484C7G`)

\- Écran + câble VGA

\- Câble USB (USB-Blaster embarqué)



\## Outils



\- Quartus Prime Lite 24.1 (synthèse, placement-routage, programmation)

\- Questa / ModelSim (simulation, testbenches VHDL)



\## Structure du dépôt



```

├── fsm\_controle.vhd          FSM de contrôle STOP/RUN/PAUSE

├── FSM.vhd                   Anti-rebond + détection de front (debounce)

├── BCD.vhd                   Compteur BCD 2 digits générique

├── chrono\_counter.vhd        Chaînage des 3 étages BCD (centièmes/secondes/minutes)

├── tick\_gen.vhd               Diviseur d'horloge générique

├── seg7\_decoder\_array.vhd    Décodage BCD → 7 segments (6 afficheurs)

├── TP\_chrono\_top.vhd          Top-level d'intégration

├── pin\_assignments.tcl       Script d'assignation des broches (Pin Planner)

├── \*\_tb.vhd                  Testbenches associés à chaque bloc

└── \*.do                      Scripts de simulation Questa

```



\## Simulation



Chaque bloc dispose de son propre testbench et script `.do`, exécutable

indépendamment sous Questa/ModelSim :



```

vsim -do BCD\_tb.do

```



\## Points techniques notables



\- Anti-rebond par échantillonnage périodique + registre à décalage (plutôt qu'un

&#x20; compteur à stabilité N cycles), pour une détection robuste sans délai variable

&#x20; sur rebond malchanceux

\- Compteurs BCD génériques (paramétrés par `MAX`), réutilisés pour les 3 échelles

&#x20; de temps (centièmes/secondes/minutes) sans duplication de code

\- Chaînage des étages via signaux `carry`/`borrow` d'un cycle, sans logique

&#x20; combinatoire intermédiaire

