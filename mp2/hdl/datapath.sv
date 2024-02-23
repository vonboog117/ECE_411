module datapath
import rv32i_types::*;
(
    input clk,
    input rst,

    input logic load_pc, load_ir, load_regfile, load_mar, load_mdr, load_data_out,

    input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,

    input alu_ops aluop,
    input branch_funct3_t cmpop,

    output rv32i_reg rs1, rs2,

    output rv32i_opcode opcode,
    output logic[2:0] funct3,
    output logic[6:0] funct7,
    output logic br_en,

    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    output rv32i_word mem_address,
    /* You will need to connect more signals to your datapath module*/

    input logic[3:0] mem_byte_enable,
    output logic[1:0] addr_1_0
    
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
/*****************************************************************************/
rv32i_word i_imm, u_imm, b_imm, s_imm, j_imm;
rv32i_word  alumux1_out, alumux2_out, marmux_out, regfilemux_out, cmp_mux_out;
rv32i_word alu_out, pc_out, pc_plus4_out;
rv32i_word rs1_out, rs2_out;
rv32i_word mem_data;

rv32i_reg rd;

assign addr_1_0 = marmux_out[1:0];

/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk(clk),
    .rst(rst),
    .load(load_ir),
    .in(mdrreg_out),

    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .clk  (clk),
    .rst (rst),
    .load (load_mar),
    .in   ({marmux_out[31:2], 2'b00}),
    .out  (mem_address)
);

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

register mem_data_out(
    .clk(clk),
    .rst(rst),
    .load(load_data_out),
    .in(rs2_out),
    .out(mem_data)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu ALU(
    .aluop(aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out)
);

//CMP
cmp CMP(
    .cmpop(cmpop),
    .rs1_out(rs1_out),
    .cmp_mux_out(cmp_mux_out),
    .br_en(br_en)
);

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out:  pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:2], 2'b00};
        // etc.
    endcase

    
    unique case (alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_out;
        alumux::pc_out:  alumux1_out = pc_out;
    endcase

    unique case (alumux2_sel)
        alumux::i_imm:   alumux2_out = i_imm;
        alumux::u_imm:   alumux2_out = u_imm;
        alumux::b_imm:   alumux2_out = b_imm;
        alumux::s_imm:   alumux2_out = s_imm;
        alumux::j_imm:   alumux2_out = j_imm;
        alumux::rs2_out: alumux2_out = rs2_out;
    endcase

    unique case (regfilemux_sel)
        regfilemux::alu_out:    regfilemux_out = alu_out;
        regfilemux::br_en:      regfilemux_out = {31'b0, br_en};
        regfilemux::u_imm:      regfilemux_out = u_imm;
        regfilemux::lw:         regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4:   regfilemux_out = pc_out + 4;
        regfilemux::lb: begin
            case(mem_byte_enable)
                4'b0001:
                    regfilemux_out = rv32i_word'(signed'(mdrreg_out[7:0]));
                4'b0010:
                    regfilemux_out = rv32i_word'(signed'(mdrreg_out[15:8]));
                4'b0100:
                    regfilemux_out = rv32i_word'(signed'(mdrreg_out[23:16]));
                4'b1000:
                    regfilemux_out = rv32i_word'(signed'(mdrreg_out[31:24]));
                default: 
                    regfilemux_out = mdrreg_out;
            endcase
            //regfilemux_out = rv32i_word'(signed'(mdrreg_out));
        end
        regfilemux::lbu: begin
            case(mem_byte_enable)
                4'b0001:
                    regfilemux_out = {24'b0, mdrreg_out[7:0]};
                4'b0010:
                    regfilemux_out = {24'b0, mdrreg_out[15:8]};
                4'b0100:
                    regfilemux_out = {24'b0, mdrreg_out[23:16]};
                4'b1000:
                    regfilemux_out = {24'b0, mdrreg_out[31:24]};
                default: 
                    regfilemux_out = mdrreg_out;
            endcase
        end
        regfilemux::lh: begin
            case(mem_byte_enable)
                4'b0011:
                    regfilemux_out = rv32i_word'(signed'(mdrreg_out[15:0]));
                4'b1100:
                    regfilemux_out = rv32i_word'(signed'(mdrreg_out[31:16]));
                default: 
                    regfilemux_out = mdrreg_out;
            endcase
        end
        regfilemux::lhu: begin
            case(mem_byte_enable)
                4'b0011:
                    regfilemux_out = {16'b0, mdrreg_out[15:0]};
                4'b1100:
                    regfilemux_out = {16'b0, mdrreg_out[31:16]};
                default: 
                    regfilemux_out = mdrreg_out;
            endcase
        end
    endcase

    unique case (marmux_sel)
        marmux::pc_out:     marmux_out = pc_out;
        marmux::alu_out:    marmux_out = alu_out;
    endcase

    unique case (cmpmux_sel)
        cmpmux::rs2_out:    cmp_mux_out = rs2_out;
        cmpmux::i_imm:      cmp_mux_out = i_imm;
    endcase

    unique case (mem_byte_enable)
        4'b0000:
            mem_wdata = '0;
        4'b0001:
            mem_wdata = {24'b0, mem_data[7:0]};
        4'b0010:
            mem_wdata = {16'b0, mem_data[7:0], 8'b0};
        4'b0100:
            mem_wdata = {8'b0, mem_data[7:0], 16'b0};
        4'b1000:
            mem_wdata = {mem_data[7:0], 24'b0};
        4'b0011:
            mem_wdata = {16'b0, mem_data[15:0]};
        4'b1100:
            mem_wdata = {mem_data[15:0], 16'b0};
        4'b1111:
            mem_wdata = mem_data;
        default:
            mem_wdata = mem_data;
    endcase
end
/*****************************************************************************/
endmodule : datapath
