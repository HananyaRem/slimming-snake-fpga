
import game_params::*;

module side_panel_draw (
input		logic	clk,
input		logic	resetN,
input  logic [10:0] pixelX,
input  logic [10:0] pixelY,

input  logic [4:0] snake_len,
input  logic [1:0] selected_level,

//the time that have passed since the start of the game, 
input  logic [3:0] sec_ones,
input  logic [3:0] sec_tens,
input  logic [3:0] min_ones,
input  logic [3:0] min_tens,
input  logic [3:0] score_sec_ones,
input  logic [3:0] score_sec_tens,
input  logic [3:0] score_min_ones,
input  logic [3:0] score_min_tens,

output logic drawingRequest,
output logic [7:0] RGB_out
);


localparam logic [7:0] HUD_COLOR = 8'b111_111_11;

// ------------------------------------------------------------
// labels and numbers Geometry
// ------------------------------------------------------------
localparam int LABEL_SIZE_X = 128; //mif width
//the Words hight size inside the mif
localparam int TIME_LABEL_SIZE_Y = 32; 
localparam int LENGTH_LABEL_SIZE_Y = 32;

localparam int TIME_LABEL_X = 16;
localparam int TIME_LABEL_Y = 64; 
localparam int LENGTH_LABEL_X = 16;
localparam int LENGTH_LABEL_Y = 192;
localparam int BEST_LABEL_X = 16;
localparam int BEST_LABEL_Y = 320;
// the hight offset of the words inside the mif
localparam int TIME_MIF_OFFSET = 48;
localparam int LENGTH_MIF_OFFSET = 48;

localparam int DIGIT_W = 16;
localparam int DIGIT_H = 32;

localparam int TIME_X = 40;
localparam int TIME_Y = 96;

localparam int LEN_X = 60;
localparam int LEN_Y = 224;

localparam int BEST_TIME_Y = 352;

localparam int TIME_M_T_X = TIME_X;
localparam int TIME_M_O_X = TIME_X + 18;
localparam int COLON_X  = TIME_X + 37;
localparam int TIME_S_T_X = TIME_X + 46;
localparam int TIME_S_O_X  = TIME_X + 64;

localparam int LEN_TENS_X = LEN_X;
localparam int LEN_ONES_X = LEN_X + 24;


//spilt the snake length into tens and ones digits
logic [3:0] len_tens;
logic [3:0] len_ones;

always_comb begin
    len_tens = 4'(snake_len / 5'd10);
	 len_ones = 4'(snake_len % 5'd10);
end

