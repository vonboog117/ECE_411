
module control
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic mem_resp,
    input logic [1:0] addr_1_0,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output branch_funct3_t cmpop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    output logic mem_read,
    output logic mem_write,
    output logic[3:0] mem_byte_enable
    //output state_t cur_state
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;
logic[1:0] addr_off, n_addr_off;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;


assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = '0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = '1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                //lh, lhu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                //lb, lbu: rmask = 4'bXXXX /* Modify for MP1 Final */ ;
                lh, lhu: rmask = addr_off[1] ? 4'b1100 : 4'b0011;
                lb, lbu: begin
                    case(addr_off)
                        2'b00:
                            rmask = 4'b0001;
                        2'b01:
                            rmask = 4'b0010;
                        2'b10:
                            rmask = 4'b0100;
                        2'b11:
                            rmask = 4'b1000;
                    endcase
                end
                default: trap = '1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                //sh: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                sh: wmask = addr_off[1] ? 4'b1100 : 4'b0011;
                //sb: wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                sb: begin
                    case(addr_off)
                        2'b00:
                            wmask = 4'b0001;
                        2'b01:
                            wmask = 4'b0010;
                        2'b10:
                            wmask = 4'b0100;
                        2'b11:
                            wmask = 4'b1000;
                    endcase
                end
                default: trap = '1;
            endcase
        end

        default: trap = '1;
    endcase
