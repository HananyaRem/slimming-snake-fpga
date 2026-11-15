


module spawn_controller (
	 
	 input  logic clk,
    input  logic resetN,
	 input  logic init_game, // from game_controller
    input  logic hit_pulse, //from collision_detector
    input  logic [7:0] random_position, //from lfsr
    input  logic [224:0] occupied_flat, //from occupancy_matrix

    output logic lfsr_trigger,
    output logic [7:0] food_position,
    output logic food_visible
);


// check if current lfsr position is occupide 
logic random_ok;

always_comb begin

    random_ok = 1'b0; //default
	 
	 if(random_position < 8'd225 && (!occupied_flat[random_position])) begin
			random_ok = 1'b1;
	 end
end	 


// fsm 
enum logic [1:0] {
    IDLE_ST,
    TRIGGER_ST,
    CHECK_ST
} position_sm;


always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        position_sm <= IDLE_ST;

        food_position <= 8'd0;
        food_visible <= 1'b0;
        lfsr_trigger <= 1'b0;
	 end

	else begin
        lfsr_trigger <= 1'b0;

        if (init_game || hit_pulse) begin
            food_visible  <= 1'b0;
            position_sm <= TRIGGER_ST;
        end	
		  
		  else begin 
				case(position_sm)
					  
					 IDLE_ST: begin
                    // do nothing 
                end

                TRIGGER_ST: begin
                    lfsr_trigger  <= 1'b1;
                    position_sm <= CHECK_ST;
                end

                CHECK_ST: begin
                    if (random_ok) begin
                        food_position      <= random_position;
                        food_visible  <= 1'b1;
                        position_sm <= IDLE_ST;
                    end 
						  else begin
                        position_sm <= TRIGGER_ST;
                    end
                end
				endcase
		  end	
	 end
end // sync	


endmodule