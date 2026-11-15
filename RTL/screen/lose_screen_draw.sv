


module lose_screen_draw (
    input  logic clk,
    input  logic resetN,

    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,

    input  logic show_lose_screen,

    output logic [7:0] lose_RGB
);


    localparam logic [7:0] COLOR_BLACK      = 8'h00;
    localparam logic [7:0] COLOR_WHITE      = 8'hff;

    localparam logic [7:0] COLOR_BG_GRAY    = 8'b010_010_01;
    localparam logic [7:0] COLOR_DARK_RAY   = 8'b001_001_01;
    localparam logic [7:0] COLOR_THIN_LINE  = 8'b101_101_10;

    localparam logic [7:0] GO_COLOR = 8'b111_000_00;   
    localparam logic [7:0] PRESS_COLOR = 8'b000_000_11; // blue

    // ------------------------------------------------------------
    // Game Over MIF parameters - 380x256, 8-bit color
    // ------------------------------------------------------------

    localparam int GO_W    = 350;
    localparam int GO_H    = 256;
    localparam int GO_LEFT = 130;
    localparam int GO_TOP  = 80;

    localparam int GO_NUMWORDS = 89600;
	 localparam int GO_ADDR_W   = 17;

    // ------------------------------------------------------------
    // Press Enter MIF parameters - 444x32, 1-bit
    // ------------------------------------------------------------

    localparam int PRESS_W    = 444;
    localparam int PRESS_H    = 32;
    localparam int PRESS_LEFT = 98;
    localparam int PRESS_TOP  = 390;
    localparam int PRESS_NUMWORDS = 16384;
    localparam int PRESS_ADDR_W   = 14;

    // ------------------------------------------------------------
    // Background pattern signals
    // ------------------------------------------------------------

    logic [12:0] xy_sum;
    logic [12:0] xy_diff;

    assign xy_sum  = pixelX + pixelY;
    assign xy_diff = pixelX - pixelY;

    logic [7:0] bg_RGB;
    logic [7:0] bg_RGB_d;

    // ------------------------------------------------------------
    // Game Over area/address
    // ------------------------------------------------------------

    logic go_area;
    logic go_area_d;

    logic [10:0] go_x;
    logic [10:0] go_y;
    logic [GO_ADDR_W-1:0] go_address;
    logic go_pixel;

    assign go_area =
        show_lose_screen &&
        pixelX >= GO_LEFT &&
        pixelX <  GO_LEFT + GO_W &&
        pixelY >= GO_TOP &&
        pixelY <  GO_TOP + GO_H;

    assign go_x = pixelX - GO_LEFT;
    assign go_y = pixelY - GO_TOP;

    assign go_address = go_area ? (go_y * GO_W + go_x) : {GO_ADDR_W{1'b0}};

    // ------------------------------------------------------------
    // Press area/address
    // ------------------------------------------------------------

    logic press_area;
    logic press_area_d;

    logic [10:0] press_x;
    logic [10:0] press_y;
    logic [PRESS_ADDR_W-1:0] press_address;
    logic press_pixel;

    assign press_area =
        show_lose_screen &&
        pixelX >= PRESS_LEFT &&
        pixelX <  PRESS_LEFT + PRESS_W &&
        pixelY >= PRESS_TOP &&
        pixelY <  PRESS_TOP + PRESS_H;

    assign press_x = pixelX - PRESS_LEFT;
    assign press_y = pixelY - PRESS_TOP;

    assign press_address = press_area ? (press_y * PRESS_W + press_x) : {PRESS_ADDR_W{1'b0}};

    // ------------------------------------------------------------
    // Background
    // ------------------------------------------------------------

    always_comb begin
        bg_RGB = COLOR_BLACK;

        if (show_lose_screen) begin
            bg_RGB = COLOR_BG_GRAY;

            // darker diagonal bands
            if (xy_sum[7] ^ xy_diff[7])
                bg_RGB = COLOR_DARK_RAY;

            // strong white diagonal streaks
            if ((xy_diff[6:0] < 7'd3) ||
                (xy_diff[6:0] > 7'd124))
                bg_RGB = COLOR_WHITE;

            // thinner secondary streaks
            if (xy_sum[7:0] < 8'd3)
                bg_RGB = COLOR_THIN_LINE;
        end
    end

    // ------------------------------------------------------------
    // Game Over ROM - 8-bit color
    // ------------------------------------------------------------

    lpm_rom #(
        .LPM_WIDTH(1),
        .LPM_WIDTHAD(GO_ADDR_W),
        .LPM_NUMWORDS(GO_NUMWORDS),
        .LPM_FILE("RTL/screen/game_over.mif"),
        .LPM_TYPE("LPM_ROM"),
        .LPM_ADDRESS_CONTROL("REGISTERED"),
        .LPM_OUTDATA("UNREGISTERED"),
        .AUTO_CARRY_CHAINS("ON"),
        .AUTO_CASCADE_BUFFERS("ON"),
        .INTENDED_DEVICE_FAMILY("Cyclone V")
    ) game_over_rom_inst (
        .address(go_address),
        .inclock(clk),
        .q(go_pixel)
    );

    // ------------------------------------------------------------
    // Press Enter ROM - 1-bit
    // ------------------------------------------------------------

    lpm_rom #(
        .LPM_WIDTH(1),
        .LPM_WIDTHAD(PRESS_ADDR_W),
        .LPM_NUMWORDS(PRESS_NUMWORDS),
        .LPM_FILE("RTL/screen/press_enter_continue.mif"),
        .LPM_TYPE("LPM_ROM"),
        .LPM_ADDRESS_CONTROL("REGISTERED"),
        .LPM_OUTDATA("UNREGISTERED"),
        .AUTO_CARRY_CHAINS("ON"),
        .AUTO_CASCADE_BUFFERS("ON"),
        .INTENDED_DEVICE_FAMILY("Cyclone V")
    ) press_rom1_inst (
        .address(press_address),
        .inclock(clk),
        .q(press_pixel)
    );

    // ------------------------------------------------------------
    // Pipeline alignment
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            bg_RGB_d     <= COLOR_BLACK;
            go_area_d    <= 1'b0;
            press_area_d <= 1'b0;
        end
        else begin
            bg_RGB_d     <= bg_RGB;
            go_area_d    <= go_area;
            press_area_d <= press_area;
        end
    end

    // ------------------------------------------------------------
    // Final priority:
    // game over > press text > background
    // ------------------------------------------------------------

    always_comb begin
        lose_RGB = bg_RGB_d;

        if (press_area_d && press_pixel == 1'b1)
            lose_RGB = PRESS_COLOR;

        if (go_area_d && go_pixel)
				lose_RGB = GO_COLOR;
    end

endmodule