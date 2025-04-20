#*******************************************************************************
##  file: porta_glue_coleco.sdc
##  author: Jay Convertino (electrobs@gmail.com)
##  date: 01/01/2024
##  brief: Constraints based upon external devices.
##          - 6116LA20 RAM
##          - Z80 cmos 10MHz CPU
##          - 74LS138
##          - 27C256 ROM 150 NS
##          - 76489
##          - TMS9918
## Partially auto-generated
#*******************************************************************************

# Clock constraints
# 3.579545 MHz
create_clock -name "ntsc_clock" -period 279.365ns [get_ports {clk}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# input delays
set_input_delay -clock "ntsc_clock" 65.000ns [get_ports {A[*]}]

set_input_delay -clock "ntsc_clock" 65.000ns [get_ports {MREQn}]
 
set_input_delay -clock "ntsc_clock" 55.000ns [get_ports {IORQn}]
 
set_input_delay -clock "ntsc_clock" 55.000ns [get_ports {WRn}]

set_input_delay -clock "ntsc_clock" 55.000ns [get_ports {RDn}]

set_input_delay -clock "ntsc_clock" 40.000ns [get_ports {RESETn}]

set_input_delay -clock "ntsc_clock" 80.000ns [get_ports {RFSHn}]

set_input_delay -clock "ntsc_clock" 10.000ns [get_ports {D[*]}]

# output delays
set_output_delay -clock "ntsc_clock" -min 10.000ns  [get_ports {D[*]}]
set_output_delay -clock "ntsc_clock" -max 100.000ns [get_ports {D[*]}]

set_output_delay -clock "ntsc_clock" 100.000ns [get_ports {RAM_CSn}]

set_output_delay -clock "ntsc_clock" 100.000ns [get_ports {RAM_OEn}]

set_output_delay -clock "ntsc_clock" 150.000ns [get_ports {AY_CSn}]

set_output_delay -clock "ntsc_clock" 150.000ns [get_ports {AY_AS}]

set_output_delay -clock "ntsc_clock" 100.000ns [get_ports {DIS_MEM}]
