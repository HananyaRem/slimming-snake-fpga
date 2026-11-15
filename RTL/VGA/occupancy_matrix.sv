
import game_params::*;

module occupancy_matrix (
		
		input  logic clk,
		input  logic resetN,
		
		input  logic [99:0] snake_body_cell_x_flat, 
      input  logic [99:0] snake_body_cell_y_flat,
		input  logic [4:0] snake_len,
		
		input  logic [4:0] food_cell_x,
		input  logic [4:0] food_cell_y,
		input  logic [4:0] fat_food_cell_x,
		input  logic [4:0] fat_food_cell_y,
		
		input  logic [4:0] mouse_cell_x,
		input  logic [4:0] mouse_cell_y,
		// optional if it exist in the game
		input  logic [7:0] portal_gate1_cell,
		input  logic [7:0] portal_gate2_cell,
		
		input  logic [3:0] obstacle_setup_id, //the randomly chosen obstacle setup representor id
		
		// output vector in the size of the arena matrix cells number
	   //	each bit represents the matching cell condition
		output logic [224:0] occupied_flat
);


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
// fill the occupied vector output with the current locations of the game objects
// for each bit in the vector 1 represents occupied cell 
// ------------------------------------------------------------ 
always_comb begin

    occupied_flat = '0; //default

	 // snake
    for (int i = 0; i < MAX_SNAKE_LEN; i++) begin
        if (i < snake_len)
            occupied_flat[snake_body_cell_y[i] * BOARD_COLS + snake_body_cell_x[i]] = 1'b1;
    end

	// foods and mouse
	occupied_flat[food_cell_y * BOARD_COLS + food_cell_x] = 1'b1;
	occupied_flat[fat_food_cell_y * BOARD_COLS + fat_food_cell_x] = 1'b1;
	occupied_flat[mouse_cell_y * BOARD_COLS + mouse_cell_x] = 1'b1;
	
	// optional portals, uncomment if exist
//	occupied_flat[portal_gate1_cell] = 1'b1;
//	occupied_flat[portal_gate1_cell] = 1'b1;

	//obstacles
	for (int i = 0; i < MATRIX_SIZE; i++) begin //check if the cell is an obstacle cell
		if (is_obstacle_cell(obstacle_setup_id, i)) begin
			 occupied_flat[i] = 1'b1;
		end	 
	end
end



// ------------------------------------------------------------
// check if the input cell is an abstacle cell according to setup id function
// ------------------------------------------------------------ 
 function automatic logic is_obstacle_cell (
	  input logic [3:0] setup_id,
	  input logic [7:0] num
 ); 
   begin
		 is_obstacle_cell = 1'b0;
		 
		 case (setup_id)
		 
			 4'd0: begin
				 if ((num == 8'd17) ||(num == 8'd16) || (num == 8'd31) ||
				      (num == 8'd111) ||(num == 8'd112) ||(num == 8'd194)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
		    
			 4'd1: begin
				 if ((num == 8'd191) ||(num == 8'd192) || (num == 8'd207) ||
				      (num == 8'd222) ||(num == 8'd26) ||(num == 8'd126)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd2: begin
				 if ((num == 8'd99) ||(num == 8'd101) || (num == 8'd97) ||
				      (num == 8'd129) ||(num == 8'd131) ||(num == 8'd127)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd3: begin
				 if ((num == 8'd7) ||(num == 8'd22) || (num == 8'd37) ||
				      (num == 8'd117) ||(num == 8'd118) ||(num == 8'd119)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd4: begin
				 if ((num == 8'd142) ||(num == 8'd157) || (num == 8'd172) ||
				      (num == 8'd187) ||(num == 8'd202) ||(num == 8'd217)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd5: begin
				 if ((num == 8'd16) ||(num == 8'd28) || (num == 8'd208) ||
				      (num == 8'd196) ||(num == 8'd111) ||(num == 8'd113)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd6: begin
				 if ((num == 8'd142) ||(num == 8'd143) || (num == 8'd144) ||
				      (num == 8'd172) ||(num == 8'd173) ||(num == 8'd174)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd7: begin
				 if ((num == 8'd115) ||(num == 8'd116) || (num == 8'd117) ||
				      (num == 8'd107) ||(num == 8'd108) ||(num == 8'd109)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd8: begin
				 if ((num == 8'd112) ||(num == 8'd128) || (num == 8'd144) ||
				      (num == 8'd160) ||(num == 8'd176) ||(num == 8'd192)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd9: begin
				 if ((num == 8'd161) ||(num == 8'd176) || (num == 8'd128) ||
				      (num == 8'd143) ||(num == 8'd95) ||(num == 8'd110)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd10: begin
				 if ((num == 8'd111) ||(num == 8'd112) || (num == 8'd113) ||
				      (num == 8'd110) ||(num == 8'd128) ||(num == 8'd114)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd11: begin
				 if ((num == 8'd174) ||(num == 8'd191) || (num == 8'd89) ||
				      (num == 8'd201) ||(num == 8'd19) ||(num == 8'd123)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd12: begin
				 if ((num == 8'd206) ||(num == 8'd221) || (num == 8'd128) ||
				      (num == 8'd126) ||(num == 8'd127) ||(num == 8'd15)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd13: begin
				 if ((num == 8'd36) ||(num == 8'd37) || (num == 8'd38) ||
				      (num == 8'd112) ||(num == 8'd127) ||(num == 8'd142)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd14: begin
				 if ((num == 8'd27) ||(num == 8'd28) || (num == 8'd43) ||
				      (num == 8'd202) ||(num == 8'd203) ||(num == 8'd211)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 4'd15: begin
				 if ((num == 8'd0) ||(num == 8'd14) || (num == 8'd210) ||
				      (num == 8'd224) ||(num == 8'd7) ||(num == 8'd217)) begin
                    is_obstacle_cell = 1'b1;
             end
          end
			 
			 default: begin
				  is_obstacle_cell = 1'b0;
			 end	 
		 endcase	 
	end
endfunction	

endmodule