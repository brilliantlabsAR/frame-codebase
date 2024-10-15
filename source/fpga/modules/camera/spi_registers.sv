/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Chips & Scripts (rmetchev@ieee.org) 
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2024 Brilliant Labs Limited
 */
 
 module spi_registers (
    input logic clock_in,
    input logic reset_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,
    output logic [7:0] response_out,
    output logic response_valid_out,

    output logic start_capture_out,
    output logic [9:0] half_resolution_out, 
    output logic [1:0] compression_factor_out,
    output logic power_save_enable_out,

    input logic image_ready_in,
    input logic [15:0] image_total_size_in,
    input logic [7:0] image_data_in,
    output logic [15:0] image_address_out,

    input logic [7:0] red_center_metering_in,
    input logic [7:0] green_center_metering_in,
    input logic [7:0] blue_center_metering_in,
    input logic [7:0] red_average_metering_in,
    input logic [7:0] green_average_metering_in,
    input logic [7:0] blue_average_metering_in
);

logic [15:0] bytes_remaining;
assign bytes_remaining = image_total_size_in - image_address_out;

logic [1:0] operand_valid_in_edge_monitor;

always_ff @(posedge clock_in) begin
    
    if (reset_n_in == 0) begin
        response_out <= 0;
        response_valid_out <= 0;

        start_capture_out <= 0;
        half_resolution_out <= 256;
        compression_factor_out <= 0;
        power_save_enable_out <= 0;

        image_address_out <= 0;

        operand_valid_in_edge_monitor <= 0;
    end

    else begin
        operand_valid_in_edge_monitor <= {operand_valid_in_edge_monitor[0], 
                                          operand_valid_in};

        if (op_code_valid_in) begin

            case (op_code_in)

                // Capture
                'h20: begin
                    start_capture_out <= 1;
                    image_address_out <= 0;
                end

                // Bytes available
                'h21: begin
                    case (operand_count_in)
                        0: response_out <= bytes_remaining[15:8];
                        1: response_out <= bytes_remaining[7:0];
                    endcase

                    response_valid_out <= 1;
                end

                // Read data
                'h22: begin
                    response_out <= image_data_in;

                    if (operand_valid_in_edge_monitor == 2'b01) begin
                        if (image_address_out < image_total_size_in) begin 
                            image_address_out <= image_address_out + 1;
                        end
                    end

                    response_valid_out <= 1;
                end

                // Zoom
                'h23: begin
                    if (operand_valid_in) begin 
                        case (operand_count_in)
                            0: begin /* Do nothing */ end
                            1: half_resolution_out <= {operand_in[1:0], 8'b0};
                            2: half_resolution_out <= {half_resolution_out[9:8], operand_in};
                        endcase
                    end
                end

                // Metering
                'h25: begin
                    case (operand_count_in)
                        0: response_out <= red_center_metering_in;
                        1: response_out <= green_center_metering_in;
                        2: response_out <= blue_center_metering_in;
                        3: response_out <= red_average_metering_in;
                        4: response_out <= green_average_metering_in;
                        5: response_out <= blue_average_metering_in;
                    endcase

                    response_valid_out <= 1;
                end

                // Compression factor
                'h26: begin
                    if (operand_valid_in) begin 
                        compression_factor_out <= operand_in[1:0];
                    end
                end

                // Image ready flag
                'h27: begin
                    response_out <= {7'b0, image_ready_in};
                    response_valid_out <= 1;
                end

                // Power saving
                'h28: begin
                   if (operand_valid_in) begin 
                        power_save_enable_out <= operand_in[0];
                    end
                end

            endcase

        end

        else begin
            response_valid_out <= 0;

            start_capture_out <= 0;
        end

    end

end

endmodule