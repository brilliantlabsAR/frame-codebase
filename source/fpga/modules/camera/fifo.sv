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
    input logic clock, // 72MHz
	input logic reset_n,
    input logic [9:0] rgb10,
	input logic [7:0] rgb8,
	input logic [3:0] gray4,
    input logic write_enable, // Camera data is valid
    input logic frame_valid, // frame complete
    input logic [3:0] pixel_width, // 4, 8 or 10

    output logic write_enable_frame_buffer, 
    output logic [31:0] pixel_data_to_ram,
    output logic [15:0] ram_address
);
    logic [7:0] head;
    logic [41:0] fifo /* synthesis syn_keep=1 nomerge=""*/;
	logic [1:0] write_enable_frame_buffer_;

localparam GRAY4 = 8'd4;
localparam RGB8 = 8'd8;
localparam RGB10 = 8'd10;

assign write_enable_frame_buffer = write_enable_frame_buffer_[1];
logic debug = 0;
	
always_ff @(posedge clock) begin
	if (!reset_n | !frame_valid) begin
		// Reset and write the last of the FIFO into RAM
		if (head != 'd41) begin
			head <= 'd41;
			// write out the unfilled buffer with padding
			write_enable_frame_buffer_ <= 2'b10;
			ram_address <= ram_address +1;
			case(head)
				'd40: pixel_data_to_ram <= {fifo[41], 31'b0};
				'd39: pixel_data_to_ram <= {fifo[41:40], 30'b0};
				'd38: pixel_data_to_ram <= {fifo[41:39], 29'b0};
				'd37: pixel_data_to_ram <= {fifo[41:38], 28'b0};
				'd36: pixel_data_to_ram <= {fifo[41:37], 27'b0};
				'd35: pixel_data_to_ram <= {fifo[41:36], 26'b0};
				'd34: pixel_data_to_ram <= {fifo[41:35], 25'b0};
				'd33: pixel_data_to_ram <= {fifo[41:34], 24'b0};
				'd32: pixel_data_to_ram <= {fifo[41:33], 23'b0};
				'd31: pixel_data_to_ram <= {fifo[41:32], 22'b0};
				'd30: pixel_data_to_ram <= {fifo[41:31], 21'b0};
				'd29: pixel_data_to_ram <= {fifo[41:30], 20'b0};
				'd28: pixel_data_to_ram <= {fifo[41:29], 19'b0};
				'd27: pixel_data_to_ram <= {fifo[41:28], 18'b0};
				'd26: pixel_data_to_ram <= {fifo[41:27], 17'b0};
				'd25: pixel_data_to_ram <= {fifo[41:26], 16'b0};
				'd24: pixel_data_to_ram <= {fifo[41:25], 15'b0};
				'd23: pixel_data_to_ram <= {fifo[41:24], 14'b0};
				'd22: pixel_data_to_ram <= {fifo[41:23], 13'b0};
				'd21: pixel_data_to_ram <= {fifo[41:22], 12'b0};
				'd20: pixel_data_to_ram <= {fifo[41:21], 11'b0};
				'd19: pixel_data_to_ram <= {fifo[41:20], 10'b0};
				'd18: pixel_data_to_ram <= {fifo[41:19], 9'b0};
				'd17: pixel_data_to_ram <= {fifo[41:18], 8'b0};
				'd16: pixel_data_to_ram <= {fifo[41:17], 7'b0};
				'd15: pixel_data_to_ram <= {fifo[41:16], 6'b0};
				'd14: pixel_data_to_ram <= {fifo[41:15], 5'b0};
				'd13: pixel_data_to_ram <= {fifo[41:14], 4'b0};
				'd12: pixel_data_to_ram <= {fifo[41:13], 3'b0};
				'd11: pixel_data_to_ram <= {fifo[41:12], 2'b0};
				'd10: pixel_data_to_ram <= {fifo[41:11], 1'b0};
				'd9: pixel_data_to_ram <= fifo[41:10];
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
				ram_address <= 'hffff; // roll over so we don't skip addr 0
				pixel_data_to_ram <= 0;
			end
		end
	end

    else begin
        if (write_enable) begin
            if (head > 'd9) begin
				// Wait for fifo to fill
				if (write_enable_frame_buffer_ != 2'b00) 
					write_enable_frame_buffer_ <= write_enable_frame_buffer_ + 1;

				// Write bits and increment head
				case(pixel_width)
					GRAY4 : begin
						case(head)
							'd41: fifo[41:38] <= gray4;
							'd40: fifo[40:37] <= gray4;
							'd39: fifo[39:36] <= gray4;
							'd38: fifo[38:35] <= gray4;
							'd37: fifo[37:34] <= gray4;
							'd36: fifo[36:33] <= gray4;
							'd35: fifo[35:32] <= gray4;
							'd34: fifo[34:31] <= gray4;
							'd33: fifo[33:30] <= gray4;
							'd32: fifo[32:29] <= gray4;
							'd31: fifo[31:28] <= gray4;
							'd30: fifo[30:27] <= gray4;
							'd29: fifo[29:26] <= gray4;
							'd28: fifo[28:25] <= gray4;
							'd27: fifo[27:24] <= gray4;
							'd26: fifo[26:23] <= gray4;
							'd25: fifo[25:22] <= gray4;
							'd24: fifo[24:21] <= gray4;
							'd23: fifo[23:20] <= gray4;
							'd22: fifo[22:19] <= gray4;
							'd21: fifo[21:18] <= gray4;
							'd20: fifo[20:17] <= gray4;
							'd19: fifo[19:16] <= gray4;
							'd18: fifo[18:15] <= gray4;
							'd17: fifo[17:14] <= gray4;
							'd16: fifo[16:13] <= gray4;
							'd15: fifo[15:12] <= gray4;
							'd14: fifo[14:11] <= gray4;
							'd13: fifo[13:10] <= gray4;
							'd12: fifo[12:9] <= gray4;
							'd11: fifo[11:8] <= gray4;
							'd10: fifo[10:7] <= gray4;
						endcase
					end
					RGB8 : begin
						case(head)
							'd41: fifo[41:34] <= rgb8;
							'd40: fifo[40:33] <= rgb8;
							'd39: fifo[39:32] <= rgb8;
							'd38: fifo[38:31] <= rgb8;
							'd37: fifo[37:30] <= rgb8;
							'd36: fifo[36:29] <= rgb8;
							'd35: fifo[35:28] <= rgb8;
							'd34: fifo[34:27] <= rgb8;
							'd33: fifo[33:26] <= rgb8;
							'd32: fifo[32:25] <= rgb8;
							'd31: fifo[31:24] <= rgb8;
							'd30: fifo[30:23] <= rgb8;
							'd29: fifo[29:22] <= rgb8;
							'd28: fifo[28:21] <= rgb8;
							'd27: fifo[27:20] <= rgb8;
							'd26: fifo[26:19] <= rgb8;
							'd25: fifo[25:18] <= rgb8;
							'd24: fifo[24:17] <= rgb8;
							'd23: fifo[23:16] <= rgb8;
							'd22: fifo[22:15] <= rgb8;
							'd21: fifo[21:14] <= rgb8;
							'd20: fifo[20:13] <= rgb8;
							'd19: fifo[19:12] <= rgb8;
							'd18: fifo[18:11] <= rgb8;
							'd17: fifo[17:10] <= rgb8;
							'd16: fifo[16:9] <= rgb8;
							'd15: fifo[15:8] <= rgb8;
							'd14: fifo[14:7] <= rgb8;
							'd13: fifo[13:6] <= rgb8;
							'd12: fifo[12:5] <= rgb8;
							'd11: fifo[11:4] <= rgb8;
							'd10: fifo[10:3] <= rgb8;
						endcase
					end

					RGB10 : begin
						case(head)
							'd41: fifo[41:32] <= rgb10;
							'd40: fifo[40:31] <= rgb10;
							'd39: fifo[39:30] <= rgb10;
							'd38: fifo[38:29] <= rgb10;
							'd37: fifo[37:28] <= rgb10;
							'd36: fifo[36:27] <= rgb10;
							'd35: fifo[35:26] <= rgb10;
							'd34: fifo[34:25] <= rgb10;
							'd33: fifo[33:24] <= rgb10;
							'd32: fifo[32:23] <= rgb10;
							'd31: fifo[31:22] <= rgb10;
							'd30: fifo[30:21] <= rgb10;
							'd29: fifo[29:20] <= rgb10;
							'd28: fifo[28:19] <= rgb10;
							'd27: fifo[27:18] <= rgb10;
							'd26: fifo[26:17] <= rgb10;
							'd25: fifo[25:16] <= rgb10;
							'd24: fifo[24:15] <= rgb10;
							'd23: fifo[23:14] <= rgb10;
							'd22: fifo[22:13] <= rgb10;
							'd21: fifo[21:12] <= rgb10;
							'd20: fifo[20:11] <= rgb10;
							'd19: fifo[19:10] <= rgb10;
							'd18: fifo[18:9] <= rgb10;
							'd17: fifo[17:8] <= rgb10;
							'd16: fifo[16:7] <= rgb10;
							'd15: fifo[15:6] <= rgb10;
							'd14: fifo[14:5] <= rgb10;
							'd13: fifo[13:4] <= rgb10;
							'd12: fifo[12:3] <= rgb10;
							'd11: fifo[11:2] <= rgb10;
							'd10: fifo[10:1] <= rgb10;
						endcase
					end
				endcase
				head <= head - pixel_width;
            end

            else begin
                pixel_data_to_ram <= fifo[41:10];
				case(pixel_width)
				GRAY4 : begin
					case(head)
						'd9: fifo[41:38] <= gray4;
						'd8: fifo[41:37] <= {fifo[9], gray4};
						'd7: fifo[41:36] <= {fifo[9:8], gray4};
						'd6: fifo[41:35] <= {fifo[9:7], gray4};
						'd5: fifo[41:34] <= {fifo[9:6], gray4};
						'd4: fifo[41:33] <= {fifo[9:5], gray4};
						'd3: fifo[41:32] <= {fifo[9:4], gray4};
						'd2: fifo[41:31] <= {fifo[9:3], gray4};
						'd1: fifo[41:30] <= {fifo[9:2], gray4};
						'd0: fifo[41:29] <= {fifo[9:1], gray4};
					endcase
					head <= head + 'd32 - 'd4;
				end
				RGB8 : begin
					case(head)
						'd9: fifo[41:34] <= rgb8;
						'd8: fifo[41:33] <= {fifo[9], rgb8};
						'd7: fifo[41:32] <= {fifo[9:8], rgb8};
						'd6: fifo[41:31] <= {fifo[9:7], rgb8};
						'd5: fifo[41:30] <= {fifo[9:6], rgb8};
						'd4: fifo[41:29] <= {fifo[9:5], rgb8};
						'd3: fifo[41:28] <= {fifo[9:4], rgb8};
						'd2: fifo[41:27] <= {fifo[9:3], rgb8};
						'd1: fifo[41:26] <= {fifo[9:2], rgb8};
						'd0: fifo[41:26] <= {fifo[9:1], rgb8};
					endcase
					head <= head + 'd32 - 'd8;
				end
				RGB10: begin
					case(head)
						'd9: fifo[41:34] <= rgb10;
						'd8: fifo[41:33] <= {fifo[9], rgb10};
						'd7: fifo[41:32] <= {fifo[9:8], rgb10};
						'd6: fifo[41:31] <= {fifo[9:7], rgb10};
						'd5: fifo[41:30] <= {fifo[9:6], rgb10};
						'd4: fifo[41:29] <= {fifo[9:5], rgb10};
						'd3: fifo[41:28] <= {fifo[9:4], rgb10};
						'd2: fifo[41:27] <= {fifo[9:3], rgb10};
						'd1: fifo[41:26] <= {fifo[9:2], rgb10};
						'd0: fifo[41:26] <= {fifo[9:1], rgb10};
					endcase
					head <= head + 'd32 - 'd10;
				end
				endcase
				write_enable_frame_buffer_ <= 2'b10;
                ram_address <= ram_address +1;
            end
        end
		else begin
			if (write_enable_frame_buffer_ != 2'b00)
				write_enable_frame_buffer_ <= write_enable_frame_buffer_ + 1;
		end
    end

end

endmodule