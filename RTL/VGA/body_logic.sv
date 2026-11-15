
import game_params::*;

module body_logic (
	input logic clk,
	input logic resetN,
	//input logic startOfFrame,
   input logic init_game, // from game controller
	//from snake move
   input logic cell_step_pulse,
   input logic [4:0] head_cell_x,
   input logic [4:0] head_cell_y,
	input logic signed [10:0] head_x,
	input logic signed [10:0] head_y,
	input logic [11:0] move_progress_fixed,
	
	//input logic snake_apple_collision,
	input logic [4:0] snake_len,//from length logic
	
	output logic signed [21:0] snake_body [0:19],
	//fllaten output for bdf
	output logic [99:0] snake_body_cell_x_flat, 
   output logic [99:0] snake_body_cell_y_flat
//	output logic [4:0] snake_length
);

//initial head position value
localparam int START_CELL_X = 10;
localparam int START_CELL_Y = 5;

localparam logic [10:0] OFFSCREEN = 11'd1000; // address outside the screen limits for hiding cells

logic [4:0] body_cell_x [0:19];
logic [4:0] body_cell_y [0:19];
logic [4:0] snake_body_cell_x [0:19];
logic [4:0] snake_body_cell_y [0:19];

int progress_pixels; //progress inside the cell

int draw_x;
int draw_y;

int previous_x;
int previous_y;
int next_x;
int next_y;
 
//end


// ------------------------------------------------------------
// Cell to pixel conversion fonctions
// ------------------------------------------------------------
function automatic int cell_x_to_pixel(input logic [4:0] cell_x);
  begin
		cell_x_to_pixel = BOARD_LEFT_X + cell_x * CELL_SIZE;
  end
endfunction

function automatic int cell_y_to_pixel(input logic [4:0] cell_y);
  begin
		cell_y_to_pixel = BOARD_TOP_Y + cell_y * CELL_SIZE;
  end
endfunction

	 
// ------------------------------------------------------------
// Reset body to initial horizontal snake
// ------------------------------------------------------------
task automatic reset_body;
  begin
		for (int i = 0; i < MAX_SNAKE_LEN; i++) begin
			 if (i <= START_CELL_X) begin
				  body_cell_x[i] <= START_CELL_X[4:0] - i[4:0];
				  body_cell_y[i] <= START_CELL_Y[4:0];
			 end
			 else begin
				  body_cell_x[i] <= 5'd0;
				  body_cell_y[i] <= START_CELL_Y[4:0];
			 end
		end
  end
endtask
 

// ------------------------------------------------------------ 
//update the logical body cells when the head enters new cell
// ------------------------------------------------------------
always_ff @(posedge clk or negedge resetN) begin
	  if (!resetN) begin
			reset_body();
	  end

	  else if (init_game) begin
			reset_body();
	  end

	  else if (cell_step_pulse) begin

			for (int i = MAX_SNAKE_LEN-1; i > 0; i--) begin
				 body_cell_x[i] <= body_cell_x[i-1];
				 body_cell_y[i] <= body_cell_y[i-1];
			end

			body_cell_x[0] <= head_cell_x;
			body_cell_y[0] <= head_cell_y;

	  end
 end	 


// ------------------------------------------------------------
//drow continuous body position
// ------------------------------------------------------------
 always_comb begin

        progress_pixels = move_progress_fixed / FIXED_POINT_MULTIPLIER;

        for (int i = 0; i < MAX_SNAKE_LEN; i++) begin
				  // default values 
				  draw_x     = OFFSCREEN; //hide cells that outside the current length
				  draw_y     = OFFSCREEN;
				  previous_x = 0;
				  previous_y = 0;
				  next_x     = 0;
				  next_y     = 0;
				  snake_body_cell_x[i] = 5'd31;
				  snake_body_cell_y[i] = 5'd31;
				  
				if (i < snake_len) begin
					snake_body_cell_x[i] = body_cell_x[i];
					snake_body_cell_y[i] = body_cell_y[i];
			
					if (i == 0) begin //drow head
						 draw_x = head_x;
						 draw_y = head_y;
					end

					else begin
						 previous_x = cell_x_to_pixel(body_cell_x[i]);
						 previous_y = cell_y_to_pixel(body_cell_y[i]);

						 next_x = cell_x_to_pixel(body_cell_x[i-1]);
						 next_y = cell_y_to_pixel(body_cell_y[i-1]);

						 draw_x = previous_x;
						 draw_y = previous_y;

						 if (next_x > previous_x)
							  draw_x = previous_x + progress_pixels;
						 else if (next_x < previous_x)
							  draw_x = previous_x - progress_pixels;

						 if (next_y > previous_y)
							  draw_y = previous_y + progress_pixels;
						 else if (next_y < previous_y)
							  draw_y = previous_y - progress_pixels;
					end
				end

          snake_body[i] = {draw_x[10:0], draw_y[10:0]};
      end  
				
end

//flatten the two dementional arrey for bdf flow
genvar gi;

generate
    for (gi = 0; gi < MAX_SNAKE_LEN; gi++) begin : flatten_body_cells
        assign snake_body_cell_x_flat[gi*5 +: 5] = snake_body_cell_x[gi];
        assign snake_body_cell_y_flat[gi*5 +: 5] = snake_body_cell_y[gi];
    end
endgenerate

endmodule	
