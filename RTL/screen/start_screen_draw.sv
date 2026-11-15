

module start_screen_draw (
    input  logic clk,
    input  logic resetN,

    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic show_start_screen,

    output logic [7:0]  start_RGB
);

    // ------------------------------------------------------------
    // Color constants
    // ------------------------------------------------------------

    localparam logic [7:0] COLOR_BLACK       = 8'h00;
    localparam logic [7:0] TRANSPARENT_COLOR = 8'hff;
	 localparam logic [7:0] TITLE_BLUE = 8'b000_000_11; 

    // ------------------------------------------------------------
    // MIF object parameters
    // ------------------------------------------------------------

    localparam int TITLE_W    = 568;
    localparam int TITLE_H    = 70;
    localparam int TITLE_LEFT = 36;
    localparam int TITLE_TOP  = 30;

    localparam int SNAKE_W    = 320;
    localparam int SNAKE_H    = 250;
    localparam int SNAKE_LEFT = 160;
    localparam int SNAKE_TOP  = 115;

    localparam int PRESS_W    = 470;
    localparam int PRESS_H    = 66;
    localparam int PRESS_LEFT = 85;
    localparam int PRESS_TOP  = 388;

    // ------------------------------------------------------------
    // Background signals
    // ------------------------------------------------------------

    logic [15:0] start_noise;
    logic [12:0] start_diag_sum;

    assign start_noise =
        pixelX * 16'd7 + pixelY * 16'd13;

    assign start_diag_sum =
        {2'b00, pixelX} + {1'b0, pixelY, 1'b0};

    // ------------------------------------------------------------
    // Area signals
    // ------------------------------------------------------------

    logic title_area;
    logic snake_area;
    logic press_area;

    logic title_area_d;
    logic snake_area_d;
    logic press_area_d;

    assign title_area =
        show_start_screen &&
        pixelX >= TITLE_LEFT &&
        pixelX <  TITLE_LEFT + TITLE_W &&
        pixelY >= TITLE_TOP &&
        pixelY <  TITLE_TOP + TITLE_H;

    assign snake_area =
        show_start_screen &&
        pixelX >= SNAKE_LEFT &&
        pixelX <  SNAKE_LEFT + SNAKE_W &&
        pixelY >= SNAKE_TOP &&
        pixelY <  SNAKE_TOP + SNAKE_H;

    assign press_area =
        show_start_screen &&
        pixelX >= PRESS_LEFT &&
        pixelX <  PRESS_LEFT + PRESS_W &&
        pixelY >= PRESS_TOP &&
        pixelY <  PRESS_TOP + PRESS_H;

		  
    // ------------------------------------------------------------
    // Local coordinates
    // ------------------------------------------------------------
    logic [10:0] title_x;
    logic [10:0] title_y;
    logic [10:0] snake_x;
    logic [10:0] snake_y;
    logic [10:0] press_x;
    logic [10:0] press_y;

    assign title_x = pixelX - TITLE_LEFT;
    assign title_y = pixelY - TITLE_TOP;

    assign snake_x = pixelX - SNAKE_LEFT;
    assign snake_y = pixelY - SNAKE_TOP;

    assign press_x = pixelX - PRESS_LEFT;
    assign press_y = pixelY - PRESS_TOP;

	 
    // ------------------------------------------------------------
    // ROM sugnals
    // ------------------------------------------------------------
    logic [15:0] title_address;
    logic [16:0] snake_address;
    logic [14:0] press_address;

    assign title_address = title_area ? (title_y * TITLE_W + title_x) : 16'd0;
    assign snake_address = snake_area ? (snake_y * SNAKE_W + snake_x) : 16'd0;
    assign press_address = press_area ? (press_y * PRESS_W + press_x) : 16'd0;

    logic title_pixel;
    logic [7:0] snake_color;
    logic [7:0] press_color;

	 
    // ------------------------------------------------------------
    // Background draw
    // ------------------------------------------------------------
    logic [7:0] bg_RGB;
    logic [7:0] bg_RGB_d;

    always_comb begin
        bg_RGB = COLOR_BLACK;

        if (show_start_screen) begin
            if (pixelY < 11'd160)
                bg_RGB = 8'b010_011_00;
            else if (pixelY < 11'd320)
                bg_RGB = 8'b010_100_00;
            else
                bg_RGB = 8'b001_101_00;

            if (pixelX[5] ^ pixelY[5]) begin
                if (pixelY < 11'd160)
                    bg_RGB = 8'b001_100_00;
                else if (pixelY < 11'd320)
                    bg_RGB = 8'b010_101_00;
                else
                    bg_RGB = 8'b010_101_00;
            end

            if ((start_diag_sum[6:0] < 7'd2) &&
                pixelY > 11'd20 && pixelY < 11'd460)
                bg_RGB = 8'b010_110_10;

            if (start_noise[8:0] < 9'd5 &&
                pixelY > 11'd30 && pixelY < 11'd450)
                bg_RGB = 8'b001_101_01;
        end
    end

	 
    // ------------------------------------------------------------
    // ROMs
    // ------------------------------------------------------------
    lpm_rom #(
        .LPM_WIDTH(1),
        .LPM_WIDTHAD(16),
        .LPM_NUMWORDS(39760),
        .LPM_FILE("RTL/screen/slimming_snake.mif"),
        .LPM_TYPE("LPM_ROM"),
        .LPM_ADDRESS_CONTROL("REGISTERED"),
        .LPM_OUTDATA("UNREGISTERED"),
        .INTENDED_DEVICE_FAMILY("Cyclone V")
    ) title_rom_inst (
        .address(title_address),
        .inclock(clk),
        .q(title_pixel)
    );

    lpm_rom #(
        .LPM_WIDTH(8),
        .LPM_WIDTHAD(17),
        .LPM_NUMWORDS(80000),
        .LPM_FILE("RTL/screen/green_snake.mif"),
        .LPM_TYPE("LPM_ROM"),
        .LPM_ADDRESS_CONTROL("REGISTERED"),
        .LPM_OUTDATA("UNREGISTERED"),
        .INTENDED_DEVICE_FAMILY("Cyclone V")
    ) snake_rom_inst (
        .address(snake_address),
        .inclock(clk),
        .q(snake_color)
    );

    lpm_rom #(
        .LPM_WIDTH(8),
        .LPM_WIDTHAD(15),
        .LPM_NUMWORDS(31020),
        .LPM_FILE("RTL/screen/press_enter_select_level.mif"),
        .LPM_TYPE("LPM_ROM"),
        .LPM_ADDRESS_CONTROL("REGISTERED"),
        .LPM_OUTDATA("UNREGISTERED"),
        .INTENDED_DEVICE_FAMILY("Cyclone V")
    ) press_rom_inst (
        .address(press_address),
        .inclock(clk),
        .q(press_color)
    );

	 
    // ------------------------------------------------------------
    // Pipeline alignment
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            title_area_d <= 1'b0;
            snake_area_d <= 1'b0;
            press_area_d <= 1'b0;
            bg_RGB_d     <= COLOR_BLACK;
        end
        else begin
            title_area_d <= title_area;
            snake_area_d <= snake_area;
            press_area_d <= press_area;
            bg_RGB_d     <= bg_RGB;
        end
    end

	 
    // ------------------------------------------------------------
    // Final priority:
    // ------------------------------------------------------------
    always_comb begin
        start_RGB = bg_RGB_d;

        if (press_area_d && press_color != TRANSPARENT_COLOR)
            start_RGB = press_color;

        if (snake_area_d && snake_color != TRANSPARENT_COLOR)
            start_RGB = snake_color;

        if (title_area_d && title_pixel == 1'b1)
				start_RGB = TITLE_BLUE;
    end

endmodule