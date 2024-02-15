`define PAGE_SIZE 4096
`define NUM_LEVELS 2
`define PTE_SIZE 4

module mmu_control(
    input logic clk, rst,
    input logic[19:0] root_ppn, pte_ppn,
    input logic tlb_hit, tlb_resp, mem_resp, translate, exception, pt_read,
    input logic itlb_hit, dtlb_hit,
    input logic instr_read, load, store,
    input logic mode, flush_tlb,
    output logic[31:0] a,
    output logic load_pte, tlb_read, tlb_write, mmu_resp, mem_read,
    output int i
);

    enum int unsigned{
        // idle,
        check_tlb,
        read_mem,
        check_excep,
        fail,
        success
    } state, next_state;
    
    int i_next;

    logic[31:0] a_next;
    logic resp_next;

    always_comb begin
        load_pte = 1'b0;
        tlb_read = 1'b0;
        tlb_write = 1'b0;
        resp_next = 1'b0;
        mem_read = 1'b0;
        a_next = a;
        i_next = i;

        unique case(state)
            check_tlb: begin
                tlb_read = 1'b1;
                a_next = {root_ppn, 12'b0};
            end
            read_mem: begin
                load_pte = 1'b1;
                mem_read = 1'b1;
            end
            check_excep: begin
                a_next = {pte_ppn, 12'b0};
                i_next = i - 1;
            end
            fail: begin
                i_next = 1;
            end
            success: begin
                resp_next = 1'b1;
                if(tlb_hit == 1'b0) begin
                    tlb_write = 1'b1;
                end
                a_next = {root_ppn, 12'b0};
                i_next = 1;
            end
        endcase
    end

    always_comb begin
        next_state = state;

        unique case(state)
            check_tlb: begin
                //if(itlb_hit == 1'b1 && /*tlb_resp == 1'b1 &&*/ translate == 1'b1) begin
                if(((itlb_hit == 1'b1 && instr_read == 1'b1) || (dtlb_hit == 1'b1 && (load == 1'b1 || store == 1'b1))) && translate == 1'b1) begin
                    next_state = success;
                end
                else begin
                    if(tlb_hit == 1'b0 && translate == 1'b1) begin
                        next_state = read_mem;
                    end
                end
            end
            read_mem: begin
                if(mem_resp == 1'b1) begin
                    next_state = check_excep;
                end
            end
            check_excep: begin
                next_state = read_mem;
                if(exception == 1'b1)
                    next_state = fail;
                else if(exception == 1'b0 && pt_read == 1'b0)
                    next_state = success;
            end
            fail: begin
                //next_state = state;
                if(translate == 1'b0)
                    next_state = check_tlb;
            end
            success: begin
                //next_state = check_tlb;
                if(translate == 1'b0)
                    next_state = check_tlb;
                if(mode == 1'b0)
                    next_state = state;
            end
        endcase
    end

    always_ff @(posedge clk) begin: next_state_assignment
        if (rst) begin
            if(mode == 1'b1)
                state <= check_tlb;
            else
                state <= success;
            a <= {root_ppn, 12'b0};
            i <= 1;
            mmu_resp <= 1'b0;
        end
        else begin 
            state <= next_state;
            a <= a_next;
            i <= i_next;
            mmu_resp <= resp_next;
        end
    end 

endmodule