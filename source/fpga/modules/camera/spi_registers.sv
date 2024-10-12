/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2024 Brilliant Labs Limited
 */
 
 module spi_registers (
    input logic clock_in,
    input logic reset_n_in,

    // SPI interface
    input logic [7:0] opcode_in,
    input logic [7:0] operand_in,
    input logic operand_read,
    input logic operand_valid_in,
    input logic [31:0] rd_operand_count_in,
    output logic [7:0] response_out,

    output logic start_capture_out,
    // TODO position signals
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

// register addresses
parameter START_CAPTURE     = 'h20; // WO + reset
parameter BYTES_REMAINING   = 'h21; // RO
parameter IMAGE_DATA        = 'h22; // RO + increment
parameter ZOOM              = 'h23; // WO
parameter PAN               = 'h24; // WO
parameter METERING          = 'h25; // RO
parameter QUALITY_FACTOR    = 'h26; // WO
parameter IMAGE_READY_FLAG  = 'h27; // RO
parameter POWER_SAVE_ENABLE = 'h28; // WO

logic [15:0] bytes_remaining;
assign bytes_remaining = image_total_size_in - image_address_out;

always_comb
     case (opcode_in)
         // Bytes available
         BYTES_REMAINING:
         case (rd_operand_count_in)
             0: response_out = bytes_remaining[15:8];
             default: response_out = bytes_remaining[7:0];
         endcase

         // Read data
         IMAGE_DATA: response_out = image_data_in;

         // Metering
         METERING:
         case (rd_operand_count_in)
             0: response_out = red_center_metering_in;
             1: response_out = green_center_metering_in;
             2: response_out = blue_center_metering_in;
             3: response_out = red_average_metering_in;
             4: response_out = green_average_metering_in;
             default: response_out = blue_average_metering_in;
         endcase

         // Image ready flag
         IMAGE_READY_FLAG: response_out = image_ready_in;

         default: response_out = 0;
     endcase


// combinatorial!
always_comb start_capture_out = operand_valid_in & opcode_in == START_CAPTURE;

always_ff @(negedge clock_in) begin
    
    if (reset_n_in == 0) begin
        // TODO position signals
        compression_factor_out <= 0;
        power_save_enable_out <= 1;
        image_address_out <= 0;
    end

    else begin
        if (operand_read) begin
            case (opcode_in)
                // Read data
                IMAGE_DATA: begin
                    if (image_address_out < image_total_size_in) begin 
                        image_address_out <= image_address_out + 1;
                    end
                end
            endcase
        end

        if (operand_valid_in) begin

            case (opcode_in)

                // Capture
                START_CAPTURE: begin
                    image_address_out <= 0;
                end

                // Zoom
                ZOOM: begin
                    // zoom_factor <= operand_in; // TODO
                end

                // Pan
                PAN: begin
                    // pan_level <= operand_in; // TODO
                end

                // Compression factor
                QUALITY_FACTOR: begin
                    compression_factor_out <= operand_in[1:0];
                end

                // Power saving
                POWER_SAVE_ENABLE: begin
                    power_save_enable_out <= operand_in[0];
                end

            endcase

        end

    end

end

endmodule
