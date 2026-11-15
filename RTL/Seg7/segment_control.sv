
module segment_control (
		 input  logic clk,	
		 input  logic resetN,
		 input  logic game_active,
		
		 // current game time
		 input  logic [3:0] sec_ones,
		 input  logic [3:0] sec_tens,
		 input  logic [3:0] min_ones,
		 input  logic [3:0] min_tens,

		 // last score 
		 input  logic [3:0] score_sec_ones,
		 input  logic [3:0] score_sec_tens,
		 input  logic [3:0] score_min_ones,
		 input  logic [3:0] score_min_tens,
		 
		 output logic [3:0] H0,
		 output logic [3:0] H1,
		 output logic [3:0] H2,
		 output logic [3:0] H3
);

 always_comb begin
		
	  if (game_active) begin
			H0 = sec_ones;
			H1 = sec_tens;
			H2 = min_ones;
			H3 = min_tens;
		end
		
		else if (score_sec_ones == 4'd10) begin
        H0 = 4'd0;
        H1 = 4'd0;
        H2 = 4'd0;
        H3 = 4'd0;
    end
	 
	 else begin
        H0 = score_sec_ones;
        H1 = score_sec_tens;
        H2 = score_min_ones;
        H3 = score_min_tens;
    end
 end

endmodule