logic [10:0] prev_record;
logic [10:0] time_sec;
logic [3:0] best_min_tens;
logic [3:0] best_min_ones;
logic [3:0] best_sec_tens;
logic [3:0] best_sec_ones;

 always_ff @(posedge clk) begin
	time_sec <= score_min_tens * 600 + score_min_ones * 60 + score_sec_tens * 10 + score_sec_ones;
	if (time_sec == 11'h236)
		prev_record <= time_sec;
	if (time_sec < prev_record) begin
		prev_record <= time_sec;
		best_min_tens <= score_min_tens;
		best_min_ones <= score_min_ones;
		best_sec_tens <= score_sec_tens;
		best_sec_ones <= score_sec_ones;
	end
end


//helper func for checking if current pixel inside a rectangle
function automatic logic inside_rectangle (
	  input logic [10:0] px,
	  input logic [10:0] py,
	  input int x,
	  input int y,
	  input int w,
	  input int h
 );
	  begin
			inside_rectangle = (px >= x) && (px < x + w) &&
							  (py >= y) && (py < y + h);
	  end
endfunction



// ------------------------------------------------------------
// Labels: TIME and LENGTH
// ------------------------------------------------------------
logic timeLabelInside, lengthLabelInside, bestLabelInside;
logic [10:0] timeLabelOffsetX, timeLabelOffsetY;
logic [10:0] lengthLabelOffsetX, lengthLabelOffsetY;
logic [10:0] bestLabelOffsetX, bestLabelOffsetY;
logic timeLabelDrawReq, lengthLabelDrawReq, bestLabelDrawReq;

assign timeLabelInside =
    inside_rectangle(pixelX, pixelY, TIME_LABEL_X, TIME_LABEL_Y, LABEL_SIZE_X, TIME_LABEL_SIZE_Y);

assign lengthLabelInside =
    inside_rectangle(pixelX, pixelY, LENGTH_LABEL_X, LENGTH_LABEL_Y, LABEL_SIZE_X, LENGTH_LABEL_SIZE_Y);
	 
assign bestLabelInside =
    inside_rectangle(pixelX, pixelY, BEST_LABEL_X, BEST_LABEL_Y, LABEL_SIZE_X, LENGTH_LABEL_SIZE_Y);

assign timeLabelOffsetX = pixelX - TIME_LABEL_X;
assign timeLabelOffsetY = pixelY - TIME_LABEL_Y;

assign lengthLabelOffsetX = pixelX - LENGTH_LABEL_X;
assign lengthLabelOffsetY = pixelY - LENGTH_LABEL_Y;

assign bestLabelOffsetX = pixelX - BEST_LABEL_X;
assign bestLabelOffsetY = pixelY - BEST_LABEL_Y;


LabelBitMap #(
	  .MIF_FILE("RTL/time_label.mif"),
	  .MIF_SIZE(128),
	  .START_Y(TIME_MIF_OFFSET),
	  .INVERT_BITS(1'b1)
) time_label_inst (
	  .clk(clk),
	  .resetN(resetN),
	  .offsetX(timeLabelOffsetX),
	  .offsetY(timeLabelOffsetY),
	  .InsideRectangle(timeLabelInside),
	  .drawingRequest(timeLabelDrawReq),
);

LabelBitMap #(
	  .MIF_FILE("RTL/length_label.mif"),
	  .MIF_SIZE(128),
	  .START_Y(LENGTH_MIF_OFFSET),
	  .INVERT_BITS(1'b1)
) length_label_inst (
	  .clk(clk),
	  .resetN(resetN),
	  .offsetX(lengthLabelOffsetX),
	  .offsetY(lengthLabelOffsetY),
	  .InsideRectangle(lengthLabelInside),
	  .drawingRequest(lengthLabelDrawReq),
);

LabelBitMap #(
	  .MIF_FILE("RTL/best_label.mif"),
	  .MIF_SIZE(128),
	  .START_Y(LENGTH_MIF_OFFSET),
	  .INVERT_BITS(1'b1)
) best_label_inst (
	  .clk(clk),
	  .resetN(resetN),
	  .offsetX(lengthLabelOffsetX),
	  .offsetY(lengthLabelOffsetY),
	  .InsideRectangle(bestLabelInside),
	  .drawingRequest(bestLabelDrawReq),
);

// ------------------------------------------------------------
// digits
// ------------------------------------------------------------
logic  digitInside;
logic [3:0] selectedDigit;
logic [10:0] digitOffsetX;
logic [10:0] digitOffsetY;

// select the current digit 
always_comb begin
	  digitInside = 1'b0;
	  selectedDigit = 4'd0;
	  digitOffsetX = 11'd0;
	  digitOffsetY = 11'd0;
		
	  // time
	  if (inside_rectangle(pixelX, pixelY, TIME_M_T_X, TIME_Y, DIGIT_W, DIGIT_H)) begin
			digitInside = 1'b1;
			selectedDigit = min_tens;
			digitOffsetX = pixelX - TIME_M_T_X;
			digitOffsetY = pixelY - TIME_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, TIME_M_O_X, TIME_Y, DIGIT_W, DIGIT_H)) begin
			digitInside = 1'b1;
			selectedDigit = min_ones;
			digitOffsetX = pixelX - TIME_M_O_X;
			digitOffsetY = pixelY - TIME_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, TIME_S_T_X, TIME_Y, DIGIT_W, DIGIT_H)) begin
			digitInside = 1'b1;
			selectedDigit = sec_tens;
			digitOffsetX = pixelX - TIME_S_T_X;
			digitOffsetY = pixelY - TIME_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, TIME_S_O_X, TIME_Y, DIGIT_W, DIGIT_H)) begin
			digitInside = 1'b1;
			selectedDigit = sec_ones;
			digitOffsetX = pixelX - TIME_S_O_X;
			digitOffsetY = pixelY - TIME_Y;
	  end
	  // best
	  else if (inside_rectangle(pixelX, pixelY, TIME_M_T_X, BEST_TIME_Y, DIGIT_W, DIGIT_H) && score_sec_ones != 10) begin
			digitInside = 1'b1;
			selectedDigit = best_min_tens;
			digitOffsetX = pixelX - TIME_M_T_X;
			digitOffsetY = pixelY - BEST_TIME_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, TIME_M_O_X, BEST_TIME_Y, DIGIT_W, DIGIT_H) && score_sec_ones != 10) begin
			digitInside = 1'b1;
			selectedDigit = best_min_ones;
			digitOffsetX = pixelX - TIME_M_O_X;
			digitOffsetY = pixelY - BEST_TIME_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, TIME_S_T_X, BEST_TIME_Y, DIGIT_W, DIGIT_H) && score_sec_ones != 10) begin
			digitInside = 1'b1;
			selectedDigit = best_sec_tens;
			digitOffsetX = pixelX - TIME_S_T_X;
			digitOffsetY = pixelY - BEST_TIME_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, TIME_S_O_X, BEST_TIME_Y, DIGIT_W, DIGIT_H) && score_sec_ones != 10) begin
			digitInside = 1'b1;
			selectedDigit = best_sec_ones;
			digitOffsetX = pixelX - TIME_S_O_X;
			digitOffsetY = pixelY - BEST_TIME_Y;
	  end
	  // length
	  else if (inside_rectangle(pixelX, pixelY, LEN_TENS_X, LEN_Y, DIGIT_W, DIGIT_H)) begin
			digitInside = 1'b1;
			selectedDigit = len_tens;
			digitOffsetX = pixelX - LEN_TENS_X;
			digitOffsetY = pixelY - LEN_Y;
	  end
	  else if (inside_rectangle(pixelX, pixelY, LEN_ONES_X, LEN_Y, DIGIT_W, DIGIT_H)) begin
			digitInside = 1'b1;
			selectedDigit = len_ones;
			digitOffsetX = pixelX - LEN_ONES_X;
			digitOffsetY = pixelY - LEN_Y;
	  end
