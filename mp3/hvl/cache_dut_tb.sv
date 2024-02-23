module cache_dut_tb;

timeunit 1ns;
timeprecision 1ns;

/****************************** Generate Clock *******************************/
bit clk;
always #5 clk = clk === 1'b0;

int timestamp = 2000000;

always @(posedge clk) begin
    //$display("Testbench Didn't Time Out, %0d", timestamp);
    if(timestamp == 0)begin
        $display("Testbench Timed Out");
        $finish;
    end
    timestamp <= timestamp - 1;
end
/****************************** Dump Signals *******************************/
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, cache_dut_tb, "+all");
    $display("Compilation Successful");
end


/****************************** Generate Reset ******************************/
logic rst;
/* CPU memory signals */
logic [31:0]    mem_address;
logic [31:0]    mem_rdata;
logic [31:0]    mem_wdata;
logic           mem_read;
logic           mem_write;
logic [3:0]     mem_byte_enable;
logic           mem_resp;

/* Physical memory signals */
logic [31:0]    pmem_address;
logic [255:0]   pmem_rdata;
logic [255:0]   pmem_wdata;
logic           pmem_read;
logic           pmem_write;
logic           pmem_resp;



logic mp3_pmem_resp;
logic [63:0] mp3_pmem_rdata;
logic mp3_pmem_read;
logic mp3_pmem_write;
logic [31:0] mp3_pmem_address;
logic [63:0] mp3_pmem_wdata;


task reset;
    rst <= 1'b1;
    mem_read <= 1'b0;
    mem_write <= 1'b0;
    pmem_resp <= 1'b0;
    mem_byte_enable <= 4'b0000;
    repeat (2) @(posedge clk);
    rst <= 1'b0;
endtask

task fill_cache;
    //Fill all cache lines
    static logic[4:0] offset;
    static logic[2:0] index;
    static logic[23:0] tag;

    for(int i = 0; i < 8; i++) begin
        //Way 0
        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i);
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_read <= 1'b1;
        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= tag;
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        mem_read <= 1'b0;

        repeat (2) @(posedge clk);

        //Way 1
        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i) + 1;
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_read <= 1'b1;
        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= tag;
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        mem_read <= 1'b0;

        repeat (2) @(posedge clk);
    end
endtask

task hit_cache;
    //Fill all cache lines
    static logic[4:0] offset;
    static logic[2:0] index;
    static logic[23:0] tag;

    for(int i = 0; i < 8; i++) begin
        //Way 0
        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i);
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_read <= 1'b1;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        mem_read <= 1'b0;

        repeat (2) @(posedge clk);

        //Way 1
        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i) + 1;
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_read <= 1'b1;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        mem_read <= 1'b0;

        repeat (2) @(posedge clk);
    end
endtask

task evict_cache;
    //Fill all cache lines
    static logic[4:0] offset;
    static logic[2:0] index;
    static logic[23:0] tag;

    for(int i = 0; i < 8; i++) begin
        //Way 0
        offset = 5'b00000;
        index = i[2:0];
        tag = 8'hf0 + (2*i);
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_read <= 1'b1;
        
        @(clk iff pmem_write == 1'b1);
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;

        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= tag;
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        mem_read <= 1'b0;

        repeat (2) @(posedge clk);

        //Way 1
        offset = 5'b00000;
        index = i[2:0];
        tag = 8'hf0 + (2*i)+1;
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_read <= 1'b1;

        @(clk iff pmem_write == 1'b1);
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;

        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= tag;
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        mem_read <= 1'b0;

        repeat (2) @(posedge clk);
    end
endtask

task fill_write;
    //Fill all cache lines
    static logic[4:0] offset;
    static logic[2:0] index;
    static logic[23:0] tag;

    for(int i = 0; i < 8; i++) begin
        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i);
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_write <= 1'b1;
        mem_wdata <= 32'hfffffff0 + tag;
        mem_byte_enable <= 4'b1111;
        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= {64'h3333333333333333, 64'h2222222222222222, 64'h1111111111111111, 64'h0000000000000000};
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        @(clk iff mem_resp == 1'b0);
        mem_write <= 1'b0;

        repeat (2) @(posedge clk);

        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i) + 1;
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag, index, offset};
        mem_write <= 1'b1;
        mem_wdata <= 32'heeeeeee0 + tag;
        mem_byte_enable <= 4'b1111;
        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= {64'h8888888888888888, 64'h7777777777777777, 64'h6666666666666666, 64'h5555555555555555};
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        @(clk iff mem_resp == 1'b0);
        mem_write <= 1'b0;

        repeat (2) @(posedge clk);
    end
endtask

task write_cache;
    //Fill all cache lines
    static logic[4:0] offset;
    static logic[2:0] index;
    static logic[23:0] tag;

    for(int i = 0; i < 8; i++) begin
        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i);
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag , index, offset};
        mem_write <= 1'b1;
        mem_wdata <= 32'h000000f0 + tag;
        mem_byte_enable <= 4'b1111;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        @(clk iff mem_resp == 1'b0);
        mem_write <= 1'b0;

        repeat (2) @(posedge clk);

        offset = 5'b00000;
        index = i[2:0];
        tag = (2*i) + 1;
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag , index, offset};
        mem_write <= 1'b1;
        mem_wdata <= 32'h0000000e0 + tag;
        mem_byte_enable <= 4'b1111;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        @(clk iff mem_resp == 1'b0);
        mem_write <= 1'b0;

        repeat (2) @(posedge clk);
    end
