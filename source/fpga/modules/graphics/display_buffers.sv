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

module display_buffers (
    input logic clock_in,
    input logic reset_n_in,

    input logic pixel_write_enable_in,
    input logic [17:0] pixel_write_address_in,
    input logic [3:0] pixel_write_data_in,

    input logic [17:0] pixel_read_address_in,
    output logic [3:0] pixel_read_data_out,

    input logic switch_write_buffer_in
);

enum logic {BUFFER_A, BUFFER_B} displayed_buffer;
logic [1:0] switch_write_buffer_edge_monitor;
logic buffer_switch_pending;

logic [13:0] display_ram_address_a;
logic [13:0] display_ram_address_b;

logic [31:0] display_ram_read_data_a_top;
logic [31:0] display_ram_read_data_a_bottom;
logic [31:0] display_ram_read_data_b_top;
logic [31:0] display_ram_read_data_b_bottom;

logic [31:0] display_ram_write_data;

logic display_ram_write_enable_a_top;
logic display_ram_write_enable_a_bottom;
logic display_ram_write_enable_b_top;
logic display_ram_write_enable_b_bottom;

logic pixel_write_enable_reg;
logic [17:0] pixel_write_address_reg;
logic [3:0] pixel_write_data_reg;
logic [17:0] pixel_read_address_reg;
logic [3:0] pixel_read_data_reg;

PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    `ifndef RADIANT
    .INITVAL_00("0x00000000"),
    `endif
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) display_buffer_a_top (
    .DI(display_ram_write_data),
    .ADW(display_ram_address_a),
    .ADR(display_ram_address_a),
    .CLK(clock_in),
    .CEW('b1),
    .CER('b1),
    .WE(display_ram_write_enable_a_top),
    .CSW('b1),
    .CSR('b1),
    .RSTR('b0),
    .BYTEEN_N('b0000),
    .DO(display_ram_read_data_a_top)
);

PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    `ifndef RADIANT
    .INITVAL_00("0x00000000"),
    `endif
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) display_buffer_a_bottom (
    .DI(display_ram_write_data),
    .ADW(display_ram_address_a),
    .ADR(display_ram_address_a),
    .CLK(clock_in),
    .CEW('b1),
    .CER('b1),
    .WE(display_ram_write_enable_a_bottom),
    .CSW('b1),
    .CSR('b1),
    .RSTR('b0),
    .BYTEEN_N('b0000),
    .DO(display_ram_read_data_a_bottom)
);

PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    `ifndef RADIANT
    .INITVAL_00("0x00000000"),
    `endif
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) display_buffer_b_top (
    .DI(display_ram_write_data),
    .ADW(display_ram_address_b),
    .ADR(display_ram_address_b),
    .CLK(clock_in),
    .CEW('b1),
    .CER('b1),
    .WE(display_ram_write_enable_b_top),
    .CSW('b1),
    .CSR('b1),
    .RSTR('b0),
    .BYTEEN_N('b0000),
    .DO(display_ram_read_data_b_top)
);

PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    `ifndef RADIANT
    .INITVAL_00("0x00000000"),
    `endif
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) display_buffer_b_bottom (
    .DI(display_ram_write_data),
    .ADW(display_ram_address_b),
    .ADR(display_ram_address_b),
    .CLK(clock_in),
    .CEW('b1),
    .CER('b1),
    .WE(display_ram_write_enable_b_bottom),
    .CSW('b1),
    .CSR('b1),
    .RSTR('b0),
    .BYTEEN_N('b0000),
    .DO(display_ram_read_data_b_bottom)
);

// Buffer switching logic
always_ff @(posedge clock_in) begin
        
    if (reset_n_in == 0) begin
        displayed_buffer <= BUFFER_A;
        switch_write_buffer_edge_monitor <= 'b00;
        buffer_switch_pending <= 0;
        pixel_write_enable_reg <= 0;
        pixel_write_address_reg <= 0;
        pixel_write_data_reg <= 0;
        pixel_read_address_reg <= 0;
        pixel_read_data_out <= 0;
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
        end

        // Buffer the inputs and outputs
        pixel_write_enable_reg <= pixel_write_enable_in;
        pixel_write_address_reg <= pixel_write_address_in;
        pixel_write_data_reg <= pixel_write_data_in;
        pixel_read_address_reg <= pixel_read_address_in;
        pixel_read_data_out <= pixel_read_data_reg;

    end

end

// Ram selection and read/write connections
always_comb begin

    // Connect address lines based on selected buffer
    if (displayed_buffer == BUFFER_A) begin
        display_ram_address_a = pixel_read_address_reg[16:3];
        display_ram_address_b = pixel_write_address_reg[16:3];
    end

    else begin
        display_ram_address_a = pixel_write_address_reg[16:3];
        display_ram_address_b = pixel_read_address_reg[16:3];
    end

    // Read pixels from displayed_buffer
    if (displayed_buffer == BUFFER_A && pixel_read_address_reg[17] == 0) begin
        case (pixel_read_address_reg[2:0])
            'd0: pixel_read_data_reg = display_ram_read_data_a_top[3:0];
            'd1: pixel_read_data_reg = display_ram_read_data_a_top[7:4];
            'd2: pixel_read_data_reg = display_ram_read_data_a_top[11:8];
            'd3: pixel_read_data_reg = display_ram_read_data_a_top[15:12];
            'd4: pixel_read_data_reg = display_ram_read_data_a_top[19:16];
            'd5: pixel_read_data_reg = display_ram_read_data_a_top[23:20];
            'd6: pixel_read_data_reg = display_ram_read_data_a_top[27:24];
            'd7: pixel_read_data_reg = display_ram_read_data_a_top[31:28];
        endcase
    end
    
    else if (displayed_buffer == BUFFER_A && pixel_read_address_reg[17] == 1) begin
        case (pixel_read_address_reg[2:0])
            'd0: pixel_read_data_reg = display_ram_read_data_a_bottom[3:0];
            'd1: pixel_read_data_reg = display_ram_read_data_a_bottom[7:4];
            'd2: pixel_read_data_reg = display_ram_read_data_a_bottom[11:8];
            'd3: pixel_read_data_reg = display_ram_read_data_a_bottom[15:12];
            'd4: pixel_read_data_reg = display_ram_read_data_a_bottom[19:16];
            'd5: pixel_read_data_reg = display_ram_read_data_a_bottom[23:20];
            'd6: pixel_read_data_reg = display_ram_read_data_a_bottom[27:24];
            'd7: pixel_read_data_reg = display_ram_read_data_a_bottom[31:28];
        endcase
    end
    
    else if (displayed_buffer == BUFFER_B && pixel_read_address_reg[17] == 0) begin
        case (pixel_read_address_reg[2:0])
            'd0: pixel_read_data_reg = display_ram_read_data_b_top[3:0];
            'd1: pixel_read_data_reg = display_ram_read_data_b_top[7:4];
            'd2: pixel_read_data_reg = display_ram_read_data_b_top[11:8];
            'd3: pixel_read_data_reg = display_ram_read_data_b_top[15:12];
            'd4: pixel_read_data_reg = display_ram_read_data_b_top[19:16];
            'd5: pixel_read_data_reg = display_ram_read_data_b_top[23:20];
            'd6: pixel_read_data_reg = display_ram_read_data_b_top[27:24];
            'd7: pixel_read_data_reg = display_ram_read_data_b_top[31:28];
        endcase
    end

    else begin
        case (pixel_read_address_reg[2:0])
            'd0: pixel_read_data_reg = display_ram_read_data_b_bottom[3:0];
            'd1: pixel_read_data_reg = display_ram_read_data_b_bottom[7:4];
            'd2: pixel_read_data_reg = display_ram_read_data_b_bottom[11:8];
            'd3: pixel_read_data_reg = display_ram_read_data_b_bottom[15:12];
            'd4: pixel_read_data_reg = display_ram_read_data_b_bottom[19:16];
            'd5: pixel_read_data_reg = display_ram_read_data_b_bottom[23:20];
            'd6: pixel_read_data_reg = display_ram_read_data_b_bottom[27:24];
            'd7: pixel_read_data_reg = display_ram_read_data_b_bottom[31:28];
        endcase
    end

    // Write pixels on the opposite buffer
    if (displayed_buffer == BUFFER_B && pixel_write_address_reg[17] == 0) begin
        case (pixel_write_address_reg[2:0])
            'd0: display_ram_write_data = {display_ram_read_data_a_top[31:4],  pixel_write_data_reg                                   };
            'd1: display_ram_write_data = {display_ram_read_data_a_top[31:8],  pixel_write_data_reg, display_ram_read_data_a_top[3:0] };
            'd2: display_ram_write_data = {display_ram_read_data_a_top[31:12], pixel_write_data_reg, display_ram_read_data_a_top[7:0] };
            'd3: display_ram_write_data = {display_ram_read_data_a_top[31:16], pixel_write_data_reg, display_ram_read_data_a_top[11:0]};
            'd4: display_ram_write_data = {display_ram_read_data_a_top[31:20], pixel_write_data_reg, display_ram_read_data_a_top[15:0]};
            'd5: display_ram_write_data = {display_ram_read_data_a_top[31:24], pixel_write_data_reg, display_ram_read_data_a_top[19:0]};
            'd6: display_ram_write_data = {display_ram_read_data_a_top[31:28], pixel_write_data_reg, display_ram_read_data_a_top[23:0]};
            'd7: display_ram_write_data = {                                    pixel_write_data_reg, display_ram_read_data_a_top[27:0]};
        endcase
    end

    else if (displayed_buffer == BUFFER_B && pixel_write_address_reg[17] == 1) begin
        case (pixel_write_address_reg[2:0])
            'd0: display_ram_write_data = {display_ram_read_data_a_bottom[31:4],  pixel_write_data_reg                                      };
            'd1: display_ram_write_data = {display_ram_read_data_a_bottom[31:8],  pixel_write_data_reg, display_ram_read_data_a_bottom[3:0] };
            'd2: display_ram_write_data = {display_ram_read_data_a_bottom[31:12], pixel_write_data_reg, display_ram_read_data_a_bottom[7:0] };
            'd3: display_ram_write_data = {display_ram_read_data_a_bottom[31:16], pixel_write_data_reg, display_ram_read_data_a_bottom[11:0]};
            'd4: display_ram_write_data = {display_ram_read_data_a_bottom[31:20], pixel_write_data_reg, display_ram_read_data_a_bottom[15:0]};
            'd5: display_ram_write_data = {display_ram_read_data_a_bottom[31:24], pixel_write_data_reg, display_ram_read_data_a_bottom[19:0]};
            'd6: display_ram_write_data = {display_ram_read_data_a_bottom[31:28], pixel_write_data_reg, display_ram_read_data_a_bottom[23:0]};
            'd7: display_ram_write_data = {                                       pixel_write_data_reg, display_ram_read_data_a_bottom[27:0]};
        endcase
    end

    else if (displayed_buffer == BUFFER_A && pixel_write_address_reg[17] == 0) begin
        case (pixel_write_address_reg[2:0])
            'd0: display_ram_write_data = {display_ram_read_data_b_top[31:4],  pixel_write_data_reg                                   };
            'd1: display_ram_write_data = {display_ram_read_data_b_top[31:8],  pixel_write_data_reg, display_ram_read_data_b_top[3:0] };
            'd2: display_ram_write_data = {display_ram_read_data_b_top[31:12], pixel_write_data_reg, display_ram_read_data_b_top[7:0] };
            'd3: display_ram_write_data = {display_ram_read_data_b_top[31:16], pixel_write_data_reg, display_ram_read_data_b_top[11:0]};
            'd4: display_ram_write_data = {display_ram_read_data_b_top[31:20], pixel_write_data_reg, display_ram_read_data_b_top[15:0]};
            'd5: display_ram_write_data = {display_ram_read_data_b_top[31:24], pixel_write_data_reg, display_ram_read_data_b_top[19:0]};
            'd6: display_ram_write_data = {display_ram_read_data_b_top[31:28], pixel_write_data_reg, display_ram_read_data_b_top[23:0]};
            'd7: display_ram_write_data = {                                    pixel_write_data_reg, display_ram_read_data_b_top[27:0]};
        endcase
    end

    else begin
        case (pixel_write_address_reg[2:0])
            'd0: display_ram_write_data = {display_ram_read_data_b_bottom[31:4],  pixel_write_data_reg                                      };
            'd1: display_ram_write_data = {display_ram_read_data_b_bottom[31:8],  pixel_write_data_reg, display_ram_read_data_b_bottom[3:0] };
            'd2: display_ram_write_data = {display_ram_read_data_b_bottom[31:12], pixel_write_data_reg, display_ram_read_data_b_bottom[7:0] };
            'd3: display_ram_write_data = {display_ram_read_data_b_bottom[31:16], pixel_write_data_reg, display_ram_read_data_b_bottom[11:0]};
            'd4: display_ram_write_data = {display_ram_read_data_b_bottom[31:20], pixel_write_data_reg, display_ram_read_data_b_bottom[15:0]};
            'd5: display_ram_write_data = {display_ram_read_data_b_bottom[31:24], pixel_write_data_reg, display_ram_read_data_b_bottom[19:0]};
            'd6: display_ram_write_data = {display_ram_read_data_b_bottom[31:28], pixel_write_data_reg, display_ram_read_data_b_bottom[23:0]};
            'd7: display_ram_write_data = {                                       pixel_write_data_reg, display_ram_read_data_b_bottom[27:0]};
        endcase
    end

    // Select one of the four enables based on write address and selected buffer
    display_ram_write_enable_a_top = displayed_buffer == BUFFER_B && 
                                     pixel_write_address_reg[17] == 0 &&
                                     pixel_write_enable_reg == 1
                                   ? 1 : 0;

    display_ram_write_enable_a_bottom = displayed_buffer == BUFFER_B  && 
                                        pixel_write_address_reg[17] == 1 &&
                                        pixel_write_enable_reg == 1
                                      ? 1 : 0;

    display_ram_write_enable_b_top = displayed_buffer == BUFFER_A && 
                                     pixel_write_address_reg[17] == 0 &&
                                     pixel_write_enable_reg == 1
                                   ? 1 : 0;

    display_ram_write_enable_b_bottom = displayed_buffer == BUFFER_A && 
                                        pixel_write_address_reg[17] == 1 &&
                                        pixel_write_enable_reg == 1
                                      ? 1 : 0;

end

endmodule