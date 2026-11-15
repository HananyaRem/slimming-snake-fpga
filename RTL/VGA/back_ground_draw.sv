//-- feb 2021 add all colors square 
// (c) Technion IIT, Department of Electrical Engineering 2025


module	back_ground_draw	(	

					input	logic	clk,
					input	logic	resetN,
					input 	logic	[10:0]	pixelX,
					input 	logic	[10:0]	pixelY,
					input 	logic	[18:0]	address,

					output	logic	[7:0]	BG_RGB,
					output	logic		boardersDrawReq, 
					output	logic	[7:0] MIF_VGA
);

/*const int	xFrameSize	=	635;
const int	yFrameSize	=	475;
const int	bracketOffset =	32;
//const int   COLOR_MARTIX_SIZE  = 16*8 ; // 128 */


// ------------------------------------------------------------
// Geometry
// ------------------------------------------------------------

localparam int SCREEN_WIDTH  = 640;
localparam int SCREEN_HEIGHT = 480;
localparam int CELL_SIZE     = 32;
localparam int GRID_SIZE     = 15;
localparam int ARENA_LEFT   = 160;
localparam int ARENA_TOP    = 0;
localparam int ARENA_RIGHT  = ARENA_LEFT + GRID_SIZE * CELL_SIZE; //640
localparam int ARENA_BOTTOM = ARENA_TOP  + GRID_SIZE * CELL_SIZE; //480


// ------------------------------------------------------------
// Colors
// ------------------------------------------------------------

localparam logic [7:0] COLOR_LEFT_BG    = 8'b000_000_10;

localparam logic [7:0] COLOR_CELL_LIGHT = 8'b001_100_11;
localparam logic [7:0] COLOR_CELL_DARK  = 8'b001_011_10;
localparam logic [7:0] COLOR_GRID_LINE  = 8'b000_010_10;

// ------------------------------------------------------------
// Region / checkerboard logic
// ------------------------------------------------------------

logic insideLeftArea;
logic insideArena;

logic [10:0] arenaOffsetX;
logic [10:0] arenaOffsetY;

logic [3:0] cellCol;
logic [3:0] cellRow;

logic [4:0] cellPixelX;
logic [4:0] cellPixelY;

logic isLightCell;
logic isGridLine;

logic [7:0] nextBG;


  assign insideLeftArea =
        (pixelX < ARENA_LEFT);
		  
  assign insideArena =
        (pixelX >= ARENA_LEFT)  &&  (pixelX <  ARENA_RIGHT) &&
        (pixelY >= ARENA_TOP)  &&  (pixelY <  ARENA_BOTTOM);	
		
  assign arenaOffsetX = pixelX - ARENA_LEFT;
  assign arenaOffsetY = pixelY - ARENA_TOP;
  
  assign cellCol = arenaOffsetX[8:5]; //devide by cell size = 32
  assign cellRow = arenaOffsetY[8:5];

  // pixel position inside each 32x32 cell
  assign cellPixelX = arenaOffsetX[4:0];
  assign cellPixelY = arenaOffsetY[4:0];
  
  // alternating checkerboard
  assign isLightCell = ~(cellRow[0] ^ cellCol[0]);
  
  //subtle grid lines: 2 pixel thick
  assign isGridLine =
        insideArena &&
        (
            (cellPixelX == 5'd0) || (cellPixelY == 5'd0) ||
				(cellPixelX == 5'd31) || (cellPixelY == 5'd31)
        );
		  
		  
	 assign MIF_VGA = 8'h00;

	 
	 

 // ------------------------------------------------------------
 // Combinational color decision
 // ------------------------------------------------------------
 always_comb begin
    boardersDrawReq = 1'b1;
    nextBG = COLOR_LEFT_BG;

    if (insideArena) begin
        if (isGridLine) begin
            nextBG = COLOR_GRID_LINE;
        end
        else if (isLightCell) begin
            nextBG = COLOR_CELL_LIGHT;
        end
        else begin
            nextBG = COLOR_CELL_DARK;
        end
    end
end

  

// ------------------------------------------------------------
// Registered output
// ------------------------------------------------------------
 always_ff @(posedge clk or negedge resetN) begin
	  if (!resetN)
			BG_RGB <= 8'h00;
	  else
			BG_RGB <= nextBG;
 end



	 

endmodule

