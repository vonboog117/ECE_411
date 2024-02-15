module tlb_datapath (
  input clk,
  input rst,


  input logic[31:0] ph_address,
  input logic[31:0] vr_address,
  input logic tlb_read,
  input logic load_data,

  output logic[31:0] out_address,
  output logic hit
);

logic [19:0] ppn_out   [4];
logic [19:0] addr_ppn;
logic [19:0] vpn_out   [4];
logic [19:0] addr_vpn;
logic [11:0] addr_offset;

logic [7:0] lru_queue;
logic [3:0] valid_out;
logic [1:0] lru_in, lru_out, hit_tag;

always_comb begin
  addr_ppn = ph_address[31:12];
  addr_vpn = vr_address[31:12];
  addr_offset = vr_address[11:0];
  out_address = '0;
  

  hit = 1'b0;
  if (valid_out[0] == 1'b1 && vpn_out[0] == addr_vpn) begin
    hit = 1'b1;
    hit_tag = 2'b00;
    out_address = {ppn_out[0], addr_offset};
  end
  else if (valid_out[1] == 1'b1 && vpn_out[1] == addr_vpn) begin
    hit = 1'b1;
    hit_tag = 2'b01;
    out_address = {ppn_out[1], addr_offset};
  end
  else if (valid_out[2] == 1'b1 && vpn_out[2] == addr_vpn) begin
    hit = 1'b1;
    hit_tag = 2'b10;
    out_address = {ppn_out[2], addr_offset};
  end
  else if (valid_out[3] == 1'b1 && vpn_out[3] == addr_vpn) begin
    hit = 1'b1;
    hit_tag = 2'b11;
    out_address = {ppn_out[3], addr_offset};
  end
end

tlb_array #(20) ppn1 (.clk(clk), .rst(rst), .load(load_data && lru_out[0]), .datain(addr_ppn), .dataout(ppn_out[0]));
tlb_array #(20) vpn1 (.clk(clk), .rst(rst), .load(load_data && lru_out[0]), .datain(addr_vpn), .dataout(vpn_out[0]));
tlb_array #(1)  valid1 (.clk(clk), .rst(rst), .load(load_data && lru_out[0]), .datain(1'b1), .dataout(valid_out[0]));

tlb_array #(20) ppn2 (.clk(clk), .rst(rst), .load(load_data && lru_out[1]), .datain(addr_ppn), .dataout(ppn_out[1]));
tlb_array #(20) vpn2 (.clk(clk), .rst(rst), .load(load_data && lru_out[1]), .datain(addr_vpn), .dataout(vpn_out[1]));
tlb_array #(1)  valid2 (.clk(clk), .rst(rst), .load(load_data && lru_out[1]), .datain(1'b1), .dataout(valid_out[1]));

tlb_array #(20) ppn3 (.clk(clk), .rst(rst), .load(load_data && lru_out[2]), .datain(addr_ppn), .dataout(ppn_out[2])); 
tlb_array #(20) vpn3 (.clk(clk), .rst(rst), .load(load_data && lru_out[2]), .datain(addr_vpn), .dataout(vpn_out[2])); 
tlb_array #(1)  valid3 (.clk(clk), .rst(rst), .load(load_data && lru_out[2]), .datain(1'b1), .dataout(valid_out[2]));

tlb_array #(20) ppn4 (.clk(clk), .rst(rst), .load(load_data && lru_out[3]), .datain(addr_ppn), .dataout(ppn_out[3])); 
tlb_array #(20) vpn4 (.clk(clk), .rst(rst), .load(load_data && lru_out[3]), .datain(addr_vpn), .dataout(vpn_out[3])); 
tlb_array #(1)  valid4 (.clk(clk), .rst(rst), .load(load_data && lru_out[3]), .datain(1'b1), .dataout(valid_out[3]));

lru LRU (.clk(clk), .rst(rst), .hit_tag(hit_tag), .load_lru(load_data), .hit(hit && tlb_read), .lru_out(lru_out));


endmodule : tlb_datapath