#set period 27.7
set period 20.0
create_clock -period $period [get_ports clk] -name clk
set_output_delay [expr 2*$period/3] [all_outputs] -clock clk
#set input_delay $period/3 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay [expr 2*${period}/3] [all_inputs] -clock clk
