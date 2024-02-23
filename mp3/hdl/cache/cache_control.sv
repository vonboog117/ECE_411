/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input clk,
    input rst,

    input logic read_hit,
    input logic write_hit,
    input logic read_miss,
    input logic write_miss,
    input logic evict,
    input logic pmem_resp,

    output logic[31:0] load_data,
    output logic load_tag, load_valid, load_dirty, load_lru,
    output logic valid, dirty,
    output logic pmem_read, pmem_write, //cache_read,
    output logic mem_resp, addr_cpu
);

logic hit, miss;
logic hold, next_hold;

assign hit = read_hit || write_hit;
assign miss = read_miss || write_miss;

enum int unsigned {
    Idle, HitR, HitW, Miss, Miss_Evict
}state, next_state;

function void set_defaults();
    load_data = '0;
    load_tag = 1'b0;
    load_valid = 1'b0;
    load_dirty = 1'b0;
    load_lru = 1'b0;
    valid = 1'b0;
    dirty = 1'b0;
    mem_resp = 1'b0;
    next_hold = 1'b1;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    addr_cpu = 1'b0;
    //cache_read = 1'b0;
endfunction

always_comb begin
    set_defaults();

    unique case(state)
        Idle: begin
            if(hit == 1'b1 || miss == 1'b1) begin
                next_hold = ~hold;
            end 
        end 
        HitR: begin
            load_lru = 1'b1;
            //next_hold = ~hold;
            //mem_resp = hold ? 1'b0 : 1'b1;
            mem_resp = 1'b1;
        end
        HitW: begin
            load_lru = 1'b1;
            load_dirty = 1'b1;
            dirty = 1'b1;
            load_data = '1;
            //
            //next_hold = ~hold;
            //mem_resp = hold ? 1'b0 : 1'b1;
            mem_resp = 1'b1;
        end
        Miss: begin
            pmem_read = 1'b1;
            addr_cpu = 1'b1;
            //pmem_write = write_miss;
            //byte_enable
            //load_data = '1;
            if(pmem_resp == 1'b1) begin
                load_data = '1;
                load_tag = 1'b1;
                load_valid = 1'b1;
                load_dirty = 1'b1;
            end
            //load_lru = 1'b1;

            valid = 1'b1;
            dirty = 1'b0;
        end
        Miss_Evict: begin
            pmem_write = 1'b1;
            addr_cpu = 1'b0;
            //cache_read = 1'b1;
            if(pmem_resp == 1'b1) begin
                load_valid = 1'b1;
                valid = 1'b0;    
            end            
            //mem_resp = 1'b1;
        end
    endcase
end

//Hit states should not hold, Idle while mem_read is high should be the first cycle of a hit

always_comb begin
    next_state = state;
    unique case(state)
        Idle: begin
            next_state = Idle;
            if(read_hit == 1'b1 && write_hit == 1'b0 && miss == 1'b0 && evict == 1'b0) begin
                if(hold == 1'b0) 
                    next_state = HitR;
            end
            else if(read_hit == 1'b0 && write_hit == 1'b1 && miss == 1'b0 && evict == 1'b0) begin
                if(hold == 1'b0) 
                    next_state = HitW;
            end
            else if(read_hit == 1'b0 && write_hit == 1'b0 && miss == 1'b1 && evict == 1'b0) begin
                if(hold == 1'b0) 
                    next_state = Miss;
            end
            else if(read_hit == 1'b0 && write_hit == 1'b0 && miss == 1'b1 && evict == 1'b1) begin
                if(hold == 1'b0) 
                    next_state = Miss_Evict;
            end
        end
        HitR: begin
            next_state = Idle;
            //if(hold == 1'b1)
            //    next_state = HitR;
        end
        HitW: begin
            next_state = Idle;
            //if(hold == 1'b1)
            //    next_state = HitW;
        end
        Miss: begin
            next_state = Idle;
            if(pmem_resp == 1'b0)
                next_state = Miss;
        end
        Miss_Evict: begin
            next_state = Miss;
            if(pmem_resp == 1'b0)
                next_state = Miss_Evict;
        end
    endcase
end

always_ff @(posedge clk) begin
    if(rst) begin
        state <= Idle;
        hold <= 1'b1;
    end
    else begin
        state <= next_state;
        hold <= next_hold;
    end
end

endmodule : cache_control
