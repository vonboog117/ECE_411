
module tlb_array #(parameter width = 1)
(
  input clk,
  input rst,
  input logic load,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

logic [width-1:0] data;

always_comb begin
  //dataout = load ? datain : data;
  dataout = data;
end

always_ff @(posedge clk)
begin
    if (rst) begin
      data <= '0;
    end
    else if(load) begin
        data <= datain;
    end
end

endmodule : tlb_array