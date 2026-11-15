module speed_controller (
    input  logic clk,
    input  logic resetN,

    // From game_controller
    input  logic       game_active,
    input  logic       init_game,
    input  logic [1:0] selected_level,

    // Current snake length
    input  logic [4:0] snake_length,

    // Future speed effects
    input  logic slow_effect_active,
    input  logic fast_effect_active,

    // Output to snake movement module
    output logic signed [10:0] current_speed

    // Debug
    //output logic [3:0] speed_stage_debug
);

    // ------------------------------------------------------------
    // Local parameters
    // ------------------------------------------------------------

    localparam int unsigned START_LENGTH = 10;
    localparam int unsigned LENGTH_STEP  = 3;

    localparam logic [1:0] LEVEL_EASY   = 2'd0;
    localparam logic [1:0] LEVEL_MEDIUM = 2'd1;
    localparam logic [1:0] LEVEL_HARD   = 2'd2;

  
    //legal speed levels   
    localparam logic signed [10:0] SPEED_VERY_SLOW = 11'sd64;
    localparam logic signed [10:0] SPEED_SLOW      = 11'sd128;
	 localparam logic signed [10:0] SPEED_MEDIUM_SLOW      = 11'sd192;
    localparam logic signed [10:0] SPEED_MEDIUM    = 11'sd256;
	 localparam logic signed [10:0] SPEED_MEDIUM_FAST    = 11'sd320;
    localparam logic signed [10:0] SPEED_FAST      = 11'sd384;
	 localparam logic signed [10:0] SPEED_VERY_FAST      = 11'sd448;

    // Maximum speed 
    localparam logic signed [10:0] MAX_SPEED = 10'sd512;

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------

    int unsigned length_removed;
    int unsigned speed_stage;
    int unsigned speed_index;

    // ------------------------------------------------------------
    // Calculate speed stage from snake length
    // ------------------------------------------------------------

    always_comb begin
        if (int'(snake_length) < int'(START_LENGTH)) begin
            length_removed = START_LENGTH - int'(snake_length);
        end
		  else begin
            length_removed = 0;
        end

        speed_stage = length_removed / LENGTH_STEP;
    end

    // ------------------------------------------------------------
    // Calculate speed index
    //
    // Easy:
    // starts slower and increases slowly
    //
    // Medium:
    // starts medium
    //
    // Hard:
    // starts faster and increases faster
    // ------------------------------------------------------------

    always_comb begin
        speed_index = 0;

        case (selected_level)

            LEVEL_EASY: begin
                // Easy starts at very slow
                speed_index = 0 + speed_stage;
            end

            LEVEL_MEDIUM: begin
                // Medium starts at slow
                speed_index = 1 + speed_stage;
            end

            LEVEL_HARD: begin
                // Hard starts at medium and reacts stronger
                speed_index = 1 + speed_stage;
            end

            default: begin
                speed_index = 1 + speed_stage;
            end

        endcase

        // Future slowing effect
        if (slow_effect_active) begin
            if (speed_index > 0) begin
                speed_index = speed_index - 1;
            end
        end

        // Future fast effect
        if (fast_effect_active) begin
            speed_index = speed_index + 1;
        end

        // Clamp index
        if (speed_index > 6) begin
            speed_index = 6;
        end
    end

    // ------------------------------------------------------------
    // Convert speed index to legal fixed-point speed
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            current_speed <= SPEED_SLOW;
        end
		  else if (init_game) begin
            case (selected_level)
                LEVEL_EASY:   current_speed <= SPEED_SLOW;
                LEVEL_MEDIUM: current_speed <= SPEED_MEDIUM;
                LEVEL_HARD:   current_speed <= SPEED_MEDIUM_FAST;
                default:      current_speed <= SPEED_SLOW;
            endcase
        end else if (game_active) begin
            case (speed_index)
                0: current_speed <= SPEED_VERY_SLOW;
                1: current_speed <= SPEED_SLOW;
                2: current_speed <= SPEED_MEDIUM_SLOW;
                3: current_speed <= SPEED_MEDIUM;
					 4: current_speed <= SPEED_MEDIUM_FAST;
                5: current_speed <= SPEED_FAST;
                6: current_speed <= SPEED_VERY_FAST;
                default: current_speed <= SPEED_FAST;
            endcase
        end
    end

    //assign speed_stage_debug = speed_stage[3:0];

endmodule