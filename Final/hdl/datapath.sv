module datapath
import rv32i_types::*;
(
    input               clk, rst,

    input 				instr_mem_resp,
    input rv32i_word 	instr_mem_rdata,
	input 				data_mem_resp,
    input rv32i_word 	data_mem_rdata, 
    //input logic         pmem_read, pmem_write, pmem_resp, //icache_hit, dcache_miss,
    output logic 		instr_read,
	output rv32i_word 	instr_mem_address,
    output logic 		data_read,
    output logic 		data_write,
    output logic [3:0] 	data_mbe,
    output rv32i_word 	data_mem_address,
    output rv32i_word 	data_mem_wdata

    //CSR<->MMU Values
    // input logic exception,
    // output logic [31:0] satp, mstatus,
    // output logic flush_tlb
);

logic [2:0]  if_funct3,      id_funct3,          ex_funct3,          mem_funct3,          wb_funct3;
logic [6:0]  if_funct7,      id_funct7,          ex_funct7,          mem_funct7,          wb_funct7;
logic [6:0]  if_opcode,      id_opcode,          ex_opcode,          mem_opcode,          wb_opcode;
rv32i_word                   id_instr_mem_rdata, ex_instr_mem_rdata, mem_instr_mem_rdata, wb_instr_mem_rdata;

rv32i_word   if_i_imm,       id_i_imm,           ex_i_imm;
rv32i_word   if_s_imm,       id_s_imm,           ex_s_imm;
rv32i_word   if_b_imm,       id_b_imm,           ex_b_imm;
rv32i_word   if_u_imm,       id_u_imm,           ex_u_imm,           mem_u_imm,           wb_u_imm;
rv32i_word   if_j_imm,       id_j_imm,           ex_j_imm;
rv32i_word   if_z_imm,       id_z_imm,           ex_z_imm;
logic [4:0]  if_rs1,         id_rs1,             ex_rs1,             mem_rs1,             wb_rs1;
logic [4:0]  if_rs2,         id_rs2,             ex_rs2,             mem_rs2,             wb_rs2;
logic [4:0]  if_rd,          id_rd,              ex_rd,              mem_rd,              wb_rd;
logic [11:0] if_csr,         id_csr,             ex_csr,             mem_csr,             wb_csr;


rv32i_word   if_pc_out,      id_pc_out,          ex_pc_out,          mem_pc_out,          wb_pc_out;   
rv32i_word   if_pc_next,     id_pc_next,         ex_pc_next,         mem_pc_next,         wb_pc_next;   

rv32i_word                   id_rs1_out,         ex_rs1_out,         mem_rs1_out,         wb_rs1_out;
rv32i_word                   id_rs2_out,         ex_rs2_out,         mem_rs2_out,         wb_rs2_out;
rv32i_word                   id_csr_out,         ex_csr_out,         mem_csr_out,         wb_csr_out;


rv32i_control_word           id_word,            ex_word,            mem_word,            wb_word;

logic[3:0]                                       ex_mem_byte_enable, mem_mem_byte_enable, wb_mem_byte_enable;
rv32i_word                                       ex_alu_out,         mem_alu_out,         wb_alu_out;
rv32i_word                                       ex_cmp_out,         mem_cmp_out,         wb_cmp_out;
rv32i_word                                       ex_csr_func_out,    mem_csr_func_out,    wb_csr_func_out;
logic                                            ex_br_en,           mem_br_en,           wb_br_en;

rv32i_word                                                           mem_mem_data,        wb_mem_data;
rv32i_word                                                           mem_mem_rdata,       wb_mem_rdata;

rv32i_word                                                                                wb_regfilemux_out;
rv32i_word                                                                                wb_csr_regfilemux_out;


logic load_if_id, load_id_ex, load_ex_mem, load_mem_wb;

logic branch_taken, ex_branch, mem_branch, wb_branch;
logic load_hazard;

rv32i_opcode opcodes [5];

logic stall;//, s, mem_resp;

assign opcodes[0] = rv32i_opcode'(instr_mem_rdata[6:0]);
assign opcodes[1] = rv32i_opcode'(id_opcode);
assign opcodes[2] = rv32i_opcode'(ex_opcode);
assign opcodes[3] = rv32i_opcode'(mem_opcode);
assign opcodes[4] = rv32i_opcode'(wb_opcode);

