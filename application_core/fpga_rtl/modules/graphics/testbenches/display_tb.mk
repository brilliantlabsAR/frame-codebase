FPGA_DIR = application_core/fpga_rtl

default:
	@mkdir -p sim
	
	@iverilog -Wall \
			  -g2012 \
			  -I $(FPGA_DIR) \
			  -o sim/display_tb.out \
			  -i $(FPGA_DIR)/modules/graphics/testbenches/display_tb.sv
	
	@vvp sim/display_tb.out \
		 -fst

	@gtkwave sim/display_tb.fst \
			 $(FPGA_DIR)/modules/graphics/testbenches/display_tb.gtkw