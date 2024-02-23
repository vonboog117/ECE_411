/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address, //?
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic[s_line-1:0] mem_wdata256, mem_rdata256;
logic[s_mask-1:0] mem_byte_enable256;
logic read_hit, write_hit, read_miss, write_miss, evict;
logic[s_mask-1:0] load_data;
logic load_tag, load_valid, load_dirty, load_lru;
logic valid, dirty, addr_cpu;
//logic cache_read;

cache_control control
(.*);
/*
    input clk, -
    input rst, -

    input logic read_hit, -
    input logic write_hit, -
    input logic read_miss, -
    input logic write_miss, -
    input logic pmem_resp, - 

    output logic load_data, load_tag, load_valid, load_dirty, load_lru, - 
    output logic valid, dirty, - 
    output logic pmem_read, pmem_write, - 
    output logic mem_resp -
*/

cache_datapath datapath
(.*);
/* 
    input clk, -
    input rst, - 

    input [s_line-1:0] mem_wdata256, pmem_rdata, - 
    input rv32i_word mem_address, - 
    input logic[3:0] mem_byte_enable, - 
    input logic load_data, load_tag, load_valid, load_dirty, load_lru, -
    input logic dirty, valid, - 
    input logic mem_read, mem_write, - 

    output [s_line-1:0] mem_rdata256, pmem_wdata, -
    output logic read_hit, read_miss, write_hit, write_miss -
 */

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(mem_rdata256),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache
