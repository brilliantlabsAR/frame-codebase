default:
	@mkdir -p sim
	
	@iverilog -Wall \
			  -g2012 \
			  -I fpga \
			  -o sim/display_tb.out \
			  -i fpga/modules/graphics/testbenches/display_tb.sv
	
	@vvp sim/display_tb.out \
		 -fst

	@gtkwave sim/display_tb.fst \
			 fpga/modules/graphics/testbenches/display_tb.gtkw