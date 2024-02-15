module control_word
import rv32i_types::*;
(
    input clk, rst, load,

    input logic[6:0] opcode_in,
    input logic[2:0] funct3_in,
    input logic[6:0] funct7_in,
    //input rv32i_control_word word_in,

    output logic[6:0] opcode_out,
    output logic[2:0] funct3_out,
    output logic[6:0] funct7_out,
    output rv32i_control_word word_out

    /*
    input pcmux::pcmux_sel_t in_pcmux_sel,
    input alumux::alumux1_sel_t in_alumux1_sel,
    input alumux::alumux2_sel_t in_alumux2_sel,
    input regfilemux::regfilemux_sel_t in_regfilemux_sel,
    input cmpmux::cmpmux_sel_t in_cmpmux_sel,
    input alu_ops in_aluop,
    input branch_funct3_t in_cmpop,
    input logic in_load_pc, in_load_regfile, in_load_dmar, in_load_data_out,
    input logic in_mem_read, in_mem_write,
    //input logic[3:0] in_mem_byte_enable,

    output pcmux::pcmux_sel_t out_pcmux_sel,
    output alumux::alumux1_sel_t out_alumux1_sel,
    output alumux::alumux2_sel_t out_alumux2_sel,
    output regfilemux::regfilemux_sel_t out_regfilemux_sel,
    output cmpmux::cmpmux_sel_t out_cmpmux_sel,
    output alu_ops out_aluop,
    output branch_funct3_t out_cmpop,
    output logic out_load_pc, out_load_regfile, out_load_dmar, out_load_data_out,
    output logic out_mem_read, out_mem_write
    //output logic[3:0] out_mem_byte_enable
    */
);

rv32i_opcode opcode;
logic[2:0] funct3;
logic[6:0] funct7;
rv32i_control_word word;

function void loadPC(pcmux::pcmux_sel_t sel);
    word.pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    word.regfilemux_sel = sel;
    word.load_regfile = 1'b1;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    word.alumux1_sel = sel1;
    word.alumux2_sel = sel2;

    if (setop)
        word.aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    word.cmpmux_sel = sel;
    word.cmpop = op;
endfunction

