

module time_bcd_counter(
	input  logic clk,
   input  logic resetN,
	input  logic moving, //from snake_move, if the snake is currently moving
	//from game_controler
	input  logic init_game,
	input  logic game_active,
	//input  logic one_sec_pulse,
	
	//outputs, the time that have passed since the start of the game
	output logic [3:0] sec_ones,
   output logic [3:0] sec_tens,
   output logic [3:0] min_ones,
   output logic [3:0] min_tens 
	
);

logic one_sec_pulse;

one_sec_counter #(
	 .SIMULATION_MODE(0)
) sec_inst (
	 .clk(clk),
	 .resetN(resetN),
	 .moving(moving),
	 .turbo(1'b0),
	 .one_sec_pulse(one_sec_pulse),
);


//sycronic time count in seconds and minuts
always_ff @(posedge clk or negedge resetN) begin

	if (!resetN) begin
		sec_ones <= 4'd0;
		sec_tens <= 4'd0;
		min_ones <= 4'd0;
		min_tens <= 4'd0;
	end
	
	else if (init_game) begin // reset the count when the game starts
		sec_ones <= 4'd0;
		sec_tens <= 4'd0;
		min_ones <= 4'd0;
		min_tens <= 4'd0;
	end
		
	else if (one_sec_pulse && game_active && moving) begin	//add 1 sec 
		if((min_tens == 4'd5) && (min_ones == 4'd9) &&
		   (sec_tens == 4'd5) && (sec_ones == 4'd9)) begin
			//we reached the max number allowd, do nothing /stop counting
		end
		
		else if(sec_ones == 4'd9) begin
			 sec_ones <= 4'd0;
			
			 if (sec_tens == 4'd5) begin
				  sec_tens <= 4'd0;
				  
				  if (min_ones == 4'd9) begin
						min_ones <= 4'd0;
						min_tens <= min_tens + 1'b1;
					end
				  
				  else 
						min_ones <= min_ones + 1'b1;
			  end		
						
			else
				 sec_tens <= sec_tens + 1'b1;
		end
		
		else
			 sec_ones <= sec_ones +1'b1;
	end		 
end //syc
endmodule	