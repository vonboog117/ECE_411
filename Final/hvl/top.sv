module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/

int timeout = 100000000; 
// logic [31:0] temp_pc;
// always @(posedge itf.clk iff rvfi.commit)
//     temp_pc <= dut.datapath.wb_pc_out;

always_comb begin
    rvfi.halt = 0;
    if(dut.datapath.ex_br_en == 1'b1) begin
        if(dut.datapath.ex_pc_out == dut.datapath.pcmux_out) begin
            rvfi.halt = 1;
        end
    end
        
end
 //change to check for nop
/***************************** Spike Log Printer *****************************/
// Can be enabled for debugging
spike_log_printer printer(.itf(itf), .rvfi(rvfi));
/*************************** End Spike Log Printer ***************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2
//assign rvfi.commit = 0;
assign rvfi.commit = ~itf.rst & ~dut.datapath.stall & ~(dut.datapath.wb_pc_out == 32'b0);
 // Set high when a valid instruction is modifying regfile or PC
// // Set high when target PC == Current PC for a branch
initial rvfi.order = 0;
// always_comb 
// begin
//     rvfi.halt = 0; 
//     if(rvfi.commit) begin
//         if(temp_pc == dut.datapath.wb_pc_out) begin
//             rvfi.halt = 1;
//         end
//     end
// end
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

//write back signals
//Instruction and trap:
    assign rvfi.inst = dut.datapath.wb_instr_mem_rdata;
    assign rvfi.trap = 1'b0;
//Regfile:
    assign rvfi.rs1_addr = dut.datapath.wb_rs1;
    assign rvfi.rs2_addr = dut.datapath.wb_rs2;
    assign rvfi.rs1_rdata = dut.datapath.wb_rs1_out;
    assign rvfi.rs2_rdata = dut.datapath.wb_rs2_out;
    assign rvfi.load_regfile = dut.datapath.wb_word.load_regfile;
    assign rvfi.rd_addr = dut.datapath.wb_rd;
    assign rvfi.rd_wdata = dut.datapath.wb_regfilemux_out;
//PC:
    assign rvfi.pc_rdata = dut.datapath.wb_pc_out;
    assign rvfi.pc_wdata = dut.datapath.wb_pc_next;
//Memory:
    //assign rvfi.mem_addr = dut.pmem_address;
    assign rvfi.mem_addr = dut.datapath.wb_data_mem_address;
    assign rvfi.mem_rmask = dut.datapath.wb_rmask;
    assign rvfi.mem_wmask = dut.datapath.wb_wmask;
    //assign rvfi.mem_rdata = dut.pmem_rdata;
    //assign rvfi.mem_wdata = dut.pmem_wdata;
    assign rvfi.mem_rdata = dut.datapath.wb_data_mem_rdata;
    assign rvfi.mem_wdata = dut.datapath.wb_data_mem_wdata;


/**************************** End RVFIMON signals ****************************/



/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
//from cpu to cache
//instruction cache
    assign itf.inst_read = dut.instruction_cache.mem_read;
    assign itf.inst_addr = dut.instruction_cache.mem_address;
    assign itf.inst_resp = dut.instruction_cache.mem_resp;
    assign itf.inst_rdata = dut.instruction_cache.mem_rdata_cpu;
//dcache signals:
    assign itf.data_read = dut.data_cache.mem_read;
    assign itf.data_write = dut.data_cache.mem_write;
    assign itf.data_mbe = dut.data_cache.mem_byte_enable_cpu;
    assign itf.data_addr = dut.data_cache.mem_address;
    assign itf.data_wdata = dut.data_cache.mem_wdata_cpu;
    assign itf.data_resp = dut.data_cache.mem_resp;
    assign itf.data_rdata = dut.data_cache.mem_rdata_cpu;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/


// // Stop simulation on error detection
// always @(itf.errcode iff (itf.errcode != 0)) begin
//     $system($sformatf("echo 'DASM(%8h)' | spike-dasm", dut.datapath.IR.data));
//     repeat (30) @(posedge itf.clk);
//     $display("TOP: Errcode: %0d", itf.errcode);
//     $finish;
// end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (rvfi.halt)
        $finish;
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

// always @(posedge itf.clk iff (itf.mem_read && itf.mem_write))
//     $error("@%0t TOP: Simultaneous memory read and write detected", $time);


/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp
Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),


    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
    
);
/***************************** End Instantiation *****************************/

endmodule