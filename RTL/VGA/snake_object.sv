//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// System-Verilog Alex Grinshpun May 2018
// New coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025 


module	snake_object	(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic signed	[10:0] pixelX,//  current VGA pixel 
					input 	logic signed	[10:0] pixelY,
					input logic signed [21:0] snake_body [0:19],
					input logic [4:0] snake_len,
					
					output 	logic	[10:0] offsetX,// offset inside bracket from top left position 
					output 	logic	[10:0] offsetY,
					output	logic	drawingRequest, // indicates pixel inside the bracket
					output   logic [1:0] snake_part //indicates which part of the snake to draw
);

parameter  int OBJECT_WIDTH_X = 32;
parameter  int OBJECT_HEIGHT_Y = 32;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'h00 ;// bitmap  representation for a transparent pixel 

//adjust number for each snake part
localparam logic [1:0] SNAKE_NONE = 2'd0;
localparam logic [1:0] SNAKE_HEAD = 2'd1;
localparam logic [1:0] SNAKE_BODY = 2'd2;

// identify the pixel inside the snake
logic        found_inside;
logic [10:0] found_offsetX;
logic [10:0] found_offsetY;
logic [4:0]  found_index; 
logic [1:0] found_part;
 
logic [9:0] bitmap_addr; //find the pixel adress in the bitmap


// ------------------------------------------------------------
// check if the pixel is inside the snake boundaries
// ------------------------------------------------------------

always_comb begin
	found_inside = 1'b0;
	found_offsetX = 11'd0;
	found_offsetY = 11'd0;
	found_index   = 5'd0;
	found_part = SNAKE_NONE;

	for (int i = 0; i < 20; i++) begin
		if (i < snake_len) begin
			if ((pixelX >= snake_body[i][21:11]) &&
			    (pixelX <  snake_body[i][21:11] + OBJECT_WIDTH_X) &&
			    (pixelY >= snake_body[i][10:0]) &&
			    (pixelY <  snake_body[i][10:0] + OBJECT_HEIGHT_Y)) begin

				found_inside = 1'b1;
				found_offsetX = pixelX - snake_body[i][21:11];
				found_offsetY = pixelY - snake_body[i][10:0];
				found_index   = i[4:0];
				if (i == 0) 
					found_part = SNAKE_HEAD;
				else 
					 found_part = SNAKE_BODY;
				break;
			end
		end
	end
end
 

assign bitmap_addr = {found_offsetY[4:0], found_offsetX[4:0]};


// ------------------------------------------------------------
// Combinatorial logic of the outputs
// ------------------------------------------------------------
always_comb begin
    // default
    offsetX        = 11'd0;
    offsetY        = 11'd0;
    drawingRequest = 1'b0;
    snake_part     = SNAKE_NONE;

    if (found_inside) begin
        offsetX        = found_offsetX;
        offsetY        = found_offsetY;
        drawingRequest = 1'b1;
        snake_part     = found_part;
    end
end
endmodule 