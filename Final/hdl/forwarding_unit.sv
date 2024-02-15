module forwarding_unit
import rv32i_types::*;
(
    input rv32i_word id_rs1_out, id_rs2_out, ex_rs1_out, ex_rs2_out, 
    input rv32i_word ex_alu_out, mem_alu_out, wb_alu_out, 
    input rv32i_word ex_u_imm, mem_u_imm, wb_u_imm, 
    input rv32i_word ex_pc_out, mem_pc_out, wb_pc_out, 
    input rv32i_word ex_br_en, mem_br_en, wb_br_en, 
    input rv32i_word mem_mem_rdata,
    input rv32i_word wb_regfilemux_out,
    input regfilemux::regfilemux_sel_t  ex_regfilemux_sel, mem_regfilemux_sel, wb_regfilemux_sel,
    //input rv32i_opcode mem_opcode, wb_opcode,
    input logic[6:0] i_op, m_op, w_op,
    input logic[4:0] id_rs1, id_rs2, ex_rs1, ex_rs2,
    input logic[4:0] ex_rd, mem_rd, wb_rd,
    input logic[3:0] mem_mem_byte_enable,
    input logic ex_load_regfile, mem_load_regfile, wb_load_regfile,
    input logic stall,

    output rv32i_word forward_rs1_out, forward_rs2_out,
    output logic load_hazard
    //output logic forward_rs1, forward_rs2
);

rv32i_opcode id_opcode, mem_opcode, wb_opcode;

rv32i_word mem_load_data;

assign id_opcode = rv32i_opcode'(i_op);
assign mem_opcode = rv32i_opcode'(m_op);
assign wb_opcode = rv32i_opcode'(w_op);

