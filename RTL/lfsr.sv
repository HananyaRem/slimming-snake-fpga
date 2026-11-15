module lfsr (
	input	logic	clk,
	input	logic	resetN,
	input logic [7:0] seed1,
	input logic trigger,
	
	output logic [7:0] random
);

logic [7:0] prev_value;

always_ff@(posedge clk or negedge resetN) begin
	if (!resetN) begin
		random <= seed1;
	end
	else begin
		if (trigger) begin
			if ({random[6:0], random[7] ^ random[5] ^ random[4] ^ random[3]} < 225)
				random <= {random[6:0], random[7] ^ random[5] ^ random[4] ^ random[3]};
			else
				random <= seed1;
		end
	end
end

endmodule
