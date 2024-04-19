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

module spi_interface (
    input logic clock_in, // 72MHz
    input logic reset_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,

    output logic clear_buffer_flag,

    output logic assign_color_enable_flag,
    output logic [3:0] assign_color_index_reg,
    output logic [9:0] assign_color_value_reg,

    output logic sprite_enable_flag,
    output logic [7:0] sprite_data,
    output logic [9:0] sprite_x_position_reg,
    output logic [9:0] sprite_y_position_reg,
    output logic [9:0] sprite_width_reg,
    output logic [4:0] sprite_total_colors_reg,
    output logic [3:0] sprite_palette_offset_reg,
    
    output logic show_buffer_flag,

    output logic data_valid,
    output logic clear_flags // TODO: can this be merged with data valid
);

// Handle op-codes as they come in
always_ff @(posedge clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (op_code_valid_in == 0 || reset_n_in == 0) begin
        clear_buffer_flag <= 0;
        assign_color_enable_flag <= 0;
        sprite_enable_flag <= 0;
        show_buffer_flag <= 0;
        clear_flags <= 1;
        data_valid <= 0;
    end

    else begin
        
        clear_flags <= 0;

        case (op_code_in)

            // Clear buffer
            'h10: begin
                clear_buffer_flag <= 1;
                data_valid <= 1;
            end

            // Assign color
            'h11: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        1: assign_color_index_reg <= operand_in[3:0];
                        2: assign_color_value_reg[9:6] <= operand_in[7:4];
                        3: assign_color_value_reg[5:3] <= operand_in[7:5];
                        4: assign_color_value_reg[2:0] <= operand_in[7:5];
                    endcase

                    assign_color_enable_flag <= operand_count_in == 4 ? 1 : 0;

                    data_valid <= 1;
                end 
                
                else begin 
                    data_valid <= 0;
                end
            end

            // Draw sprite
            'h12: begin
                
                if (operand_valid_in) begin
                    case (operand_count_in)
                        0: begin /* Do nothing */ end
                        1: sprite_x_position_reg <= {operand_in[1:0], 8'b0};
                        2: sprite_x_position_reg <= {sprite_x_position_reg[9:8], operand_in};
                        3: sprite_y_position_reg <= {operand_in[1:0], 8'b0};
                        4: sprite_y_position_reg <= {sprite_y_position_reg[9:8], operand_in};
                        5: sprite_width_reg <= {operand_in[1:0], 8'b0};
                        6: sprite_width_reg <= {sprite_width_reg[9:8], operand_in};
                        7: sprite_total_colors_reg <= operand_in[4:0];
                        8: sprite_palette_offset_reg <= operand_in[3:0];
                        default begin
                            sprite_enable_flag <= 1;
                            data_valid <= 1;
                            sprite_data <= operand_in;        
                        end
                    endcase
                    data_valid <= 1;
                end

                else begin
                    data_valid <= 0;
                end

            end

            // Show buffer
            'h14: begin
                show_buffer_flag <= 1;
                data_valid <= 1;
            end

            default: data_valid <= 0;

        endcase

    end
end


endmodule