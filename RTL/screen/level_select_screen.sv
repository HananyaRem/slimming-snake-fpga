

module level_select_screen (
    input  logic clk,
    input  logic resetN,

    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,

    input  logic  show_level_screen,
    input  logic [1:0]  selected_level,

    output logic [7:0]  level_RGB
);


    localparam logic [7:0] BLACK_TRANSPARENT = 8'h00;
    localparam logic [7:0] WHITE_TRANSPARENT = 8'hFF;

    // ------------------------------------------------------------
    // Geometry
    // ------------------------------------------------------------
    localparam int TITLE_W = 500;
    localparam int TITLE_H = 200;
    localparam int TITLE_X = 70;     
    localparam int TITLE_Y = 20;

    localparam int LVL_W = 128;
    localparam int LVL_H = 128;
    localparam int LVL_Y = 256;

    localparam int EASY_X = 64;
    localparam int MID_X  = 256;
    localparam int HARD_X = 448;

    localparam int PROMPT_W = 514;   
    localparam int PROMPT_H = 38;
    localparam int PROMPT_X = 63;
    localparam int PROMPT_Y = 413;

    // ------------------------------------------------------------
    // Addresses
    // ------------------------------------------------------------

    logic [16:0] title_addr;    
    logic [14:0] prompt_addr;
	 logic [13:0] level_addr;
	 logic [13:0] easy_addr;
	 logic [13:0] mid_addr;
	 logic [13:0] hard_addr;
	 logic [13:0] easy_selected_addr;
	 logic [13:0] mid_selected_addr;
	 logic [13:0] hard_selected_addr;

    // ------------------------------------------------------------
    // ROM outputs
    // ------------------------------------------------------------

    logic [7:0] title_rgb;
    logic [7:0] prompt_rgb;

    logic [7:0] easy_rgb;
    logic [7:0] mid_rgb;
    logic [7:0] hard_rgb;

    logic [7:0] easy_selected_rgb;
    logic [7:0] mid_selected_rgb;
    logic [7:0] hard_selected_rgb;

    logic [7:0] current_level_rgb;

    // ------------------------------------------------------------
    // Area flags
    // ------------------------------------------------------------

    logic title_area;
    logic prompt_area;
    logic level_area;

    logic title_area_d;
    logic prompt_area_d;
    logic level_area_d;

    logic [1:0] level_slot;
    logic [1:0] level_slot_d;

    logic [1:0] selected_level_d;

    logic [10:0] local_x;
    logic [10:0] local_y;

    logic [7:0] bg_rgb;
    logic [7:0] bg_rgb_d;
	 
	 
// ------------------------------------------------------------
// ROM instances
// ------------------------------------------------------------

lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (17),
    .LPM_NUMWORDS           (100000),
    .LPM_FILE               ("RTL/screen/select_level_500x200.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) title_rom_inst (
    .address (title_addr),
    .inclock (clk),
    .q       (title_rgb)
);




lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (14),
    .LPM_NUMWORDS           (16384),
    .LPM_FILE               ("RTL/screen/easy_level.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) easy_normal_rom_inst (
    .address (easy_addr),
    .inclock (clk),
    .q       (easy_rgb)
);



lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (14),
    .LPM_NUMWORDS           (16384),
    .LPM_FILE               ("RTL/screen/mid_level.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) mid_normal_rom_inst (
    .address (mid_addr),
    .inclock (clk),
    .q       (mid_rgb)
);




lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (14),
    .LPM_NUMWORDS           (16384),
    .LPM_FILE               ("RTL/screen/hard_level.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) hard_normal_rom_inst (
    .address (hard_addr),
    .inclock (clk),
    .q       (hard_rgb)
);




lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (14),
    .LPM_NUMWORDS           (16384),
    .LPM_FILE               ("RTL/screen/easy_level_sel.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) easy_selected_rom_inst (
    .address (easy_selected_addr),
    .inclock (clk),
    .q       (easy_selected_rgb)
);




lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (14),
    .LPM_NUMWORDS           (16384),
    .LPM_FILE               ("RTL/screen/mid_level_sel.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) mid_selected_rom_inst (
    .address (mid_selected_addr),
    .inclock (clk),
    .q       (mid_selected_rgb)
);



lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (14),
    .LPM_NUMWORDS           (16384),
    .LPM_FILE               ("RTL/screen/hard_level_sel.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) hard_selected_rom_inst (
    .address (hard_selected_addr),
    .inclock (clk),
    .q       (hard_selected_rgb)
);




