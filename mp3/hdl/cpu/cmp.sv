module cmp
import rv32i_types::*;
(
    input branch_funct3_t cmpop,
    input [31:0] rs1_out, cmp_mux_out,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq: br_en = rs1_out == cmp_mux_out ? 1'b1 : 1'b0; 
        bne: br_en = rs1_out != cmp_mux_out ? 1'b1 : 1'b0;
        blt: br_en = $signed(rs1_out) < $signed(cmp_mux_out) ? 1'b1 : 1'b0;
        bge: br_en = $signed(rs1_out) >= $signed(cmp_mux_out) ? 1'b1 : 1'b0;
        bltu: br_en = $unsigned(rs1_out) < $unsigned(cmp_mux_out) ? 1'b1 : 1'b0;
        bgeu: br_en = $unsigned(rs1_out) >= $unsigned(cmp_mux_out) ? 1'b1 : 1'b0;
        default: br_en = 1'b0;
    endcase
end

endmodule : cmp
