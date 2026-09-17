# debounce_tb.do
# Compilation, elaboration et simulation du testbench debounce

vlib work

vcom -work work -2002 -explicit FSM.vhd
vcom -work work -2002 -explicit FSM_tb.vhd

vsim -voptargs="+acc" work.debounce_tb

# Ajout des signaux au chronogramme
add wave -divider "Entrees/Sorties"
add wave sim:/debounce_tb/clk
add wave sim:/debounce_tb/reset_n
add wave sim:/debounce_tb/btn_in
add wave sim:/debounce_tb/btn_pulse

add wave -divider "Signaux internes DUT"
add wave sim:/debounce_tb/DUT/sync_reg
add wave sim:/debounce_tb/DUT/tick
add wave sim:/debounce_tb/DUT/shift_reg
add wave sim:/debounce_tb/DUT/stable

add wave -divider "Verification"
add wave sim:/debounce_tb/pulse_count

# Duree totale : ~5+5 (reset) + phases de rebond (~150us) + 3x10ms stabilisation
# => on vise large, 35 ms couvre tout le scenario avec marge
run 35 ms

wave zoom full