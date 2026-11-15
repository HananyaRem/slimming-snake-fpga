

module win_screen_draw (
    input  logic clk,
    input  logic resetN,

    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,

    input  logic show_win_screen,
	 input  logic [3:0] score_sec_ones,
	 input  logic [3:0] score_sec_tens,
	 input  logic [3:0] score_min_ones,
	 input  logic [3:0] score_min_tens,

    output logic [7:0] win_RGB
);

    // ------------------------------------------------------------
    // Color constants
    // ------------------------------------------------------------

    localparam logic [7:0] COLOR_BLACK = 8'h00;
	 localparam logic [7:0] COLOR_WHITE = 8'hff;


    // ------------------------------------------------------------
    // Trophy parameters 
    // ------------------------------------------------------------

    localparam int TROPHY_W    = 256;
    localparam int TROPHY_H    = 256;
    localparam int TROPHY_LEFT = 192;
    localparam int TROPHY_TOP  = 122;

    logic trophy_area;
    logic trophy_area_d;

    logic [7:0]  trophy_x;
    logic [7:0]  trophy_y;
    logic [15:0] trophy_address;
    logic [7:0]  trophy_color;
	 
	// ------------------------------------------------------------
	// Press Enter label
	// ------------------------------------------------------------
	localparam int PRESS_W    = 444;
	localparam int PRESS_H    = 32;
	localparam int PRESS_LEFT = 98;
	localparam int PRESS_TOP  = 416;

	localparam logic [7:0] PRESS_COLOR = 8'b000_000_11; // blue

	logic press_area, press_area_d;
	logic [10:0] press_x, press_y;
	logic [13:0] press_address;
	logic press_pixel;

	// ------------------------------------------------------------
	// Clock icon - 64x64
	// ------------------------------------------------------------
	localparam int CLOCK_W    = 64;
	localparam int CLOCK_H    = 64;
	localparam int CLOCK_LEFT = 190;
	localparam int CLOCK_TOP  = 50;

	localparam logic [7:0] CLOCK_TRANSPARENT = 8'h00;

	logic clock_area, clock_area_d;
	logic [5:0] clock_x, clock_y;
	logic [11:0] clock_address;
	logic [7:0] clock_color;

	// ------------------------------------------------------------
	// Big time digits - 32x64, SIZE_SHIFT=1
	// ------------------------------------------------------------
	localparam logic [7:0] TIME_COLOR = 8'b000_111_11; // yellow

	localparam int BIG_DIGIT_W = 32;
	localparam int BIG_DIGIT_H = 64;

	localparam int TIME_Y = 50;

	localparam int TIME_M_T_X = 270;
	localparam int TIME_M_O_X = 306;
	localparam int COLON_X    = 342;
	localparam int TIME_S_T_X = 358;
	localparam int TIME_S_O_X = 394;

	logic digitInside;
	logic [3:0] selectedDigit;
	logic [10:0] digitOffsetX;
	logic [10:0] digitOffsetY;
	logic digitDrawReq;
	logic colonDrawReq;

    // ------------------------------------------------------------
    // Background/rays/confetti signals
    // ------------------------------------------------------------

    logic [15:0] confetti_noise;

    logic signed [12:0] dx_win;
    logic signed [12:0] dy_win;

    logic [7:0] win_bg_RGB;
    logic [7:0] win_bg_RGB_d;

   logic [15:0] px16;
	logic [15:0] py16;

	assign px16 = {5'd0, pixelX};
	assign py16 = {5'd0, pixelY};

	assign confetti_noise =
		 (px16 << 3) + (px16 << 2) + px16 +      // pixelX * 13
		 (py16 << 2) + (py16 << 1) + py16 +      // pixelY * 7
		 {8'd0, pixelX[7:0] ^ pixelY[7:0]};

    assign dx_win = $signed({2'b00, pixelX}) - 13'sd320;
    assign dy_win = $signed({2'b00, pixelY}) - 13'sd240;

    // ------------------------------------------------------------
    // Trophy area and address
    // ------------------------------------------------------------

    assign trophy_area =
        show_win_screen &&
        pixelX >= TROPHY_LEFT &&
        pixelX <  TROPHY_LEFT + TROPHY_W &&
        pixelY >= TROPHY_TOP &&
        pixelY <  TROPHY_TOP + TROPHY_H;

    assign trophy_x = pixelX - TROPHY_LEFT;
    assign trophy_y = pixelY - TROPHY_TOP;

    assign trophy_address = trophy_area ? {trophy_y, trophy_x} : 16'd0;

    // ------------------------------------------------------------
    // Helper functions
    // ------------------------------------------------------------

    function automatic [12:0] abs13(input logic signed [12:0] v);
    begin
        abs13 = v[12] ? -v : v;
    end
    endfunction


   logic [12:0] ax_win;
	logic [12:0] ay_win;
	logic [13:0] ray_dist_win;
	logic [13:0] ray_width_win;

	assign ax_win = dx_win[12] ? -dx_win : dx_win;
	assign ay_win = dy_win[12] ? -dy_win : dy_win;

	assign ray_dist_win  = {1'b0, ax_win} + {1'b0, ay_win};
	assign ray_width_win = (ray_dist_win >> 4) + 14'd5;

	function automatic logic near_band_14 (
		 input logic [13:0] a,
		 input logic [13:0] b,
		 input logic [13:0] w
	);
		 logic [13:0] diff;
	begin
		 diff = (a > b) ? (a - b) : (b - a);
		 near_band_14 = (diff < w);
	end
	endfunction
	
	
	assign press_area =
    show_win_screen &&
    pixelX >= PRESS_LEFT &&
    pixelX <  PRESS_LEFT + PRESS_W &&
    pixelY >= PRESS_TOP &&
    pixelY <  PRESS_TOP + PRESS_H;

	assign press_x = pixelX - PRESS_LEFT;
	assign press_y = pixelY - PRESS_TOP;

	assign press_address = press_area ? (press_y * PRESS_W + press_x) : 14'd0;


	assign clock_area =
		 show_win_screen &&
		 pixelX >= CLOCK_LEFT &&
		 pixelX <  CLOCK_LEFT + CLOCK_W &&
		 pixelY >= CLOCK_TOP &&
		 pixelY <  CLOCK_TOP + CLOCK_H;

	assign clock_x = pixelX - CLOCK_LEFT;
	assign clock_y = pixelY - CLOCK_TOP;

	// 64x64 => address = y*64 + x
	assign clock_address = clock_area ? {clock_y, clock_x} : 12'd0; 


    // ------------------------------------------------------------
    // Trophy ROM
    // ------------------------------------------------------------

    lpm_rom #(
        .LPM_WIDTH(8),
        .LPM_WIDTHAD(16),
        .LPM_NUMWORDS(65536),
        .LPM_FILE("RTL/screen/trophy.mif"),
        .LPM_TYPE               ("LPM_ROM"),
        .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
        .LPM_OUTDATA            ("UNREGISTERED"), 
        .AUTO_CARRY_CHAINS      ("ON"),
        .AUTO_CASCADE_BUFFERS   ("ON"),
        .INTENDED_DEVICE_FAMILY ("Cyclone V")  
    ) trophy_rom_inst (
        .address(trophy_address),
        .inclock(clk),
        // .outclock(clk),
        .q(trophy_color)
    );

	//label rom
	lpm_rom #(
		 .LPM_WIDTH(1),
		 .LPM_WIDTHAD(14),
		 .LPM_NUMWORDS(16384),
		 .LPM_FILE("RTL/screen/press_enter_continue.mif"),
		 .LPM_TYPE("LPM_ROM"),
		 .LPM_ADDRESS_CONTROL("REGISTERED"),
		 .LPM_OUTDATA("UNREGISTERED"),
		 .INTENDED_DEVICE_FAMILY("Cyclone V")
	) press_rom_inst (
		 .address(press_address),
		 .inclock(clk),
		 .q(press_pixel)
	);
	 
	//clock rom
	lpm_rom #(
		 .LPM_WIDTH(8),
		 .LPM_WIDTHAD(12),
		 .LPM_NUMWORDS(4096),
		 .LPM_FILE("RTL/screen/clock.mif"),
		 .LPM_TYPE("LPM_ROM"),
		 .LPM_ADDRESS_CONTROL("REGISTERED"),
		 .LPM_OUTDATA("UNREGISTERED"),
		 .INTENDED_DEVICE_FAMILY("Cyclone V")
	) clock_rom_inst (
		 .address(clock_address),
		 .inclock(clk),
		 .q(clock_color)
	);
	
	// ------------------------------------------------------------
   // digits logic
   // ------------------------------------------------------------
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

	
	always_comb begin
		 digitInside   = 1'b0;
		 selectedDigit = 4'd0;
		 digitOffsetX  = 11'd0;
		 digitOffsetY  = 11'd0;

		 if (show_win_screen &&
			  inside_rectangle(pixelX, pixelY, TIME_M_T_X, TIME_Y, BIG_DIGIT_W, BIG_DIGIT_H)) begin
			  digitInside   = 1'b1;
			  selectedDigit = score_min_tens;
			  digitOffsetX  = pixelX - TIME_M_T_X;
			  digitOffsetY  = pixelY - TIME_Y;
		 end

		 else if (show_win_screen &&
			  inside_rectangle(pixelX, pixelY, TIME_M_O_X, TIME_Y, BIG_DIGIT_W, BIG_DIGIT_H)) begin
			  digitInside   = 1'b1;
			  selectedDigit = score_min_ones;
			  digitOffsetX  = pixelX - TIME_M_O_X;
			  digitOffsetY  = pixelY - TIME_Y;
		 end

		 else if (show_win_screen &&
			  inside_rectangle(pixelX, pixelY, TIME_S_T_X, TIME_Y, BIG_DIGIT_W, BIG_DIGIT_H)) begin
			  digitInside   = 1'b1;
			  selectedDigit = score_sec_tens;
			  digitOffsetX  = pixelX - TIME_S_T_X;
			  digitOffsetY  = pixelY - TIME_Y;
		 end

		 else if (show_win_screen &&
			  inside_rectangle(pixelX, pixelY, TIME_S_O_X, TIME_Y, BIG_DIGIT_W, BIG_DIGIT_H)) begin
			  digitInside   = 1'b1;
			  selectedDigit = score_sec_ones;
			  digitOffsetX  = pixelX - TIME_S_O_X;
			  digitOffsetY  = pixelY - TIME_Y;
		 end
	end


	NumbersBitMap #(
		 .SIZE_SHIFT(1)
	) win_digit_inst (
		 .clk(clk),
		 .resetN(resetN),
		 .offsetX(digitOffsetX),
		 .offsetY(digitOffsetY),
		 .InsideRectangle(digitInside),
		 .digit(selectedDigit),
		 .drawingRequest(digitDrawReq)
	);
	 
	 //colon
	 assign colonDrawReq =
    show_win_screen &&
    pixelX >= COLON_X &&
    pixelX <  COLON_X + 12 &&
    (
        (pixelY >= TIME_Y + 16 && pixelY < TIME_Y + 28) ||
        (pixelY >= TIME_Y + 40 && pixelY < TIME_Y + 52)
    );
	 
	 
    // ------------------------------------------------------------
    // blue background + gray rays + confetti
    // ------------------------------------------------------------

    always_comb begin
        win_bg_RGB = COLOR_BLACK;

        if (show_win_screen) begin
            // Deep blue base
            win_bg_RGB = 8'b011_001_00;

            if (
					 // horizontal / vertical rays
					 (ay_win < ray_width_win) ||
					 (ax_win < ray_width_win) ||

					 // diagonal 45 degrees
					 near_band_14({1'b0, ay_win}, {1'b0, ax_win}, ray_width_win) ||

					 // shallow diagonals
					 near_band_14({1'b0, ay_win}, ({1'b0, ax_win} >> 1), ray_width_win) ||
					 near_band_14({1'b0, ay_win}, ({1'b0, ax_win} >> 2), ray_width_win) ||

					 // steep diagonals
					 near_band_14({1'b0, ax_win}, ({1'b0, ay_win} >> 1), ray_width_win) ||
					 near_band_14({1'b0, ax_win}, ({1'b0, ay_win} >> 2), ray_width_win)
				) begin
					 win_bg_RGB = 8'b010_010_01;
				end
				
            // ------------------------------------------------------------
            // Confetti
            // ------------------------------------------------------------
            if (confetti_noise[9:0] < 10'd18 ||
                ((confetti_noise[9:0] >= 10'd18) &&
                 (confetti_noise[9:0] < 10'd28) &&
                 pixelX[1:0] != 2'b00 &&
                 pixelY[1:0] != 2'b00)) begin

                case (confetti_noise[13:11])
                    3'd0: win_bg_RGB = 8'b000_000_11; // red
                    3'd1: win_bg_RGB = 8'b000_111_00; // green
                    3'd2: win_bg_RGB = 8'b111_000_00; // cyan/blue
                    3'd3: win_bg_RGB = 8'b000_111_11; // yellow
                    3'd4: win_bg_RGB = 8'b010_000_11; // magenta
                    3'd5: win_bg_RGB = 8'b111_111_00; // cyan
                    3'd6: win_bg_RGB = 8'b001_101_11; // orange
                    default: win_bg_RGB = 8'b111_111_11;
                endcase
            end
        end
    end


    // ------------------------------------------------------------
    // Pipeline alignment
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge resetN) begin
		 if (!resetN) begin
			  trophy_area_d <= 1'b0;
			  press_area_d  <= 1'b0;
			  clock_area_d  <= 1'b0;
			  win_bg_RGB_d  <= COLOR_BLACK;
		 end
		 else begin
			  trophy_area_d <= trophy_area;
			  press_area_d  <= press_area;
			  clock_area_d  <= clock_area;
			  win_bg_RGB_d  <= win_bg_RGB;
		 end
	end


    // ------------------------------------------------------------
    // Final win screen RGB
    // ------------------------------------------------------------

    always_comb begin
		 win_RGB = win_bg_RGB_d;

		 // trophy MIF
		 if (trophy_area_d && trophy_color != COLOR_WHITE)
			  win_RGB = trophy_color;

		 // clock icon MIF
		 if (clock_area_d && clock_color != CLOCK_TRANSPARENT)
			  win_RGB = clock_color;

		 // big time digits
		 if (digitDrawReq)
			  win_RGB = TIME_COLOR;

		 // colon
		 if (colonDrawReq)
			  win_RGB = TIME_COLOR;

		 // press enter 1-bit MIF
		 if (press_area_d && press_pixel == 1'b1)
			  win_RGB = PRESS_COLOR;
	end

endmodule