

module screen_mux (
    input  logic clk,
    input  logic resetN,

    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,

    input  logic show_start_screen,
    input  logic show_level_screen,
    input  logic show_game_screen,
    input  logic show_win_screen,
    input  logic show_lose_screen,

    input  logic [1:0] selected_level,
    input  logic [7:0] game_RGB,
	 input  logic [3:0] score_sec_ones,
	 input  logic [3:0] score_sec_tens,
	 input  logic [3:0] score_min_ones,
	 input  logic [3:0] score_min_tens,

    output logic [7:0] final_RGB
);

    // ------------------------------------------------------------
    // Color constants
    // ------------------------------------------------------------

    localparam logic [7:0] COLOR_BLACK  = 8'b000_000_00;
    
    logic [7:0] start_RGB;
    logic [7:0] level_RGB;
    logic [7:0] win_RGB;
    logic [7:0] lose_RGB;


 // ------------------------------------------------------------
 // start screen
 // ------------------------------------------------------------
 start_screen_draw start_screen_draw_inst (
 .clk (clk),
 .resetN (resetN),
 .pixelX (pixelX),
 .pixelY (pixelY),
 .show_start_screen (show_start_screen),
 
 .start_RGB (start_RGB)
);

 
 // ------------------------------------------------------------
 // Level select screen
 // ------------------------------------------------------------
 level_select_screen level_select_screen_inst (
 .clk (clk),
 .resetN (resetN),
 .pixelX (pixelX),
 .pixelY (pixelY),
 .show_level_screen (show_level_screen),
 .selected_level (selected_level),

 .level_RGB (level_RGB)
);
 
 
// ------------------------------------------------------------
// Win screen
// ------------------------------------------------------------
win_screen_draw win_screen_draw_inst (
    .clk (clk),
    .resetN (resetN),
    .pixelX (pixelX),
    .pixelY (pixelY),
    .show_win_screen (show_win_screen),
	 .score_sec_ones (score_sec_ones),
	 .score_sec_tens (score_sec_tens),
	 .score_min_ones (score_min_ones),
	 .score_min_tens (score_min_tens),
    .win_RGB (win_RGB)
);

 
// ------------------------------------------------------------
//lose screen
// ------------------------------------------------------------
lose_screen_draw lose_screen_draw_inst (
    .clk (clk),
    .resetN (resetN),
    .pixelX (pixelX),
    .pixelY (pixelY),
    .show_lose_screen (show_lose_screen),
    .lose_RGB (lose_RGB)
);

// ------------------------------------------------------------
// Final screen selection
// ------------------------------------------------------------

 always_ff @(posedge clk or negedge resetN) begin
	  if (!resetN) begin
			final_RGB <= COLOR_BLACK;
	  end
	  else begin

			if (show_start_screen) begin
				 final_RGB <= start_RGB;
			end

			else if (show_level_screen) begin
				 final_RGB <= level_RGB;
			end

			else if (show_win_screen) begin
				 final_RGB <= win_RGB;
			end

			else if (show_lose_screen) begin
				 final_RGB <= lose_RGB;
			end

			else if (show_game_screen) begin
				 final_RGB <= game_RGB;
			end

			else begin
				 final_RGB <= COLOR_BLACK;
			end

	  end
 end

endmodule