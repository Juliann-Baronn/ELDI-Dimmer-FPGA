
#======================================================
# PROYECTO: DIMMER DIGITAL ELDI
# MODULO: M3 - pot_to_delay
# FPGA: Nexys 4 DDR - Artix-7
#
# RESTRICCIONES TEMPORALES
# Reloj principal: 100 MHz
# Periodo: 10 ns
#======================================================


#------------------------------------------------------
# 1. RELOJ PRINCIPAL
#------------------------------------------------------

# Define el reloj de entrada del modulo.
# Periodo de 10 ns = frecuencia de 100 MHz.

create_clock -name clk_100MHz -period 10.000 [get_ports clk]


#======================================================
# FIN DE RESTRICCIONES INICIALES M3
#======================================================