endtask

task write_evict;
    //Fill all cache lines
    static logic[4:0] offset;
    static logic[2:0] index;
    static logic[23:0] tag;

    for(int i = 0; i < 8; i++) begin
        offset = 5'b00000;
        index = i[2:0];
        tag = 24'hf0 + (2*i);
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag , index, offset};
        mem_write <= 1'b1;
        mem_wdata <= 32'hddddddd0 + tag;
        mem_byte_enable <= 4'b1111;
        //Expect an evict
        @(clk iff pmem_write == 1'b1);
        @(clk iff pmem_wdata == {64'h3333333333333333, 64'h2222222222222222, 64'h1111111111111111, 64'h00000000000000f0 + (2*i)});
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= {64'h0000000000000000, 64'h1111111111111111, 64'h2222222222222222, 64'h3333333333333333};
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        @(clk iff mem_resp == 1'b0);
        mem_write <= 1'b0;

        repeat (2) @(posedge clk);

        offset = 5'b00000;
        index = i[2:0];
        tag = 24'hf0 + (2*i) + 1;
        @(clk iff mem_resp == 1'b0);
        mem_address <= {tag , index, offset};
        mem_write <= 1'b1;
        mem_wdata <= 32'hccccccc0 + tag;
        mem_byte_enable <= 4'b1111;
        //Expect an evict
        @(clk iff pmem_write == 1'b1);
        @(clk iff pmem_wdata == {64'h8888888888888888, 64'h7777777777777777, 64'h6666666666666666, 64'h55555555000000e0 + (2*i) + 1});
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Once the cache misses, it will ask the physical memory for info
        @(clk iff pmem_read == 1'b1);
        pmem_rdata <= {64'h5555555555555555, 64'h6666666666666666, 64'h7777777777777777, 64'h8888888888888888};
        pmem_resp <= 1'b1;
        repeat (1) @(posedge clk);
        pmem_resp <= 1'b0;
        //Wait for the cache to respond
        @(clk iff mem_resp == 1'b1);
        @(clk iff mem_resp == 1'b0);
        mem_write <= 1'b0;

        repeat (2) @(posedge clk);
    end
endtask

/*************************** Instantiate DUT HERE ***************************/

cache dut( 
    .clk(clk),
    .rst(rst),

    /* CPU memory signals */
    .mem_address(mem_address),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_resp(mem_resp),

    /* Physical memory signals */
    .pmem_address(pmem_address),
    .pmem_rdata(pmem_rdata),
    .pmem_wdata(pmem_wdata),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .pmem_resp(pmem_resp)
);

mp3 mp3_dut(
    .clk(clk),
    .rst(rst),
    .pmem_resp(mp3_pmem_resp),
    .pmem_rdata(mp3_pmem_rdata),
    .pmem_read(mp3_pmem_read),
    .pmem_write(mp3_pmem_write),
    .pmem_address(mp3_pmem_address),
    .pmem_wdata(mp3_pmem_wdata)
);

initial begin
    reset();
    #1;
    $display("Just Reset, %0d", rst);
    $display("Cache control state, %0d", dut.control.state);
    // assert(mem_resp == 1'b0)
    // else begin
    //     $error("Cache response active too soon during cold miss");
    // end
    
    //offset = 5'b00000;
    //index = i[2:0];
    //tag = (2*i);
    // @(clk iff mem_resp == 1'b0);
    // mem_address <= {24'b00000, 3'b000, 5'b00000};
    // mem_write <= 1'b1;
    // mem_wdata <= 32'h55555555;
    // mem_byte_enable <= 4'b1111;
    // //Once the cache misses, it will ask the physical memory for info
    // @(clk iff pmem_read == 1'b1);
    // pmem_rdata <= {64'h3333333333333333, 64'h2222222222222222, 64'h1111111111111111, 64'h0000000000000000};
    // pmem_resp <= 1'b1;
    // repeat (1) @(posedge clk);
    // pmem_resp <= 1'b0;
    // //Wait for the cache to respond
    // @(clk iff mem_resp == 1'b1);
    // @(clk iff mem_resp == 1'b0);
    // mem_write <= 1'b0;

    // repeat (2) @(posedge clk);

    // @(clk iff mem_resp == 1'b0);
    // mem_address <= {24'b0, 3'b000, 5'b00100};
    // mem_write <= 1'b1;
    // mem_wdata <= 32'hfffffff0;
    // mem_byte_enable <= 4'b1111;
    // //Once the cache misses, it will ask the physical memory for info
    // @(clk iff pmem_read == 1'b1);
    // pmem_rdata <= {64'h3333333333333333, 64'h2222222222222222, 64'h1111111111111111, 64'h0000000000000000};
    // pmem_resp <= 1'b1;
    // repeat (1) @(posedge clk);
    // pmem_resp <= 1'b0;
    // //Wait for the cache to respond
    // @(clk iff mem_resp == 1'b1);
    // @(clk iff mem_resp == 1'b0);
    // mem_write <= 1'b0;

    // repeat (2) @(posedge clk);




    fill_write();
    repeat (3) @(posedge clk);
    // write_cache();
    // repeat (3) @(posedge clk);
    //write_evict();

    //fill_cache();
    //repeat (3) @(posedge clk);
    hit_cache();
    //repeat (3) @(posedge clk);
    evict_cache();


    $finish;
end


endmodule : cache_dut_tb