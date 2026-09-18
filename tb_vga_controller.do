# tb_vga_controller.do
# Compilation, elaboration et simulation du testbench du controleur VGA

vlib work

vcom -work work -2002 -explicit vga_controller.vhd
vcom -work work -2002 -explicit tb_vga_controller.vhd

vsim -voptargs="+acc" work.tb_vga_controller

add wave -divider "Entrees"
add wave sim:/tb_vga_controller/pixel_clk
add wave sim:/tb_vga_controller/reset_n
add wave sim:/tb_vga_controller/etat
add wave sim:/tb_vga_controller/cent_tens
add wave sim:/tb_vga_controller/cent_units

add wave -divider "Position balayage (estimee par le TB)"
add wave -radix unsigned sim:/tb_vga_controller/h_pixel
add wave -radix unsigned sim:/tb_vga_controller/v_line

add wave -divider "Sorties VGA"
add wave -radix hexadecimal sim:/tb_vga_controller/VGA_R
add wave -radix hexadecimal sim:/tb_vga_controller/VGA_G
add wave -radix hexadecimal sim:/tb_vga_controller/VGA_B
add wave sim:/tb_vga_controller/VGA_HS
add wave sim:/tb_vga_controller/VGA_VS

add wave -divider "Signaux internes DUT"
add wave -radix unsigned sim:/tb_vga_controller/DUT/h_counter
add wave -radix unsigned sim:/tb_vga_controller/DUT/v_counter
add wave -radix unsigned sim:/tb_vga_controller/DUT/bar_width
add wave sim:/tb_vga_controller/DUT/in_bar_zone
add wave sim:/tb_vga_controller/DUT/in_active_display

# Duree : le TB attend plusieurs trames completes (chaque trame = 800*525*40ns ~ 16.8ms)
# Test 8 attend 10 trames a lui seul -- il faut une duree confortable
run 200 ms

wave zoom full