//assign stall = (~instr_mem_resp && instr_read) || (~data_mem_resp && (data_read || data_write)) || (instr_mem_resp || data_mem_resp);
assign stall = (~instr_mem_resp && instr_read) || (~data_mem_resp && (data_read || data_write));

assign load_if_id = ~stall && ~load_hazard;
assign load_id_ex = ~stall && ~load_hazard;
assign load_ex_mem = ~stall;
assign load_mem_wb = ~stall;

assign instr_read = ~rst;
assign branch_taken = ex_branch || mem_branch || wb_branch;
//assign load_hazard = (mem_opcode == op_load) || (wb_opcode == op_load);

/***************************** Instruction Fetch ****************************/
rv32i_word pcmux_out, pc_out, mar_pc_next;
logic pc_branch;

/*
ir IR(
    .clk(clk),
    .rst(rst),
    //.load(load_ir),
    .load(~stall && ~load_hazard),
    //.in(mdrreg_out),
    .in(instr_mem_rdata),
    .funct3(if_funct3),
    .funct7(if_funct7),
    .opcode(if_opcode),
    .i_imm(if_i_imm),
    .s_imm(if_s_imm),
    .b_imm(if_b_imm),
    .u_imm(if_u_imm),
    .j_imm(if_j_imm),
    .rs1(if_rs1),
    .rs2(if_rs2),
    .rd(if_rd)
);*/

ir IR(
    .clk(clk),
    .rst(rst),
    .load(~stall && ~load_hazard),
    .in(instr_mem_rdata),
    .funct3(if_funct3),
    .funct7(if_funct7),
    .opcode(if_opcode),
    .i_imm(if_i_imm),
    .s_imm(id_s_imm),
    .b_imm(id_b_imm),
    .u_imm(id_u_imm),
    .j_imm(id_j_imm),
    .rs1(if_rs1),
    .rs2(id_rs2),
    .rd(if_rd),

    .z_imm(id_z_imm),
    .csr(id_csr)
);

register #(.width(32)) IF_pc_out ( .clk(clk), .rst(rst), .load(load_if_id), .in(instr_mem_address), .out(id_pc_out) );
register #(.width(32)) IF_pc_next ( .clk(clk), .rst(rst), .load(load_if_id), .in(mar_pc_next), .out(id_pc_next) );


pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(~stall && ~load_hazard),
    // .in(ex_branch ? ex_alu_out : pcmux_out),
    .in(pcmux_out),
    .out(pc_out)
);

