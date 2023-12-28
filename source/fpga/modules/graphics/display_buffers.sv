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
 
module display_buffers (
    input logic clock_in,
    input logic reset_n_in,

    input logic [17:0] pixel_write_address_in,
    input logic [3:0] pixel_write_data_in,
    output logic pixel_write_buffer_ready_out,

    input logic [17:0] pixel_read_address_in,
    output logic [3:0] pixel_read_data_out,

    input logic switch_write_buffer_in
);

enum {BUFFER_A, BUFFER_B} displayed_buffer;
logic [1:0] switch_write_buffer_edge_monitor = 0;
logic buffer_switch_pending = 0;

logic [13:0] display_buffer_a_top_read_address;
logic [13:0] display_buffer_a_top_write_address;
logic [31:0] display_buffer_a_top_read_data;
logic [31:0] display_buffer_a_top_write_data;
logic display_buffer_a_top_write_enable;

logic [13:0] display_buffer_a_bottom_read_address;
logic [13:0] display_buffer_a_bottom_write_address;
logic [31:0] display_buffer_a_bottom_read_data;
logic [31:0] display_buffer_a_bottom_write_data;
logic display_buffer_a_bottom_write_enable;

logic [13:0] display_buffer_b_top_read_address;
logic [13:0] display_buffer_b_top_write_address;
logic [31:0] display_buffer_b_top_read_data;
logic [31:0] display_buffer_b_top_write_data;
logic display_buffer_b_top_write_enable;

logic [13:0] display_buffer_b_bottom_read_address;
logic [13:0] display_buffer_b_bottom_write_address;
logic [31:0] display_buffer_b_bottom_read_data;
logic [31:0] display_buffer_b_bottom_write_data;
logic display_buffer_b_bottom_write_enable;

PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    .INITVAL_00("0x00000000"),
    .INITVAL_01(),
    .INITVAL_02(),
    .INITVAL_03(),
    .INITVAL_04(),
    .INITVAL_05(),
    .INITVAL_06(),
    .INITVAL_07(),
    .INITVAL_08(),
    .INITVAL_09(),
    .INITVAL_0A(),
    .INITVAL_0B(),
    .INITVAL_0C(),
    .INITVAL_0D(),
    .INITVAL_0E(),
    .INITVAL_0F(),
    .INITVAL_10(),
    .INITVAL_11(),
    .INITVAL_12(),
    .INITVAL_13(),
    .INITVAL_14(),
    .INITVAL_15(),
    .INITVAL_16(),
    .INITVAL_17(),
    .INITVAL_18(),
    .INITVAL_19(),
    .INITVAL_1A(),
    .INITVAL_1B(),
    .INITVAL_1C(),
    .INITVAL_1D(),
    .INITVAL_1E(),
    .INITVAL_1F(),
    .INITVAL_20(),
    .INITVAL_21(),
    .INITVAL_22(),
    .INITVAL_23(),
    .INITVAL_24(),
    .INITVAL_25(),
    .INITVAL_26(),
    .INITVAL_27(),
    .INITVAL_28(),
    .INITVAL_29(),
    .INITVAL_2A(),
    .INITVAL_2B(),
    .INITVAL_2C(),
    .INITVAL_2D(),
    .INITVAL_2E(),
    .INITVAL_2F(),
    .INITVAL_30(),
    .INITVAL_31(),
    .INITVAL_32(),
    .INITVAL_33(),
    .INITVAL_34(),
    .INITVAL_35(),
    .INITVAL_36(),
    .INITVAL_37(),
    .INITVAL_38(),
    .INITVAL_39(),
    .INITVAL_3A(),
    .INITVAL_3B(),
    .INITVAL_3C(),
    .INITVAL_3D(),
    .INITVAL_3E(),
    .INITVAL_3F(),
    .INITVAL_40(),
    .INITVAL_41(),
    .INITVAL_42(),
    .INITVAL_43(),
    .INITVAL_44(),
    .INITVAL_45(),
    .INITVAL_46(),
    .INITVAL_47(),
    .INITVAL_48(),
    .INITVAL_49(),
    .INITVAL_4A(),
    .INITVAL_4B(),
    .INITVAL_4C(),
    .INITVAL_4D(),
    .INITVAL_4E(),
    .INITVAL_4F(),
    .INITVAL_50(),
    .INITVAL_51(),
    .INITVAL_52(),
    .INITVAL_53(),
    .INITVAL_54(),
    .INITVAL_55(),
    .INITVAL_56(),
    .INITVAL_57(),
    .INITVAL_58(),
    .INITVAL_59(),
    .INITVAL_5A(),
    .INITVAL_5B(),
    .INITVAL_5C(),
    .INITVAL_5D(),
    .INITVAL_5E(),
    .INITVAL_5F(),
    .INITVAL_60(),
    .INITVAL_61(),
    .INITVAL_62(),
    .INITVAL_63(),
    .INITVAL_64(),
    .INITVAL_65(),
    .INITVAL_66(),
    .INITVAL_67(),
    .INITVAL_68(),
    .INITVAL_69(),
    .INITVAL_6A(),
    .INITVAL_6B(),
    .INITVAL_6C(),
    .INITVAL_6D(),
    .INITVAL_6E(),
    .INITVAL_6F(),
    .INITVAL_70(),
    .INITVAL_71(),
    .INITVAL_72(),
    .INITVAL_73(),
    .INITVAL_74(),
    .INITVAL_75(),
    .INITVAL_76(),
    .INITVAL_77(),
    .INITVAL_78(),
    .INITVAL_79(),
    .INITVAL_7A(),
    .INITVAL_7B(),
    .INITVAL_7C(),
    .INITVAL_7D(),
    .INITVAL_7E(),
    .INITVAL_7F(),
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) display_buffer_a_top (
    .DI(display_buffer_a_top_write_data),
    .ADW(display_buffer_a_top_write_address),
    .ADR(display_buffer_a_top_read_address),
    .CLK(clock_in),
    .CEW(1),
    .CER(1),
    .WE(display_buffer_a_top_write_enable),
    .CSW(1),
    .CSR(1),
    .RSTR(0),
    .BYTEEN_N('b0000),
    .DO(display_buffer_a_top_read_data)
);

always_ff @(posedge clock_in) begin
        
    if (reset_n_in == 0) begin

        pixel_write_buffer_ready_out <= 0;

        displayed_buffer <= BUFFER_A;
        switch_write_buffer_edge_monitor <= 'b00;
        buffer_switch_pending <= 0;

    end

    else begin
        
        // Switch buffer only when the read address resets back to zero
        switch_write_buffer_edge_monitor <= {
            switch_write_buffer_edge_monitor[0], 
            switch_write_buffer_in
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
    
        /*
        if (displayed_buffer == 0) begin
    
            // Read from top of buffer A
            if (pixel_read_address_in[17] == 0) begin
                
                // 14 bit addressable range per ram block
                display_buffer_a_top_read_address <= pixel_read_address_in[16:3];
                display_buffer_a_bottom_read_address <= 0;

                // Pixels are stored in groups of 32 bits. i.e. 8 pixels
                case (pixel_read_address_in[2:0])
                    'd0: pixel_read_data_out <= display_buffer_a_top_read_data[3:0];
                    'd1: pixel_read_data_out <= display_buffer_a_top_read_data[7:4];
                    'd2: pixel_read_data_out <= display_buffer_a_top_read_data[11:8];
                    'd3: pixel_read_data_out <= display_buffer_a_top_read_data[15:12];
                    'd4: pixel_read_data_out <= display_buffer_a_top_read_data[19:16];
                    'd5: pixel_read_data_out <= display_buffer_a_top_read_data[23:20];
                    'd6: pixel_read_data_out <= display_buffer_a_top_read_data[27:24];
                    'd7: pixel_read_data_out <= display_buffer_a_top_read_data[31:28];
                endcase

            end

            // Read from bottom of buffer A
            else begin
    
                // 14 bit addressable range per ram block
                display_buffer_a_top_read_address <= 0;
                display_buffer_a_bottom_read_address <= pixel_read_address_in[16:3];

                // Pixels are stored in groups of 32 bits. i.e. 8 pixels
                // case (pixel_read_address_in[2:0])
                
                pixel_read_data_out <= 0;

            end

        end

        else begin

            // Write to top of buffer A
            if (pixel_write_address_in[17] == 0) begin
            
                // 14 bit addressable range per ram block
                display_buffer_a_top_write_address <= pixel_write_address_in[16:3];
                display_buffer_a_bottom_write_address <= 0;

                case (pixel_write_data_in[2:0])
                    'd0: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:4],  pixel_write_data_in};
                    'd1: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:8],  pixel_write_data_in, display_buffer_a_top_read_data[3:0]};
                    'd2: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:12], pixel_write_data_in, display_buffer_a_top_read_data[7:0]};
                    'd3: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:16], pixel_write_data_in, display_buffer_a_top_read_data[11:0]};
                    'd4: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:20], pixel_write_data_in, display_buffer_a_top_read_data[15:0]};
                    'd5: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:24], pixel_write_data_in, display_buffer_a_top_read_data[19:0]};
                    'd6: display_buffer_a_top_write_data <= {display_buffer_a_top_read_data[31:28], pixel_write_data_in, display_buffer_a_top_read_data[23:0]};
                    'd7: display_buffer_a_top_write_data <= {                                       pixel_write_data_in, display_buffer_a_top_read_data[27:0]};
                endcase

            end

            // Write to bottom of buffer A
            else begin

                // 14 bit addressable range per ram block
                display_buffer_a_top_write_address <= 0;
                display_buffer_a_bottom_write_address <= pixel_write_address_in[16:3];

                // case ...

            end

            // TEMP for testing
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
        */
    end

end

always_comb begin

    // Select one of the four RAMs based on write address and selected buffer
    display_buffer_a_top_write_enable = displayed_buffer == BUFFER_B && 
                                        pixel_write_address_in[17] == 1
                                      ? 1 : 0;

    display_buffer_a_bottom_write_enable = displayed_buffer == BUFFER_B  && 
                                           pixel_write_address_in[17] == 0
                                         ? 1 : 0;

    display_buffer_b_top_write_enable = displayed_buffer == BUFFER_A && 
                                        pixel_write_address_in[17] == 1
                                      ? 1 : 0;

    display_buffer_b_bottom_write_enable = displayed_buffer == BUFFER_A && 
                                           pixel_write_address_in[17] == 0
                                         ? 1 : 0;

    // Output pixel value based on read address and selected buffer
    if (displayed_buffer == BUFFER_A && pixel_read_address_in[17] == 0) begin
        pixel_read_data_out = 0;
    end
    
    else if (displayed_buffer == BUFFER_A && pixel_read_address_in[17] == 1) begin
        pixel_read_data_out = 1;
    end
    
    else if (displayed_buffer == BUFFER_B && pixel_read_address_in[17] == 0) begin
        pixel_read_data_out = 2;
    end

    else begin
        pixel_read_data_out = 3;
    end

end

endmodule