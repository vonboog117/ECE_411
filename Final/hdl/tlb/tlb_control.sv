module tlb_control (
  input clk,
  input rst,

  input logic tlb_read, tlb_write, hit,

  output logic load_data, tlb_resp 
);

enum int unsigned{
  check_hit,
	write_addr
} state, next_state;

always_comb begin : state_logic
  tlb_resp = 1'b0;
  load_data = 1'b0;

  unique case(state)
  check_hit: begin
    if (tlb_read == 1'b1 && hit == 1'b1) begin
        tlb_resp = 1'b1; 
    end
  end
  write_addr: begin
    load_data = 1'b1;
  end
  endcase
end

always_comb begin : next_state_logic
  next_state = state;

  unique case(state)
    check_hit: begin
      if (tlb_read == 1'b1 && hit == 1'b0) begin
          next_state = write_addr;
      end
    end
    write_addr: begin
      if(tlb_write == 1'b1) begin
        next_state = check_hit;
      end
    end
  endcase
end

always_ff @(posedge clk) begin: next_state_assignment
  if (rst) state <= check_hit;
  else state <= next_state;
end

endmodule : tlb_control