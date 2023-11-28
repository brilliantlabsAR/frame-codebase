
module spi_register_chip_id (
    input logic [7:0] address_in,
    input logic address_valid,
    output logic [7:0] data_out,
    output logic data_valid
);
    always @(posedge address_valid) begin

        if (address_in == 'h0A) begin
            data_out <= 'hF1;
            data_valid <= 1;
        end

        else begin
            data_out <= 'h00;
            data_valid <= 0;
        end
    end

endmodule