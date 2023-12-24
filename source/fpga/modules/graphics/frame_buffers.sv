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
 
module frame_buffers (
    input logic clock_in,
    input logic reset_n_in,

    input logic [17:0] pixel_write_address_in,
    input logic [3:0] pixel_write_data_in,
    output logic pixel_write_buffer_ready_out,

    input logic [17:0] pixel_read_address_in,
    output logic [3:0] pixel_read_data_out,

    input logic switch_write_buffer_in
);
    
logic currently_displayed_buffer = 0;
logic [1:0] switch_write_buffer_edge_monitor = 0;
logic buffer_switch_pending = 0;

always_ff @(posedge clock_in) begin
        
    if (reset_n_in == 0) begin

        pixel_write_buffer_ready_out <= 0;
        pixel_read_data_out <= 0;

        currently_displayed_buffer <= 0;
        switch_write_buffer_edge_monitor <= 'b00;
        buffer_switch_pending = 0;

    end

    else begin
        
        switch_write_buffer_edge_monitor <= {
            switch_write_buffer_edge_monitor[0], 
            switch_write_buffer_in
        };

        if (switch_write_buffer_edge_monitor == 'b01) begin
            buffer_switch_pending <= 1;
        end

        if (buffer_switch_pending == 1 && pixel_read_address_in == 0) begin
            currently_displayed_buffer <= ~currently_displayed_buffer;
            buffer_switch_pending <= 0;
        end
    
        if (currently_displayed_buffer == 0) begin
            if      (pixel_read_address_in < 25  * 640) pixel_read_data_out <= 0;
            else if (pixel_read_address_in < 50  * 640) pixel_read_data_out <= 1;
            else if (pixel_read_address_in < 75  * 640) pixel_read_data_out <= 2;
            else if (pixel_read_address_in < 100 * 640) pixel_read_data_out <= 3;
            else if (pixel_read_address_in < 125 * 640) pixel_read_data_out <= 4;
            else if (pixel_read_address_in < 150 * 640) pixel_read_data_out <= 5;
            else if (pixel_read_address_in < 175 * 640) pixel_read_data_out <= 6;
            else if (pixel_read_address_in < 200 * 640) pixel_read_data_out <= 7;
            else if (pixel_read_address_in < 225 * 640) pixel_read_data_out <= 8;
            else if (pixel_read_address_in < 250 * 640) pixel_read_data_out <= 9;
            else if (pixel_read_address_in < 275 * 640) pixel_read_data_out <= 10;
            else if (pixel_read_address_in < 300 * 640) pixel_read_data_out <= 11;
            else if (pixel_read_address_in < 325 * 640) pixel_read_data_out <= 12;
            else if (pixel_read_address_in < 350 * 640) pixel_read_data_out <= 13;
            else if (pixel_read_address_in < 375 * 640) pixel_read_data_out <= 14;
            else if (pixel_read_address_in < 400 * 640) pixel_read_data_out <= 15;
            else                                        pixel_read_data_out <= 0;

        end

        else begin
            if      (pixel_read_address_in < 100 * 640) pixel_read_data_out <= 0;
            else if (pixel_read_address_in < 200 * 640) pixel_read_data_out <= 1;
            else if (pixel_read_address_in < 300 * 640) pixel_read_data_out <= 2;
            else if (pixel_read_address_in < 400 * 640) pixel_read_data_out <= 3;
            else                                        pixel_read_data_out <= 0;
        end

    end

end

endmodule