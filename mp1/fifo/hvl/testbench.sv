`ifndef testbench
`define testbench


module testbench(fifo_itf itf);
import fifo_types::*;

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

task check_ready();
    assert(itf.rdy == 1'b1)
    else begin
	    $error("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
	    report_error(RESET_DOES_NOT_CAUSE_READY_O);
    end 
endtask : check_ready

task enqueue_test();
    @(tb_clk iff itf.rdy)
    //for(int word = '0; word <= cap_p-1; word++) begin
    for(word_t word = '0; itf.rdy == 1'b1; word++) begin
        itf.data_i <= word;
        itf.valid_i <= 1'b1;
        itf.yumi <= 1'b0;
        ##1;
    end
    itf.valid_i <= 1'b0;
    ##1;
endtask : enqueue_test

task dequeue_test();
    //Dequeue words until the fifo is empty
    @(tb_clk iff itf.valid_o)
    //for(int word = '0; word <= cap_p-1; word++) begin
    for(word_t word = 1; itf.valid_o == 1'b1; word++) begin
        itf.yumi <= 1'b1;
        itf.valid_i <= 1'b0;
        //size--;
        ##1;
        assert(itf.data_o == word)
        else begin
            $error("%0d: %0t: %b: %b: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time, itf.data_o, word);
            report_error(INCORRECT_DATA_O_ON_YUMI_I);
        end 
    end
    itf.yumi <= 1'b0;
    ##1;
endtask: dequeue_test

task simultaneous_test;
    static word_t word = 0;
    for(int size = 1; size <= (cap_p - 1); size++) begin
        @(tb_clk iff itf.rdy)
	    //Increase the size of the fifo
        itf.data_i <= word;
        itf.valid_i <= 1'b1;
        itf.yumi <= 1'b0;
        ##1;			//1 enqueued, size 1; 3 enqueued, size=2
        word++;			//A word has been enqueued, move to the next; 1->2; 3->4
        itf.valid_i <= 1'b0;
        ##1;

        @(tb_clk iff itf.rdy)
        //Enqueue and dequeue a word
        itf.data_i <= word;
        itf.valid_i <= 1'b1;
        itf.yumi <= 1'b1;
        ##1;			//1 dequeued, 2 enqueued, size=1; 2 dequeued, 4 enqueued, size=2
        itf.valid_i <= 1'b0;
        itf.yumi <= 1'b0;
        word++;			//A word has been enqueued, move to the next; 2->3; 4->5
        assert(itf.data_o == size)	//@ size 1, 1 dequeued; @ size 2, 2 dequeued (size is the same as dequeued value)
        else begin
            $error("%0d: %0t: %b: %b: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time, itf.data_o, size);
            report_error(INCORRECT_DATA_O_ON_YUMI_I);
        end 
        ##1;	
    end
endtask : simultaneous_test

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    /* Coverage */
    //Enqueue words while the FIFO has a size in the range [0, cap_p-1] (not full)
    //Dequeue words while the FIFO has a size in the range [1, cap_p] (not empty)
    //Simultaneously enqueue and dequeue while the FIFO has a size [1, cap_p-1] (neither empty nor full)
    /* Error Reporting */
    //Asserting reset_n_i at @(tb_clk) should result in ready_o being high at @(posedge clk_i), otherwise report RESET_DOES_NOT_CAUSE_READY_O
    //When asserting yumi_i at @(tb_clk) when data is ready, the value on data_o must be correct, otherwise report INCORRECT_DATA_O_ON_YUMI_I
	//Avoid asserting yumi_i when the FIFO is empty

    check_ready(); 

    //Enqueue words when the fifo has size [0, cap_p-1]
    enqueue_test();

    //FIFO should now be full

    //Dequeue words when the fifo has size [1, cap_p]
    //reset();
    //check_ready();
    dequeue_test();

    //Enqueue and Dequeue words when the fifo has size [1, cap_p-1]
    reset();
    check_ready();
    simultaneous_test();

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

