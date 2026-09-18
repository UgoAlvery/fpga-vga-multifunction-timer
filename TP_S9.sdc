## TP_S9.sdc
## Contraintes temporelles pour TimeQuest STA.
## A placer a la racine du projet Quartus, meme nom que le projet
## (TP_S9.sdc), et ajouter via Assignments > Settings > Timing Analyzer
## > SDC File, ou en le laissant simplement dans le dossier du projet
## (Quartus le detecte automatiquement au nom correspondant).

#--------------------------------------------------------------
# Horloge principale : 50 MHz (periode 20 ns)
#--------------------------------------------------------------
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]

# Marge de securite standard sur les transferts horloge-horloge
# (ici un seul domaine, mais bonne pratique de la calculer explicitement
# plutot que de laisser Quartus improviser)
derive_clock_uncertainty

#--------------------------------------------------------------
# Entrees utilisateur asynchrones (boutons, switches)
# Ces signaux ne sont pas synchronises en amont d'un plan de test
# temporel strict : KEY(1) passe par un synchroniseur/debounce interne
# (donc pas de contrainte de setup/hold pertinente sur le port lui-meme),
# KEY(0) est un reset asynchrone (pas de chemin de donnees classique),
# et les SW sont des signaux de configuration lus en continu, sans
# exigence de synchronisation cycle-precis.
#--------------------------------------------------------------
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]

#--------------------------------------------------------------
# A AJOUTER une fois la PLL (pll_vga) integree au top-level :
#
#   derive_pll_clocks
#
#   set_false_path -from [get_ports {KEY[*]}] -to [get_clocks {pll_vga|altpll_component|auto_generated|pll1|clk[0]}]
#   set_false_path -from [get_ports {SW[*]}]  -to [get_clocks {pll_vga|altpll_component|auto_generated|pll1|clk[0]}]
#
# (Le nom exact du noeud d'horloge genere par la PLL se verifie dans le
# rapport TimeQuest apres une premiere compilation avec la PLL presente
# -- report_clocks dans la console Tcl du Timing Analyzer le donne.)
#--------------------------------------------------------------
