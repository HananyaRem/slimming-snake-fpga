
import game_params::*;

module obstacle_matrix (
		input		logic	clk,
		input		logic	resetN,
		input 	logic signed	[10:0] pixelX,// current VGA pixel 
		input 	logic signed	[10:0] pixelY, 
		input    logic [7:0] random,
		//from game controler
		input    logic init_game,
		input    logic game_active,

		output logic  drawingRequest,
	   output logic  [7:0] RGBout,
		output logic  [3:0] obstacle_setup_id
);


logic [3:0] setup_id_reg; //holds the chosen setup number during the game 

logic inside_board;
logic [7:0] cell_num;
logic [10:0] cell_pixel_x; //the distance of current pixel from the left of the arena pixel (180)
logic [10:0] cell_pixel_y; //the distance of current pixel from the top of the arena pixel (0)

logic	[4:0] offsetX; // offset inside bracket from top left position
logic	[4:0] offsetY;

logic obstacle_cell; //BitMap nodule input if current cell is an obstacle cell
//BitMap module outputs
logic bitmap_DR;
logic [7:0] bitmap_RGB;



// random setup id selection in the begining of the game, from [0,,,15]
always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            setup_id_reg <= 4'd0; 
        end
        else if (init_game) begin 
		     setup_id_reg <= random[3:0];
//            if (random[3:0] < 4'd10) begin 
//					 setup_id_reg <= random[3:0];
//				end else begin
//					 setup_id_reg <= random[3:0] - 4'd10; 
//				end
        end
 end
 
assign obstacle_setup_id = setup_id_reg;
 
 
 
// cells calculation 
always_comb begin

	  inside_board = 1'b0;
	  
	  cell_num = 8'd0;
	  cell_pixel_x = 11'd0;	
	  cell_pixel_y = 11'd0;
	  
	  offsetX = 5'd0;
	  offsetY = 5'd0;
	 
	  if (pixelX >= BOARD_LEFT_X) begin
			inside_board = 1'b1;
	  
			cell_pixel_x = pixelX - BOARD_LEFT_X;
			cell_pixel_y = pixelY - BOARD_TOP_Y;
			
			cell_num = cell_pixel_x[8:5] + BOARD_COLS  * cell_pixel_y[8:5];
         offsetX = cell_pixel_x[4:0];
         offsetY = cell_pixel_y[4:0];
	  end 
 end
 
 
 
 //obstacle cells setup acorrding to the id number 
 //check if the input cell is an abstacle cell function
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



//Check if current pixel belongs to an obstacle cell	
always_comb begin
	  obstacle_cell = 1'b0;

	  if (inside_board) begin
			obstacle_cell = is_obstacle_cell(setup_id_reg, cell_num);
	  end
 end 


//BitMap 
obstacleBitMap obstacle_bitmap_inst (
	  .clk(clk),
	  .resetN(resetN),
	  .offsetX(offsetX),
	  .offsetY(offsetY),
	  .InsideRectangle(obstacle_cell),
	  .drawingRequest(bitmap_DR),
	  .RGBout(bitmap_RGB)
);


//outputs
assign drawingRequest = bitmap_DR;
assign RGBout = bitmap_RGB;

endmodule