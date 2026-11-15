

package game_params;

    localparam int SCREEN_WIDTH  = 640;
    localparam int SCREEN_HEIGHT = 480;
	 
	 localparam int FIXED_POINT_MULTIPLIER = 64;
	 
	 localparam int BOARD_LEFT_X = 160;
	 localparam int BOARD_TOP_Y  = 0;

    localparam int BOARD_COLS = 15;
    localparam int BOARD_ROWS = 15;
	 localparam int MATRIX_SIZE = BOARD_COLS * BOARD_ROWS;

    localparam int CELL_SIZE = 32;
    localparam int CELL_BITS = 5;

    localparam int MAX_SNAKE_LEN   = 20;
    localparam int START_SNAKE_LEN = 10;
    localparam int MIN_SNAKE_LEN   = 1;

    localparam logic [1:0] LEVEL_EASY   = 2'd0;
    localparam logic [1:0] LEVEL_MEDIUM = 2'd1;
    localparam logic [1:0] LEVEL_HARD   = 2'd2;

endpackage