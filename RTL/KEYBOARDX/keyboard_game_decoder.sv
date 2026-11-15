

module keyboard_game_decoder (
    input  logic clk,
    input  logic resetN,

    input  logic enter,
    input  logic [9:0] numbers,

    output logic start_pressed_pulse,
    output logic level_pressed_pulse,
    output logic [1:0] digit_value
);

    logic enter_d;
    logic level_raw;
    logic level_raw_d;

    assign level_raw = numbers[1] || numbers[2] || numbers[3];

    always_comb begin
        digit_value = 2'd0;

        if (numbers[1])
            digit_value = 2'd1;
        else if (numbers[2])
            digit_value = 2'd2;
        else if (numbers[3])
            digit_value = 2'd3;
    end

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            enter_d             <= 1'b0;
            level_raw_d         <= 1'b0;
            start_pressed_pulse <= 1'b0;
            level_pressed_pulse <= 1'b0;
        end
        else begin
            start_pressed_pulse <= enter && !enter_d;
            level_pressed_pulse <= level_raw && !level_raw_d;

            enter_d     <= enter;
            level_raw_d <= level_raw;
        end
    end

endmodule