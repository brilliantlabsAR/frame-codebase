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

module spi (
    input logic clk,
    input logic sck,
    input logic cs,
    input logic copi,
    output logic cipo
);

localparam CHIPID_REG = 8'h00;
localparam CHIPID = 8'hAA;

// Registers to keep track of SCK and CS edges
logic [1:0] cs_edge_monitor = 0;
logic [1:0] sck_edge_monitor = 0;

logic [3:0] bit_counter = 0;
logic [3:0] byte_counter = 0;

logic [7:0] cipo_reg;
logic [7:0] copi_reg;

logic [7:0] opcode;

always @(posedge clk) begin
    // Update the edge monitors with the latest cs and sck signal values
    cs_edge_monitor <= {cs_edge_monitor[0], cs};
    sck_edge_monitor <= {sck_edge_monitor[0], sck};

    // CS low, transaction in progress
    if (cs_edge_monitor == 2'b00) begin 
        // If CS is rising edge, we reset the counters and release io
        if (cs_edge_monitor == 'b01) begin
            bit_counter <= 0;
            byte_counter <= 0;
        end

        // We only change data counters on the falling edge of SCK
        if (sck_edge_monitor == 'b10) begin
            case (byte_counter) 
            // Opcode
            'd0: begin
                if (bit_counter == 'd7) begin
                    opcode <= copi_reg;
                    case (copi_reg)
                        CHIPID_REG: begin
                            cipo_reg <= 'hAA;
                            cipo <= CHIPID[7];
                        end
                        default: cipo <= 1;
                    endcase
                end else cipo <= 1;
            end
            // Response
            'd1: begin
                // Shift out data
                case (opcode)
                    CHIPID_REG: begin
                        case (bit_counter)
                            'd0: cipo <= cipo_reg[6];
                            'd1: cipo <= cipo_reg[5];
                            'd2: cipo <= cipo_reg[4];
                            'd3: cipo <= cipo_reg[3];
                            'd4: cipo <= cipo_reg[2];
                            'd5: cipo <= cipo_reg[1];
                            'd6: cipo <= cipo_reg[0];
                            default: cipo <= 1;
                        endcase
                    end
                    default: cipo <= 1;
                endcase
            end
            default: cipo <= 0;
            endcase

            // Increment counter
            if (bit_counter == 'd7) begin
                bit_counter <= 0;
                byte_counter <= byte_counter + 1;
            end else bit_counter <= bit_counter + 1;
        end

        // Rising edge of SCK 
        else if ((sck_edge_monitor == 'b01) && (byte_counter == 0)) begin
            // Shift in data from nRF MSB first
            copi_reg <= {copi_reg[6:0], copi};
        end
    end
    // Reset on falling CS
    if (cs_edge_monitor == 2'b10) begin
        bit_counter <= 0;
        byte_counter <= 0;
        cipo <= 0;
    end
end

endmodule