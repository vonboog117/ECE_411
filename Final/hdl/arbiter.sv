module arbiter
import rv32i_types::*;
(
    input clk, rst,
    //Instruction Cache
    input rv32i_word instr_mem_address,
    input logic instr_mem_read,
    output logic[255:0] instr_mem_burst,
    output logic instr_mem_resp,
    //Data Cache
    input logic[255:0] data_cache_burst,
    input rv32i_word data_mem_address,
    input logic data_mem_read, data_mem_write,
    output logic[255:0] data_mem_burst,
    output logic data_mem_resp,
    //Memory
    input logic[255:0] pmem_rburst,
    input logic pmem_resp,
    output logic pmem_read, pmem_write,
    output logic[255:0] pmem_wburst,
    output rv32i_word pmem_address
);
//list of arbiter states
enum int unsigned {
    idle, data, instr
} state, next_states;

function void set_defaults();//all outputs default to 0
    instr_mem_burst = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    instr_mem_resp = 1'b0;
    data_mem_burst = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    data_mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    pmem_wburst = 256'h0000000000000000000000000000000000000000000000000000000000000000;
    pmem_address = 32'h00000000;
endfunction

always_comb
begin : state_actions
    set_defaults();
    unique case (state)
        idle:begin
            //wait state
        end   
        data:begin
            data_mem_resp=pmem_resp;
            pmem_address=data_mem_address; 
            if(data_mem_read)begin 
                pmem_read = data_mem_read; 
                data_mem_burst = pmem_rburst; 
            end 
            else if(data_mem_write) begin  
                pmem_write=data_mem_write; 
                pmem_wburst = data_cache_burst;
            end
        end      
        instr:begin
            instr_mem_burst=pmem_rburst; 
            instr_mem_resp=pmem_resp;
            pmem_read=instr_mem_read; 
            pmem_address=instr_mem_address;
        end 
    endcase
end

always_comb
begin : next_state_logic
    unique case (state)
        idle:begin
            if(data_mem_read || data_mem_write) begin
                next_states=data; 
            end
            else if(instr_mem_read) begin 
                next_states=instr;
            end 
            else begin
                next_states=idle; 
            end
        end
        data:begin
            if(pmem_resp) begin 
                next_states=idle; 
            end
            else begin 
                next_states=data;
            end
        end
        instr:begin
            if(pmem_resp) begin
                next_states=idle;
            end
            else begin
                next_states=instr;
            end
        end
        
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) begin
        state <= idle;
    end
    else begin 
        state <= next_states;
    end
end

// always_comb 
// begin
//     set_defaults();
//     if(data_mem_read || data_mem_write) begin
//         data_mem_resp = pmem_resp;
//         pmem_address = data_mem_address;
//         pmem_read = data_mem_read;
//         data_mem_burst = pmem_rburst;
//         pmem_wburst = data_cache_burst;
//         pmem_write = data_mem_write;
//     // if(data_mem_read) begin
//     //     pmem_address = data_mem_address;
//     //     pmem_read = data_mem_read;
//     //     data_mem_burst = pmem_rburst;
//     // end
//     // else if(data_mem_write) begin
//     //     pmem_wburst = data_cache_burst;
//     //     pmem_write = data_mem_write;
//     // end
        
//     end
//     else if(instr_mem_read)begin
//     pmem_address = instr_mem_address;
//     instr_mem_burst = pmem_rburst;
//     instr_mem_resp = pmem_resp;
//     pmem_read = instr_mem_read;
//    end
// end


endmodule