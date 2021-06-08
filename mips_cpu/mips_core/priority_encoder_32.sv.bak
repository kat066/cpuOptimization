`include "mips_core.svh"
/* priority_encoder.sv
 *
 * Author: Haaris Tahir-Kheli
 * Date  : June 2nd, 2021
 *
 * A priority encoder that takes, as parameters, the number of inputs, 
 * and a wire signal to determine whether or not the encoder will operate
 * as a high priority encoder, or a low priority encoder.
 *
 * The output of the encoder is the binary encoding of the "index" of the
 * valid input that has the highest priority (based on whatever priority scheme the
 * module is uses, which is based on the value of the parameter, "HIGH_PRIORITY", 
 * and whether or not a 1 or a 0 is going to be seen as the valid input, which is
 * based on the value of the parameter, "SIGNAL".)
 * 
 */
module priority_encoder_32 #(parameter HIGH_PRIORITY = 0, parameter SIGNAL = 1) (
	input [31:0] data_inputs,
	output logic [4:0] encoding_output
);

int i; 

always_comb begin
	if (HIGH_PRIORITY) begin
		if (SIGNAL) begin
			casex(data_inputs)
				32'b1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd31;
				32'b01XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd30;
				32'b001XXXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd29;
				32'b0001XXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd28;
				32'b00001XXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd27;
				32'b000001XXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd26;
				32'b0000001XXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd25;
				32'b00000001XXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd24;
				32'b000000001XXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd23;
				32'b0000000001XXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd22;
				32'b00000000001XXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd21;
				32'b000000000001XXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd20;
				32'b0000000000001XXXXXXXXXXXXXXXXXXX: encoding_output = 5'd19;
				32'b00000000000001XXXXXXXXXXXXXXXXXX: encoding_output = 5'd18;
				32'b000000000000001XXXXXXXXXXXXXXXXX: encoding_output = 5'd17;
				32'b0000000000000001XXXXXXXXXXXXXXXX: encoding_output = 5'd16;
				32'b00000000000000001XXXXXXXXXXXXXXX: encoding_output = 5'd15;
				32'b000000000000000001XXXXXXXXXXXXXX: encoding_output = 5'd14;
				32'b0000000000000000001XXXXXXXXXXXXX: encoding_output = 5'd13;
				32'b00000000000000000001XXXXXXXXXXXX: encoding_output = 5'd12;
				32'b000000000000000000001XXXXXXXXXXX: encoding_output = 5'd11;
				32'b0000000000000000000001XXXXXXXXXX: encoding_output = 5'd10;
				32'b00000000000000000000001XXXXXXXXX: encoding_output = 5'd9;
				32'b000000000000000000000001XXXXXXXX: encoding_output = 5'd8;
				32'b0000000000000000000000001XXXXXXX: encoding_output = 5'd7;
				32'b00000000000000000000000001XXXXXX: encoding_output = 5'd6;
				32'b000000000000000000000000001XXXXX: encoding_output = 5'd5;
				32'b0000000000000000000000000001XXXX: encoding_output = 5'd4;
				32'b00000000000000000000000000001XXX: encoding_output = 5'd3;
				32'b000000000000000000000000000001XX: encoding_output = 5'd2;
				32'b0000000000000000000000000000001X: encoding_output = 5'd1;
				32'b00000000000000000000000000000001: encoding_output = 5'd0;
				default								: encoding_output = 5'd0;
			endcase
		end
		else begin
			casex(data_inputs)
				32'b0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd31;
				32'b10XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd30;
				32'b110XXXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd29;
				32'b1110XXXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd28;
				32'b11110XXXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd27;
				32'b111110XXXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd26;
				32'b1111110XXXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd25;
				32'b11111110XXXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd24;
				32'b111111110XXXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd23;
				32'b1111111110XXXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd22;
				32'b11111111110XXXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd21;
				32'b111111111110XXXXXXXXXXXXXXXXXXXX: encoding_output = 5'd20;
				32'b1111111111110XXXXXXXXXXXXXXXXXXX: encoding_output = 5'd19;
				32'b11111111111110XXXXXXXXXXXXXXXXXX: encoding_output = 5'd18;
				32'b111111111111110XXXXXXXXXXXXXXXXX: encoding_output = 5'd17;
				32'b1111111111111110XXXXXXXXXXXXXXXX: encoding_output = 5'd16;
				32'b11111111111111110XXXXXXXXXXXXXXX: encoding_output = 5'd15;
				32'b111111111111111110XXXXXXXXXXXXXX: encoding_output = 5'd14;
				32'b1111111111111111110XXXXXXXXXXXXX: encoding_output = 5'd13;
				32'b11111111111111111110XXXXXXXXXXXX: encoding_output = 5'd12;
				32'b111111111111111111110XXXXXXXXXXX: encoding_output = 5'd11;
				32'b1111111111111111111110XXXXXXXXXX: encoding_output = 5'd10;
				32'b11111111111111111111110XXXXXXXXX: encoding_output = 5'd9;
				32'b111111111111111111111110XXXXXXXX: encoding_output = 5'd8;
				32'b1111111111111111111111110XXXXXXX: encoding_output = 5'd7;
				32'b11111111111111111111111110XXXXXX: encoding_output = 5'd6;
				32'b111111111111111111111111110XXXXX: encoding_output = 5'd5;
				32'b1111111111111111111111111110XXXX: encoding_output = 5'd4;
				32'b11111111111111111111111111110XXX: encoding_output = 5'd3;
				32'b111111111111111111111111111110XX: encoding_output = 5'd2;
				32'b1111111111111111111111111111110X: encoding_output = 5'd1;
				32'b11111111111111111111111111111110: encoding_output = 5'd0;
				default								: encoding_output = 5'd0;
			endcase		
		end
	end
	else begin
		if (SIGNAL) begin
			casex(data_inputs)
				32'b10000000000000000000000000000000: encoding_output = 5'd31;
				32'bX1000000000000000000000000000000: encoding_output = 5'd30;
				32'bXX100000000000000000000000000000: encoding_output = 5'd29;
				32'bXXX10000000000000000000000000000: encoding_output = 5'd28;
				32'bXXXX1000000000000000000000000000: encoding_output = 5'd27;
				32'bXXXXX100000000000000000000000000: encoding_output = 5'd26;
				32'bXXXXXX10000000000000000000000000: encoding_output = 5'd25;
				32'bXXXXXXX1000000000000000000000000: encoding_output = 5'd24;
				32'bXXXXXXXX100000000000000000000000: encoding_output = 5'd23;
				32'bXXXXXXXXX10000000000000000000000: encoding_output = 5'd22;
				32'bXXXXXXXXXX1000000000000000000000: encoding_output = 5'd21;
				32'bXXXXXXXXXXX100000000000000000000: encoding_output = 5'd20;
				32'bXXXXXXXXXXXX10000000000000000000: encoding_output = 5'd19;
				32'bXXXXXXXXXXXXX1000000000000000000: encoding_output = 5'd18;
				32'bXXXXXXXXXXXXXX100000000000000000: encoding_output = 5'd17;
				32'bXXXXXXXXXXXXXXX10000000000000000: encoding_output = 5'd16;
				32'bXXXXXXXXXXXXXXXX1000000000000000: encoding_output = 5'd15;
				32'bXXXXXXXXXXXXXXXXX100000000000000: encoding_output = 5'd14;
				32'bXXXXXXXXXXXXXXXXXX10000000000000: encoding_output = 5'd13;
				32'bXXXXXXXXXXXXXXXXXXX1000000000000: encoding_output = 5'd12;
				32'bXXXXXXXXXXXXXXXXXXXX100000000000: encoding_output = 5'd11;
				32'bXXXXXXXXXXXXXXXXXXXXX10000000000: encoding_output = 5'd10;
				32'bXXXXXXXXXXXXXXXXXXXXXX1000000000: encoding_output = 5'd9;
				32'bXXXXXXXXXXXXXXXXXXXXXXX100000000: encoding_output = 5'd8;
				32'bXXXXXXXXXXXXXXXXXXXXXXXX10000000: encoding_output = 5'd7;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXX1000000: encoding_output = 5'd6;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXX100000: encoding_output = 5'd5;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXX10000: encoding_output = 5'd4;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXX1000: encoding_output = 5'd3;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXXX100: encoding_output = 5'd2;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX10: encoding_output = 5'd1;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX1: encoding_output = 5'd0;
				default								: encoding_output = 5'd0;
			endcase		
		end
		else begin
			casex(data_inputs)
				32'b01111111111111111111111111111111: encoding_output = 5'd31;
				32'bX0111111111111111111111111111111: encoding_output = 5'd30;
				32'bXX011111111111111111111111111111: encoding_output = 5'd29;
				32'bXXX01111111111111111111111111111: encoding_output = 5'd28;
				32'bXXXX0111111111111111111111111111: encoding_output = 5'd27;
				32'bXXXXX011111111111111111111111111: encoding_output = 5'd26;
				32'bXXXXXX01111111111111111111111111: encoding_output = 5'd25;
				32'bXXXXXXX0111111111111111111111111: encoding_output = 5'd24;
				32'bXXXXXXXX011111111111111111111111: encoding_output = 5'd23;
				32'bXXXXXXXXX01111111111111111111111: encoding_output = 5'd22;
				32'bXXXXXXXXXX0111111111111111111111: encoding_output = 5'd21;
				32'bXXXXXXXXXXX011111111111111111111: encoding_output = 5'd20;
				32'bXXXXXXXXXXXX01111111111111111111: encoding_output = 5'd19;
				32'bXXXXXXXXXXXXX0111111111111111111: encoding_output = 5'd18;
				32'bXXXXXXXXXXXXXX011111111111111111: encoding_output = 5'd17;
				32'bXXXXXXXXXXXXXXX01111111111111111: encoding_output = 5'd16;
				32'bXXXXXXXXXXXXXXXX0111111111111111: encoding_output = 5'd15;
				32'bXXXXXXXXXXXXXXXXX011111111111111: encoding_output = 5'd14;
				32'bXXXXXXXXXXXXXXXXXX01111111111111: encoding_output = 5'd13;
				32'bXXXXXXXXXXXXXXXXXXX0111111111111: encoding_output = 5'd12;
				32'bXXXXXXXXXXXXXXXXXXXX011111111111: encoding_output = 5'd11;
				32'bXXXXXXXXXXXXXXXXXXXXX01111111111: encoding_output = 5'd10;
				32'bXXXXXXXXXXXXXXXXXXXXXX0111111111: encoding_output = 5'd9;
				32'bXXXXXXXXXXXXXXXXXXXXXXX011111111: encoding_output = 5'd8;
				32'bXXXXXXXXXXXXXXXXXXXXXXXX01111111: encoding_output = 5'd7;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXX0111111: encoding_output = 5'd6;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXX011111: encoding_output = 5'd5;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXX01111: encoding_output = 5'd4;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXX0111: encoding_output = 5'd3;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXXX011: encoding_output = 5'd2;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX01: encoding_output = 5'd1;
				32'bXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0: encoding_output = 5'd0;
				default								: encoding_output = 5'd0;
			endcase			
		end
	end
end


endmodule
