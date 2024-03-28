module jpeg (
    input logic pixel_clock_in,
    input logic pixel_reset_n_in,

    input logic jpeg_buffer_clock_in,
    input logic jpeg_buffer_reset_n_in,

    input logic [9:0] red_data_in,
    input logic [9:0] green_data_in,
    input logic [9:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    input logic start_capture_in,
    input logic [9:0] x_size_in,
    input logic [9:0] y_size_in,
    input logic [3:0] quality_factor_in,

    output logic [127:0] data_out,
    output logic data_valid_out,
    output logic [15:0] address_out, // TODO 32 bit aligned [13:0]
    output logic image_valid_out
);

// Data
assign data_out = {120'b0,
                   red_data_in[9:7], 
                   green_data_in[9:7], 
                   blue_data_in[9:8]};

// Address
always_ff @(posedge pixel_clock_in) begin
    if (pixel_reset_n_in == 0) begin
        address_out <= 0;
    end

    else begin
        if (frame_valid_in == 0) begin
            address_out <= 0;
        end
        else if (frame_valid_in && line_valid_in) begin
            address_out <= address_out + 1;
        end
    end
end

// Valid
logic capture_armed;
logic capture_in_progress;
logic [1:0] frame_valid_edge_monitor;

always_ff @(posedge pixel_clock_in) begin
    if (pixel_reset_n_in == 0) begin
        capture_armed <= 0;
        capture_in_progress <= 0;
        frame_valid_edge_monitor <= 0;
    end

    else begin
        frame_valid_edge_monitor <= {frame_valid_edge_monitor[0], frame_valid_in};

        if (capture_armed == 0) begin            
            if (start_capture_in) begin
                capture_armed <= 1;
            end
        end

        else begin
            if (frame_valid_edge_monitor == 'b01) begin
                capture_in_progress <= 1;
            end

            else if (frame_valid_edge_monitor == 'b10) begin
                if (capture_in_progress) begin
                    capture_armed <= 0;
                    capture_in_progress <= 0;
                end
            end
        end
    end
end

assign data_valid_out = frame_valid_in && line_valid_in && capture_in_progress;

endmodule