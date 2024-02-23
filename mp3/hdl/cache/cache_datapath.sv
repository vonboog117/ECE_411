/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
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

    input logic[s_line-1:0] mem_wdata256, pmem_rdata,
    input logic[31:0] mem_address,
    input logic[s_mask-1:0] mem_byte_enable256,
    input logic[s_mask-1:0] load_data,
    input logic load_tag, load_valid, load_dirty, load_lru,
    input logic dirty, valid, addr_cpu,
    input logic mem_read, mem_write, //cache_read,

    output logic[s_line-1:0] mem_rdata256, pmem_wdata,
    output logic[31:0] pmem_address,
    output logic read_hit, read_miss, write_hit, write_miss, evict
);

logic[s_line-1:0] way_0_out, way_1_out, datain;

logic[s_tag-1:0] tag, tag_0_out, tag_1_out, tag_value;
logic[s_index-1:0] index;
logic[s_offset-1:0] offset;

logic[1:0] dirty_out, valid_out;
logic hit, miss, evict_0, evict_1, way_0_hit, way_1_hit, hit_way;
logic lru_in, lru_out, lru_value;

logic[s_mask-1:0] load_way_0, load_way_1, load_way;
logic load_tag_0, load_tag_1, load_valid_0, load_valid_1, load_dirty_0, load_dirty_1;

assign tag = mem_address[31:8];
assign index = mem_address[7:5];
assign offset = mem_address[4:0];

assign hit = way_0_hit || way_1_hit;
assign miss = hit ? 1'b0 : 1'b1;
//assign evict = miss && valid_out[0] && valid_out[1];
assign evict_0 = evict && ~lru_value;
assign evict_1 = evict && lru_value;
assign read_hit = hit && mem_read;
assign read_miss = miss && mem_read;
assign write_hit = hit && mem_write;
assign write_miss = miss && mem_write;

