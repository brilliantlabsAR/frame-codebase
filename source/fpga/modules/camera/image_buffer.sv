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

module image_buffer (
    input logic clock_in,
    input logic reset_n_in,

    input logic [13:0] write_address_in,
    input logic [15:0] read_address_in,

    input logic [31:0] write_data_in,
    output logic [7:0] read_data_out,

    input logic write_enable_in
);

`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];

always @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        read_data_out <= 0;
    end

    else begin
        if (write_enable_in) begin
            mem[write_address_in] <= write_data_in;
        end

        case (read_address_in[1:0])
            'd0: read_data_out <= mem[read_address_in[15:2]][7:0];
            'd1: read_data_out <= mem[read_address_in[15:2]][15:8];
            'd2: read_data_out <= mem[read_address_in[15:2]][23:16];
            'd3: read_data_out <= mem[read_address_in[15:2]][31:24];
        endcase
    end
 end

/*
logic [31:0]    q;
logic [13:0]    a;
logic [1:0]     a0, a1;

always @(negedge clock_in) a1 <= read_address_in[1:0];
always @(negedge clock_in) a0 <= a1;
always_comb
    case (a0[1:0])
    'd0: read_data_out = q[7:0];
    'd1: read_data_out = q[15:8];
    'd2: read_data_out = q[23:16];
    'd3: read_data_out = q[31:24];
    endcase



`define INFER_LARGE_RAM
`ifdef INFER_LARGE_RAM
`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];

always @(negedge clock_in) begin
    if (write_enable_in)
        mem[write_address_in] <= write_data_in;
    a <= read_address_in[15:2];
    q <= mem[a];
end

`else

always_comb a = read_address_in[15:2];

`ifndef USE_LATTICE_EBR
large_ram_dp_q mem (
    .wa     (write_address_in),
    .wd     (write_data_in),
    .we     (write_enable_in),
    .ra     (a),
    .rd     (q),
    .clk    (~clock_in)
);
`else
large_ram_dp_q mem (
    .clk_i          (~clock_in), 
    .dps_i          (1'b0), 
    .rst_i          (1'b0),
    .wr_clk_en_i    (write_enable_in), 
    .rd_clk_en_i    (1'b1), 
    .wr_en_i        (write_enable_in), 
    .wr_data_i      (write_data_in), 
    .wr_addr_i      (write_address_in), 
    .rd_addr_i      (a), 
    .rd_data_o      (q), 
    .lramready_o    (), 
    .rd_datavalid_o ()
) ;
`endif       
`endif
*/
endmodule