always_comb begin
    forward_rs1_out = id_rs1_out;
    forward_rs2_out = id_rs2_out;
    load_hazard = 1'b0;

    if (ex_load_regfile == 1'b1 && id_rs1 == ex_rd && id_rs1 != 5'b000) begin    //If the operation in the EX stage will load the regfile and the rd = ex_rs1
        if(ex_regfilemux_sel == regfilemux::br_en)
            forward_rs1_out = ex_br_en;
        else if (ex_regfilemux_sel == regfilemux::u_imm)
            forward_rs1_out = ex_u_imm;
        else if (ex_regfilemux_sel == regfilemux::pc_plus4) begin
            if(ex_rd != 5'b0)
                forward_rs1_out = ex_pc_out + 4;
            else
                forward_rs1_out = 32'b0;
        end
        else
            forward_rs1_out = ex_alu_out;
    end 
    else begin
        if (mem_load_regfile == 1'b1 && id_rs1 == mem_rd && id_rs1 != 5'b000) begin
            if(mem_regfilemux_sel == regfilemux::br_en)
                forward_rs1_out = mem_br_en;
            else if (mem_regfilemux_sel == regfilemux::u_imm)
                forward_rs1_out = mem_u_imm;
            else if (mem_regfilemux_sel == regfilemux::pc_plus4) begin
                if(mem_rd != 5'b0)
                    forward_rs1_out = mem_pc_out + 4;
                else
                    forward_rs1_out = 32'b0;
            end
            else
                forward_rs1_out = mem_alu_out;

            if(mem_opcode == op_load)
                forward_rs1_out = mem_mem_rdata;
        end
        else begin
            if (wb_load_regfile == 1'b1 && id_rs1 == wb_rd && id_rs1 != 5'b000) begin
                if (wb_opcode == op_load || wb_opcode == op_jal || wb_opcode == op_jalr) begin
                    forward_rs1_out = wb_regfilemux_out;
                end
                else begin
                    if(wb_regfilemux_sel == regfilemux::br_en)
                        forward_rs1_out = wb_br_en;
                    else if (wb_regfilemux_sel == regfilemux::u_imm)
                        forward_rs1_out = wb_u_imm;
                    else if (wb_regfilemux_sel == regfilemux::pc_plus4) begin
                        if(wb_rd != 5'b0)
                            forward_rs1_out = wb_pc_out + 4;
                        else
                            forward_rs1_out = 32'b0;
                    end
                    else
                        forward_rs1_out = wb_alu_out;
                end
            end
        end
        if (mem_opcode == op_load && id_rs1 == mem_rd && id_opcode != op_load && stall == 1'b0) begin
            forward_rs1_out = mem_load_data;
            //if(ex_rs2 != mem_rd)begin
            //forward_rs2_out = ex_rs2_out;
            //end
        end
    end

    if (ex_load_regfile == 1'b1 && id_rs2 == ex_rd && id_rs2 != 5'b000) begin    //If the operation in the EX stage will load the regfile and the rd = ex_rs2
        if(ex_regfilemux_sel == regfilemux::br_en)
            forward_rs2_out = ex_br_en;
        else if (ex_regfilemux_sel == regfilemux::u_imm)
            forward_rs2_out = ex_u_imm;
        else if (ex_regfilemux_sel == regfilemux::pc_plus4) begin
            if(ex_rd != 5'b0)
                forward_rs2_out = ex_pc_out + 4;
            else
                forward_rs2_out = 32'b0;
        end
        else
            forward_rs2_out = ex_alu_out;
    end 
    else begin
        if (mem_load_regfile == 1'b1 && id_rs2 == mem_rd && id_rs2 != 5'b000) begin
            if(mem_regfilemux_sel == regfilemux::br_en)
                forward_rs2_out = mem_br_en;
            else if (mem_regfilemux_sel == regfilemux::u_imm)
                forward_rs2_out = mem_u_imm;
            else if (mem_regfilemux_sel == regfilemux::pc_plus4) begin
                if(mem_rd != 5'b0)
                    forward_rs2_out = mem_pc_out + 4;
                else
                    forward_rs2_out = 32'b0;
            end
            else
                forward_rs2_out = mem_alu_out;

            if(mem_opcode == op_load)
                forward_rs2_out = mem_mem_rdata;
        end
        else begin
            if (wb_load_regfile == 1'b1 && id_rs2 == wb_rd && id_rs2 != 5'b000) begin
                if (wb_opcode == op_load || wb_opcode == op_jal || wb_opcode == op_jalr) begin
                    forward_rs2_out = wb_regfilemux_out;
                end
                else begin
                    if(wb_regfilemux_sel == regfilemux::br_en)
                        forward_rs2_out = wb_br_en;
                    else if (wb_regfilemux_sel == regfilemux::u_imm)
                        forward_rs2_out = wb_u_imm;
                    else if (wb_regfilemux_sel == regfilemux::pc_plus4) begin
                        if(wb_rd != 5'b0)
                            forward_rs2_out = wb_pc_out + 4;
                        else
                            forward_rs2_out = 32'b0;
                    end
                    else
                        forward_rs2_out = wb_alu_out;
                end
            end
        end
        if (mem_opcode == op_load && id_rs2 == mem_rd && id_opcode != op_load && stall == 1'b0) begin
            forward_rs2_out = mem_load_data;
            //if(ex_rs1 != mem_rd)begin
            //forward_rs1_out = ex_rs1_out;
            //end
        end
    end

/*
    if (mem_opcode == op_load && id_rs1 == mem_rd && id_opcode != op_load && stall == 1'b0) begin
        forward_rs1_out = mem_load_data;
        //if(ex_rs2 != mem_rd)begin
        //forward_rs2_out = ex_rs2_out;
        //end
    end


    if (mem_opcode == op_load && id_rs2 == mem_rd && id_opcode != op_load && stall == 1'b0) begin
        forward_rs2_out = mem_load_data;
        //if(ex_rs1 != mem_rd)begin
        //forward_rs1_out = ex_rs1_out;
        //end
    end
*/
    if (mem_opcode == op_load && ex_rs1 == mem_rd && stall == 1'b0) begin
        load_hazard = 1'b1;
        forward_rs1_out = mem_load_data;
        if(ex_rs2 != mem_rd)begin
            forward_rs2_out = ex_rs2_out;
        end
    end


    if (mem_opcode == op_load && ex_rs2 == mem_rd && stall == 1'b0) begin
        load_hazard = 1'b1;
        forward_rs2_out = mem_load_data;
        if(ex_rs1 != mem_rd)begin
            forward_rs1_out = ex_rs1_out;
        end
    end

    /*
    if (wb_opcode == op_load && ex_rs1 == wb_rd && stall == 1'b0) begin
        load_hazard = 1'b1;
        forward_rs1_out = wb_regfilemux_out;
        //if(ex_rs2 != mem_rd)begin
        forward_rs2_out = ex_rs2_out;
        //end
    end


    if (wb_opcode == op_load && ex_rs2 == wb_rd && stall == 1'b0) begin
        load_hazard = 1'b1;
        forward_rs2_out = wb_regfilemux_out;
        //if(ex_rs1 != mem_rd)begin
        forward_rs1_out = ex_rs1_out;
        //end
    end
    */
end

always_comb begin
    mem_load_data = 32'b0;
    unique case (mem_regfilemux_sel)
        regfilemux::lw:         mem_load_data = mem_mem_rdata;
        regfilemux::lb: begin
            case(mem_mem_byte_enable)
                4'b0001:
                    mem_load_data = rv32i_word'(signed'(mem_mem_rdata[7:0]));
                4'b0010:
                    mem_load_data = rv32i_word'(signed'(mem_mem_rdata[15:8]));
                4'b0100:
                    mem_load_data = rv32i_word'(signed'(mem_mem_rdata[23:16]));
                4'b1000:
                    mem_load_data = rv32i_word'(signed'(mem_mem_rdata[31:24]));
                default: 
                    mem_load_data = mem_mem_rdata;
            endcase
        end
        regfilemux::lbu: begin
            case(mem_mem_byte_enable)
                4'b0001:
                    mem_load_data = {24'b0, mem_mem_rdata[7:0]};
                4'b0010:
                    mem_load_data = {24'b0, mem_mem_rdata[15:8]};
                4'b0100:
                    mem_load_data = {24'b0, mem_mem_rdata[23:16]};
                4'b1000:
                    mem_load_data = {24'b0, mem_mem_rdata[31:24]};
                default: 
                    mem_load_data = mem_mem_rdata;
            endcase
        end
        regfilemux::lh: begin
            case(mem_mem_byte_enable)
                4'b0011:
                    mem_load_data = rv32i_word'(signed'(mem_mem_rdata[15:0]));
                4'b1100:
                    mem_load_data = rv32i_word'(signed'(mem_mem_rdata[31:16]));
                default: 
                    mem_load_data = mem_mem_rdata;
            endcase
        end
        regfilemux::lhu: begin
            case(mem_mem_byte_enable)
                4'b0011:
                    mem_load_data = {16'b0, mem_mem_rdata[15:0]};
                4'b1100:
                    mem_load_data = {16'b0, mem_mem_rdata[31:16]};
                default: 
                    mem_load_data = mem_mem_rdata;
            endcase
        end
        default: ;
    endcase
end

endmodule : forwarding_unit