data_array way_0 (
                  .clk(clk),
                  //.read(mem_read || cache_read),
                  .read(1'b1),
                  .write_en(load_way_0),
                  //.write_en(mem_byte_enable256),
                  .rindex(index),
                  .windex(load_data ? index : ~index),
                  .datain(datain),
                  .dataout(way_0_out)
);

data_array way_1 (
                  .clk(clk),
                  //.read(mem_read || cache_read),
                  .read(1'b1),
                  .write_en(load_way_1),
                  //.write_en(mem_byte_enable256),
                  .rindex(index),
                  .windex(load_data ? index : ~index),
                  .datain(datain),
                  .dataout(way_1_out)
);

array #(.s_index(3), .width(24)) tag_0 (
                                        .clk(clk),
                                        .read(1'b1),
                                        .load(load_tag_0),
                                        .rindex(index),
                                        .windex(load_tag ? index : ~index),
                                        .datain(tag),
                                        .dataout(tag_0_out)
);

array #(.s_index(3), .width(24)) tag_1 (
                                        .clk(clk),
                                        .read(1'b1),
                                        .load(load_tag_1),
                                        .rindex(index),
                                        .windex(load_tag ? index : ~index),
                                        .datain(tag),
                                        .dataout(tag_1_out)
);

array valid_0 (
               .clk(clk),
               .read(1'b1),
               .load(load_valid_0),
               .rindex(index),
               .windex(load_valid ? index : ~index),
               .datain(valid),
               .dataout(valid_out[0])
);

array valid_1 (
               .clk(clk),
               .read(1'b1),
               .load(load_valid_1),
               .rindex(index),
               .windex(load_valid ? index : ~index),
               .datain(valid),
               .dataout(valid_out[1])
);

array dirty_0 (
               .clk(clk),
               .read(1'b1),
               .load(load_dirty_0),
               .rindex(index),
               .windex(load_dirty ? index : ~index),
               .datain(dirty),
               .dataout(dirty_out[0])
);

array dirty_1 (
               .clk(clk),
               .read(1'b1),
               .load(load_dirty_1),
               .rindex(index),
               .windex(load_dirty ? index : ~index),
               .datain(dirty),
               .dataout(dirty_out[1])
);

array lru (
           .clk(clk),
           .read(1'b1),
           .load(load_lru),
           .rindex(index),
           .windex(load_lru ? index : ~index),
           .datain(lru_in),
           .dataout(lru_out)
);

always_comb begin : muxes
    //Assign outgoing data based on which Way had a hit (defaults to Way 0)
    if(hit_way == 1'b1 || evict_1 == 1'b1) begin //|| (miss == 1'b1 && lru_value == 1'b1)) begin
        mem_rdata256 = way_1_out;
        pmem_wdata = way_1_out;
    end
    else begin
        mem_rdata256 = way_0_out;
        pmem_wdata = way_0_out;
    end

    //Assign the input for the lru based on whether there is a hit
    if(hit == 1'b1)begin //If there is a hit the new lru value should be the way that did not get a hit
        //lru_in = hit_way ? 1'b0 : 1'b1;
        lru_in = ~hit_way;
    end
    else begin //If there is not a hit the new lru value is the opposite of the old one
        //lru_in = lru_value ? 1'b0 : 1'b1;
        if(lru_value == 1'b1)
            lru_in = 1'b0;
        else
            lru_in = 1'b1;
    end

    //Deterine where incoming data should come from
    if(write_hit == 1'b1) begin
        //Write from the CPU
        datain = mem_wdata256;
    end
    else begin
        //Write from pmem
        datain = pmem_rdata;
    end
        

    if(write_hit == 1'b1) begin
        load_way = load_data & mem_byte_enable256;
    end
    else begin
        load_way = load_data;
    end

    if((lru_value == 1'b1 && dirty_out[1] == 1'b1) || (lru_value == 1'b0 && dirty_out[0] == 1'b1) && valid_out == 2'b11)
        evict = miss;
    else
        evict = 1'b0;
end

always_comb begin : comparators
    //Determine if Way 0 has a hit
    if(tag == tag_0_out) 
        way_0_hit = 1'b1;
    else
        way_0_hit = 1'b0;

    //Determine if Way 1 has a hit
    if(tag == tag_1_out) 
        way_1_hit = 1'b1;
    else
        way_1_hit = 1'b0;

    //Consolidate hit information 
    if(way_0_hit < way_1_hit)
        hit_way = 1'b1;
    else
        hit_way = 1'b0;
end

always_comb begin : decoder
    //Determine which Way should write data (defaults to Way 0)
    if(lru_value == 1'b1 && way_0_hit == 1'b0) begin
        load_way_0 = 32'b0;
        //load_way_1 = load_data;
        load_way_1 = load_way;
        load_tag_0 = 1'b0;
        load_tag_1 = load_tag;
        load_valid_0 = 1'b0;
        load_valid_1 = load_valid;
        load_dirty_0 = 1'b0;
        load_dirty_1 = load_dirty;
    end
    else begin
        //load_way_0 = load_data;
        load_way_0 = load_way;
        load_way_1 = 32'b0;
        load_tag_0 = load_tag;
        load_tag_1 = 1'b0;
        load_valid_0 = load_valid;
        load_valid_1 = 1'b0;
        load_dirty_0 = load_dirty;
        load_dirty_1 = 1'b0;
    end
end

//pmem_address - addr to memory from cpu (offset zeroed out) -> allocate into cache, from tag + index + 00000-> on data eviction
always_comb begin
    pmem_address = {mem_address[31:5], 5'b00000};

    if(evict_0 == 1'b1 && dirty_out[0] == 1'b1 && addr_cpu == 1'b0) begin
        pmem_address = {tag_0_out, index, 5'b00000};
    end
    else if(evict_1 == 1'b1 && dirty_out[1] == 1'b1 && addr_cpu == 1'b0) begin
        pmem_address = {tag_1_out, index, 5'b00000};
    end 
end


always_ff @(posedge clk) begin
    if(rst) begin
        lru_value <= 1'bx;
        tag_value <= '0;
    end
    else begin 
        lru_value <= lru_out;
        tag_value <= tag;
    end
end

endmodule : cache_datapath
