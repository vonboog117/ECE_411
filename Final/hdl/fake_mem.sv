module fake_mem(
    input logic[31:0] mem_addr,
    input logic mem_read,
    output logic[31:0] mem_data,
    output logic mem_resp
);

logic[31:0] page_directory_entry1, page_directory_entry2, page_directory_entry3, page_directory_entry4, page_directory_entry5, page_directory_entry6, page_directory_entry_bad, page_directory_entry_super;
logic[31:0] page_table_entry1, page_table_entry2, page_table_entry3, page_table_entry4, page_table_entry5, page_table_entry6;

//    31  20 19 10 9 8 7                      0
//PTE [PPN1][PPN2][RSW][D][A][G][U][X][W][R][V]

assign page_directory_entry1 = {12'h3fc, 10'h001, 2'b00, 8'b00000001};
assign page_directory_entry_bad = {12'h3fc, 10'h001, 2'b00, 8'b01000011}; //Bad, misaligned superpage
assign page_directory_entry_super = {12'h03c, 10'h000, 2'b00, 8'b01000011}; //Good, aligned superpage -> 0000111100 0000000000 = {0x0f000}\
//These are to access the page tables because I cannot write to the page tables from an assembly file
assign page_directory_entry2 =    {12'h3fc, 10'h002, 2'b00, 8'b00000001};
assign page_directory_entry3 =    {12'h3fc, 10'h003, 2'b00, 8'b00000001}; 
assign page_directory_entry4 =    {12'h3fc, 10'h004, 2'b00, 8'b00000001}; 
assign page_directory_entry5 =    {12'h3fc, 10'h005, 2'b00, 8'b00000001}; 
assign page_directory_entry6 =    {12'h3fc, 10'h006, 2'b00, 8'b00000001};

assign page_table_entry1 =    {12'h001, 10'b000, 2'b00, 8'b01000011}; // Good, arv flags -> 0000000001 0000000000 = {0x00400}
assign page_table_entry2 =    {12'hbad, 10'b000, 2'b00, 8'b01000000}; // Bad, not valid
assign page_table_entry3 =    {12'hbad, 10'b000, 2'b00, 8'b01000001}; // Bad, valid but not interactable (flags indicate a pointer but it is not)
assign page_table_entry4 =    {12'hbad, 10'b000, 2'b00, 8'b01000101}; // Bad, r=0, w=1
assign page_table_entry5 =    {12'hbad, 10'b000, 2'b00, 8'b00000011}; // Bad, a=0
assign page_table_entry6 =    {12'h011, 10'b000, 2'b00, 8'b01001001}; // Maybe Bad, r=0, x=1 -> 0000010001 0000000000 = {0x04400}
//Storing these will also result in an exception because d=0



//Expected stap entry
//  31  30      22 21   0
//[Mode][  ASID  ][ PPN ]
//  0   000000000  0x3C0000 (0011 1100 0000 0000 0000 0000)

//1000 0000 0000 0000 0000 0000 0000 0000
//VPN[1]     VPN[0]     Offset
//1000000000 0000000000 000000000000 = 0x80000000
//VPN[1] x PTESIZE (PTESIZE=4)
//100000000000 = 0x800

always_comb begin
    mem_data = '0;
    unique case(mem_addr)
        32'hf0000800:
            mem_data = page_directory_entry1;
        32'hf0001800:
            mem_data = page_directory_entry2;
        32'hf0002800:
            mem_data = page_directory_entry3;
        32'hf0003800:
            mem_data = page_directory_entry4;
        32'hf0004800:
            mem_data = page_directory_entry5;
        32'hf0005800:
            mem_data = page_directory_entry6;
        32'hf0006800:
            mem_data = page_directory_entry_bad;
        32'hf0007800:
            mem_data = page_directory_entry_super;
        32'hff001000:
            mem_data = page_table_entry1;
        32'hff002000:
            mem_data = page_table_entry2;
        32'hff003000:
            mem_data = page_table_entry3;
        32'hff004000:
            mem_data = page_table_entry4;
        32'hff005000:
            mem_data = page_table_entry5;
        32'hff006000:
            mem_data = page_table_entry6;
        default:
            mem_data = '0;
    endcase

    mem_resp = mem_read;
end

endmodule