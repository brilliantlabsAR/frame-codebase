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
    
(* lram *) reg [7:0] frame_buffer_a [0:32000];
// (* lram *) reg [3:0] frame_buffer_b [0:16000];

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
        
        // 
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
    
        // 
        if (currently_displayed_buffer == 0) begin
    
            // Odd pixel
            if (pixel_read_address_in[0]) begin
                pixel_read_data_out <= frame_buffer_a[pixel_read_address_in >> 1][3:0];
                // TODO write buffer B
            end

            // Even pixel
            else begin
                pixel_read_data_out <= frame_buffer_a[pixel_read_address_in >> 1][7:4];
                // TODO write buffer B
            end

        end

        else begin

            // Odd pixel
            if (pixel_read_address_in[0]) begin
                frame_buffer_a[pixel_write_address_in >> 1] <= {
                        frame_buffer_a[pixel_write_address_in >> 1][7:4],
                        pixel_write_data_in
                    };
                // pixel_read_data_out <= frame_buffer_b[pixel_read_address_in >> 1][3:0];
            end

            // Even pixel
            else begin
                frame_buffer_a[pixel_write_address_in >> 1] <= {
                        pixel_write_data_in,
                        frame_buffer_a[pixel_write_address_in >> 1][3:0]
                    };
                // pixel_read_data_out <= frame_buffer_b[pixel_read_address_in >> 1][7:4];
            end
        end

    end

end

endmodule