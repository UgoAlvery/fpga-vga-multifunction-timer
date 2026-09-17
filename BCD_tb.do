# BCD_tb.do
# Compilation, elaboration et simulation du testbench du compteur BCD

vlib work

vcom -work work -2002 -explicit BCD.vhd
vcom -work work -2002 -explicit BCD_tb.vhd

# +acc pour rendre visibles les signaux internes du DUT (tens, unit_val)
vsim -voptargs="+acc" work.BCD_tb

add wave -divider "Entrees"
add wave sim:/BCD_tb/clk
add wave sim:/BCD_tb/reset_n
add wave sim:/BCD_tb/enable
add wave sim:/BCD_tb/count_up
add wave sim:/BCD_tb/load
add wave sim:/BCD_tb/load_tens
add wave sim:/BCD_tb/load_units

add wave -divider "Sorties"
add wave -radix unsigned sim:/BCD_tb/digit_tens
add wave -radix unsigned sim:/BCD_tb/digit_units
add wave sim:/BCD_tb/carry_out
add wave sim:/BCD_tb/borrow_out

add wave -divider "Verification"
add wave -radix unsigned sim:/BCD_tb/value_dec

add wave -divider "Signaux internes DUT"
add wave -radix unsigned sim:/BCD_tb/DUT/tens
add wave -radix unsigned sim:/BCD_tb/DUT/unit_val

# Duree : reset + 9 + 1 + 49 + 1 + load + 6 + 39 + 1 impulsions,
# chacune sur 2 cycles de 20 ns => on vise large avec marge
run 20 us

wave zoom full
