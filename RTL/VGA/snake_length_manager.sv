

import game_params::*;

module snake_length_manager (
    input  logic clk,
    input  logic resetN,

    input  logic init_game,

    input  logic eat_food_pulse,
    input  logic eat_fat_food_pulse,
	 input logic eat_mouse_pulse,

    output logic [4:0] snake_length,
    output logic win_condition
);

logic [4:0] snake_len;

 //update length acorrding to food type
always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		snake_length <= START_SNAKE_LEN;
	end

	else if (init_game) begin
		snake_length <= START_SNAKE_LEN;
	end

	else begin
		if (eat_mouse_pulse) begin
			if (snake_length > MIN_SNAKE_LEN + 3)
				snake_length <= snake_length - 3;
			else 
				snake_length <= MIN_SNAKE_LEN;
		end
		else if (eat_food_pulse) begin
			 if (snake_length > MIN_SNAKE_LEN)
				  snake_length <= snake_length - 1;
		end

		else if (eat_fat_food_pulse) begin
			 if (snake_length < MAX_SNAKE_LEN)
				  snake_length <= snake_length + 1;
		end
		snake_len <= snake_length;
	
		if (snake_len == MIN_SNAKE_LEN)
			snake_length <= 10;
	end
end

 assign win_condition = (snake_length == MIN_SNAKE_LEN);

endmodule