register #(.width(32)) MAR_pc_next ( .clk(clk), .rst(rst), .load(load_if_id), .in(ex_branch ? ex_alu_out : pcmux_out), .out(mar_pc_next) );
register IMAR(
    .clk  (clk),
    .rst (rst),
    .load(~stall && ~load_hazard),
    .in   ({pc_out[31:2], 2'b00}),
    .out  (instr_mem_address)
);

always_comb begin : MUXES 
    unique case (ex_word.pcmux_sel)
        pcmux::pc_plus4: begin
            if(ex_branch == 1'b1)
                pcmux_out = ex_alu_out;
            else
                pcmux_out = pc_out + 4;
        end
        pcmux::alu_out:  pcmux_out = ex_alu_out;
        pcmux::alu_mod2: pcmux_out = {ex_alu_out[31:2], 2'b00};
    endcase
end

//Instruction Cache

/*****************************************************************************/

register #(.width(32)) IF_ID_inst_word ( .clk(clk), .rst(rst), .load(load_if_id), .in(instr_mem_rdata), .out(id_instr_mem_rdata) );
/*
register #(.width(3)) IF_ID_funct3 ( .clk(clk), .rst(rst), .load(load_if_id), .in(branch_taken ? 3'b000 : if_funct3), .out(id_funct3) );
register #(.width(7)) IF_ID_funct7 ( .clk(clk), .rst(rst), .load(load_if_id), .in(branch_taken ? 7'b0000000 : if_funct7), .out(id_funct7) );
register #(.width(7)) IF_ID_opcode ( .clk(clk), .rst(rst), .load(load_if_id), .in(branch_taken ? 7'b0010011 : if_opcode), .out(id_opcode) );
register #(.width(32)) IF_ID_i_imm ( .clk(clk), .rst(rst), .load(load_if_id), .in(branch_taken ? 32'b0 : if_i_imm), .out(id_i_imm) );
register #(.width(32)) IF_ID_s_imm ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_s_imm), .out(id_s_imm) );
register #(.width(32)) IF_ID_b_imm ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_b_imm), .out(id_b_imm) );
register #(.width(32)) IF_ID_u_imm ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_u_imm), .out(id_u_imm) );
register #(.width(32)) IF_ID_j_imm ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_j_imm), .out(id_j_imm) );
register #(.width(5)) IF_ID_rs1 ( .clk(clk), .rst(rst), .load(load_if_id), .in(branch_taken ? 5'b0 : if_rs1), .out(id_rs1) );
register #(.width(5)) IF_ID_rs2 ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_rs2), .out(id_rs2) );
register #(.width(5)) IF_ID_rd ( .clk(clk), .rst(rst), .load(load_if_id), .in(branch_taken ? 5'b0 : if_rd), .out(id_rd) );

register #(.width(32)) IF_ID_pc_out ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_pc_out), .out(id_pc_out) );
register #(.width(32)) IF_ID_pc_next ( .clk(clk), .rst(rst), .load(load_if_id), .in(if_pc_next), .out(id_pc_next) );
*/

always_comb begin
    if(branch_taken == 1'b1) begin
        id_funct3 = 3'b0;
        id_funct7 = 7'b0;
        id_opcode = 7'b0010011;
        id_i_imm = 32'b0;
        id_rs1 = 5'b0;
        id_rd = 5'b0;
    end
    else begin
        id_funct3 = if_funct3;
        id_funct7 = if_funct7;
        id_opcode = if_opcode;
        id_i_imm = if_i_imm;
        id_rs1 = if_rs1;
        id_rd = if_rd;
    end
end

/***************************** Instruction Decode ****************************/
rv32i_word forward_rs1_out, forward_rs2_out;
//logic exception;
//logic [31:0] satp, mstatus;
//logic flush_tlb;

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(wb_word.load_regfile),
    .in(wb_regfilemux_out),
    .src_a(id_rs1),
    .src_b(id_rs2),
    .dest(wb_rd),
    .reg_a(id_rs1_out),
    .reg_b(id_rs2_out)
);

csr_regfile csr_regfile(
    .clk(clk), 
    .rst(rst),
    .write_data(wb_csr_regfilemux_out),
    .in_csr(wb_csr),
    .out_csr(id_csr),
    .load_csr(wb_word.load_csr_regfile),
    .read_data(id_csr_out)

    //MMU Signals
    //.mstatus_out(mstatus), 
    //.satp_out(satp),
    //.exception(exception),
    //.flush_tlb(flush_tlb)
);

forwarding_unit FU (
    .id_rs1_out(id_rs1_out), .id_rs2_out(id_rs2_out), .ex_rs1_out(ex_rs1_out), .ex_rs2_out(ex_rs2_out),
    .ex_alu_out(ex_alu_out), .mem_alu_out(mem_alu_out), .wb_alu_out(wb_alu_out), 
    .ex_u_imm(ex_u_imm), .mem_u_imm(mem_u_imm), .wb_u_imm(wb_u_imm), 
    .ex_pc_out(ex_pc_out), .mem_pc_out(mem_pc_out), .wb_pc_out(wb_pc_out), 
    .ex_br_en({31'b0, ex_br_en}), .mem_br_en({31'b0, mem_br_en}), .wb_br_en({31'b0, wb_br_en}), 
    .mem_mem_rdata(mem_mem_rdata),
    .wb_regfilemux_out(wb_regfilemux_out),
    .i_op(id_opcode), .m_op(mem_opcode), .w_op(wb_opcode),
    .id_rs1(id_rs1), .id_rs2(id_rs2), .ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
    .ex_rd(ex_rd), .mem_rd(mem_rd), .wb_rd(wb_rd),
    .mem_mem_byte_enable(mem_mem_byte_enable),
    .load_hazard(load_hazard),
    .ex_regfilemux_sel(ex_word.regfilemux_sel), .mem_regfilemux_sel(mem_word.regfilemux_sel), .wb_regfilemux_sel(wb_word.regfilemux_sel),
    .ex_load_regfile(ex_word.load_regfile), .mem_load_regfile(mem_word.load_regfile), .wb_load_regfile(wb_word.load_regfile),
    .stall(stall),

    .forward_rs1_out(forward_rs1_out), .forward_rs2_out(forward_rs2_out)
);

/*****************************************************************************/
register #(.width(32)) ID_EX_pc_out ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_pc_out), .out(ex_pc_out) );
register #(.width(32)) ID_EX_pc_next ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_pc_next), .out(ex_pc_next) );
register #(.width(32)) IF_EX_inst_word ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_instr_mem_rdata), .out(ex_instr_mem_rdata) );
register #(.width(32)) ID_EX_i_imm ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_i_imm), .out(ex_i_imm) );
register #(.width(32)) ID_EX_s_imm ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_s_imm), .out(ex_s_imm) );
register #(.width(32)) ID_EX_b_imm ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_b_imm), .out(ex_b_imm) );
register #(.width(32)) ID_EX_u_imm ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_u_imm), .out(ex_u_imm) );
register #(.width(32)) ID_EX_j_imm ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_j_imm), .out(ex_j_imm) );
register #(.width(5)) ID_EX_rs1 ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 5'b0 : id_rs1), .out(ex_rs1) );
register #(.width(5)) ID_EX_rs2 ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 5'b0 : id_rs2), .out(ex_rs2) );
register #(.width(5)) ID_EX_rd ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 5'b0 : id_rd), .out(ex_rd) );

register #(.width(32)) ID_EX_rs1_out ( .clk(clk), .rst(rst), .load(load_id_ex || load_hazard), .in(branch_taken ? 32'b0 : forward_rs1_out), .out(ex_rs1_out) );
register #(.width(32)) ID_EX_rs2_out ( .clk(clk), .rst(rst), .load(load_id_ex || load_hazard), .in(branch_taken ? 32'b0 : forward_rs2_out), .out(ex_rs2_out) );

register #(.width(32)) ID_EX_z_imm ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_z_imm), .out(ex_z_imm) );
register #(.width(12)) ID_EX_csr ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 12'b0 : id_csr), .out(ex_csr) );
register #(.width(32)) ID_EX_csr_out ( .clk(clk), .rst(rst), .load(load_id_ex), .in(branch_taken ? 32'b0 : id_csr_out), .out(ex_csr_out) );

control_word ID_EX_Control (
    .clk(clk), .rst(rst), .load(load_id_ex),

    .opcode_in(branch_taken ? 7'b0010011 : id_opcode),
    .funct3_in(branch_taken ? 3'b000 : id_funct3),
    .funct7_in(branch_taken ? 7'b0000000 : id_funct7),

    .opcode_out(ex_opcode),
    .funct3_out(ex_funct3),
    .funct7_out(ex_funct7),
    .word_out(ex_word)
);

/********************************** Execute **********************************/
rv32i_word alumux1_out, alumux2_out, cmp_mux_out;

alu ALU(
    .aluop(ex_word.aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(ex_alu_out)
);

cmp CMP(
    .cmpop(ex_word.cmpop),
    .rs1_out(ex_rs1_out),
    .cmp_mux_out(cmp_mux_out),
    .br_en(ex_br_en)
);


always_comb begin : EX_MUXES    
    unique case (ex_word.alumux1_sel)
        alumux::rs1_out: alumux1_out = ex_rs1_out;
        alumux::pc_out:  alumux1_out = ex_pc_out;
    endcase

    unique case (ex_word.alumux2_sel)
        alumux::i_imm:   alumux2_out = ex_i_imm;
        alumux::u_imm:   alumux2_out = ex_u_imm;
        alumux::b_imm:   alumux2_out = ex_b_imm;
        alumux::s_imm:   alumux2_out = ex_s_imm;
        alumux::j_imm:   alumux2_out = ex_j_imm;
        alumux::rs2_out: alumux2_out = ex_rs2_out;
    endcase

    unique case (ex_word.cmpmux_sel)
        cmpmux::rs2_out:    cmp_mux_out = ex_rs2_out;
        cmpmux::i_imm:      cmp_mux_out = ex_i_imm;
    endcase

    
    if (((ex_br_en == 1'b1 && rv32i_opcode'(ex_opcode) == op_br) || ex_opcode == op_jal || ex_opcode == op_jalr) && load_hazard == 1'b0)
        ex_branch = 1'b1;
    else
        ex_branch = 1'b0;

    ex_mem_byte_enable = 4'b0000;

    unique case(rv32i_opcode'(ex_opcode))
        op_load : begin
            unique case(load_funct3_t'(ex_funct3))
                lw : begin
                    ex_mem_byte_enable = 4'b1111;
                end
                lh : begin
                    ex_mem_byte_enable = 4'b0011 << ex_alu_out[1:0];
                end
                lhu : begin
                    ex_mem_byte_enable = 4'b0011 << ex_alu_out[1:0];
                end
                lb : begin
                    ex_mem_byte_enable = 4'b0001 << ex_alu_out[1:0];
                end
                lbu : begin
                    ex_mem_byte_enable = 4'b0001 << ex_alu_out[1:0];
                end
            endcase
        end
        op_store : begin
            unique case(store_funct3_t'(ex_funct3))
            sw : begin
                ex_mem_byte_enable = 4'b1111;
            end
            sh : begin
                ex_mem_byte_enable = 4'b0011 << ex_alu_out[1:0];
            end
            sb : begin
                ex_mem_byte_enable = 4'b0001 << ex_alu_out[1:0];
            end
            endcase
        end
        default : ;
    endcase

    unique case(csr_funct3_t'(ex_funct3))
        csrrw : ex_csr_func_out = ex_rs1_out;
        csrrs : ex_csr_func_out = ex_csr_out | ex_rs1_out;
        csrrc : ex_csr_func_out = ex_csr_out & ~(ex_rs1_out);
        csrrwi: ex_csr_func_out = ex_z_imm;
        csrrsi: ex_csr_func_out = ex_csr_out | ex_z_imm;
        csrrci: ex_csr_func_out = ex_csr_out & ~(ex_z_imm);
        default: ex_csr_func_out = 32'b0;
    endcase
end
/*****************************************************************************/
register #(.width(32)) EX_MEM_pc_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_pc_out), .out(mem_pc_out) );
register #(.width(32)) EX_MEM_pc_next ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_branch ? ex_alu_out : ex_pc_next), .out(mem_pc_next) );

register #(.width(32)) EX_MEM_inst_word ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_instr_mem_rdata), .out(mem_instr_mem_rdata) );
register #(.width(32)) EX_MEM_u_imm ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_u_imm), .out(mem_u_imm) );
register #(.width(5)) EX_MEM_rs1 ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), /*.in(load_hazard ? 5'b0 : ex_rs1),*/ .in(ex_rs1), .out(mem_rs1) );
register #(.width(5)) EX_MEM_rs2 ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_rs2), .out(mem_rs2) );
register #(.width(5)) EX_MEM_rd ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(load_hazard ? 5'b0 : ex_rd), .out(mem_rd) );

register #(.width(32)) EX_MEM_rs1_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_rs1_out), .out(mem_rs1_out) );
register #(.width(32)) EX_MEM_rs2_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_rs2_out), .out(mem_rs2_out) );

register #(.width(32)) EX_MEM_alu_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_rd != 5'b0 ? ex_alu_out : 32'b0), .out(mem_alu_out) );
register #(.width(32)) EX_MEM_cmp_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_cmp_out), .out(mem_cmp_out) );
register #(.width(1)) EX_MEM_br_en ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_br_en), .out(mem_br_en) );
register #(.width(1)) EX_MEM_branch ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_branch), .out(mem_branch) );

register #(.width(12)) EX_MEM_csr ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_csr), .out(mem_csr) );
register #(.width(32)) EX_MEM_csr_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_csr_out), .out(mem_csr_out) );
register #(.width(32)) EX_MEM_csr_func_out ( .clk(clk), .rst(rst || load_hazard), .load(load_ex_mem), .in(ex_csr_func_out), .out(mem_csr_func_out) );

control_word EX_MEM_Control (
    .clk(clk), .rst(rst), .load(load_ex_mem),

    .opcode_in(load_hazard ? 7'b0010011 : ex_opcode),
    .funct3_in(load_hazard ? 3'b000 : ex_funct3),
    .funct7_in(load_hazard ? 7'b0000000 : ex_funct7),

    .opcode_out(mem_opcode),
    .funct3_out(mem_funct3),
    .funct7_out(mem_funct7),
    .word_out(mem_word)
);

register #(.width(4)) EX_MEM_mem_byte_enable( .clk(clk), .rst(rst), .load(load_ex_mem), .in(ex_mem_byte_enable), .out(mem_mem_byte_enable) );

/********************************** Memory ***********************************/
assign mem_mem_rdata = data_mem_rdata; 
assign data_read = mem_word.mem_read;
assign data_write = mem_word.mem_write;
assign data_mbe = mem_mem_byte_enable;

register mem_data_out(
    .clk(clk),
    .rst(rst),
    .load(ex_word.load_data_out && ~stall),
    .in(ex_rs2_out),
    .out(mem_mem_data)
);

register DMAR(
    .clk  (clk),
    .rst (rst),
    .load (ex_word.load_dmar && ~stall),
    .in   ({ex_alu_out[31:2], 2'b00}),
    .out  (data_mem_address)
);

//Data Cache

always_comb begin : MEM_MUXES
    unique case (mem_mem_byte_enable)
        4'b0000:
            data_mem_wdata = '0;
        4'b0001:
            data_mem_wdata = {24'b0, mem_mem_data[7:0]};
        4'b0010:
            data_mem_wdata = {16'b0, mem_mem_data[7:0], 8'b0};
        4'b0100:
            data_mem_wdata = {8'b0, mem_mem_data[7:0], 16'b0};
        4'b1000:
            data_mem_wdata = {mem_mem_data[7:0], 24'b0};
        4'b0011:
            data_mem_wdata = {16'b0, mem_mem_data[15:0]};
        4'b1100:
            data_mem_wdata = {mem_mem_data[15:0], 16'b0};
        4'b1111:
            data_mem_wdata = mem_mem_data;
        default:
            data_mem_wdata = mem_mem_data;
    endcase
end

/*****************************************************************************/
rv32i_word wb_data_mem_rdata, wb_data_mem_wdata, wb_data_mem_address;

register #(.width(32)) MEM_WB_pc_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_pc_out), .out(wb_pc_out) );
register #(.width(32)) MEM_WB_pc_next ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_pc_next), .out(wb_pc_next) );

register #(.width(32)) MEM_WB_inst_word ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_instr_mem_rdata), .out(wb_instr_mem_rdata) );
register #(.width(5)) MEM_WB_rs1 ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_rs1), .out(wb_rs1) );
register #(.width(5)) MEM_WB_rs2 ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_rs2), .out(wb_rs2) );
register #(.width(5)) MEM_WB_rd ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_rd), .out(wb_rd) );
register #(.width(32)) MEM_WB_u_imm ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_u_imm), .out(wb_u_imm) );

register #(.width(32)) MEM_WB_rs1_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_rs1_out), .out(wb_rs1_out) );
register #(.width(32)) MEM_WB_rs2_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_rs2_out), .out(wb_rs2_out) );

register #(.width(32)) MEM_WB_alu_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_alu_out), .out(wb_alu_out) );
register #(.width(32)) MEM_WB_cmp_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_cmp_out), .out(wb_cmp_out) );
register #(.width(1)) MEM_WB_br_en ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_br_en), .out(wb_br_en) );
register #(.width(1)) MEM_WB_branch ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_branch), .out(wb_branch) );

register #(.width(12)) MEM_WB_csr ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_csr), .out(wb_csr) );
register #(.width(32)) MEM_WB_csr_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_csr_out), .out(wb_csr_out) );
register #(.width(32)) MEM_WB_csr_func_out ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_csr_func_out), .out(wb_csr_func_out) );

register #(.width(32)) MEM_WB_mem_rdata ( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_mem_rdata), .out(wb_mem_rdata) );

control_word MEM_WB_Control (
    .clk(clk), .rst(rst), .load(load_mem_wb),

    .opcode_in(mem_opcode),
    .funct3_in(mem_funct3),
    .funct7_in(mem_funct7),

    .opcode_out(wb_opcode),
    .funct3_out(wb_funct3),
    .funct7_out(wb_funct7),
    .word_out(wb_word)
);

register #(.width(4)) MEM_WB_mem_byte_enable( .clk(clk), .rst(rst), .load(load_mem_wb), .in(mem_mem_byte_enable), .out(wb_mem_byte_enable) );
register #(.width(32)) MEM_WB_data_mem_wdata( .clk(clk), .rst(rst), .load(load_mem_wb), .in(data_mem_wdata), .out(wb_data_mem_wdata) );
register #(.width(32)) MEM_WB_data_mem_rdata( .clk(clk), .rst(rst), .load(load_mem_wb), .in(data_mem_rdata), .out(wb_data_mem_rdata) );
register #(.width(32)) MEM_WB_data_mem_address( .clk(clk), .rst(rst), .load(load_mem_wb), .in(data_mem_address), .out(wb_data_mem_address) );


/********************************* Write Back ********************************/
rv32i_word wb_rmask, wb_wmask;

assign wb_rmask = (rv32i_opcode'(wb_opcode) == op_load) ? wb_mem_byte_enable : 32'b0;
assign wb_wmask = (rv32i_opcode'(wb_opcode) == op_store) ? wb_mem_byte_enable : 32'b0;

always_comb begin : WB_MUXES
    unique case (wb_word.regfilemux_sel)
        regfilemux::alu_out:    wb_regfilemux_out = wb_alu_out;
        regfilemux::br_en:      wb_regfilemux_out = {31'b0, wb_br_en};
        regfilemux::u_imm:      wb_regfilemux_out = wb_u_imm;
        regfilemux::lw:         wb_regfilemux_out = wb_mem_rdata;
        regfilemux::pc_plus4: begin
            if(wb_rd != 5'b0)
                wb_regfilemux_out = wb_pc_out + 4;
            else
                wb_regfilemux_out = 32'b0;
        end
        regfilemux::lb: begin
            case(wb_mem_byte_enable)
                4'b0001:
                    wb_regfilemux_out = rv32i_word'(signed'(wb_mem_rdata[7:0]));
                4'b0010:
                    wb_regfilemux_out = rv32i_word'(signed'(wb_mem_rdata[15:8]));
                4'b0100:
                    wb_regfilemux_out = rv32i_word'(signed'(wb_mem_rdata[23:16]));
                4'b1000:
                    wb_regfilemux_out = rv32i_word'(signed'(wb_mem_rdata[31:24]));
                default: 
                    wb_regfilemux_out = wb_mem_rdata;
            endcase
            //regfilemux_out = rv32i_word'(signed'(mdrreg_out));
        end
        regfilemux::lbu: begin
            case(wb_mem_byte_enable)
                4'b0001:
                    wb_regfilemux_out = {24'b0, wb_mem_rdata[7:0]};
                4'b0010:
                    wb_regfilemux_out = {24'b0, wb_mem_rdata[15:8]};
                4'b0100:
                    wb_regfilemux_out = {24'b0, wb_mem_rdata[23:16]};
                4'b1000:
                    wb_regfilemux_out = {24'b0, wb_mem_rdata[31:24]};
                default: 
                    wb_regfilemux_out = wb_mem_rdata;
            endcase
        end
        regfilemux::lh: begin
            case(wb_mem_byte_enable)
                4'b0011:
                    wb_regfilemux_out = rv32i_word'(signed'(wb_mem_rdata[15:0]));
                4'b1100:
                    wb_regfilemux_out = rv32i_word'(signed'(wb_mem_rdata[31:16]));
                default: 
                    wb_regfilemux_out = wb_mem_rdata;
            endcase
        end
        regfilemux::lhu: begin
            case(wb_mem_byte_enable)
                4'b0011:
                    wb_regfilemux_out = {16'b0, wb_mem_rdata[15:0]};
                4'b1100:
                    wb_regfilemux_out = {16'b0, wb_mem_rdata[31:16]};
                default: 
                    wb_regfilemux_out = wb_mem_rdata;
            endcase
        end
        regfilemux::csr_out: begin
            if(wb_rd != 5'b0)
                wb_regfilemux_out = wb_csr_out;
            else
                wb_regfilemux_out = 32'b0;
        end
    endcase

    wb_csr_regfilemux_out = wb_csr_func_out;
end

/*****************************************************************************/

endmodule : datapath