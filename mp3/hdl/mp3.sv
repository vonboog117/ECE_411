module mp3
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic rst_n;

//Signals between CPU and Cache
rv32i_word mem_rdata, mem_wdata;
rv32i_word mem_address;
logic [3:0] mem_byte_enable;
logic mem_read, mem_write;
logic cache_resp;

//Signals between Adaptor and Cache
logic[255:0] pmem_rdata256, pmem_wdata256;
rv32i_word pmem_address_cache;
logic pmem_read_cache, pmem_write_cache;
logic pmem_resp_cache;

assign rst_n = ~rst;

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(
    .clk(clk),
    .rst(rst), 
    .mem_resp(cache_resp),
    .mem_rdata(mem_rdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_address(mem_address),
    .mem_wdata(mem_wdata)
);


// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk(clk), 
    .rst(rst), 

    /* CPU memory signals */
    .mem_address(mem_address),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_resp(cache_resp),

    /* Physical memory signals */
    .pmem_address(pmem_address_cache), 
    .pmem_rdata(pmem_rdata256), 
    .pmem_wdata(pmem_wdata256), 
    .pmem_read(pmem_read_cache), 
    .pmem_write(pmem_write_cache), 
    .pmem_resp(pmem_resp_cache) 
);

// Hint: What do you need to interface between cache and main memory?
cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(rst_n),

    // Port to LLC (Lowest Level Cache)
    .line_i(pmem_wdata256),
    .line_o(pmem_rdata256),
    .address_i(pmem_address_cache),
    .read_i(pmem_read_cache),
    .write_i(pmem_write_cache),
    .resp_o(pmem_resp_cache),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp3