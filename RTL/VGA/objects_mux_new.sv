
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux_new	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		   // snake
					input		logic	snakeDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] snakeRGB, 
		  // background 
					input    logic AplleDrawingRequest, // box of numbers
					input		logic	[7:0] AplleRGB,   
					input		logic	[7:0] backGroundRGB, 
					input		logic	BGDrawingRequest, 
					input		logic	[7:0] RGB_MIF,
					input logic [7:0] RGB_burger,
					input logic burgerDR,
					input logic [7:0] mouse_RGB,
					input logic mouseDR,
					input logic [7:0]SidePanel_RGB,
					input logic SidePanel_DR,
					input logic [7:0] obstacle_RGB,
					input logic obstacle_DR,
			  
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (snakeDrawingRequest == 1'b1 )   
			RGBOut <= snakeRGB;  //first priority 
			
		else if (obstacle_DR == 1'b1) begin
				RGBOut <= obstacle_RGB;
		end 
 		else if (AplleDrawingRequest == 1'b1) begin
				RGBOut <= AplleRGB;
		end
		else if (mouseDR == 1'b1) begin
				RGBOut <= mouse_RGB;
		end
		else if (burgerDR == 1'b1) begin
				RGBOut <= RGB_burger;
		end
		else if (SidePanel_DR) begin
				RGBOut <= SidePanel_RGB;
		end		
		else if (BGDrawingRequest == 1'b1) begin
				RGBOut <= backGroundRGB;
		end
		else begin
			RGBOut <= RGB_MIF ;// last priority 
		end
		end ; 
	end

endmodule


