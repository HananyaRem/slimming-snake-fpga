

module game_controller (
    input  logic clk,
    input  logic resetN,

    // User inputs
    input  logic start_pressed_pulse, //active only in the first clock after pressing,                                 
	 input  logic level_pressed_pulse, //to avoid duble screen transition in one press.
	 
    input  logic [1:0]digit_value,  //chosen level number
   
    // Game events 
    input logic hit_wall_pulse,
	 input logic hit_obstacle_pulse,
	 input logic hit_self_pulse,
    input logic win_condition,
	 input logic [3:0] sec_ones,
    input logic [3:0] sec_tens,
    input logic [3:0] min_ones,
	 input logic [3:0] min_tens,

    // Control outputs to the game logic
    output logic game_active,
    output logic init_game,
    
    // Screen show select outputs
    output logic show_start_screen,
    output logic show_level_screen,
    output logic show_game_screen,
    output logic show_win_screen,
    output logic show_lose_screen,

    output logic [1:0] selected_level,
	 
	 output logic [3:0] score_sec_ones,
    output logic [3:0] score_sec_tens,
    output logic [3:0] score_min_ones,
	 output logic [3:0] score_min_tens
);

 // ------------------------------------------------------------
 // Game states
 // ------------------------------------------------------------
 typedef enum logic [3:0] {
	  S_Idle = 4'd0,
	  S_LEVEL_SELECT = 4'd1,
	  S_INIT_GAME = 4'd2,
	  S_PLAYING = 4'd3,
	  S_WIN = 4'd4,
	  S_LOSE = 4'd5
 } game_state_t;

 game_state_t current_state;
 game_state_t next_state;

 
 // ------------------------------------------------------------
 // Difficulty levels
 // ------------------------------------------------------------
 localparam logic [1:0] LEVEL_EASY = 2'd0;
 localparam logic [1:0] LEVEL_MEDIUM = 2'd1;
 localparam logic [1:0] LEVEL_HARD = 2'd2;
 
 logic valid_level_digit;
 logic started_game = 0;

 assign valid_level_digit = level_pressed_pulse &&
	  ((digit_value == 4'd1) ||(digit_value == 4'd2) ||
		(digit_value == 4'd3));


 // ------------------------------------------------------------
 // State register + selected level register
 // ------------------------------------------------------------

 always_ff @(posedge clk or negedge resetN) begin
	  if (!resetN) begin
			current_state  <= S_Idle;
			selected_level <= LEVEL_EASY;
	  end
	  else begin
			current_state <= next_state;
			if (start_pressed_pulse)
				started_game <= 1;
			if (!started_game) begin
				score_sec_ones <= 4'd10;
				score_sec_tens <= 4'd10;
				score_min_ones <= 4'd10;
				score_min_tens <= 4'd10;
			end

			// Level selection is allowed only in the level-select screen
			if (current_state == S_LEVEL_SELECT) begin
				 // Level selection by keyboard digits 1, 2, 3
				if ((current_state == S_LEVEL_SELECT) &&
					 valid_level_digit) begin

					 case (digit_value)
						  2'd1: selected_level <= LEVEL_EASY;
						  2'd2: selected_level <= LEVEL_MEDIUM;
						  2'd3: selected_level <= LEVEL_HARD;
						  default: selected_level <= selected_level;
					 endcase

				end
			end
			if (win_condition) begin
				score_sec_ones <= sec_ones;
				score_sec_tens <= sec_tens;
				score_min_ones <= min_ones;
				score_min_tens <= min_tens;
			end
	  end
 end

 // ------------------------------------------------------------
 // Next state logic
 // ------------------------------------------------------------

 always_comb begin
	  next_state = current_state;

	  case (current_state)

			// Opening screen
			S_Idle: begin
				 if (start_pressed_pulse) begin
					  next_state = S_LEVEL_SELECT;
				 end
			end

			// Difficulty selection screen
			S_LEVEL_SELECT: begin
				 if (start_pressed_pulse) begin
					  next_state = S_INIT_GAME;
				 end
			end

			// One-clock initialization state
			S_INIT_GAME: begin
				 next_state = S_PLAYING;
			end

			// Main gameplay state
			S_PLAYING: begin
				 if (hit_wall_pulse || hit_self_pulse || hit_obstacle_pulse) begin
					  next_state = S_LOSE;
				 end

				 else if (win_condition) begin
					  next_state = S_WIN;
				 end

			end

			
			// Victory screen
			S_WIN: begin
				
				 if (start_pressed_pulse) begin
					  next_state = S_Idle;
				 end
			end

			// Game over screen
			S_LOSE: begin
				 if (start_pressed_pulse) begin
					  next_state = S_Idle;
				 end
			end

			default: begin
				 next_state = S_Idle;
			end

	  endcase
 end

 // ------------------------------------------------------------
 // Output logic
 // ------------------------------------------------------------
 always_comb begin
	  // Default values
	  game_active = 1'b0;
	  init_game = 1'b0;
	  
	  show_start_screen = 1'b0;
	  show_level_screen = 1'b0;
	  show_game_screen  = 1'b0;
	  show_win_screen = 1'b0;
	  show_lose_screen = 1'b0;

	  case (current_state)

			S_Idle: begin
				 show_start_screen = 1'b1;
			end

			S_LEVEL_SELECT: begin
				 show_level_screen = 1'b1;
			end

			S_INIT_GAME: begin
				 init_game = 1'b1;
				 show_game_screen = 1'b1;
			end

			S_PLAYING: begin
				 game_active = 1'b1;
				 show_game_screen = 1'b1;
			end

			S_WIN: begin
				 show_win_screen = 1'b1;
			end

			S_LOSE: begin
				 show_lose_screen = 1'b1;
			end

			default: begin
				 show_start_screen = 1'b1;
			end

	  endcase
 end


endmodule