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

module line (
    input logic clock_in,
    input logic reset_n_in,
    input logic enable_in,
    input logic [9:0] x0_in,
    input logic [9:0] x1_in,
    input logic [8:0] y0_in,
    input logic [8:0] y1_in,
    output logic [9:0] horizontal_out,
    output logic [8:0] vertical_out,
    output logic write_enable_out,
    output logic ready_out
);

integer dx;
integer dy;
logic [9:0] x;
logic [8:0] y;
logic xPositive;
logic yPositive;
integer error;
integer error2; 
logic hold;

assign horizontal_out = x;
assign vertical_out = y;

always_ff @(posedge clock_in) begin
    if (reset_n_in == 0 || enable_in == 0) begin
        x <= 0;
        y <= 0;
        ready_out <= 1;
        write_enable_out <= 0;
    end

    else begin
    
        // Initialise
        if (ready_out) begin
            x <= x0_in;
            y <= y0_in;

            ready_out <= 0;
            write_enable_out <= 1;
            hold <= 0;

            if ((x1_in>x0_in) && (y1_in>y0_in)) begin
                dx <= x1_in - x0_in;
                xPositive <= 1;
                dy <= -(y1_in - y0_in);
                yPositive <= 1;
                error <= x1_in - x0_in - y1_in + y0_in;
                error2 <= (x1_in - x0_in - y1_in + y0_in) << 1;
            end
            else if ((x1_in>x0_in) && !(y1_in>y0_in)) begin
                dx <= x1_in - x0_in;
                xPositive <= 1;
                dy <= -(y0_in - y1_in);
                yPositive <= 0;
                error <= x1_in - x0_in - y0_in + y1_in;
                error2 <= (x1_in - x0_in - y0_in + y1_in) << 1;
            end
            else if (!(x1_in>x0_in) && (y1_in>y0_in)) begin
                dx <= x0_in - x1_in;
                xPositive <= 0;
                dy <= -(y1_in - y0_in);
                yPositive <= 1;
                error <= x0_in - x1_in - y1_in + y0_in;
                error2 <= (x0_in - x1_in - y1_in + y0_in) << 1;
            end
            else if (!(x1_in>x0_in) && !(y1_in>y0_in)) begin
                dx <= x0_in - x1_in;
                xPositive <= 0;
                dy <= -(y0_in - y1_in);
                yPositive <= 0;
                error <= x0_in - x1_in - y0_in + y1_in;
                error2 <= (x0_in - x1_in - y0_in + y1_in) << 1;
            end
        end
        
        
        // Plot points
        else begin
            hold = ~hold;
            
            if (!hold) begin

                // Check if we reached target point
                if ((x == x1_in) && (y == y1_in)) begin
                    ready_out <= 1;
                    write_enable_out <= 0;
                end

                else begin 
                    write_enable_out <= 1;

                    // Step in the direction of bigger error
                    if (error2 >= dy) begin
                        if (xPositive)  x <= x + 1;
                        else            x <= x - 1;
                        if (error2 <= dx) begin
                            error <= error + dy + dx;
                            error2 <= (error + dy + dx) << 1;

                            if (yPositive)  y <= y + 1;
                            else            y <= y - 1;
                        end
                        else begin
                            error <= error + dy;
                            error2 <= (error + dy) << 1;
                        end
                    end 
                    
                    else begin
                        if (error2 <= dx) begin
                            error <= error + dx;
                            error2 <= (error + dx) << 1;

                            if (yPositive)  y <= y + 1;
                            else            y <= y - 1;
                        end
                    end

                end
            end
        end

    end
end

endmodule