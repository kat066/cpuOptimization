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
 * input that has the highest priority (based on whatever priority scheme the
 * module is uses, which is based on the value of the parameter "HIGH_PRIORITY".
 *
 */
module priority_encoder #(parameter NUM_OF_INPUTS = 32, HIGH_PRIORITY = 1) (
	input [NUM_OF_INPUTS-1:0] data_inputs,
	output logic [$clog2(NUM_OF_INPUTS)-1:0] encoding_output
);

int i;

generate											//The "generate" keyword tells Quartus to only synthesize the block of code within
													//the generate area if all of the conditions are meet.
													//
													//For example, if (HIGH_PRIORITY == 1), then only the code in the if-statement will
													//be synthesized.  If (HIGH_PRIORITY == 0), then only the code in the else-statement will
													//be synthesized.
													//
													//That said, "generate" can only work if the conditions are based on parameters! This is 
													//because parameters are constant at compile time!  If you try to do a "generate" condition based
													//on a variable that can change, Quartus will give an error!
	always_comb begin
		if (HIGH_PRIORITY) begin
			for (i = 0; i < NUM_OF_INPUTS; i++) begin	
				if (data_inputs[i]) begin
					encoding_output = i;				//If we ever have a case where there are more than one cases
														//where "data_inputs[i] == 1", then the case where "i" is the highest
														//value will be the one we go with.
														//
														//Effectively, the highest valued "i", overrides the output of the lower valued
														//"i".  Since the priority_encoder priorities "high 'i'" input in this case, we say
														//that it is a "High Priority Encoder."
				end
			end	
		end
		else begin
			for (i = NUM_OF_INPUTS; i >= 0; i--) begin
				if (data_inputs[i]) begin				//This case is the inverse of the above, so we call it a "Low Priority Encoder."
					encoding_output = i;
				end
			end
		end
	end
	
	
	
	
	
	
	
	
endgenerate

endmodule
