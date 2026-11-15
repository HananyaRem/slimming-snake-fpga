// (c) Technion IIT, Department of Electrical Engineering 2020 

// Implements a slow clock as an one-second counter
// Turbo input sets output 10 times faster
// Updated by Mor Dahan - January 2022
// Updated by Dudy BarOn - October 2023

 
 module one_sec_counter      	
	(
   // Input, Output Ports
	input  logic clk, 
	input  logic resetN,
	input  logic moving, //from snake_move
	input  logic turbo,
	output logic one_sec_pulse
   );
	
	int oneSecCount ;
	int sec ;		 // gets either one seccond or Turbo top value

parameter logic SIMULATION_MODE = 0 ;// to update in outside table: 1 for simulation, 0 for DE10 board
	
//       ----------------------------------------------	counter limit setting
	localparam oneSecVal_REAL = 32'd31_500_000; // for DE10 board 
	localparam oneSecVal_SIM = 32'd20; // for quartus simulation 
	localparam oneSecVal= SIMULATION_MODE ? oneSecVal_SIM : oneSecVal_REAL ; //select what to use 
//       ----------------------------------------------	
	
	//create 1 clk pulse when the snake starts to move
	logic move_begin;
	logic move_begin_d;
	assign move_begin = moving;
	
	assign sec = turbo ? oneSecVal/10 : oneSecVal;  // it is legal to devide by 10, as it is done by the compiler not by logic (actual transistors) 


	
   always_ff @( posedge clk or negedge resetN )
   begin
	
		// asynchronous reset
		if ( !resetN ) begin
			one_sec_pulse <= 1'b0;
			oneSecCount <= 32'd0;
			move_begin_d <= 1'b0;
		end // if reset
		
		else if (move_begin && !move_begin_d) begin //reset the count when the move begins
			one_sec_pulse <= 1'b0;
			oneSecCount <= 32'd0;
			move_begin_d <= move_begin;
		end
		
		// executed once every clock 	
		else begin
			move_begin_d <= move_begin;
			if (oneSecCount >= sec) begin
				one_sec_pulse <= 1'b1;
				oneSecCount <= 0;
			end
			else begin
				oneSecCount <= oneSecCount + 1;
				one_sec_pulse		<= 1'b0;
			end
		end // else clk
		
	end // always
	
endmodule