lpm_rom #(
    .LPM_WIDTH              (8),
    .LPM_WIDTHAD            (15),
    .LPM_NUMWORDS           (19532),
    .LPM_FILE               ("RTL/screen/choose_and_start.mif"),
    .LPM_TYPE               ("LPM_ROM"),
    .LPM_ADDRESS_CONTROL    ("REGISTERED"),
    .LPM_OUTDATA            ("UNREGISTERED"),
    .AUTO_CARRY_CHAINS      ("ON"),
    .AUTO_CASCADE_BUFFERS   ("ON"),
    .INTENDED_DEVICE_FAMILY ("Cyclone V")
) prompt_rom_inst (
    .address (prompt_addr),
    .inclock (clk),
    .q       (prompt_rgb)
);

 // ------------------------------------------------------------
 // Area and address calculation
 // ------------------------------------------------------------

 always_comb begin
	  title_area  = 1'b0;
	  prompt_area = 1'b0;
	  level_area  = 1'b0;

	  title_addr  = '0;
	  prompt_addr = '0;
	  level_addr  = '0;
	  easy_addr = 14'd0;
     mid_addr  = 14'd0;
     hard_addr = 14'd0;
     easy_selected_addr = 14'd0;
     mid_selected_addr  = 14'd0;
     hard_selected_addr = 14'd0;

	  local_x = 11'd0;
	  local_y = 11'd0;

	  level_slot = 2'd0;

	  // --------------------------------------------------------
	  // Background
	  // --------------------------------------------------------

		bg_rgb = 8'b001_011_10;

		if (pixelX[5] ^ pixelY[5])
			 bg_rgb = 8'b001_100_11;

		if (pixelX[4:0] == 5'd0 || pixelY[4:0] == 5'd0)
			 bg_rgb = 8'b000_010_10;

			// ----------------------------------------------------
			// Title: 500x200
			// ----------------------------------------------------
			if (
				 pixelX >= TITLE_X && pixelX < TITLE_X + TITLE_W &&
				 pixelY >= TITLE_Y && pixelY < TITLE_Y + TITLE_H
			) begin
				 title_area = 1'b1;

				 title_addr =
					  (pixelY - TITLE_Y) * TITLE_W +
					  (pixelX - TITLE_X);
			end

			// ----------------------------------------------------
			// Level icons: 128x128 each
			// ----------------------------------------------------
			if (pixelY >= LVL_Y && pixelY < LVL_Y + LVL_H) begin

				 if (pixelX >= EASY_X && pixelX < EASY_X + LVL_W) begin
					  level_area = 1'b1;
					  level_slot = 2'd0;
					  local_x = pixelX - EASY_X;
					  local_y = pixelY - LVL_Y;
				 end

				 else if (pixelX >= MID_X && pixelX < MID_X + LVL_W) begin
					  level_area = 1'b1;
					  level_slot = 2'd1;
					  local_x = pixelX - MID_X;
					  local_y = pixelY - LVL_Y;
				 end

				 else if (pixelX >= HARD_X && pixelX < HARD_X + LVL_W) begin
					  level_area = 1'b1;
					  level_slot = 2'd2;
					  local_x = pixelX - HARD_X;
					  local_y = pixelY - LVL_Y;
				 end
			end

			if (level_area) begin
			 // 128 * local_y + local_x
			 // because 128 = 2^7
			 level_addr = {local_y[6:0], 7'b0} + local_x[6:0];

			 case (level_slot)

				  2'd0: begin
						if (selected_level == 2'd0)
							 easy_selected_addr = level_addr;
						else
							 easy_addr = level_addr;
				  end

				  2'd1: begin
						if (selected_level == 2'd1)
							 mid_selected_addr = level_addr;
						else
							 mid_addr = level_addr;
				  end

				  2'd2: begin
						if (selected_level == 2'd2)
							 hard_selected_addr = level_addr;
						else
							 hard_addr = level_addr;
				  end

				  default: begin
						// all ROM addresses stay zero
				  end

			 endcase
		 end

			// ----------------------------------------------------
			// Prompt text
			// ----------------------------------------------------
			if (
				 pixelX >= PROMPT_X && pixelX < PROMPT_X + PROMPT_W &&
				 pixelY >= PROMPT_Y && pixelY < PROMPT_Y + PROMPT_H
			) begin
				 prompt_area = 1'b1;

				 prompt_addr =
					  (pixelY - PROMPT_Y) * PROMPT_W +
					  (pixelX - PROMPT_X);
			end
	  
 end

 // ------------------------------------------------------------
 // Delay area flags 
 // ------------------------------------------------------------

 always_ff @(posedge clk or negedge resetN) begin
	  if (!resetN) begin
			title_area_d     <= 1'b0;
			prompt_area_d    <= 1'b0;
			level_area_d     <= 1'b0;
			level_slot_d     <= 2'd0;
			selected_level_d <= 2'd0;
			bg_rgb_d         <= BLACK_TRANSPARENT;
	  end
	  else begin
			title_area_d     <= title_area;
			prompt_area_d    <= prompt_area;
			level_area_d     <= level_area;
			level_slot_d     <= level_slot;
			selected_level_d <= selected_level;
			bg_rgb_d         <= bg_rgb;
	  end
 end

 // ------------------------------------------------------------
 // Select correct level icon RGB
 // ------------------------------------------------------------

 always_comb begin
	  current_level_rgb = BLACK_TRANSPARENT;

	  case (level_slot_d)

			2'd0: begin
				 if (selected_level_d == 2'd0)
					  current_level_rgb = easy_selected_rgb;
				 else
					  current_level_rgb = easy_rgb;
			end

			2'd1: begin
				 if (selected_level_d == 2'd1)
					  current_level_rgb = mid_selected_rgb;
				 else
					  current_level_rgb = mid_rgb;
			end

			2'd2: begin
				 if (selected_level_d == 2'd2)
					  current_level_rgb = hard_selected_rgb;
				 else
					  current_level_rgb = hard_rgb;
			end

			default: begin
				 current_level_rgb = BLACK_TRANSPARENT;
			end

	  endcase
 end

 // ------------------------------------------------------------
 // Final pixel composition
 // ------------------------------------------------------------

 always_comb begin
	  level_RGB = bg_rgb_d;

	  // Title has white background, so white is transparent
	  if (title_area_d && title_rgb != WHITE_TRANSPARENT) begin
			level_RGB = title_rgb;
	  end

	  if (level_area_d) begin
			level_RGB = current_level_rgb;
	  end

	  // Prompt has white background, so white is transparent
	  if (prompt_area_d && prompt_rgb != WHITE_TRANSPARENT) begin
			level_RGB = prompt_rgb;
	  end
 end

endmodule