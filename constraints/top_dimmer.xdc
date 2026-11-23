
# ============================================================
# PROYECTO: DIMMER DIGITAL ELDI
# TOP: top_dimmer
# FPGA: Digilent Nexys 4 DDR - Artix-7
# RELOJ: 100 MHz
# ============================================================

# ------------------------------------------------------------
# 1. RELOJ PRINCIPAL
# ------------------------------------------------------------

set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -name clk_100MHz -period 10.000 [get_ports { clk }]

# ------------------------------------------------------------
# 2. RESET
# ------------------------------------------------------------

set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { CPU_RESETN }]

## ENTRADAS ANALOGICAS XADC - CANAL VAUX3
## Se conserva la asignacion fisica, sin imponer IOSTANDARD.

set_property -dict { PACKAGE_PIN A13 IOSTANDARD LVCMOS33 } [get_ports {vauxp3}]
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports {vauxn3}]

# ------------------------------------------------------------
# 4. DETECTOR DE CRUCE POR CERO
# JA1 - Pin C17
# ------------------------------------------------------------

set_property -dict { PACKAGE_PIN C17 IOSTANDARD LVCMOS33 } [get_ports { zc_in }]

# ------------------------------------------------------------
# 5. SALIDA HACIA INTERFAZ AISLADA M8
# JA2 - Pin D18
# ------------------------------------------------------------

set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 DRIVE 16 SLEW SLOW } [get_ports { gate_pulse }]

# ------------------------------------------------------------
# 6. RESTRICCIONES DE RUTAS ASINCRONAS
# ------------------------------------------------------------

set_false_path -from [get_ports { zc_in }]
set_false_path -from [get_ports { CPU_RESETN }]

# ------------------------------------------------------------
#  CONFIGURACION DEL BANCO 0 DE LA FPGA
# ------------------------------------------------------------

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ============================================================
# FIN DE RESTRICCIONES
# ============================================================