end
/*****************************************************************************/
enum int unsigned {
    /* List of states */
    Fetch1, Fetch2, Fetch3,
    Decode,
    SLTI,
    SLTIU,
    SLT,
    SLTU,
    SRAI,
    SRA,
    S_Imm,
    S_Reg,
    SUB,
    BR,
    Calc_AddrLW, Calc_AddrLH, Calc_AddrLB, Calc_AddrLHU, Calc_AddrLBU, 
    Calc_AddrSW, Calc_AddrSH, Calc_AddrSB,
    LDRW1, LDRW2,
    LDRH1, LDRH2,
    LDRHU1, LDRHU2,
    LDRB1, LDRB2,
    LDRBU1, LDRBU2,
    STRW1, STRW2,
    STRH1, STRH2,
    STRB1, STRB2,
    AUIPC,
    LUI,
    JAL1,
    //JAL2,
    JALR1
    //JALR2
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
    cmpop = branch_funct3;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
    aluop = alu_ops'(funct3);
    mem_byte_enable = 4'b0000;
    mem_read = 1'b0;
    mem_write = 1'b0;
    n_addr_off = 2'b00;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    regfilemux_sel = sel;
    load_regfile = 1'b1;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    marmux_sel = sel;
    load_mar = 1'b1;
endfunction

function void loadMDR();
    load_mdr = 1'b1;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    /* Student code here */
    alumux1_sel = sel1;
    alumux2_sel = sel2;

    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    cmpmux_sel = sel;
    cmpop = op;
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    unique case(state)
        Fetch1:
            loadMAR(marmux::pc_out);
        Fetch2: begin
            loadMDR();
            mem_read = 1'b1;
        end
        Fetch3:
            load_ir = 1'b1;
        SLTI: begin
            loadRegfile(regfilemux::br_en);
            loadPC(pcmux::pc_plus4);
            setCMP(cmpmux::i_imm, blt);
            //rs1_addr = rs1;
        end
        SLTIU: begin
            loadRegfile(regfilemux::br_en);
            loadPC(pcmux::pc_plus4);
            setCMP(cmpmux::i_imm, bltu);
            //rs1_addr = rs1;
        end
        SLT: begin
            loadRegfile(regfilemux::br_en);
            loadPC(pcmux::pc_plus4);
            setCMP(cmpmux::rs2_out, blt);
            //rs1_addr = rs1;
        end
        SLTU: begin
            loadRegfile(regfilemux::br_en);
            loadPC(pcmux::pc_plus4);
            setCMP(cmpmux::rs2_out, bltu);
            //rs1_addr = rs1;
        end
        SRAI: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
        end
        SRA: begin
            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
        end
        S_Imm: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(arith_funct3));
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
        end
        S_Reg: begin
            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(arith_funct3));
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
        end
        SUB: begin
            setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
        end
        BR: begin
            setCMP(cmpmux::rs2_out, branch_funct3);
            setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
            if(br_en)
                loadPC(pcmux::alu_out);
            else
                loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            //rs2_addr = rs2;
        end
        Calc_AddrLW: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
        end
        Calc_AddrLH: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            case(addr_1_0)
                2'b00:
                    n_addr_off = 2'b00;
                2'b01:  ;
                2'b10:
                    n_addr_off = 2'b10;
                2'b11:  ;
            endcase
        end
        Calc_AddrLB: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            case(addr_1_0)
                2'b00:
                    n_addr_off = 2'b00;
                2'b01:  
                    n_addr_off = 2'b01;
                2'b10:
                    n_addr_off = 2'b10;
                2'b11:  
                    n_addr_off = 2'b11;
            endcase
        end
        Calc_AddrLHU: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            case(addr_1_0)
                2'b00:
                    n_addr_off = 2'b00;
                2'b01:  ;
                2'b10:
                    n_addr_off = 2'b10;
                2'b11:  ;
            endcase
        end
        Calc_AddrLBU: begin
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            case(addr_1_0)
                2'b00:
                    n_addr_off = 2'b00;
                2'b01:  
                    n_addr_off = 2'b01;
                2'b10:
                    n_addr_off = 2'b10;
                2'b11:  
                    n_addr_off = 2'b11;
            endcase
        end
        Calc_AddrSW: begin
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            load_data_out = 1'b1;
        end
        Calc_AddrSH: begin
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            load_data_out = 1'b1;
            case(addr_1_0)
                2'b00:
                    n_addr_off = 2'b00;
                2'b01:  ;
                2'b10:
                    n_addr_off = 2'b10;
                2'b11:  ;
            endcase
        end
        Calc_AddrSB: begin
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
            loadMAR(marmux::alu_out);
            load_data_out = 1'b1;
            case(addr_1_0)
                2'b00:
                    n_addr_off = 2'b00;
                2'b01:  
                    n_addr_off = 2'b01;
                2'b10:
                    n_addr_off = 2'b10;
                2'b11:  
                    n_addr_off = 2'b11;
            endcase
        end
        LDRW1: begin
            loadMDR();
            mem_read = 1'b1;
            mem_byte_enable = rmask;
        end 
        LDRW2: begin
            loadRegfile(regfilemux::lw);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            mem_byte_enable = rmask;
        end
        LDRH1: begin
            loadMDR();
            n_addr_off = addr_off;
            mem_read = 1'b1;
            mem_byte_enable = rmask;
        end 
        LDRH2: begin
            loadRegfile(regfilemux::lh);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            n_addr_off = addr_off;
            mem_byte_enable = rmask;
        end
        LDRHU1: begin
            loadMDR();
            n_addr_off = addr_off;
            mem_read = 1'b1;
            mem_byte_enable = rmask;
        end  
        LDRHU2: begin
            loadRegfile(regfilemux::lhu);
            loadPC(pcmux::pc_plus4);
            n_addr_off = addr_off;
            //rs1_addr = rs1;
            mem_byte_enable = rmask;
        end
        LDRB1: begin
            loadMDR();
            n_addr_off = addr_off;
            mem_read = 1'b1;
            mem_byte_enable = rmask;
        end  
        LDRB2: begin
            loadRegfile(regfilemux::lb);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            n_addr_off = addr_off;
            mem_byte_enable = rmask;
        end
        LDRBU1: begin
            loadMDR();
            n_addr_off = addr_off;
            mem_read = 1'b1;
            mem_byte_enable = rmask;
        end  
        LDRBU2: begin
            loadRegfile(regfilemux::lbu);
            loadPC(pcmux::pc_plus4);
            n_addr_off = addr_off;
            //rs1_addr = rs1;
            mem_byte_enable = rmask;
        end
        STRW1: begin
            mem_write = 1'b1;
            mem_byte_enable = wmask;
        end
        STRW2: begin
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            //rs2_addr = rs2;
            mem_byte_enable = wmask;
        end
        STRH1: begin
            n_addr_off = addr_off;
            mem_write = 1'b1;
            mem_byte_enable = wmask;
        end
        STRH2: begin
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            //rs2_addr = rs2;
            n_addr_off = addr_off;
            mem_byte_enable = wmask;
        end
        STRB1: begin
            n_addr_off = addr_off;
            mem_write = 1'b1;
            mem_byte_enable = wmask;
        end
        STRB2: begin
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
            //rs2_addr = rs2;
            n_addr_off = addr_off;
            mem_byte_enable = wmask;
        end
        AUIPC: begin
            setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            loadRegfile(regfilemux::alu_out);
            loadPC(pcmux::pc_plus4);
        end
        LUI: begin
            loadRegfile(regfilemux::u_imm);
            loadPC(pcmux::pc_plus4);
            //rs1_addr = rs1;
        end
        JAL1: begin
            //rd <- PC + 4
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
            loadPC(pcmux::alu_out);
        end
        // JAL2: begin
        //     //PC <- PC + j_imm
        //     setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
        //     loadPC(pcmux::alu_out);
        // end
        JALR1: begin
            //rd <- PC + 4
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
            loadPC(pcmux::alu_mod2);
        end
        // JALR2: begin
        //     //PC <- rs1 + i_imm
        //     setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
        //     loadPC(pcmux::alu_mod2);
        // end
        default: ;
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    next_states = state;
    unique case(state)
        Fetch1:
            next_states = Fetch2;
        Fetch2: begin
            if(mem_resp == 1'b0)
                next_states = Fetch2;
            else
                next_states = Fetch3;
        end
        Fetch3:
            next_states = Decode;
        Decode: begin
            unique case(opcode)
                op_lui:     // 0110111
                    next_states = LUI;
                op_auipc:   // 0010111
                    next_states = AUIPC;
                op_jal:     // 1101111
                    next_states = JAL1;
                op_jalr:    // 1100111
                    next_states = JALR1;
                op_br:      // 1100011
                    next_states = BR;
                op_load:    // 0000011
                    case(load_funct3)
                        lb:
                            next_states = Calc_AddrLB;
                        lh:
                            next_states = Calc_AddrLH;
                        lw:
                            next_states = Calc_AddrLW;
                        lbu:
                            next_states = Calc_AddrLBU;
                        lhu:
                            next_states = Calc_AddrLHU;
                    endcase
                op_store:   // 0100011
                    case(store_funct3)
                        sb:
                            next_states = Calc_AddrSB;
                        sh:
                            next_states = Calc_AddrSH;
                        sw:
                            next_states = Calc_AddrSW;
                    endcase
                op_imm: begin     // 0010011
                    next_states = S_Imm;
                    if(arith_funct3 == slt) begin
                        next_states = SLTI;
                    end
                    else if(arith_funct3 == sltu) begin
                        next_states = SLTIU;
                    end
                    else if(arith_funct3 == sr) begin
                        if(funct7 == 7'b0100000) begin
                            next_states = SRAI;
                        end
                    end
                end
                op_reg: begin     // 0110011 S-type
                    next_states = S_Reg;
                    if(arith_funct3 == slt) begin
                        next_states = SLT;
                    end
                    else if(arith_funct3 == sltu) begin
                        next_states = SLTU;
                    end
                    else if(arith_funct3 == sr) begin
                        if(funct7 == 7'b0100000) begin
                            next_states = SRA;
                        end
                    end
                    else if(arith_funct3 == add) begin
                        if(funct7 == 7'b0100000) begin
                            next_states = SUB;
                        end
                    end
                end
                default: 
                    next_states = Fetch1;
            endcase
        end
        SLTI, SLTIU, SRAI, SRA, S_Imm:
            next_states = Fetch1;
        S_Reg, SUB, SLT, SLTU:
            next_states = Fetch1;
        BR:
            next_states = Fetch1;
        Calc_AddrLW:
            next_states = LDRW1;
        Calc_AddrLH:
            next_states = LDRH1;
        Calc_AddrLHU:
            next_states = LDRHU1;    
        Calc_AddrLB:
            next_states = LDRB1;
        Calc_AddrLBU:
            next_states = LDRBU1;
        Calc_AddrSW:
            next_states = STRW1;
        Calc_AddrSH:
            next_states = STRH1;
        Calc_AddrSB:
            next_states = STRB1;
        LDRW1: begin
            if(mem_resp == 1'b0)
                next_states = LDRW1;
            else
                next_states = LDRW2;
        end 
        LDRH1: begin
            if(mem_resp == 1'b0)
                next_states = LDRH1;
            else
                next_states = LDRH2;
        end 
        LDRHU1: begin
            if(mem_resp == 1'b0)
                next_states = LDRHU1;
            else
                next_states = LDRHU2;
        end  
        LDRB1: begin
            if(mem_resp == 1'b0)
                next_states = LDRB1;
            else
                next_states = LDRB2;
        end  
        LDRBU1: begin
            if(mem_resp == 1'b0)
                next_states = LDRBU1;
            else
                next_states = LDRBU2;
        end  
        STRW1: begin
            if(mem_resp == 1'b0)
                next_states = STRW1;
            else
                next_states = STRW2;
        end 
        STRH1: begin
            if(mem_resp == 1'b0)
                next_states = STRH1;
            else
                next_states = STRH2;
        end  
        STRB1: begin
            if(mem_resp == 1'b0)
                next_states = STRB1;
            else
                next_states = STRB2;
        end  
        LDRW2, LDRH2, LDRHU2, LDRB2, LDRBU2, STRW2, STRH2, STRB2:
            next_states = Fetch1;
        AUIPC, LUI:
            next_states = Fetch1;
        JAL1: 
            //next_states = JAL2;
            next_states = Fetch1;
        JALR1: 
            //next_states = JALR2;
            next_states = Fetch1;
        // JAL2, JALR2: 
        //     next_states = Fetch1;
        default: ;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if(rst) begin
        state <= Fetch1;
        addr_off <= 2'b00;
    end
    else begin
        state <= next_states;
        addr_off <= n_addr_off;
    end
end

endmodule : control
