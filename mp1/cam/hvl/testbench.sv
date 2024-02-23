
module testbench(cam_itf itf);
import cam_types::*;

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task write(input key_t key, input val_t val);
    itf.key <= key;
    itf.val_i <= val;
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    ##1;
endtask

task read(input key_t key, output val_t val);
    itf.key <= key;
    itf.rw_n <= 1'b1;
    itf.valid_i <= 1'b1;
    ##1;    
    @(tb_clk iff itf.valid_o);
    val = itf.val_o;
endtask

task evict_test();
    static key_t key = 8'b00010000;
    static val_t value = '0;
    
    //Fill the CAM
    for(int count = '0; count < camsize_p; count++) begin
        write(key, value);	
        key++;
    end    

    key = '0;

    //Evict each key in the CAM
    for(int count = '0; count < camsize_p; count++) begin
        write(key, value);
        key++;	
    end  
endtask : evict_test

task read_test();
    static key_t key = '0;
    static val_t value;
   
    for(int count = '0; count < camsize_p; count++) begin
        read(key, value);
        assert(value == '0)
        else begin
                itf.tb_report_dut_error(READ_ERROR);
                $error("%0t TB: Read %0d, Expected %0d", $time, value, '0);
        end
        key++;
    end
endtask : read_test

//task ww_test();
//endtask : ww_test

//task wr_test();
//endtask : wr_test

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
    /* Coverage */
    //The CAM must evict a key-value pair from each of its eight indices
    //The CAM must record a read-hit from each of its eight indices
    //Must perform writes of different values to the same key on consecutive clock cycles
    //Must perform a write then a read to the same key on consecutive clock cycles
    /* Error Reporting */
    //Assert a read error when the value from the CAM is incorrect (READ_ERROR)
    /**********************************************************************/
    //Fill the CAM and immediatly evict each pair
    evict_test();

    //Read the value at each index
    read_test();

    //Perform writes of different values on consecutive cycles
    reset();

    itf.key <= '0;
    itf.val_i <= '0;
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    ##1;
    itf.key <= '0;
    itf.val_i <= '1;
    itf.rw_n <= 1'b0;
    itf.valid_i <= 1'b1;
    ##1;
    //Perform a read one cycle after a write
    itf.key <= '0;
    itf.rw_n <= 1'b1;
    itf.valid_i <= 1'b1;    
    @(tb_clk iff itf.valid_o)
    //check_value('1);
    assert(itf.val_o == '1)
    else begin
	    itf.tb_report_dut_error(READ_ERROR);
	    $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, '1);
    end


    itf.finish();
end

endmodule : testbench
