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
 
 /*
  * Each display buffer holds 640 * 400 pixels, and each pixel is a 4bit value.
  * In total, 256,000 pixels, or 1,024,000 bits are needed per buffer. Each LRAM
  * block can hold 524,288 bits, therefore, 2 blocks are needed for a single 
  * buffer, and 4 blocks are required for double display buffering. While one 
  * buffer is being displayed, the other may be written to. Once ready, the 
  * buffers are switched. Each LRAM block has a 14 bit address bus. Therefore,
  * 32 bit words are addressed at a time. i.e. 8 pixels per address. To properly 
  * address each LRAM block, the following scheme is used:
  * 
  *   xx xxxx xxxx xxxx xxxx = 18 bits needed to address 256,000 pixels
  *   0                      = Selects top LRAM of a buffer
  *   1                      = Selects bottom LRAM of a buffer
  *                      xxx = Lower 3 bits selects a pixel from the 32 bit word
  *    x xxxx xxxx xxxx x    = This leaves 14 bits to address an LRAM block
  */

module display_buffer (
    input logic clock,
    input logic reset_n,

    input logic [17:0] write_address,
    input logic [17:0] read_address,

    input logic [3:0] write_data,
    output logic [3:0] read_data,

    input logic write_enable
);

`ifndef RADIANT (* ram_style="huge" *) `endif reg [31:0] mem [0:32767];

always @(posedge clock) begin

    if (reset_n == 0) begin
        read_data <= 0;
    end

    else begin
        if (write_enable) begin
            case (write_address[2:0])
                'd0: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:4],  write_data                                };
                'd1: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:8],  write_data, mem[write_address[17:3]][3:0] };
                'd2: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:12], write_data, mem[write_address[17:3]][7:0] };
                'd3: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:16], write_data, mem[write_address[17:3]][11:0]};
                'd4: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:20], write_data, mem[write_address[17:3]][15:0]};
                'd5: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:24], write_data, mem[write_address[17:3]][19:0]};
                'd6: mem[write_address[17:3]] <= {mem[write_address[17:3]][31:28], write_data, mem[write_address[17:3]][23:0]};
                'd7: mem[write_address[17:3]] <= {                                 write_data, mem[write_address[17:3]][27:0]};
            endcase
        end

        case (read_address[2:0])
            'd0: read_data <= mem[read_address[17:3]][3:0];
            'd1: read_data <= mem[read_address[17:3]][7:4];
            'd2: read_data <= mem[read_address[17:3]][11:8];
            'd3: read_data <= mem[read_address[17:3]][15:12];
            'd4: read_data <= mem[read_address[17:3]][19:16];
            'd5: read_data <= mem[read_address[17:3]][23:20];
            'd6: read_data <= mem[read_address[17:3]][27:24];
            'd7: read_data <= mem[read_address[17:3]][31:28];
        endcase
    end
end

endmodule

module display_buffers (
    input logic clock_in,
    input logic reset_n_in,

    input logic pixel_write_enable_in,
    input logic [17:0] pixel_write_address_in,
    input logic [3:0] pixel_write_data_in,

    input logic [17:0] pixel_read_address_in,
    output logic [3:0] pixel_read_data_out,

    output logic [7:0] debug_0,
    input logic switch_write_buffer_in
);

logic [17:0] display_ram_address_a;
logic [17:0] display_ram_address_b;

logic [3:0] display_ram_read_data_a;
logic [3:0] display_ram_read_data_b;

logic [3:0] display_ram_write_data;

logic display_ram_write_enable_a;
logic display_ram_write_enable_b;

logic clear_flag;
logic [18:0] clear_address_counter;

display_buffer buffer_a (
    .clock(clock_in),
    .reset_n(reset_n_in),
    .write_address(display_ram_address_a),
    .read_address(display_ram_address_a),
    .write_data(display_ram_write_data),
    .read_data(display_ram_read_data_a),
    .write_enable(display_ram_write_enable_a)
);

display_buffer buffer_b (
    .clock(clock_in),
    .reset_n(reset_n_in),
    .write_address(display_ram_address_b),
    .read_address(display_ram_address_b),
    .write_data(display_ram_write_data),
    .read_data(display_ram_read_data_b),
    .write_enable(display_ram_write_enable_b)
);

// Buffer switching & clearing logic
enum logic {BUFFER_A, BUFFER_B} displayed_buffer;
logic [1:0] switch_write_buffer_edge_monitor;
logic buffer_switch_pending;

always_ff @(posedge clock_in) begin
        
    if (reset_n_in == 0) begin
        displayed_buffer <= BUFFER_A;
        switch_write_buffer_edge_monitor <= 'b00;
        buffer_switch_pending <= 0;
        clear_flag <= 0;
        clear_address_counter <= 0;
    end

    else begin
        
        // Switch buffer only when the read address resets back to zero
        switch_write_buffer_edge_monitor <= {
            switch_write_buffer_edge_monitor[0], switch_write_buffer_in
        };

        if (switch_write_buffer_edge_monitor == 'b01) begin
            buffer_switch_pending <= 1;
        end

        if (buffer_switch_pending == 1 && pixel_read_address_in == 0) begin
            if (displayed_buffer == BUFFER_A) begin
                displayed_buffer <= BUFFER_B;
            end

            else begin
                displayed_buffer <= BUFFER_A;
            end

            buffer_switch_pending <= 0;

            clear_flag <= 1;
            clear_address_counter <= 0;
        end

        if (clear_flag == 1) begin
            clear_address_counter <= clear_address_counter + 1;

            if (clear_address_counter == 'd512000) begin
                clear_flag <= 0;
            end
        end

    end

end

// RAM Addressing logic
always_ff @(posedge clock_in) begin
    
    if (reset_n_in == 0) begin
        display_ram_address_a <= 0;
        display_ram_address_b <= 0;
    end

    else begin
        if (displayed_buffer == BUFFER_A) begin
            if (clear_flag == 1) begin
                display_ram_address_b <= clear_address_counter >> 1;
            end else begin
                display_ram_address_b <= pixel_write_address_in;
            end

            display_ram_address_a <= pixel_read_address_in; 
        end

        else begin
            if (clear_flag == 1) begin 
                display_ram_address_a <= clear_address_counter >> 1;
            end else begin
               display_ram_address_a <= pixel_write_address_in; 
            end

            display_ram_address_b <= pixel_read_address_in;
        end
    end

end

// RAM reading logic
always_ff @(posedge clock_in) begin
    
    if (reset_n_in == 0) begin
        pixel_read_data_out <= 0;
    end

    // Read pixels from displayed_buffer
    if (displayed_buffer == BUFFER_A) begin
        pixel_read_data_out <= display_ram_read_data_a;
    end

    else begin
        pixel_read_data_out <= display_ram_read_data_b;
    end

end

// RAM writing logic
always_ff @(posedge clock_in) begin

    if (clear_flag == 1) begin
        display_ram_write_data <= 0;
    end else begin
        display_ram_write_data <= pixel_write_data_in;
    end

    if (pixel_write_enable_in == 1 || clear_flag == 1) begin
        if (displayed_buffer == BUFFER_A) begin
            display_ram_write_enable_a <= 0;
            display_ram_write_enable_b <= 1;
        end else begin
            display_ram_write_enable_a <= 1;
            display_ram_write_enable_b <= 0;
        end
    end else begin
        display_ram_write_enable_a <= 0;
        display_ram_write_enable_b <= 0;
    end

end

always_comb debug_0 = {clear_flag, buffer_switch_pending, displayed_buffer};
endmodule
