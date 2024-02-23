module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

/*** Declarations ***/
enum {IDLE, L1, L2, L3, L4, L5, S1, S2, S3, S4, S5} state, next_state; //L = load = read, S = store = write

logic[255:0] buffer;

/*** Assignments ***/

always_comb begin
	read_o = 1'b0;
	write_o = 1'b0;
	resp_o = 1'b0;
	line_o = buffer;
	address_o = address_i;

	next_state = state;

	case(state)
		IDLE: begin
			next_state = IDLE;
			if(read_i && ~write_i && reset_n) begin
				next_state = L1;
			end
			else if(~read_i && write_i && reset_n) begin
				next_state = S1;
				buffer = line_i;
			end
		end
		L1: begin
			read_o = 1'b1;	
			buffer[63:0] = burst_i;

			if(resp_i) begin
				next_state = L2;
			end
		end
		L2: begin
			read_o = 1'b1;
			buffer[127:64] = burst_i;

			if(resp_i) begin
				next_state = L3;
			end
			
		end
		L3: begin
			read_o = 1'b1;
			buffer[191:128] = burst_i;

			if(resp_i) begin
				next_state = L4;
			end
			
		end
		L4: begin
			read_o = 1'b1;
			buffer[255:192] = burst_i;

			if(resp_i) begin
				next_state = L5;
			end
		end
		L5: begin
			resp_o = 1'b1;
			next_state = IDLE;
		end
		S1: begin
			write_o = 1'b1;	
			burst_o = buffer[63:0];

			if(resp_i) begin
				next_state = S2;
			end
		end
		S2: begin
			write_o = 1'b1;
			burst_o = buffer[127:64];

			if(resp_i) begin
				next_state = S3;
			end
			
		end
		S3: begin
			write_o = 1'b1;
			burst_o = buffer[191:128];

			if(resp_i) begin
				next_state = S4;
			end
			
		end
		S4: begin
			write_o = 1'b1;
			burst_o = buffer[255:192];

			if(resp_i) begin
				next_state = S5;
			end
		end
		S5: begin
			resp_o = 1'b1;
			next_state = IDLE;
		end
	endcase
end

/*** Non-Blocking Assignments ***/
always_ff @(posedge clk) begin
    if(~reset_n) begin
		state <= IDLE;
    end
    else begin
		state <= next_state;
	end
end

endmodule : cacheline_adaptor
