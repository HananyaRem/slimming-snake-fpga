module	mouse_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 					
					input  logic game_active,
					input  logic init_game,
					
					input  logic signed [10:0] current_speed, //speed controller
					input logic [1:0] current_direction,
					input logic number_4,

					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					//current head location for body drawing
					output logic [4:0] mouse_cell_x,
					output logic [4:0] mouse_cell_y					
);

int 	 topLeftX_tmp; // output the top left corner 
 int   topLeftY_tmp;  // can be negative , if the object is partliy outside 

// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 576;
parameter int INITIAL_Y = 320;

const int MAX_Y_SPEED = 500;
//const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 32;
const int   OBJECT_HIGHT_Y = 32;

const int	x_FRAME_LEFT	=	(160 + OBJECT_WIDTH_X) * FIXED_POINT_MULTIPLIER ;//(SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int	x_FRAME_RIGHT	=	(640- OBJECT_WIDTH_X * 2)* FIXED_POINT_MULTIPLIER; 
const int	y_FRAME_TOP		=	OBJECT_HIGHT_Y; //(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	y_FRAME_BOTTOM	=	(480 - OBJECT_HIGHT_Y * 2) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

localparam int BOARD_LEFT_X = 160;
localparam int BOARD_TOP_Y  = 0;

localparam int BOARD_COLS = 15;
localparam int BOARD_ROWS = 15;

localparam int CELL_SIZE = 32;
localparam int _FIXED = CELL_SIZE * 64; // 32 * 64 = 2048

localparam int START_CELL_X = (INITIAL_X - BOARD_LEFT_X) / CELL_SIZE; // 10
localparam int START_CELL_Y = (INITIAL_Y - BOARD_TOP_Y)  / CELL_SIZE; // 5


