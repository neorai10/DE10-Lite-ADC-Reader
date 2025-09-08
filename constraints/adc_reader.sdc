# SDC (Synopsys Design Constraints) file for DE10-Lite ADC Reader project
# This file contains timing constraints

# Create clock constraints
create_clock -name "MAX10_CLK1_50" -period 20.000ns [get_ports {MAX10_CLK1_50}]
# Note: ADC_CLK_10 timing handled internally by QSYS/PLL

# Set clock uncertainty (jitter)
set_clock_uncertainty -add 0.1 [get_clocks MAX10_CLK1_50]
# Note: ADC clock uncertainty handled by QSYS

# Set input delay constraints for external signals
set_input_delay -clock MAX10_CLK1_50 2.0 [get_ports KEY[*]]
set_input_delay -clock MAX10_CLK1_50 2.0 [get_ports SW[*]]

# Set output delay constraints  
set_output_delay -clock MAX10_CLK1_50 2.0 [get_ports LEDR[*]]
set_output_delay -clock MAX10_CLK1_50 2.0 [get_ports HEX*[*]]

# Set false paths for asynchronous inputs
set_false_path -from [get_ports KEY[*]] -to [all_registers]
set_false_path -from [get_ports SW[*]] -to [all_registers]