
module mp4
import rv32i_types::*;
(
    input clk,
    input rst,

    input pmem_resp,
    input [63:0] pmem_rdata,
	//To physical memory
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata

);

//*Note about caches, cacheline adaptor, and arbiter.*
//A lot of these units use identical names for signals and I can't have overlapping names with different signals. Also it's confusing.
//So to prevent myself from losing my mind, I labeled every signal with 2 letters. The first letter represents the unit outputing that signal.
//The second letter represents the unit taking that signal as input. Memory and CPU signals don't have these labels so that they match the high level inputs and outputs
// i = instruction cache, d = data cache, a = arbiter, c = cacheline adaptor, 

//Cache and arbiter signals
logic data_mem_resp_ad, pmem_read_ac, pmem_write_ac, pmem_resp_ca, instr_mem_read_ia, instr_mem_resp_ai, data_mem_read_da, data_mem_write_da;
rv32i_word data_mem_address_da, instr_mem_address_ia, pmem_address_ac;
logic [255:0] pmem_wburst_ac, pmem_rburst_ca, instr_mem_burst_ai, data_cache_burst_da, data_mem_burst_ad;
logic [255:0] pmem_wdatai;
//logic [3:0] mem_byte_enable_cpui;
//logic [31:0] mem_wdata_cpui;
logic pmem_writei;//, mem_writei;
//CPU and cache signals
logic instr_read, instr_mem_resp, data_read, data_write, data_mem_resp;
rv32i_word instr_mem_address, instr_mem_rdata, data_mem_address, data_mem_wdata, data_mem_rdata;
logic [3:0] data_mbe;

cacheline_adaptor cl_adaptor(.clk(clk), .reset_n(~rst), 
    //Arbiter lines
    .line_i(pmem_wburst_ac), .line_o(pmem_rburst_ca), .address_i(pmem_address_ac), .read_i(pmem_read_ac), .write_i(pmem_write_ac), .resp_o(pmem_resp_ca), 
    //Memory lines
    .burst_i(pmem_rdata), .burst_o(pmem_wdata), .address_o(pmem_address), .read_o(pmem_read), .write_o(pmem_write), .resp_i(pmem_resp));

arbiter arbiter(
    .clk(clk), .rst(rst),
    //Instruction cache lines
    .instr_mem_address(instr_mem_address_ia), .instr_mem_read(instr_mem_read_ia), .instr_mem_burst(instr_mem_burst_ai), .instr_mem_resp(instr_mem_resp_ai), 
    //Data Cache lines
    .data_cache_burst(data_cache_burst_da), .data_mem_address(data_mem_address_da), .data_mem_read(data_mem_read_da), .data_mem_write(data_mem_write_da), .data_mem_burst(data_mem_burst_ad), 
    .data_mem_resp(data_mem_resp_ad),
    //Cacheline Adaptor lines
    .pmem_rburst(pmem_rburst_ca), .pmem_read(pmem_read_ac), .pmem_write(pmem_write_ac), .pmem_resp(pmem_resp_ca), .pmem_wburst(pmem_wburst_ac), .pmem_address(pmem_address_ac));

cache instruction_cache(.clk(clk), .rst(rst), 
    //Arbiter lines
    .pmem_resp(instr_mem_resp_ai), .pmem_rdata(instr_mem_burst_ai), .pmem_address(instr_mem_address_ia), .pmem_wdata(pmem_wdatai), .pmem_read(instr_mem_read_ia), .pmem_write(pmem_writei),
    //CPU lines
    .mem_read(instr_read), .mem_write(1'b0), .mem_byte_enable_cpu(4'b0), .mem_address(instr_mem_address), .mem_wdata_cpu(32'b0), .mem_resp(instr_mem_resp),
    .mem_rdata_cpu(instr_mem_rdata));

cache data_cache(.clk(clk), .rst(rst), 
    //Arbiter lines
    .pmem_resp(data_mem_resp_ad), .pmem_rdata(data_mem_burst_ad), .pmem_address(data_mem_address_da), .pmem_wdata(data_cache_burst_da), .pmem_read(data_mem_read_da), 
    .pmem_write(data_mem_write_da), 
    //CPU lines
    .mem_read(data_read), .mem_write(data_write), .mem_byte_enable_cpu(data_mbe), .mem_address(data_mem_address), .mem_wdata_cpu(data_mem_wdata), .mem_resp(data_mem_resp),
    .mem_rdata_cpu(data_mem_rdata)); 


//logic[31:0] mmu_mem_data;
//logic[31:0] satp, mstatus;
//logic[31:0] mmu_p_addr, mmu_pte_addr;
//logic mmu_mem_read, exception, mmu_mem_resp, mmu_resp, flush_tlb;


datapath datapath(.*);

/*mmu mmu(.clk(clk), .rst(rst),
        .v_addr(pmem_address),
        .mstatus(mstatus), .satp(satp),
        .pte_in(mmu_mem_data),
        .instr_read(instr_mem_read_ia), .load(data_mem_read_da), .store(data_mem_write_da),
        .mem_resp(mmu_mem_resp || pmem_resp), .translate(pmem_read || pmem_write), .flush_tlb(flush_tlb),
        .p_addr(mmu_p_addr),
        .pte_addr(mmu_pte_addr),
        .mem_read(mmu_mem_read), .mmu_resp(mmu_resp), .exception(exception));

fake_mem mem(.mem_addr(mmu_pte_addr),
             .mem_read(mmu_mem_read),
             .mem_data(mmu_mem_data),
             .mem_resp(mmu_mem_resp));
*/


endmodule : mp4