enum  logic [3:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 WAIT_ST_RIGHT,
						 WAIT_ST_LEFT,
						 WAIT_ST_DOWN,
						 WAIT_ST_UP,
						 //CHECK_COLLISION_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST // position interpolate 
						 //POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;



// Direction encoding
localparam logic [1:0] DIR_RIGHT = 2'd0;
localparam logic [1:0] DIR_LEFT  = 2'd1;
localparam logic [1:0] DIR_UP    = 2'd2;
localparam logic [1:0] DIR_DOWN  = 2'd3;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;
 
//registers for keeping the head inside the cell limits in rotation
int target_Xposition; //position of the edge of current cell
int target_Yposition;

int head_cell_x_reg;
int head_cell_y_reg;

int target_cell_x;
int target_cell_y;
int progress_calc;
logic reached_target; //internal pulse when the head reaches the cell edge
logic [1:0] previous_direction;

 // ------------------------------------------------------------
 // Helper functions for calculate next cell pixeles
 // ------------------------------------------------------------
 function automatic int cell_x_to_fixed(input int cell_x);
	  begin
			cell_x_to_fixed =
				 (BOARD_LEFT_X + cell_x * CELL_SIZE) * FIXED_POINT_MULTIPLIER;
	  end
 endfunction

 function automatic int cell_y_to_fixed(input int cell_y);
	  begin
			cell_y_to_fixed =
				 (BOARD_TOP_Y + cell_y * CELL_SIZE) * FIXED_POINT_MULTIPLIER;
	  end
 endfunction



// ------------------------------------------------------------
// Tasks
// ------------------------------------------------------------
//reset to initial position and zero speed 
task automatic reset_mouse_position;
begin
  SM_Motion <= IDLE_ST;

  Xspeed <= 0;
  Yspeed <= 0;

  Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
  Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;

  target_Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
  target_Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;

  head_cell_x_reg <= START_CELL_X;
  head_cell_y_reg <= START_CELL_Y;

  target_cell_x <= START_CELL_X;
  target_cell_y <= START_CELL_Y;
  
  previous_direction <= DIR_RIGHT;

 // hit_reg <= 5'b0;
end
endtask 



 task automatic set_speed_direction;
        input int dx;
        input int dy;
    begin
        Xspeed <= dx * (current_speed + 64);
        Yspeed <= dy * (current_speed + 64);
    end
    endtask
	
	
task automatic set_next_target;
	  input int dx;
	  input int dy;
 begin
	  target_cell_x <= target_cell_x + dx;
	  target_cell_y <= target_cell_y + dy;

	  target_Xposition <= cell_x_to_fixed(target_cell_x + dx);
	  target_Yposition <= cell_y_to_fixed(target_cell_y + dy);
 end
 endtask


//fix the head to the next cell limits 
task automatic fix_to_target_cell;
	begin
	  Xposition <= target_Xposition;
	  Yposition <= target_Yposition;

	  head_cell_x_reg <= target_cell_x;
	  head_cell_y_reg <= target_cell_y;

	end
endtask

 
//
task automatic continue_current_direction;
    begin
        if (Xspeed > 0) begin
            set_next_target(1, 0);
        end
        else if (Xspeed < 0) begin
            set_next_target(-1, 0);
        end
        else if (Yspeed > 0) begin
            set_next_target(0, 1);
        end
        else if (Yspeed < 0) begin
            set_next_target(0, -1);
        end
    end
endtask



//turn when head reaches the end of current cell
task automatic turn_when_ready;
  input int dx;
  input int dy;
begin
  // Start moving in the requested direction.
  if ((Xspeed == 0) && (Yspeed == 0)) begin
		 if (number_4) begin
          SM_Motion <= MOVE_ST;
      end
      else begin
			set_speed_direction(dx, dy);
			set_next_target(dx, dy);
			SM_Motion <= MOVE_ST;
		end	
  end

  // Turn only when the current target cell is reached.
  else if (reached_target) begin
		fix_to_target_cell();

		set_speed_direction(dx, dy);
		set_next_target(dx, dy);

		SM_Motion <= MOVE_ST;
  end

  // Still between cells.
  // Keep moving toward current target.
  else begin
		 Xposition <= Xposition + Xspeed;
       Yposition <= Yposition + Yspeed;
  end
end
endtask


//check if the head reched the next cell by pixel
always_comb begin
	  reached_target = 1'b0;

	  if ((Xspeed > 0) && (Xposition + Xspeed >= target_Xposition)) 
			reached_target = 1'b1;
	  else if ((Xspeed < 0) && (Xposition + Xspeed <= target_Xposition)) 
			reached_target = 1'b1;
	  
	  else if ((Yspeed > 0) && (Yposition + Yspeed >= target_Yposition)) 
			reached_target = 1'b1;
	  
	  else if ((Yspeed < 0) && (Yposition + Yspeed <= target_Yposition)) 
			reached_target = 1'b1;
        
 end
 
 
 
// ------------------------------------------------------------
// Main FSM
// ------------------------------------------------------------
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
	    reset_mouse_position();
	end 	
	
	else begin
		// Delayed one-clock step pulse.

		if (init_game) begin
			 reset_mouse_position();
		end
		
		else if (!game_active) begin
			// do nothing
		end
		
		else begin
			previous_direction <= current_direction;
	
			case(SM_Motion)
			
			//------------
				IDLE_ST: begin
			//------------
					
					if (startOfFrame && game_active) 
						SM_Motion <= MOVE_ST ;
		
				end
		
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------
		// direction change 
				if ((current_direction == DIR_UP && previous_direction != DIR_UP
						&& Yposition >= y_FRAME_TOP)) begin
					SM_Motion <= WAIT_ST_UP;
				end
				else if ((current_direction == DIR_DOWN && previous_direction != DIR_DOWN
						&& Yposition <= y_FRAME_BOTTOM)) begin 
					SM_Motion <= WAIT_ST_DOWN;
				end
				else if ((current_direction == DIR_LEFT && previous_direction != DIR_LEFT
						&& Xposition >= x_FRAME_LEFT)) begin 
					SM_Motion <= WAIT_ST_LEFT;
				end
				else if ((current_direction == DIR_RIGHT && previous_direction != DIR_RIGHT
						&& Xposition <= x_FRAME_RIGHT)) begin 
					SM_Motion <= WAIT_ST_RIGHT;
				end
				else if (head_cell_y_reg[4:0] <= 1 && Yspeed < 0) begin
					if (head_cell_x_reg[4:0] >= 9)
						SM_Motion <= WAIT_ST_LEFT;
					else
						SM_Motion <= WAIT_ST_RIGHT;
				end
				else if (head_cell_y_reg[4:0] >= 13 && Yspeed > 0) begin
					if (head_cell_x_reg[4:0] <= 4)
						SM_Motion <= WAIT_ST_RIGHT;
					else
						SM_Motion <= WAIT_ST_LEFT;
				end
				else if (head_cell_x_reg[4:0] <= 1 && Xspeed < 0) begin
					if (head_cell_y_reg[4:0] <= 4)
						SM_Motion <= WAIT_ST_DOWN;
					else
						SM_Motion <= WAIT_ST_UP;
				end
				else if (head_cell_x_reg[4:0] >= 13 && Xspeed > 0) begin
					if (head_cell_y_reg[4:0] >= 9)
						SM_Motion <= WAIT_ST_UP;
					else
						SM_Motion <= WAIT_ST_DOWN;
				end
				else if (startOfFrame)	
					SM_Motion <= POSITION_CHANGE_ST ;
       // collcting collisions 	
				
		end 
		
		  // ------------------------------------------------
			  WAIT_ST_UP: begin
		  // ------------------------------------------------
					if (startOfFrame) begin
						 turn_when_ready(0, -1);
					end
			  end

		  // ------------------------------------------------
			  WAIT_ST_DOWN: begin
		  // ------------------------------------------------
					if (startOfFrame) begin
						 turn_when_ready(0, 1);
					end
			  end

		  // ------------------------------------------------
			  WAIT_ST_LEFT: begin
		  // ------------------------------------------------
					if (startOfFrame) begin
						 turn_when_ready(-1, 0);
					end
			  end

		  // ------------------------------------------------
			  WAIT_ST_RIGHT: begin
		  // ------------------------------------------------
					if (startOfFrame) begin
						 turn_when_ready(1, 0);
					end
			  end

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
			if (reached_target) begin
				fix_to_target_cell();
				continue_current_direction();
			end
         else begin
				Xposition <= Xposition + Xspeed ; 
				Yposition <= Yposition + Yspeed ;
			end	
			SM_Motion <= MOVE_ST ; 
		end
			
			//-----
			default: begin
					SM_Motion <= IDLE_ST;
			  end

		endcase  // case 

		end
	end 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER ;    

assign 	topLeftX = {topLeftX_tmp[10:0]} ;   // note it must be 2^n 
assign 	topLeftY = {topLeftY_tmp[10:0]} ;


// ------------------------------------------------------------
// outputs logic
// ------------------------------------------------------------
assign mouse_cell_x = head_cell_x_reg[4:0];
assign mouse_cell_y = head_cell_y_reg[4:0];

endmodule	
//---------------