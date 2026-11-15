

module LabelBitMap (

 input  logic        clk,
    input  logic        resetN,

    input  logic [10:0] offsetX,
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle,
	 
    output logic        drawingRequest
    //output logic [7:0]  RGBout
);

parameter string MIF_FILE = "RTL/time_label.mif";
parameter int MIF_SIZE = 128;
parameter int START_Y = 48; //teh start hight of the word inside the mif file
parameter logic INVERT_BITS = 1'b1; // for inverted 1bit mif file when the letter code is zero
//parameter logic [7:0] LABEL_COLOR = 8'h00;

localparam int PIXEL_NUM = MIF_SIZE * MIF_SIZE;
localparam int ADDR_WIDTH = $clog2(PIXEL_NUM);

logic [ADDR_WIDTH-1:0] address;
logic mifBit;
logic drawBit;
logic inside_delay; //1 clk delay to synchronize the draw
assign address = (START_Y + offsetY) * MIF_SIZE + offsetX;
//assign RGBout  = LABEL_COLOR;

assign drawBit = INVERT_BITS ? ~mifBit : mifBit;

lpm_rom #(
    .LPM_WIDTH(1),
    .LPM_WIDTHAD(ADDR_WIDTH),
	 .LPM_NUMWORDS(PIXEL_NUM),
    .LPM_FILE(MIF_FILE),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(address),
	 .inclock(clk),
    .q(mifBit)
);

always_ff @(posedge clk or negedge resetN) begin
	  if (!resetN) begin
			drawingRequest <= 1'b0;
			inside_delay <= 1'b0;
			
	  end
	  else begin
			drawingRequest <= inside_delay && drawBit;
			inside_delay <= InsideRectangle;
	  end
 end
 
endmodule 