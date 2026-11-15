


import game_params::*;

module collision_detector (
    input  logic clk,
    input  logic resetN,
	 
    input  logic game_active, // from game controller  
	 input logic init_game,
	
    input  logic cell_step_pulse,   // one clock pulse when head enters a new cell
    input  logic [4:0] head_cell_x,
    input  logic [4:0] head_cell_y,
    input  logic [4:0] snake_len,
	 
	 //objects_cells
	 input  logic snake_head_DR,
	 input  logic snake_body_DR,
	 input  logic obstacle_DR,
	 input  logic food_DR,
    input  logic fat_food_DR,
	 input  logic mouse_DR,
	 
	 input logic [99:0] snake_body_cell_x_flat,
	 input logic [99:0] snake_body_cell_y_flat,
	 
	 input  logic [1:0] snake_part,
	 input logic startOfFrame,
    
	 
    // collision pulses
    output logic hit_wall_pulse,
	 output logic hit_obstacle_pulse,
    output logic hit_self_pulse,
	 output logic hit_food_pulse,
	 output logic hit_fat_food_pulse,
	 output logic hit_mouse_pulse,
	 output logic hit_mouse_object_pulse
);
    
    

 logic hit_wall_comb;
 logic hit_self_comb;
 
 logic food_hit;
 logic fat_food_hit;
 logic obstacle_hit;
 logic obstacle_hit_d;
 logic mouse_object_hit;
 logic hit_mouse_comb;
 logic one_hit_mouse;
 
 logic food_hit_flag;
 logic fat_food_hit_flag;
 logic mouse_object_hit_flag;

// ------------------------------------------------------------
// convert the flatten body cells inputs bake into two demention arreys
// ------------------------------------------------------------ 
logic [4:0] snake_body_cell_x [0:19];
logic [4:0] snake_body_cell_y [0:19];

genvar j;

generate
    for (j = 0; j < 20; j++) begin : unpack_body_cells
        assign snake_body_cell_x[j] = snake_body_cell_x_flat[j*5 +: 5];
        assign snake_body_cell_y[j] = snake_body_cell_y_flat[j*5 +: 5];
    end
endgenerate


// ------------------------------------------------------------
// Combinational collision checks
// ------------------------------------------------------------
always_comb begin
  hit_wall_comb   = 1'b0; 
  hit_self_comb   = 1'b0;
  obstacle_hit  = 1'b0;
  food_hit   = 1'b0;
  fat_food_hit  = 1'b0;
  mouse_object_hit = 1'b0;
  hit_mouse_comb = 1'b0;
  

  // --------------------------------------------------------
  // Wall collision
  // --------------------------------------------------------
  if ((head_cell_x >= BOARD_COLS) ||
		(head_cell_y >= BOARD_ROWS)) begin
		hit_wall_comb = 1'b1;
  end
	
  // --------------------------------------------------------
  // Self collision
  // Compare head cell to body cells
  // --------------------------------------------------------
  for (int i = 1; i < MAX_SNAKE_LEN; i++) begin
		if (i < snake_len - 1) begin
			 if ((head_cell_x == snake_body_cell_x[i]) &&
				  (head_cell_y == snake_body_cell_y[i])) begin
				  hit_self_comb = 1'b1;
			 end
		end
  end

  // --------------------------------------------------------
  // obstacle collision
  // --------------------------------------------------------
  if (snake_head_DR && obstacle_DR) begin
		obstacle_hit = 1'b1;
  end
  
  
  // --------------------------------------------------------
  // food collision
  // --------------------------------------------------------
	if (snake_head_DR && fat_food_DR) begin
		 fat_food_hit = 1'b1;
   end
	
	if (snake_head_DR && food_DR) begin
		 food_hit = 1'b1;
   end
	
  
  // mouse collision
  
  if (mouse_DR &&
		 (snake_part == 2'b1) && !one_hit_mouse) begin
		 hit_mouse_comb = 1'b1;
  end
  
  // mouse object collision
  if (mouse_DR && (snake_body_DR || obstacle_DR || fat_food_DR || food_DR)) begin
		mouse_object_hit = 1'b1;
	end	
end

 
// ------------------------------------------------------------
// Register collision outputs as one-clock pulses
// ------------------------------------------------------------
always_ff @(posedge clk or negedge resetN) begin
  if (!resetN) begin
		hit_wall_pulse  <= 1'b0;
		hit_obstacle_pulse  <= 1'b0;
		hit_self_pulse  <= 1'b0;
		hit_fat_food_pulse  <= 1'b0;
		hit_food_pulse  <= 1'b0;
		hit_mouse_pulse  <= 1'b0;
		obstacle_hit_d <= 1'b0;
		one_hit_mouse <= 1'b0;
		food_hit_flag <= 1'b0;
      fat_food_hit_flag <= 1'b0;
		mouse_object_hit_flag <= 1'b0;
  end

  else begin
		// default: no pulse
		hit_wall_pulse       <= 1'b0;
		hit_obstacle_pulse   <= 1'b0;
		hit_self_pulse       <= 1'b0;
		hit_fat_food_pulse   <= 1'b0;
		hit_food_pulse       <= 1'b0;
		hit_mouse_pulse      <= 1'b0;
		hit_mouse_object_pulse <= 1'b0;
		
		if (init_game) begin
			one_hit_mouse <= 1'b0;
			food_hit_flag <= 1'b0;
			fat_food_hit_flag <= 1'b0;
			mouse_object_hit_flag <= 1'b0;
		end	

		// check wall and self collisions only when the head enters a new cell
		if (game_active && cell_step_pulse) begin
			 hit_wall_pulse <= hit_wall_comb;
			 hit_self_pulse <= hit_self_comb;
		end
		
		if (game_active) begin
			obstacle_hit_d <= obstacle_hit;
			
			if (food_hit)
				 food_hit_flag <= 1'b1;
				
			if (fat_food_hit)
				 fat_food_hit_flag <= 1'b1;
				
			if	(mouse_object_hit)
				 mouse_object_hit_flag <= 1'b1;
			
			if (startOfFrame) begin
                if (food_hit_flag) begin
                    hit_food_pulse <= 1'b1;
                    food_hit_flag <= 1'b0; 
                end
					 if (fat_food_hit_flag)	begin
						  hit_fat_food_pulse <= 1'b1;
                    fat_food_hit_flag <= 1'b0; 
                end
					 if(mouse_object_hit_flag)	begin
						  hit_mouse_object_pulse <= 1'b1;
                    mouse_object_hit_flag <= 1'b0;
					 end
			end			
				
			if (obstacle_hit && !obstacle_hit_d)
				hit_obstacle_pulse <= 1'b1;
				
			hit_mouse_pulse     <= hit_mouse_comb;
			 if (hit_mouse_comb)
				one_hit_mouse <= 1'b1;
		end
  end
end

endmodule