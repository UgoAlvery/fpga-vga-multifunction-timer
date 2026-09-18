# chenillard_tb.do
# Compilation, elaboration et simulation du testbench du chenillard

vlib work

vcom -work work -2002 -explicit chenillard.vhd
vcom -work work -2002 -explicit chenillard_tb.vhd

# +acc pour rendre visibles les signaux internes (position, going_up)
vsim -voptargs="+acc" work.chenillard_tb

add wave -divider "Entrees"
add wave sim:/chenillard_tb/clk
add wave sim:/chenillard_tb/reset_n
add wave sim:/chenillard_tb/enable

add wave -divider "Sortie"
add wave -radix binary sim:/chenillard_tb/leds

add wave -divider "Signaux internes DUT"
add wave -radix unsigned sim:/chenillard_tb/DUT/position
add wave sim:/chenillard_tb/DUT/going_up

run 1 us

wave zoom full
