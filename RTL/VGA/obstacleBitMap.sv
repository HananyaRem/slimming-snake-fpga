

module obstacleBitMap (

	 input logic  clk,
	 input logic  resetN,
		
	 input  logic [4:0] offsetX,
    input  logic [4:0] offsetY,
    input  logic  InsideRectangle,
	 
    output logic  drawingRequest,
	 output logic	[7:0] RGBout

);

localparam logic [7:0] TRANSPARENT_ENCODING = 8'h00 ;// RGB value in the bitmap representing a transparent pixel 

logic [9:0] address;
logic [7:0] color;

assign address = {offsetY[4:0], offsetX[4:0]};


//
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/obstacle4.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(color)
);


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	TRANSPARENT_ENCODING;
	end
	else begin
		RGBout <= TRANSPARENT_ENCODING; // default 
		if (InsideRectangle)	
			begin 
				RGBout <= color;	
			end 
	end 
end

// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ;
endmodule