end


logic digitDrawReq;

NumbersBitMap #(
		.SIZE_SHIFT(0)
)  digit_inst (
	  .clk(clk),
	  .resetN(resetN),
	  .offsetX(digitOffsetX),
	  .offsetY(digitOffsetY),
	  .InsideRectangle(digitInside),
	  .digit(selectedDigit),
	  .drawingRequest(digitDrawReq),
	  
);



// ------------------------------------------------------------
// Colon between min and sec
// ------------------------------------------------------------
logic colonDrawReq;

assign colonDrawReq =
	  ((pixelX >= COLON_X) && (pixelX < COLON_X + 6) &&
	  (((pixelY >= TIME_Y + 8) && (pixelY < TIME_Y + 14)) ||
		((pixelY >= TIME_Y + 20) && (pixelY < TIME_Y + 26)))) ||
		((pixelX >= COLON_X) && (pixelX < COLON_X + 6) && prev_record != 999 &&
		(((pixelY >= BEST_TIME_Y + 8) && (pixelY < BEST_TIME_Y + 14)) ||
		((pixelY >= BEST_TIME_Y + 20) && (pixelY < BEST_TIME_Y + 26))));
		

// ------------------------------------------------------------
// final outputs
// ------------------------------------------------------------
assign drawingRequest = (timeLabelDrawReq || lengthLabelDrawReq ||
		                   digitDrawReq || colonDrawReq || bestLabelDrawReq);
assign RGB_out = HUD_COLOR;
		
		
endmodule