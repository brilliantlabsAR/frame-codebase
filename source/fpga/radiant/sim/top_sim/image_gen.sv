module image_gen #(
    parameter HPIX = 32'd640,
    parameter VPIX = 32'd400,
    parameter VBP = 32'd2,
	parameter VFP = 32'd1,
	parameter HSYNC = 32'd44,
	parameter VSYNC = 32'd5
) (
    input logic clk,
    input logic reset_n,
    output logic lv,
    output logic fv,
    output logic [9:0] pix_data,
	output logic pix_en
);

logic [31:0] x;
logic [31:0] y;
logic [7:0] reset_counter;

localparam HFP = 2*HPIX;
localparam HBP = 2.2*HPIX;
// localparam HFP = 32'd2560;
// localparam HBP = 32'd2816;

always @(posedge clk) begin
    if(!reset_n) begin
        x <= 0;
		y <= 0;
		reset_counter <= 'd0;
    end else begin
		if (!reset_counter[4])
			reset_counter <= reset_counter +1;
		else begin 
			if ( (x >= (HSYNC+HBP)) && (x < (HSYNC+HBP+HPIX))  &&  (y >= (VSYNC+VBP)) && (y < (VSYNC+VBP+VPIX)) )
				pix_en <= 1;
			else 
				pix_en <= 0;
			
			if ( (x >= (HSYNC)) && (x < (HSYNC+HBP+HPIX+HFP))  &&  (y >= (VSYNC+VBP)) && (y < (VSYNC+VBP+VPIX)) )
				lv <= 1;
			else
				lv <= 0;

			if ( (y >= 0) && (y < VSYNC) )
				fv <= 0;
			else
				fv <= 1;
			
			if (x <= (HSYNC+HBP+HPIX+HFP))
				x <= x + 1;
			else begin
				x <= 0;
				if (y <= (VSYNC+VBP+VPIX+VFP))
					y <= y + 1;
				else 
					y <= 0;
			end

			if (x >= (HSYNC+HBP)) begin
				if ((x - (HSYNC+HBP)) < 'd320) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h3ff; // r
						else pix_data <= 'h3ff; // g
					end
					else begin
						if (x[0]) pix_data <= 'h3ff; // g
						else pix_data <= 'h3ff; // b
					end
				end
				else if (((x - (HSYNC+HBP)) >= 'd320) & ((x - (HSYNC+HBP)) < 'd640)) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h3ff; // r
						else pix_data <= 'h0; // g
					end
					else begin
						if (x[0]) pix_data <= 'h0; // g
						else pix_data <= 'h3ff; // b
					end
				end
				else if (((x - (HSYNC+HBP)) >= 'd640) & ((x - (HSYNC+HBP)) < 'd960)) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h0; // r
						else pix_data <= 'h3ff; // g
					end
					else begin
						if (x[0]) pix_data <= 'h3ff; // g
						else pix_data <= 'h0; // b
					end
				end
				else if (((x - (HSYNC+HBP)) >= 'd960) & ((x - (HSYNC+HBP)) < 'd1280)) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h3ff; // r
						else pix_data <= 'h3ff; // g
					end
					else begin
						if (x[0]) pix_data <= 'h0; // g
						else pix_data <= 'h0; // b
					end
				end
			end

			// else if (((x - (HSYNC+HBP)) >= 'd96) & ((x - (HSYNC+HBP)) < 'd128)) pix_data <= 'h60; 
			// else if (((x - (HSYNC+HBP)) >= 'd128) & ((x - (HSYNC+HBP)) < 'd160)) pix_data <= 'h80; 
			// else if (((x - (HSYNC+HBP)) >= 'd160) & ((x - (HSYNC+HBP)) < 'd192)) pix_data <= 'ha0; 
			// else if (((x - (HSYNC+HBP)) >= 'd192) & ((x - (HSYNC+HBP)) < 'd224)) pix_data <= 'hc0; 
			// else if (((x - (HSYNC+HBP)) >= 'd224) & ((x - (HSYNC+HBP)) < 'd256)) pix_data <= 'he0;
			// else if (((x - (HSYNC+HBP)) >= 'd256) & ((x - (HSYNC+HBP)) < 'd288)) pix_data <= 'h100;
			// else if (((x - (HSYNC+HBP)) >= 'd288) & ((x - (HSYNC+HBP)) < 'd312)) pix_data <= 'h12;
			// else if (((x - (HSYNC+HBP)) >= 'd312) & ((x - (HSYNC+HBP)) < 'd344)) pix_data <= 'h14;
			// else if (((x - (HSYNC+HBP)) >= 'd344) & ((x - (HSYNC+HBP)) < 'd376)) pix_data <= 'h16;
			// else pix_data <= 'h122;
		end
	end
end

endmodule