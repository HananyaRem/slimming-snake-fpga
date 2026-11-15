// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 



module	snakeBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic [1:0] snake_part, //which part of the snake to draw
					input logic [1:0] current_diraction,
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
				   //for collision detection
					output   logic	snake_head_DR, 
					output   logic	snake_body_DR
 ) ;

// this is the devider used to acess the right pixel 
localparam  int OBJECT_NUMBER_OF_Y_BITS = 5;  // 
localparam  int OBJECT_NUMBER_OF_X_BITS = 5;  //

//adjust the representative number for each snake part
localparam logic [1:0] SNAKE_NONE = 2'd0;
localparam logic [1:0] SNAKE_HEAD = 2'd1;
localparam logic [1:0] SNAKE_BODY = 2'd2;
//localparam logic [1:0] SNAKE_TAIL = 2'd3;

localparam logic [7:0] TRANSPARENT_ENCODING = 8'h00;  
logic	[10:0] address;

localparam  logic	[10:0] OBJECT_HEIGHT_Y = 11'b1 <<  OBJECT_NUMBER_OF_Y_BITS ;
localparam  logic	[10:0] OBJECT_WIDTH_X = 11'b1 <<  OBJECT_NUMBER_OF_X_BITS;


//generating the snake parts bitmap from a MIF file
logic [7:0] head_rgb;
logic [7:0] body_rgb;
logic [7:0] tail_rgb;
logic [7:0] selected_rgb;

assign address = {offsetY[4:0], offsetX[4:0]};

logic [9:0] head_address;

always_comb begin
	head_address = {31 - offsetX[4:0], offsetY[4:0]};
	case (current_diraction)
		2'h2: head_address = {offsetY[4:0], offsetX[4:0]}; // up
		2'h3: head_address = {31 - offsetY[4:0], offsetX[4:0]}; // down
		2'h0: head_address = {31 - offsetX[4:0], offsetY[4:0]}; // right
		2'h1: head_address = {offsetX[4:0], offsetY[4:0]}; // left
	endcase
end 


lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
    .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/s_head.mif"),
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"),
    .LPM_OUTDATA("UNREGISTERED"),
    .AUTO_CARRY_CHAINS("ON"),
    .AUTO_CASCADE_BUFFERS("ON"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) head_rom (
    .address(head_address),
    .inclock(clk),
    .q(head_rgb)
);

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
    .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/s_body.mif"),
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"),
    .LPM_OUTDATA("UNREGISTERED"),
    .AUTO_CARRY_CHAINS("ON"),
    .AUTO_CASCADE_BUFFERS("ON"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) body_rom (
    .address(address),
    .inclock(clk),
    .q(body_rgb)
);



//timeing for the current pixel
logic InsideRectangle_d;
logic [1:0] snake_part_d;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		InsideRectangle_d <= 1'b0;
		snake_part_d  <= SNAKE_NONE;
	end
	else begin
		InsideRectangle_d <= InsideRectangle;
		snake_part_d  <= snake_part;
	end
end



//choos the snake part for the rgb
always_comb begin
    selected_rgb = TRANSPARENT_ENCODING;

    case (snake_part_d)
        SNAKE_HEAD: selected_rgb = head_rgb;
        SNAKE_BODY: selected_rgb = body_rgb;
        //SNAKE_TAIL: selected_rgb = tail_rgb;
        default:    selected_rgb = TRANSPARENT_ENCODING;
    endcase
end

always_comb begin
    //default
    RGBout = TRANSPARENT_ENCODING;

    if (InsideRectangle_d == 1'b1) begin 
        RGBout = selected_rgb;
    end
end


//////////--------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
assign snake_head_DR = ((RGBout != TRANSPARENT_ENCODING) && (snake_part_d == SNAKE_HEAD)) ? 1'b1 : 1'b0 ;
assign snake_body_DR = ((RGBout != TRANSPARENT_ENCODING) && (snake_part_d == SNAKE_BODY)) ? 1'b1 : 1'b0 ;
endmodule