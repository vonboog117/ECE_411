
`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);
import mult_types::*;

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;

    //Check for error #2 (ready_o not asserted after a reset)
    assert(itf.rdy)
    else begin 
	$error("NOT_READY error detected at line: %0d at time: %0t", `__LINE__, $time);
	report_error(NOT_READY);
    end
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


task combo_test;
    static result_t spec;
    static operand_t mc;
    static operand_t m; 

    //Generate every multiplicand and multiplier
    for(int i = '0; i < operand_limit; i++) begin
	    for(int j = '0; j < operand_limit; j++) begin
            mc = i[width_p-1:0];
            m = j[width_p-1:0];
            spec = i * j;		//Expected result from the multiplier

            @(tb_clk iff itf.rdy);

            itf.multiplicand <= mc;
            itf.multiplier <= m;
            ##1;
            itf.start <= 1'b1;
            ##1;
            itf.start <= 1'b0;

            @(tb_clk iff itf.done);	//Wait for the current multiplication to finish
            //Check for error #3 (ready_o not asserted after completion of multiplication)
            assert(itf.rdy)
            else begin 
                $error("NOT_READY error detected at line: %0d at time: %0t", `__LINE__, $time);
                report_error(NOT_READY);
            end

            //Check for error #1 (product_o returns the incorrect product)
            assert(itf.product == spec)
            else begin 
                $error("BAD_PRODUCT error detected at line: %0d at time: %0t", `__LINE__, $time);
                report_error(BAD_PRODUCT);
            end
        end
    end

endtask : combo_test

task start_test;
    static operand_t mc = 8'b10101010;
    static operand_t m = 8'b00000001;   
    static result_t spec = mc * m; 

    @(tb_clk iff itf.rdy);
    itf.multiplicand <= mc;
    itf.multiplier <= m;
    ##1
    itf.start <= 1'b1;
    ##1;
    itf.start <= 1'b0;

    @(tb_clk iff (itf.mult_op == ADD));	//Wait unitl the current operation is ADD and assert start_i for one cycle
    itf.start <= 1'b1;
    ##1;
    itf.start <= 1'b0;
    @(tb_clk iff (itf.mult_op == SHIFT));  //Wait unitl the current operation is SHIFT and assert start_i for one cycle
    itf.start <= 1'b1;
    ##1;
    itf.start <= 1'b0;

    //Asserting start_i while in a run state should not affect the result, so check that the product is correct
    @(tb_clk iff itf.done);	//Wait for the current multiplication to finish
    //Check for error #1 (product_o returns the incorrect product)
    assert(itf.product == spec)
    else begin 
	    $error("BAD_PRODUCT error detected at line: %0d at time: %0t", `__LINE__, $time);
	    report_error(BAD_PRODUCT);
    end

    //Check for error #3 (ready_o not asserted after completion of multiplication)
    assert(itf.rdy)
    else begin 
	    $error("NOT_READY error detected at line: %0d at time: %0t", `__LINE__, $time);
	    report_error(NOT_READY);
    end

endtask : start_test

task reset_test;
    static operand_t mc = 8'b10101010;
    static operand_t m = 8'b00000001; 

    @(tb_clk iff itf.rdy);
    itf.multiplicand <= mc;
    itf.multiplier <= m;
    ##1
    itf.start <= 1'b1;
    ##1;
    itf.start <= 1'b0;

    @(tb_clk iff (itf.mult_op == ADD));	//Wait unitl the current operation is ADD and assert reset_n_i
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;

    //Check for error #2 (ready_o not asserted after a reset)
    assert(itf.rdy)
    else begin 
	    $error("NOT_READY error detected at line: %0d at time: %0t", `__LINE__, $time);
	    report_error(NOT_READY);
    end

    //Start another multiplication to check reset in SHIFT
    itf.multiplicand <= mc;
    itf.multiplier <= m;
    ##1
    itf.start <= 1'b1;
    ##1;
    itf.start <= 1'b0;

    @(tb_clk iff (itf.mult_op == SHIFT));  //Wait unitl the current operation is SHIFT and assert reset_n_i
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;

    //Check for error #2 (ready_o not asserted after a reset)
    assert(itf.rdy)
    else begin 
	    $error("NOT_READY error detected at line: %0d at time: %0t", `__LINE__, $time);
	    report_error(NOT_READY);
    end

endtask : reset_test

initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    //sequencer - generate input stimuli
    //driver - generate the bus or control input stimuli and trasfer the sequencer data to the DUT
    //monitor - mirrored image of the driver, collect inputs and outputs from the DUT to identify completion
    //scoreboard - takes the output of the monitor and checks if the DUT produced the right value
    /* Coverage */
    //From a ready state (NONE, DONE) assert start_i with every multiplier input combination, and enter the DONE state without resetting
    //From each run state (ADD, SHIFT) assert start_i while the multiplier is in that state
    //From each run state assert reset_n_i while in that state
    /* Error Reporting */
    //Upon entering a DONE state, if product_o is the incorrect product, report a BAD_PRODUCT error
    //If the ready_o signal is not asserted after a reset, report a NOT_READY error
    //If the ready_o signal is not asserted upon completion of a multiplication, report a NOT_READY error


    /* Coverage Case 1 */
    combo_test();
    
    /* Coverage Case 2 */
    reset();
    start_test();

    /* Coverage Case 3 */
    reset();
    reset_test();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
