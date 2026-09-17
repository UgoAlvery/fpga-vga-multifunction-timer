# fsm_controle_tb.do
# Compilation, elaboration et simulation du testbench de la FSM de controle

vlib work

vcom -work work -2002 -explicit fsm_controle.vhd
vcom -work work -2002 -explicit fsm_controle_tb.vhd

# +acc pour rendre visibles les signaux internes (state_reg, state_next)
vsim -voptargs="+acc" work.fsm_controle_tb

add wave -divider "Entrees"
add wave sim:/fsm_controle_tb/clk
add wave sim:/fsm_controle_tb/reset_n
add wave sim:/fsm_controle_tb/key1

add wave -divider "Sortie"
add wave sim:/fsm_controle_tb/etat

add wave -divider "Signaux internes DUT"
add wave sim:/fsm_controle_tb/DUT/state_reg
add wave sim:/fsm_controle_tb/DUT/state_next

run 400 ns

wave zoom full
