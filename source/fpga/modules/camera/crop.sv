module crop (
    input logic pixel_clock_in,
    input logic reset_n_in,

    // Allows max 2048 x 2048 pixel input
    input logic [11:0]  x_crop_start, 
    input logic [11:0]  x_crop_end,
    input logic [11:0]  y_crop_start,
    input logic [11:0]  y_crop_end, 

    input logic [9:0] pixel_red_data_in,
    input logic [9:0] pixel_green_data_in,
    input logic [9:0] pixel_blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [9:0] pixel_red_data_out,
    output logic [9:0] pixel_green_data_out,
    output logic [9:0] pixel_blue_data_out,
    output logic line_valid_out,
    output logic frame_valid_out
);

// Allows max 2048 x 2048 pixel input
logic [11:0] x_counter;
logic [11:0] y_counter;

logic previous_line_valid;

always_ff @(posedge pixel_clock_in) begin

    if(reset_n_in == 0 || frame_valid_in == 0) begin

        line_valid_out <= 0;
        frame_valid_out <= 0;

        x_counter <= 0;
        y_counter <= 0;
        
        previous_line_valid <= 0;

    end
    
    else begin
        
        previous_line_valid <= line_valid_in;

        // Increment counters
        if (line_valid_in) begin
            x_counter <= x_counter + 1;
        end

        else begin
            x_counter <= 0;

            if (previous_line_valid) begin
                y_counter <= y_counter + 1;
            end
        end

        // Output cropped version
        if(line_valid_in &&
           x_counter >= x_crop_start &&
           x_counter < x_crop_end &&
           y_counter >= y_crop_start &&
           y_counter < y_crop_end) begin

            line_valid_out <= 1;
            pixel_red_data_out <= pixel_red_data_in;
            pixel_green_data_out <= pixel_green_data_in;
            pixel_blue_data_out <= pixel_blue_data_in;

        end

        else begin
            
            line_valid_out <= 0;
            pixel_red_data_out <= 0;
            pixel_green_data_out <= 0;
            pixel_blue_data_out <= 0;

        end

        frame_valid_out <= frame_valid_in;

    end
   
end
    
endmodule
