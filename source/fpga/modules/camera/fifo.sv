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

module fifo (
    input logic clock_in, // 72MHz
	input logic reset_n_in,
    input logic [9:0] rgb10_in,
	input logic [7:0] rgb8_in,
	input logic [3:0] gray4_in,
    input logic write_enable_in, // Camera data is valid
    input logic frame_valid_in, // frame complete
    input logic [3:0] pixel_width_in, // 4, 8 or 10

    output logic write_enable_out, 
    output logic [31:0] pixel_data_out,
    output logic [15:0] address_out
);
    logic [7:0] head;
    logic [41:0] fifo /* synthesis syn_keep=1 nomerge=""*/;
	logic [1:0] write_enable_frame_buffer_;

localparam GRAY4 = 8'd4;
localparam RGB8 = 8'd8;
localparam RGB10 = 8'd10;

assign write_enable_out = write_enable_frame_buffer_[1];
logic debug = 0;
	
always_ff @(posedge clock_in) begin
	if (!reset_n_in | !frame_valid_in) begin
		// Reset and write the last of the FIFO into RAM
		if (head != 'd41) begin
			head <= 'd41;
			// write out the unfilled buffer with padding
			write_enable_frame_buffer_ <= 2'b10;
			address_out <= address_out +1;
			case(head)
				'd40: pixel_data_out <= {fifo[41], 31'b0};
				'd39: pixel_data_out <= {fifo[41:40], 30'b0};
				'd38: pixel_data_out <= {fifo[41:39], 29'b0};
				'd37: pixel_data_out <= {fifo[41:38], 28'b0};
				'd36: pixel_data_out <= {fifo[41:37], 27'b0};
				'd35: pixel_data_out <= {fifo[41:36], 26'b0};
				'd34: pixel_data_out <= {fifo[41:35], 25'b0};
				'd33: pixel_data_out <= {fifo[41:34], 24'b0};
				'd32: pixel_data_out <= {fifo[41:33], 23'b0};
				'd31: pixel_data_out <= {fifo[41:32], 22'b0};
				'd30: pixel_data_out <= {fifo[41:31], 21'b0};
				'd29: pixel_data_out <= {fifo[41:30], 20'b0};
				'd28: pixel_data_out <= {fifo[41:29], 19'b0};
				'd27: pixel_data_out <= {fifo[41:28], 18'b0};
				'd26: pixel_data_out <= {fifo[41:27], 17'b0};
				'd25: pixel_data_out <= {fifo[41:26], 16'b0};
				'd24: pixel_data_out <= {fifo[41:25], 15'b0};
				'd23: pixel_data_out <= {fifo[41:24], 14'b0};
				'd22: pixel_data_out <= {fifo[41:23], 13'b0};
				'd21: pixel_data_out <= {fifo[41:22], 12'b0};
				'd20: pixel_data_out <= {fifo[41:21], 11'b0};
				'd19: pixel_data_out <= {fifo[41:20], 10'b0};
				'd18: pixel_data_out <= {fifo[41:19], 9'b0};
				'd17: pixel_data_out <= {fifo[41:18], 8'b0};
				'd16: pixel_data_out <= {fifo[41:17], 7'b0};
				'd15: pixel_data_out <= {fifo[41:16], 6'b0};
				'd14: pixel_data_out <= {fifo[41:15], 5'b0};
				'd13: pixel_data_out <= {fifo[41:14], 4'b0};
				'd12: pixel_data_out <= {fifo[41:13], 3'b0};
				'd11: pixel_data_out <= {fifo[41:12], 2'b0};
				'd10: pixel_data_out <= {fifo[41:11], 1'b0};
				'd9: pixel_data_out <= fifo[41:10];
			endcase
		end else begin
			head <= 'd41;
			fifo <= 42'b0;
			if (write_enable_frame_buffer_ != 2'b00) begin
				write_enable_frame_buffer_ <= write_enable_frame_buffer_ + 1;
				debug <= 1;
			end
			else begin
				write_enable_frame_buffer_ <= 2'b00;
				address_out <= 'hffff; // roll over so we don't skip addr 0
				pixel_data_out <= 0;
			end
		end
	end

    else begin
        if (write_enable_in) begin
            if (head > 'd9) begin
				// Wait for fifo to fill
				if (write_enable_frame_buffer_ != 2'b00) 
					write_enable_frame_buffer_ <= write_enable_frame_buffer_ + 1;

				// Write bits and increment head
				case(pixel_width_in)
					GRAY4 : begin
						case(head)
							'd41: fifo[41:38] <= gray4_in;
							'd40: fifo[40:37] <= gray4_in;
							'd39: fifo[39:36] <= gray4_in;
							'd38: fifo[38:35] <= gray4_in;
							'd37: fifo[37:34] <= gray4_in;
							'd36: fifo[36:33] <= gray4_in;
							'd35: fifo[35:32] <= gray4_in;
							'd34: fifo[34:31] <= gray4_in;
							'd33: fifo[33:30] <= gray4_in;
							'd32: fifo[32:29] <= gray4_in;
							'd31: fifo[31:28] <= gray4_in;
							'd30: fifo[30:27] <= gray4_in;
							'd29: fifo[29:26] <= gray4_in;
							'd28: fifo[28:25] <= gray4_in;
							'd27: fifo[27:24] <= gray4_in;
							'd26: fifo[26:23] <= gray4_in;
							'd25: fifo[25:22] <= gray4_in;
							'd24: fifo[24:21] <= gray4_in;
							'd23: fifo[23:20] <= gray4_in;
							'd22: fifo[22:19] <= gray4_in;
							'd21: fifo[21:18] <= gray4_in;
							'd20: fifo[20:17] <= gray4_in;
							'd19: fifo[19:16] <= gray4_in;
							'd18: fifo[18:15] <= gray4_in;
							'd17: fifo[17:14] <= gray4_in;
							'd16: fifo[16:13] <= gray4_in;
							'd15: fifo[15:12] <= gray4_in;
							'd14: fifo[14:11] <= gray4_in;
							'd13: fifo[13:10] <= gray4_in;
							'd12: fifo[12:9] <= gray4_in;
							'd11: fifo[11:8] <= gray4_in;
							'd10: fifo[10:7] <= gray4_in;
						endcase
					end
					RGB8 : begin
						case(head)
							'd41: fifo[41:34] <= rgb8_in;
							'd40: fifo[40:33] <= rgb8_in;
							'd39: fifo[39:32] <= rgb8_in;
							'd38: fifo[38:31] <= rgb8_in;
							'd37: fifo[37:30] <= rgb8_in;
							'd36: fifo[36:29] <= rgb8_in;
							'd35: fifo[35:28] <= rgb8_in;
							'd34: fifo[34:27] <= rgb8_in;
							'd33: fifo[33:26] <= rgb8_in;
							'd32: fifo[32:25] <= rgb8_in;
							'd31: fifo[31:24] <= rgb8_in;
							'd30: fifo[30:23] <= rgb8_in;
							'd29: fifo[29:22] <= rgb8_in;
							'd28: fifo[28:21] <= rgb8_in;
							'd27: fifo[27:20] <= rgb8_in;
							'd26: fifo[26:19] <= rgb8_in;
							'd25: fifo[25:18] <= rgb8_in;
							'd24: fifo[24:17] <= rgb8_in;
							'd23: fifo[23:16] <= rgb8_in;
							'd22: fifo[22:15] <= rgb8_in;
							'd21: fifo[21:14] <= rgb8_in;
							'd20: fifo[20:13] <= rgb8_in;
							'd19: fifo[19:12] <= rgb8_in;
							'd18: fifo[18:11] <= rgb8_in;
							'd17: fifo[17:10] <= rgb8_in;
							'd16: fifo[16:9] <= rgb8_in;
							'd15: fifo[15:8] <= rgb8_in;
							'd14: fifo[14:7] <= rgb8_in;
							'd13: fifo[13:6] <= rgb8_in;
							'd12: fifo[12:5] <= rgb8_in;
							'd11: fifo[11:4] <= rgb8_in;
							'd10: fifo[10:3] <= rgb8_in;
						endcase
					end

					RGB10 : begin
						case(head)
							'd41: fifo[41:32] <= rgb10_in;
							'd40: fifo[40:31] <= rgb10_in;
							'd39: fifo[39:30] <= rgb10_in;
							'd38: fifo[38:29] <= rgb10_in;
							'd37: fifo[37:28] <= rgb10_in;
							'd36: fifo[36:27] <= rgb10_in;
							'd35: fifo[35:26] <= rgb10_in;
							'd34: fifo[34:25] <= rgb10_in;
							'd33: fifo[33:24] <= rgb10_in;
							'd32: fifo[32:23] <= rgb10_in;
							'd31: fifo[31:22] <= rgb10_in;
							'd30: fifo[30:21] <= rgb10_in;
							'd29: fifo[29:20] <= rgb10_in;
							'd28: fifo[28:19] <= rgb10_in;
							'd27: fifo[27:18] <= rgb10_in;
							'd26: fifo[26:17] <= rgb10_in;
							'd25: fifo[25:16] <= rgb10_in;
							'd24: fifo[24:15] <= rgb10_in;
							'd23: fifo[23:14] <= rgb10_in;
							'd22: fifo[22:13] <= rgb10_in;
							'd21: fifo[21:12] <= rgb10_in;
							'd20: fifo[20:11] <= rgb10_in;
							'd19: fifo[19:10] <= rgb10_in;
							'd18: fifo[18:9] <= rgb10_in;
							'd17: fifo[17:8] <= rgb10_in;
							'd16: fifo[16:7] <= rgb10_in;
							'd15: fifo[15:6] <= rgb10_in;
							'd14: fifo[14:5] <= rgb10_in;
							'd13: fifo[13:4] <= rgb10_in;
							'd12: fifo[12:3] <= rgb10_in;
							'd11: fifo[11:2] <= rgb10_in;
							'd10: fifo[10:1] <= rgb10_in;
						endcase
					end
				endcase
				head <= head - pixel_width_in;
            end

            else begin
                pixel_data_out <= fifo[41:10];
				case(pixel_width_in)
				GRAY4 : begin
					case(head)
						'd9: fifo[41:38] <= gray4_in;
						'd8: fifo[41:37] <= {fifo[9], gray4_in};
						'd7: fifo[41:36] <= {fifo[9:8], gray4_in};
						'd6: fifo[41:35] <= {fifo[9:7], gray4_in};
						'd5: fifo[41:34] <= {fifo[9:6], gray4_in};
						'd4: fifo[41:33] <= {fifo[9:5], gray4_in};
						'd3: fifo[41:32] <= {fifo[9:4], gray4_in};
						'd2: fifo[41:31] <= {fifo[9:3], gray4_in};
						'd1: fifo[41:30] <= {fifo[9:2], gray4_in};
						'd0: fifo[41:29] <= {fifo[9:1], gray4_in};
					endcase
					head <= head + 'd32 - 'd4;
				end
				RGB8 : begin
					case(head)
						'd9: fifo[41:34] <= rgb8_in;
						'd8: fifo[41:33] <= {fifo[9], rgb8_in};
						'd7: fifo[41:32] <= {fifo[9:8], rgb8_in};
						'd6: fifo[41:31] <= {fifo[9:7], rgb8_in};
						'd5: fifo[41:30] <= {fifo[9:6], rgb8_in};
						'd4: fifo[41:29] <= {fifo[9:5], rgb8_in};
						'd3: fifo[41:28] <= {fifo[9:4], rgb8_in};
						'd2: fifo[41:27] <= {fifo[9:3], rgb8_in};
						'd1: fifo[41:26] <= {fifo[9:2], rgb8_in};
						'd0: fifo[41:26] <= {fifo[9:1], rgb8_in};
					endcase
					head <= head + 'd32 - 'd8;
				end
				RGB10: begin
					case(head)
						'd9: fifo[41:34] <= rgb10_in;
						'd8: fifo[41:33] <= {fifo[9], rgb10_in};
						'd7: fifo[41:32] <= {fifo[9:8], rgb10_in};
						'd6: fifo[41:31] <= {fifo[9:7], rgb10_in};
						'd5: fifo[41:30] <= {fifo[9:6], rgb10_in};
						'd4: fifo[41:29] <= {fifo[9:5], rgb10_in};
						'd3: fifo[41:28] <= {fifo[9:4], rgb10_in};
						'd2: fifo[41:27] <= {fifo[9:3], rgb10_in};
						'd1: fifo[41:26] <= {fifo[9:2], rgb10_in};
						'd0: fifo[41:26] <= {fifo[9:1], rgb10_in};
					endcase
					head <= head + 'd32 - 'd10;
				end
				endcase
				write_enable_frame_buffer_ <= 2'b10;
                address_out <= address_out +1;
            end
        end
		else begin
			if (write_enable_frame_buffer_ != 2'b00)
				write_enable_frame_buffer_ <= write_enable_frame_buffer_ + 1;
		end
    end

end

endmodule