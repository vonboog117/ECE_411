module tlb (
  input clk,
  input rst,

  input logic[31:0] ph_address,
  input logic[31:0] vr_address,
  input logic tlb_read, tlb_write,

  output logic[31:0] out_address,
  output logic tlb_hit, tlb_resp
);

logic load_data;

tlb_control control(.clk(clk), .rst(rst), .tlb_read(tlb_read), .tlb_write(tlb_write), .hit(tlb_hit), .load_data(load_data), .tlb_resp(tlb_resp));
tlb_datapath datapath(.clk(clk), .rst(rst), .ph_address(ph_address), .vr_address(vr_address), .tlb_read(tlb_read), .load_data(tlb_write && load_data), .out_address(out_address), .hit(tlb_hit));

endmodule : tlb