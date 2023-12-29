/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

module camera_peripheral (
    input logic clock,
    input logic reset_n,
    input logic enable,
    
    input logic data_in_valid,
    output logic [7:0] data_out,
    output logic data_out_valid,
    output logic [15:0] camera_ram_read_address,
    input logic [31:0] camera_ram_read_data,
	output logic camera_ram_read_enable
);

	logic [1:0] byte_counter;
    logic [1:0] data_in_valid_reg;
    always_ff @(posedge clock) begin
        
        if (enable == 0 | reset_n == 0) begin
            data_out_valid <= 0;
            camera_ram_read_enable <= 0;
			byte_counter <= 0;
			//TODO: change this based on image config
			if (camera_ram_read_address >= 'd10000 | reset_n == 0)
				camera_ram_read_address <= 0;
        end

        else begin
            camera_ram_read_enable <= 1;
            data_in_valid_reg <= {data_in_valid_reg[0], data_in_valid};
			case (byte_counter)
				'b00 : data_out <= camera_ram_read_data[31:24];
				'b01 : data_out <= camera_ram_read_data[23:16];
				'b10 : data_out <= camera_ram_read_data[15:8];
				'b11 : data_out <= camera_ram_read_data[7:0];
			endcase
			
            if (data_in_valid_reg == 'b01) begin
				byte_counter <= byte_counter + 1;
                data_out_valid <= 1;
				if (byte_counter == 'b11)
					camera_ram_read_address <= camera_ram_read_address + 1;
            end
            else if (data_in_valid_reg == 'b10 | data_in_valid_reg == 'b00) begin
                data_out_valid <= 1;
            end
        end

    end

endmodule