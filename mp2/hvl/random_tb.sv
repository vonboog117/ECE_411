
/**
 * Generates constrained random vectors with which to drive the DUT.
 * Recommended usage is to test arithmetic and comparator functionality,
 * as well as branches.
 *
 * Randomly testing load/stores will require building a memory model,
 * which you can do using a SystemVerilog associative array:
 *     logic[7:0] byte_addressable_mem [logic[31:0]]
 *   is an associative array with value type logic[7:0] and
 *   key type logic[31:0].
 * See IEEE 1800-2017 Clause 7.8
**/
module random_tb
import rv32i_types::*;
(
    tb_itf.tb itf,
    tb_itf.mem mem_itf
);

/**
 * SystemVerilog classes can be defined inside modules, in which case
 *   their usage scope is constrained to that module
 * RandomInst generates constrained random test vectors for your
 * rv32i DUT.
 * As is, RandomInst only supports generation of op_imm opcode instructions.
 * You are highly encouraged to expand its functionality.
**/
class RandomInst;
    rv32i_reg reg_range[$];
    arith_funct3_t arith3_range[$];

    /** Constructor **/
    function new();
        arith_funct3_t af3;
        af3 = af3.first;

        for (int i = 0; i < 32; ++i)
            reg_range.push_back(i);
        do begin
            arith3_range.push_back(af3);
            af3 = af3.next;
        end while (af3 != af3.first);

    endfunction

    function rv32i_word register_reg(
        ref rv32i_reg rd_range[$] = reg_range,
        ref arith_funct3_t funct3_range[$] = arith3_range,
        ref rv32i_reg rs1_range[$] = reg_range,
        ref rv32i_reg rs2_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic[6:0] funct7;
                rv32i_reg rs2;
                rv32i_reg rs1;
                logic[2:0] funct3;
                logic[4:0] rd;
                rv32i_opcode opcode;
            } r_word;
        } word;

        word.rvword = '0;
        word.r_word.opcode = op_reg;

        // Set rd register
        do begin
            word.r_word.rd = $urandom();
        end while (!(word.r_word.rd inside {rd_range}));

        // set funct3
        do begin
            word.r_word.funct3 = $urandom();
        end while (!(word.r_word.funct3 inside {funct3_range}));

        // set rs1
        do begin
            word.r_word.rs1 = $urandom();
        end while (!(word.r_word.rs1 inside {rs1_range}));

        do begin
            word.r_word.rs1 = $urandom();
        end while (!(word.r_word.rs1 inside {rs1_range}));

        word.r_word.funct7[5] = 1'b0;

        return word.rvword;
    endfunction

    function rv32i_word immediate(
        ref rv32i_reg rd_range[$] = reg_range,
        ref arith_funct3_t funct3_range[$] = arith3_range,
        ref rv32i_reg rs1_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [31:20] i_imm;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_imm;

        // Set rd register
        do begin
            word.i_word.rd = $urandom();
        end while (!(word.i_word.rd inside {rd_range}));

        // set funct3
        do begin
            word.i_word.funct3 = $urandom();
        end while (!(word.i_word.funct3 inside {funct3_range}));

        // set rs1
        do begin
            word.i_word.rs1 = $urandom();
        end while (!(word.i_word.rs1 inside {rs1_range}));

        // set immediate value
        word.i_word.i_imm = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word store(
        ref arith_funct3_t funct3_range[$] = arith3_range,
        ref rv32i_reg rs1_range[$] = reg_range,
        ref rv32i_reg rs2_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [6:0] s_imm11_5;
                rv32i_reg rs2;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] s_imm4_0;
                rv32i_opcode opcode;
            } s_word;
        } word;

        word.rvword = '0;
        word.s_word.opcode = op_store;
        word.s_word.s_imm4_0 = $urandom();

        // set funct3
        //do begin
        //    word.s_word.funct3 = $urandom();
        //end while (!(word.s_word.funct3 inside {funct3_range}));
        word.s_word.funct3 = 3'b010;

        // Set rs1 register
        do begin
            word.s_word.rs1 = $urandom();
        end while (!(word.s_word.rs1 inside {rs1_range}));

        // set rs2
        do begin
            word.s_word.rs2 = $urandom();
        end while (!(word.s_word.rs2 inside {rs2_range}));

        word.s_word.s_imm11_5 = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word branch(
        ref arith_funct3_t funct3_range[$] = arith3_range,
        ref rv32i_reg rs1_range[$] = reg_range,
        ref rv32i_reg rs2_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic b_imm12;
                logic [5:0] b_imm10_5;
                rv32i_reg rs2;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [3:0] b_imm4_1;
                logic b_imm11;
                rv32i_opcode opcode;
            } b_word;
        } word;

        word.rvword = '0;
        word.b_word.opcode = op_br;
        word.b_word.b_imm11 = $urandom();

        do begin
            word.b_word.b_imm4_1 = $urandom();
        end while(!(word.b_word.b_imm4_1[0] == 0));

        // set funct3
        do begin
            word.b_word.funct3 = $urandom();
        end while (!(word.b_word.funct3 inside {funct3_range}));

        // Set rs1 register
        do begin
            word.b_word.rs1 = $urandom();
        end while (!(word.b_word.rs1 inside {rs1_range}));

        // set rs2
        do begin
            word.b_word.rs2 = $urandom();
        end while (!(word.b_word.rs2 inside {rs2_range}));

        word.b_word.b_imm10_5 = $urandom();
        word.b_word.b_imm12 = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word u_type(
        ref rv32i_reg rd_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [31:12] u_imm;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } u_word;
        } word;

        word.rvword = '0;
        word.u_word.opcode = op_lui;

        // Set rd register
        do begin
            word.u_word.rd = $urandom();
        end while (!(word.u_word.rd inside {rd_range}));

        // set immediate value
        word.u_word.u_imm = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word jal(
        ref rv32i_reg rd_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic j_imm20;
                logic [10:1] j_imm10_1;
                logic j_imm11;
                logic [19:12] j_imm19_12;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } j_word;
        } word;

        word.rvword = '0;
        word.j_word.opcode = op_jal;

        // Set rd register
        do begin
            word.j_word.rd = $urandom();
        end while (!(word.j_word.rd inside {rd_range}));

        // set immediate value
        word.j_word.j_imm19_12 = $urandom();
        word.j_word.j_imm11 = $urandom();
        word.j_word.j_imm10_1 = $urandom();
        word.j_word.j_imm20 = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word jalr(
        ref rv32i_reg rd_range[$] = reg_range,
        ref arith_funct3_t funct3_range[$] = arith3_range,
        ref rv32i_reg rs1_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [31:20] i_imm;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_jalr;

        // Set rd register
        do begin
            word.i_word.rd = $urandom();
        end while (!(word.i_word.rd inside {rd_range}));

        // set funct3
        // do begin
        //     word.i_word.funct3 = $urandom();
        // end while (!(word.i_word.funct3 inside {funct3_range}));
        word.i_word.funct3 = 3'b000;

        // set rs1
        do begin
            word.i_word.rs1 = $urandom();
        end while (!(word.i_word.rs1 inside {rs1_range}));

        // set immediate value
        word.i_word.i_imm = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word specific(
        ref rv32i_reg rd_range[$] = reg_range,
        ref arith_funct3_t funct3_range[$] = arith3_range,
        ref rv32i_reg rs1_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [31:20] i_imm;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_imm;

        // Set rd register
        do begin
            word.i_word.rd = $urandom();
        end while (!(word.i_word.rd inside {rd_range}));

        //// set funct3
        //do begin
        //    word.i_word.funct3 = $urandom();
        //end while (!(word.i_word.funct3 inside {funct3_range}));
        word.i_word.funct3 = 3'b100;

        // set rs1
        do begin
            word.i_word.rs1 = $urandom();
        end while (!(word.i_word.rs1 inside {rs1_range}));

        // set immediate value
        word.i_word.i_imm = $urandom();

        return word.rvword;
    endfunction

endclass

RandomInst generator = new();

task immediate_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting Immediate Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.immediate();
        mem_itf.mcb.resp <= 1;
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing Immediate Tests");
endtask

task branch_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting Branch Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.branch();
        mem_itf.mcb.resp <= 1;
        //$display("%d", count);
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing Branch Tests");
endtask

task reg_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting Register Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.register_reg();
        mem_itf.mcb.resp <= 1;
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing Register Tests");
endtask

task store_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting Store Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.store();
        mem_itf.mcb.resp <= 1;
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing Store Tests");
endtask

task u_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting U Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.u_type();
        mem_itf.mcb.resp <= 1;
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing U Tests");
endtask

task jump_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting Jump Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.jal();
        //mem_itf.mcb.rdata <= generator.jalr();
        mem_itf.mcb.resp <= 1;
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing Jump Tests");
endtask

task specific_tests(input int count);
    @(posedge itf.clk iff itf.rst == 1'b0)
    $display("Starting Specific Tests");
    repeat (count) begin
        @(mem_itf.mcb iff mem_itf.mcb.read);
        mem_itf.mcb.rdata <= generator.specific();
        mem_itf.mcb.resp <= 1;
        @(mem_itf.mcb) mem_itf.mcb.resp <= 1'b0;
    end
    $display("Finishing Specific Tests");
endtask

initial begin
    //immediate_tests(10000);
    //branch_tests(10);
    //reg_tests(100);
    //store_tests(100);
    //u_tests(100);
    jump_tests(10);
    //specific_tests(1);
    $finish;
end

endmodule : random_tb


