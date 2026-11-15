// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024   
// good practice code - Dudy MAR 2025  ert

module	snake_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic numbers[9:0],   //keyPad 
					//game_controller
					input  logic game_active,
					input  logic init_game,
					
					input  logic signed [10:0] current_speed, //speed controller

					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					//current head location for body drawing
					output logic [4:0] head_cell_x,
					output logic [4:0] head_cell_y,
					output logic [11:0] move_progress_fixed, // Progress inside current cell movement, 0..2048
				   output logic cell_step_pulse,// short pulse when the head enters new cell
					output logic [1:0] current_direction,
					//next head location for collision detection
					output logic [4:0] target_cell_x_out,
					output logic [4:0] target_cell_y_out,
					output logic moving // output that the snake is currently moving
					
					//output logic [1:0] current_direction, //for debug
);
 int 	 topLeftX_tmp; // output the top left corner 
 int   topLeftY_tmp;  // can be negative , if the object is partliy outside 

// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 480;
parameter int INITIAL_Y = 160;

//const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 32;
const int   OBJECT_HIGHT_Y = 32;

localparam int BOARD_LEFT_X = 160;
localparam int BOARD_TOP_Y  = 0;

localparam int BOARD_COLS = 15;
localparam int BOARD_ROWS = 15;

localparam int CELL_SIZE = 32;
localparam int CELL_STEP_FIXED = CELL_SIZE * 64; // 32 * 64 = 2048

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
logic cell_step_pending; //one clock delay

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
task automatic reset_snake_position;
begin
  SM_Motion <= IDLE_ST;

  Xspeed <= 0;
  Yspeed <= 0;
  
  moving <= 1'b0;

  Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
  Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;

  target_Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER;
  target_Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;

  head_cell_x_reg <= START_CELL_X;
  head_cell_y_reg <= START_CELL_Y;

  target_cell_x <= START_CELL_X;
  target_cell_y <= START_CELL_Y;

  cell_step_pulse <= 1'b0;
  cell_step_pending <= 1'b0;
end
endtask 



 task automatic set_speed_direction;
        input int dx;
        input int dy;
    begin
        Xspeed <= dx * current_speed;
        Yspeed <= dy * current_speed;
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

	  cell_step_pending <= 1'b1;
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
  // Snake is currently standing still.
  // Start moving in the requested direction.
  if ((Xspeed == 0) && (Yspeed == 0)) begin
		set_speed_direction(dx, dy);
		moving <= 1'b1;
		set_next_target(dx, dy);
		SM_Motion <= MOVE_ST;
  end

  // Snake is moving.
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

 
 //determine current direcation
 always_comb begin
        if (Xspeed > 0)
            current_direction = DIR_RIGHT;
        else if (Xspeed < 0)
            current_direction = DIR_LEFT;
        else if (Yspeed < 0)
            current_direction = DIR_UP;
        else if (Yspeed > 0)
            current_direction = DIR_DOWN;
        else
            current_direction = DIR_RIGHT;
 end 

 
 
 
// ------------------------------------------------------------
// Main FSM
// ------------------------------------------------------------
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
//		SM_Motion <= IDLE_ST ; 
//		Xspeed <= 0   ; 
//		Yspeed <= 0  ; 
//		Xposition <= 0  ; 
//		Yposition <= 0   ; 
	    reset_snake_position();
	end 	
	
	else begin
		// Delayed one-clock step pulse.
		cell_step_pulse   <= cell_step_pending;
      cell_step_pending <= 1'b0;

		if (init_game) begin
			 reset_snake_position();
		end
		
		else if (!game_active) begin //stop moving
			moving <= 1'b0; 
		end
		
		else begin
	
			case(SM_Motion)
			
			//------------
				IDLE_ST: begin
			//------------
			
//					Xspeed  <= 0 ; 
//					Yspeed  <= 0  ; 
//					Xposition <= 480*FIXED_POINT_MULTIPLIER; 
//					Yposition <= 160*FIXED_POINT_MULTIPLIER; 
					
					if (startOfFrame && game_active) 
						SM_Motion <= MOVE_ST ;
		
				end
		
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------

		// keys direction change 
				if (numbers[8] && (Yspeed == 0) && (numbers[2] == 0 && numbers[4] == 0 && numbers[6] == 0)) begin
					SM_Motion <= WAIT_ST_UP;
				end
				else if (numbers[2] && Yspeed == 0 && (numbers[8] == 0 && numbers[4] == 0 && numbers[6] == 0)) begin 
					SM_Motion <= WAIT_ST_DOWN;
				end
				else if (numbers[4] && Xspeed == 0 && Yspeed != 0 && (numbers[2] == 0 && numbers[8] == 0 && numbers[6] == 0)) begin 
					SM_Motion <= WAIT_ST_LEFT;
				end
				else if (numbers[6] && Xspeed == 0 && (numbers[2] == 0 && numbers[4] == 0 && numbers[8] == 0)) begin 
					SM_Motion <= WAIT_ST_RIGHT;
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
assign head_cell_x = head_cell_x_reg[4:0];
assign head_cell_y = head_cell_y_reg[4:0];
assign target_cell_x_out = target_cell_x[4:0];
assign target_cell_y_out = target_cell_y[4:0];

// ------------------------------------------------------------
// Movement progress inside current cell
// 0    = just left current logical cell
// 2048 = reached next cell
// ------------------------------------------------------------

always_comb begin
  progress_calc = 0;

  if (Xspeed > 0) begin
		progress_calc = Xposition - cell_x_to_fixed(head_cell_x_reg);
  end
  else if (Xspeed < 0) begin
		progress_calc = cell_x_to_fixed(head_cell_x_reg) - Xposition;
  end
  else if (Yspeed > 0) begin
		progress_calc = Yposition - cell_y_to_fixed(head_cell_y_reg);
  end
  else if (Yspeed < 0) begin
		progress_calc = cell_y_to_fixed(head_cell_y_reg) - Yposition;
  end
  else begin
		progress_calc = 0;
  end

  if (progress_calc < 0)
		move_progress_fixed = 12'd0;
  else if (progress_calc > CELL_STEP_FIXED)
		move_progress_fixed = CELL_STEP_FIXED[11:0];
  else
		move_progress_fixed = progress_calc[11:0];
end

endmodule	
//---------------
 
