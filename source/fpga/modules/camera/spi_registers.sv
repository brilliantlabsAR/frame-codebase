module spi_registers (
    input logic clock_in,
    input logic reset_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,
    output logic [7:0] response_out,
    output logic response_valid_out,

    output logic start_capture_out,
    // TODO position signals
    output logic [3:0] quality_factor_out,

    input logic [15:0] bytes_available_in,
    input logic [7:0] data_in,
    output logic [15:0] bytes_read_out,

    input logic [7:0] red_metering_in,
    input logic [7:0] green_metering_in,
    input logic [7:0] blue_metering_in
);

logic [15:0] bytes_remaining;
assign bytes_remaining = bytes_available_in - bytes_read_out;

logic [1:0] operand_valid_in_edge_monitor;

always_ff @(posedge clock_in) begin
    
    if (reset_n_in == 0) begin
        response_out <= 0;
        response_valid_out <= 0;

        start_capture_out <= 0;
        // TODO position signals
        quality_factor_out <= 0;

        bytes_read_out <= 0;

        operand_valid_in_edge_monitor <= 0;
    end

    else begin
        operand_valid_in_edge_monitor <= {operand_valid_in_edge_monitor[0], 
                                          operand_valid_in};

        if (op_code_valid_in) begin

            case (op_code_in)

                // Capture
                'h20: begin
                    start_capture_out <= 1;
                    bytes_read_out <= 0;
                end

                // Bytes available
                'h21: begin
                    case (operand_count_in)
                        0: response_out <= bytes_remaining[15:8];
                        1: response_out <= bytes_remaining[7:0];
                    endcase

                    response_valid_out <= 1;
                end

                // Read data
                'h22: begin
                    response_out <= data_in;

                    if (operand_valid_in_edge_monitor == 2'b01) begin
                        if (bytes_read_out < bytes_available_in) begin 
                            bytes_read_out <= bytes_read_out + 1;
                        end
                    end

                    response_valid_out <= 1;
                end

                // Zoom
                'h23: begin
                    if (operand_valid_in) begin 
                        // zoom_factor <= operand_in; // TODO
                    end
                end

                // Pan
                'h24: begin
                    if (operand_valid_in) begin 
                        // pan_level <= operand_in; // TODO
                    end
                end

                // Metering
                'h25: begin
                    case (operand_count_in)
                        0: response_out <= red_metering_in;
                        1: response_out <= green_metering_in;
                        2: response_out <= blue_metering_in;
                    endcase

                    response_valid_out <= 1;
                end

                // Quality factor
                'h26: begin
                    if (operand_valid_in) begin 
                        quality_factor_out <= operand_in[3:0];
                    end
                end

            endcase

        end

        else begin
            response_valid_out <= 0;

            start_capture_out <= 0;
        end

    end

end

endmodule