# pin_assignments.tcl
# Assignation des broches physiques de la DE10-Lite pour TP_chrono_top
# Source : Terasic DE10-Lite pin assignment / user manual
#
# A executer dans Quartus via : Tools > Tcl Scripts... > pin_assignments.tcl
# (le projet doit deja exister, avec TP_chrono_top comme top-level)

package require ::quartus::project

set need_to_close_project 0
if {[is_project_open]} {
    if {[string compare $quartus(project) "TP_S9"]} {
        puts "Un autre projet est deja ouvert, fermeture..."
        project_close
        set need_to_close_project 1
    }
} else {
    set need_to_close_project 1
}

if {$need_to_close_project} {
    project_open TP_S9
}

#--------------------------------------------------------------
# Horloge
#--------------------------------------------------------------
set_location_assignment PIN_P11 -to MAX10_CLK1_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MAX10_CLK1_50

#--------------------------------------------------------------
# Push-buttons KEY (actifs bas, anti-rebond materiel Schmitt deja
# present sur la carte -- notre debounce logiciel vient en plus,
# pour filtrer les rebonds residuels et gerer la detection de front)
#--------------------------------------------------------------
set_location_assignment PIN_B8 -to KEY[0]
set_location_assignment PIN_A7 -to KEY[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[1]

#--------------------------------------------------------------
# Slide switches SW(9 downto 0)
#--------------------------------------------------------------
set_location_assignment PIN_C10 -to SW[0]
set_location_assignment PIN_C11 -to SW[1]
set_location_assignment PIN_D12 -to SW[2]
set_location_assignment PIN_C12 -to SW[3]
set_location_assignment PIN_A12 -to SW[4]
set_location_assignment PIN_B12 -to SW[5]
set_location_assignment PIN_A13 -to SW[6]
set_location_assignment PIN_A14 -to SW[7]
set_location_assignment PIN_B14 -to SW[8]
set_location_assignment PIN_F15 -to SW[9]
for {set i 0} {$i <= 9} {incr i} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[$i]
}

#--------------------------------------------------------------
# LEDR(9 downto 0) -- actifs hauts
#--------------------------------------------------------------
set_location_assignment PIN_A8  -to LEDR[0]
set_location_assignment PIN_A9  -to LEDR[1]
set_location_assignment PIN_A10 -to LEDR[2]
set_location_assignment PIN_B10 -to LEDR[3]
set_location_assignment PIN_D13 -to LEDR[4]
set_location_assignment PIN_C13 -to LEDR[5]
set_location_assignment PIN_E14 -to LEDR[6]
set_location_assignment PIN_D14 -to LEDR[7]
set_location_assignment PIN_A11 -to LEDR[8]
set_location_assignment PIN_B11 -to LEDR[9]
for {set i 0} {$i <= 9} {incr i} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[$i]
}

#--------------------------------------------------------------
# Afficheurs 7 segments HEX0-HEX5(6 downto 0) -- actifs bas
#--------------------------------------------------------------
# HEX0
set_location_assignment PIN_C14 -to HEX0[0]
set_location_assignment PIN_E15 -to HEX0[1]
set_location_assignment PIN_C15 -to HEX0[2]
set_location_assignment PIN_C16 -to HEX0[3]
set_location_assignment PIN_E16 -to HEX0[4]
set_location_assignment PIN_D17 -to HEX0[5]
set_location_assignment PIN_C17 -to HEX0[6]

# HEX1
set_location_assignment PIN_C18 -to HEX1[0]
set_location_assignment PIN_D18 -to HEX1[1]
set_location_assignment PIN_E18 -to HEX1[2]
set_location_assignment PIN_B16 -to HEX1[3]
set_location_assignment PIN_A17 -to HEX1[4]
set_location_assignment PIN_A18 -to HEX1[5]
set_location_assignment PIN_B17 -to HEX1[6]

# HEX2
set_location_assignment PIN_B20 -to HEX2[0]
set_location_assignment PIN_A20 -to HEX2[1]
set_location_assignment PIN_B19 -to HEX2[2]
set_location_assignment PIN_A21 -to HEX2[3]
set_location_assignment PIN_B21 -to HEX2[4]
set_location_assignment PIN_C22 -to HEX2[5]
set_location_assignment PIN_B22 -to HEX2[6]

# HEX3
set_location_assignment PIN_F21 -to HEX3[0]
set_location_assignment PIN_E22 -to HEX3[1]
set_location_assignment PIN_E21 -to HEX3[2]
set_location_assignment PIN_C19 -to HEX3[3]
set_location_assignment PIN_C20 -to HEX3[4]
set_location_assignment PIN_D19 -to HEX3[5]
set_location_assignment PIN_E17 -to HEX3[6]

# HEX4
set_location_assignment PIN_F18 -to HEX4[0]
set_location_assignment PIN_E20 -to HEX4[1]
set_location_assignment PIN_E19 -to HEX4[2]
set_location_assignment PIN_J18 -to HEX4[3]
set_location_assignment PIN_H19 -to HEX4[4]
set_location_assignment PIN_F19 -to HEX4[5]
set_location_assignment PIN_F20 -to HEX4[6]

# HEX5
set_location_assignment PIN_J20 -to HEX5[0]
set_location_assignment PIN_K20 -to HEX5[1]
set_location_assignment PIN_L18 -to HEX5[2]
set_location_assignment PIN_N18 -to HEX5[3]
set_location_assignment PIN_M20 -to HEX5[4]
set_location_assignment PIN_N19 -to HEX5[5]
set_location_assignment PIN_N20 -to HEX5[6]

for {set h 0} {$h <= 5} {incr h} {
    for {set s 0} {$s <= 6} {incr s} {
        set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX$h\[$s\]
    }
}

#--------------------------------------------------------------
# Port VGA (DAC R-2R 4 bits par couleur) + synchros
#--------------------------------------------------------------
set_location_assignment PIN_AA1 -to VGA_R[0]
set_location_assignment PIN_V1  -to VGA_R[1]
set_location_assignment PIN_Y2  -to VGA_R[2]
set_location_assignment PIN_Y1  -to VGA_R[3]

set_location_assignment PIN_W1  -to VGA_G[0]
set_location_assignment PIN_T2  -to VGA_G[1]
set_location_assignment PIN_R2  -to VGA_G[2]
set_location_assignment PIN_R1  -to VGA_G[3]

set_location_assignment PIN_P1  -to VGA_B[0]
set_location_assignment PIN_T1  -to VGA_B[1]
set_location_assignment PIN_P4  -to VGA_B[2]
set_location_assignment PIN_N2  -to VGA_B[3]

set_location_assignment PIN_N3  -to VGA_HS
set_location_assignment PIN_N1  -to VGA_VS

for {set c 0} {$c <= 3} {incr c} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[$c]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[$c]
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[$c]
}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS

#--------------------------------------------------------------
# Sauvegarde
#--------------------------------------------------------------
export_assignments

if {$need_to_close_project} {
    project_close
}