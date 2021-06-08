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
	input data_inputs [32],
	output logic [4:0] encoding_output 
);
 

always_comb begin
	encoding_output = 0;
	for (int i = 0; i<32; i++) begin
		if(data_inputs[i] == SIGNAL) begin
			encoding_output = i;
			break;
		end
	end

end


endmodule