always_comb begin : Control_Decode
    word.load_regfile = 1'b0;
    word.load_dmar = 1'b0;
    word.load_data_out = 1'b0;
    word.load_csr_regfile = 1'b0;
    word.pcmux_sel = pcmux::pc_plus4;
    word.cmpop = branch_funct3_t'(funct3_in);
    word.alumux1_sel = alumux::rs1_out;
    word.alumux2_sel = alumux::i_imm;
    word.regfilemux_sel = regfilemux::alu_out;
    word.cmpmux_sel = cmpmux::rs2_out;
    word.aluop = alu_ops'(funct3_in);
    word.mem_read = 1'b0;
    word.mem_write = 1'b0;

    unique case(rv32i_opcode'(opcode_in))
        op_lui   : begin
            loadRegfile(regfilemux::u_imm);
            loadPC(pcmux::pc_plus4);
        end
        op_auipc : begin
            setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
        end
        op_jal   : begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
            loadPC(pcmux::alu_out);
        end
        op_jalr  : begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadPC(pcmux::alu_mod2);
        end
        op_br    : begin
            setCMP(cmpmux::rs2_out, branch_funct3_t'(funct3_in));
            setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
            /* 
            if br_en
                PC = ALU out
            else
                PC = PC+4
            */
            loadPC(pcmux::pc_plus4);
        end
        op_load  : begin
            /* Calculate Adress */
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            word.load_dmar = 1'b1;
            //Address Offset
            /* Load Data */
            word.mem_read = 1'b1;
            unique case(load_funct3_t'(funct3_in))
                lw : begin
                    // id_mem_byte_enable = 4'b1111;
                    loadRegfile(regfilemux::lw);        
                end
                lh : begin
                    // id_mem_byte_enable = 4'b0011 << instr_mem_address[1:0];
                    loadRegfile(regfilemux::lh);        
                end
                lhu : begin
                    // id_mem_byte_enable = 4'b0011 << instr_mem_address[1:0];
                    loadRegfile(regfilemux::lhu);        
                end
                lb : begin
                    // id_mem_byte_enable = 4'b0001 << instr_mem_address[1:0];
                    loadRegfile(regfilemux::lb);        
                end
                lbu : begin
                    // id_mem_byte_enable = 4'b0001 << instr_mem_address[1:0];
                    loadRegfile(regfilemux::lbu);    
                end
            endcase
            loadPC(pcmux::pc_plus4);
            
        end
        op_store : begin
            /* Calculate Adress */
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
            word.load_dmar = 1'b1;
            word.load_data_out = 1'b1;
            //Address Offset
            /* Write Data */
            word.mem_write = 1'b1;
            // unique case(store_funct3_t'(id_funct3))
            //     sw : begin
            //         id_mem_byte_enable = 4'b1111;
            //     end
            //     sh : begin
            //         id_mem_byte_enable = 4'b0011 << instr_mem_address[1:0];
            //     end
            //     sb : begin
            //         id_mem_byte_enable = 4'b0001 << instr_mem_address[1:0];
            //     end
            // endcase
            loadPC(pcmux::pc_plus4);
        end
        op_imm   : begin
            case(arith_funct3_t'(funct3_in))
                slt     : begin
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::i_imm, blt);
                end
                sltu    : begin
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::i_imm, bltu);
                end
                sr      : begin
                    if (funct7_in == 7'b0100000)
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                    else
                        setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
                default : begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3_in));
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
            endcase
        end
        op_reg   : begin
            case(arith_funct3_t'(funct3_in))
                slt     : begin
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::rs2_out, blt);
                end
                sltu    : begin
                    loadRegfile(regfilemux::br_en);
                    loadPC(pcmux::pc_plus4);
                    setCMP(cmpmux::rs2_out, bltu);
                end
                sr      : begin
                    if (funct7_in == 7'b0100000)
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                    else
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                end
                default : begin
                    loadRegfile(regfilemux::alu_out);
                    loadPC(pcmux::pc_plus4);
                    if(funct7_in == 7'b0100000)
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                    else
                        setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3_in));
                end
            endcase
        end
        op_csr   : begin
            loadRegfile(regfilemux::csr_out);
            loadPC(pcmux::pc_plus4);
            word.load_csr_regfile = 1'b1;
        end
        default : ;
    endcase

    opcode = rv32i_opcode'(opcode_in);
    funct3 = funct3_in;
    funct7 = funct7_in;
end

always_ff @(posedge clk)
begin
    if (rst)
    begin
        opcode_out <= 7'b0;
        funct3_out <= 3'b0;
        funct7_out <= 7'b0;
        word_out <= '0;
    end
    else if (load)
    begin
        opcode_out <= opcode;
        funct3_out <= funct3;
        funct7_out <= funct7;
        word_out <= word;
    end
    else
    begin
        opcode_out <= opcode_out;
        funct3_out <= funct3_out;
        funct7_out <= funct7_out;
        word_out <= word_out;
    end
end

/*
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
alu_ops aluop;
branch_funct3_t cmpop;
logic load_pc, load_regfile, load_dmar, load_data_out;
logic mem_read, mem_write;
//logic[3:0] mem_byte_enable;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        load_pc <= 1'b0;
        load_regfile <= 1'b0;
        load_dmar <= 1'b0;
        load_data_out <= 1'b0;
        pcmux_sel <= pcmux::pc_plus4;
        cmpop <= branch_funct3_t'(3'b000);
        alumux1_sel <= alumux::rs1_out;
        alumux2_sel <= alumux::i_imm;
        regfilemux_sel <= regfilemux::alu_out;
        cmpmux_sel <= cmpmux::rs2_out;
        aluop <= alu_ops'(3'b000);
        //mem_byte_enable <= 4'b0000;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
    end
    else if (load)
    begin
        load_pc <= in_load_pc;
        load_regfile <= in_load_regfile;
        load_dmar <= in_load_dmar;
        load_data_out <= in_load_data_out;
        pcmux_sel <= in_pcmux_sel;
        cmpop <= in_cmpop;
        alumux1_sel <= in_alumux1_sel;
        alumux2_sel <= in_alumux2_sel;
        regfilemux_sel <= in_regfilemux_sel;
        cmpmux_sel <= in_cmpmux_sel;
        aluop <= in_aluop;
        //mem_byte_enable <= in_mem_byte_enable;
        mem_read <= in_mem_read;
        mem_write <= in_mem_write;
    end
    else
    begin
        load_pc <= load_pc;
        load_regfile <= load_regfile;
        load_dmar <= load_dmar;
        load_data_out <= load_data_out;
        pcmux_sel <= pcmux_sel;
        cmpop <= cmpop;
        alumux1_sel <= alumux1_sel;
        alumux2_sel <= alumux2_sel;
        regfilemux_sel <= regfilemux_sel;
        cmpmux_sel <= cmpmux_sel;
        aluop <= aluop;
        //mem_byte_enable <= mem_byte_enable;
        mem_read <= mem_read;
        mem_write <= mem_write;
    end
end

always_comb
begin
    out_load_pc <= load_pc;
    out_load_regfile <= load_regfile;
    out_load_dmar <= load_dmar;
    out_load_data_out <= load_data_out;
    out_pcmux_sel <= pcmux_sel;
    out_cmpop <= cmpop;
    out_alumux1_sel <= alumux1_sel;
    out_alumux2_sel <= alumux2_sel;
    out_regfilemux_sel <= regfilemux_sel;
    out_cmpmux_sel <= cmpmux_sel;
    out_aluop <= aluop;
    //out_mem_byte_enable <= mem_byte_enable;
    out_mem_read <= mem_read;
    out_mem_write <= mem_write;
end
*/

endmodule : control_word