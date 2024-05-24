/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 *
 * Based on http://members.chello.at/~easyfilter/bresenham.c by Zingl Alois
 */

module line (
    input logic clock_in,
    input logic reset_n_in,
    input logic enable_in,
    input logic [9:0] x0_in,
    input logic [9:0] x1_in,
    input logic [9:0] y0_in,
    input logic [9:0] y1_in,
    output logic [17:0] address_out,
    output logic write_enable_out,
    output logic ready_out
);

integer dx;
integer dy;
logic [9:0] x;
logic [8:0] y;
logic dx_positive;
logic dy_positive;
integer error;
integer error2; 
logic write_enable;

enum logic [1:0] { IDLE, INIT, PLOT, HOLD } state;

// TODO: Make this common for all vector operations
always_ff @(posedge clock_in) begin
    write_enable_out <= write_enable;
    address_out <= (y * 640) + x;
end

always_ff @(posedge clock_in) begin
    if (reset_n_in == 0) begin
        x <= 0;
        y <= 0;
        write_enable <= 0;
        state <= IDLE;
        ready_out <= 0;
    end

    else begin
        case (state)

        IDLE: begin
            x <= 0;
            y <= 0;
            write_enable <= 0;
            if (enable_in) begin
                state <= INIT;
                ready_out <= 0;
            end
            else begin
                ready_out <= 1;
            end
        end

        INIT: begin
            x <= x0_in;
            y <= y0_in;

            write_enable <= 1;

            state <= HOLD;

            if ((x1_in>x0_in) && (y1_in>y0_in)) begin
                dx <= x1_in - x0_in;
                dx_positive <= 1;
                dy <= -(y1_in - y0_in);
                dy_positive <= 1;
                error <= x1_in - x0_in - y1_in + y0_in;
                error2 <= (x1_in - x0_in - y1_in + y0_in) << 1;
            end
            else if ((x1_in>x0_in) && !(y1_in>y0_in)) begin
                dx <= x1_in - x0_in;
                dx_positive <= 1;
                dy <= -(y0_in - y1_in);
                dy_positive <= 0;
                error <= x1_in - x0_in - y0_in + y1_in;
                error2 <= (x1_in - x0_in - y0_in + y1_in) << 1;
            end
            else if (!(x1_in>x0_in) && (y1_in>y0_in)) begin
                dx <= x0_in - x1_in;
                dx_positive <= 0;
                dy <= -(y1_in - y0_in);
                dy_positive <= 1;
                error <= x0_in - x1_in - y1_in + y0_in;
                error2 <= (x0_in - x1_in - y1_in + y0_in) << 1;
            end
            else if (!(x1_in>x0_in) && !(y1_in>y0_in)) begin
                dx <= x0_in - x1_in;
                dx_positive <= 0;
                dy <= -(y0_in - y1_in);
                dy_positive <= 0;
                error <= x0_in - x1_in - y0_in + y1_in;
                error2 <= (x0_in - x1_in - y0_in + y1_in) << 1;
            end
        end

        PLOT: begin
            write_enable <= 1;

            state <= HOLD;

            if (error2 >= dy) begin
                
                if (dx_positive)  x <= x + 1;
                else            x <= x - 1;
                
                if (error2 <= dx) begin
                    if (dy_positive)  y <= y + 1;
                    else            y <= y - 1;

                    error <= error + dy + dx;
                    error2 <= (error + dy + dx) << 1;
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
                    
                    if (dy_positive)  y <= y + 1;
                    else            y <= y - 1;
                end

            end
        end

        HOLD: begin
            write_enable <= 1;

            // Check if we reached target point
            if ((x == x1_in) && (y == y1_in)) begin
                state <= IDLE;
            end
            else begin
                state <= PLOT;
            end
        end

        endcase

    end
end


endmodule