`define PAGE_SIZE 4096
`define NUM_LEVELS 2
`define PTE_SIZE 4

module mmu(
    input logic clk, rst,
    input logic [31:0] v_addr,
    input logic [31:0] mstatus, satp,
    input logic [31:0] pte_in,
    input logic instr_read, load, store,
    input logic mem_resp, translate, flush_tlb,

    output logic [31:0] p_addr,
    output logic [31:0] pte_addr,
    output logic mem_read, mmu_resp, exception
);

logic [31:0] pte_out;

logic [9:0] vpn [2];
logic [11:0] page_offset;

logic [21:0] root_ppn;  //ppn of the page directory
logic [8:0] asid;       //address space identifier (any or all bits may be hardwired 0)
logic mode;             //address translation scheme (0=Bare -> no translation or protection, 1=Sv32 -> translation)

logic [1:0] mpp, priv;        //memory previous priviledge, one bit for S one for U, U bit is implicitly 0
logic mxr;              //Make eXecutable Readable changes load access, 0 -> only read from readable pages, 1 -> read from readble or executable pages (0 if S mode not supported)
logic sum;              //permit Supervisor User Memory access, 0 -> S mode cannot access U mode pages, 1 -> S mode can access U mode pages (0 if S mode not supported)
logic mprv;             //load/store priviledge mode, 0 -> normal translation and protection, 1 -> translate as if current mode is equal to mpp (instruction translation not affected, hardwired 0 if U mode not implimented)

logic [11:0] ppn_1;
logic [9:0] ppn_0;
logic [7:0] flags;      //d,a,g,u,x,w,r,v;
logic [1:0] rsw;        //Reserved by supervisor, ignored 

assign page_offset = v_addr[11:0];
assign vpn[0] = v_addr[21:12];  //Page table VPN
assign vpn[1] = v_addr[31:22];  //Page directory VPN

assign root_ppn = satp[21:0];
assign asid = satp[30:22];
assign mode = satp[31];

assign mpp = mstatus[12:11];
assign mprv = mstatus[17];
assign sum = mstatus[18];
assign mxr = mstatus[19];
assign priv = mprv ? mpp : 2'b11;

assign flags = pte_out[7:0];
assign rsw = pte_out[9:8];
assign ppn_0 = pte_out[19:10];
assign ppn_1 = pte_out[31:20];


logic[31:0] translated_addr, itlb_addr, dtlb_addr, a;
logic[21:0] level_ppn;
logic[2:0] exception_idx;
logic itlb_hit, dtlb_hit, tlb_read, tlb_write, itlb_resp, dtlb_resp, load_pte;
logic pt_read;

int i;

//assign p_addr = mode ? translated_addr : v_addr;

always_comb begin
    if(mode == 1'b1) begin
        if(itlb_hit == 1'b1 && instr_read == 1'b1)
            p_addr = itlb_addr;
        if(dtlb_hit && (load == 1'b1 || store == 1'b1))
            p_addr = dtlb_addr;
    end
    else begin
        p_addr = v_addr;
    end
end

/* Translation Process (From Priviledged Manual) */
//Let a be satp.ppn × PAGESIZE, and let i = LEVELS − 1
    //is {a, 0000 0000 0000} all that is needed for the address of the page directory?
//Let pte be the value of the PTE at address a+va.vpn[i]×PTESIZE. If accessing pte violates a PMA or PMP check, raise an access exception.
    //need to access memory to get pte (control component?), how to raise an exception?
//If pte.v = 0, or if pte.r = 0 and pte.w = 1, stop and raise a page-fault exception.
/*Otherwise, the PTE is valid. If pte.r = 1 or pte.x = 1, go to step 5. 
  Otherwise, this PTE is a pointer to the next level of the page table. Let i = i − 1. If i < 0, stop and raise a page-fault exception. 
  Otherwise, let a = pte.ppn × PAGESIZE and go to step 2*/
/*A leaf PTE has been found. Determine if the requested memory access is allowed by the
  pte.r, pte.w, pte.x, and pte.u bits, given the current privilege mode and the value of the SUM
  and MXR fields of the mstatus register. If not, stop and raise a page-fault exception.*/
//If i > 0 and pa.ppn[i − 1 : 0] != 0, this is a misaligned superpage; stop and raise a page-fault exception.
/*If pte.a = 0, or if the memory access is a store and pte.d = 0, either raise a page-fault
  exception or:
  • Set pte.a to 1 and, if the memory access is a store, also set pte.d to 1.
  • If this access violates a PMA or PMP check, raise an access exception.
  • This update and the loading of pte in step 2 must be atomic; in particular, no intervening
    store to the PTE may be perceived to have occurred in-between*/
/*The translation is successful. The translated physical address is given as follows:
  • pa.pgoff = va.pgoff.
  • If i > 0, then this is a superpage translation and pa.ppn[i − 1 : 0] = va.vpn[i − 1 : 0].
  • pa.ppn[LEVELS − 1 : i] = pte.ppn[LEVELS − 1 : i].*/


register #(.width(32)) pte (.clk(clk), .rst(rst || tlb_read), .load(load_pte), .in(pte_in), .out(pte_out));

mmu_control control(
    .clk(clk), .rst(rst),
    .root_ppn(root_ppn[19:0]), .pte_ppn(pte_out[29:10]),
    .tlb_hit(1'b0), .tlb_resp(1'b1), .mem_resp(mem_resp), .translate(translate), .exception(exception), .pt_read(pt_read),
    .itlb_hit(itlb_hit), .dtlb_hit(dtlb_hit),
    .instr_read(instr_read), .load(load), .store(store),
    .mode(mode),
    .a(a),
    .load_pte(load_pte), .tlb_read(tlb_read), .tlb_write(tlb_write), .mmu_resp(mmu_resp), .mem_read(mem_read),
    .i(i)
);


tlb ITLB(
    .clk(clk), .rst(rst || flush_tlb),
    .ph_address(translated_addr), .vr_address(v_addr), .tlb_read(tlb_read && instr_read), .tlb_write(tlb_write && instr_read),
    .out_address(itlb_addr), .tlb_hit(itlb_hit), .tlb_resp(itlb_resp)
);


tlb DTLB(
    .clk(clk), .rst(rst  || flush_tlb),
    .ph_address(translated_addr), .vr_address(v_addr), .tlb_read(tlb_read && ~instr_read), .tlb_write(tlb_write && ~instr_read),
    .out_address(dtlb_addr), .tlb_hit(dtlb_hit), .tlb_resp(dtlb_resp)
);


always_comb begin : translation
    translated_addr = 32'b0;
    pte_addr = 32'b0;
    pt_read = 1'b0;
    exception = 1'b0;
    exception_idx = 1'b0;

    //Step 1 (Start, root page directory)
    //a = {root_ppn[19:0], 12'b0};
    //i = NUM_LEVELS - 1 = 1;
    //leaf = 1'b0;

    //Step 2a (Get PTE)
    //if((itlb_hit == 1'b0 || dtlb_hit == 1'b1) && translate == 1'b1) begin
    
    //Step 2b
    //PMA and PMP check (access exception if violated)

    //Step 3 (Check if PTE we got is valid)
    if(flags[0] == 1'b0 || flags[2:1] == 2'b10) begin //If pte.v = 0, or if pte.r = 0 and pte.w = 1, stop and raise a page-fault exception.
        //page-fault exception (instruction, load, or store/amo page fault?)
        exception = 1'b1;
        exception_idx = 3'h1;
    end

    //Step 4 (PTE is valid, check if it is a leaf or a pointer)
    //pte.r = 1 or pte.x = 1 -> Go to step 5 (leaf PTE)
    //(Pointer) -> i = i-1, (i not <0 check), a = {pte.ppn, 12'b0} -> Go to step 2 (read_mem)
    if(flags[1] == 1'b1 || flags[3] == 1'b1)begin //Leaf PTE
        //Step 5 (Leaf PTE, check permissions)
        //Use r,w,x,u flags, current priv mode, and SUM, MXR to determine priviledge (How is w flag used?)
        if(sum == 1'b0 && flags[4] == 1'b1 && (/*priv == S ||*/ (mpp == 2'b10 && mprv == 1'b1)))begin
            exception = 1'b1;
            exception_idx = 3'h2;
        end
        if(mxr == 1'b0 && flags[3] == 1'b1 && flags[1] == 1'b0) begin
            exception = 1'b1;
            exception_idx = 3'h3;
        end
        

        //Step 6 (Have premission, check misalgined superpage)
        //if i > 0 and pa.ppn[i-1 : 0] != 0 then misaligned
        if(i > 0 && ppn_0 != '0) begin
            //page-fault exception
            exception = 1'b1;
            exception_idx = 3'h4;
        end
        

        //Step 7 (Check if we can access with the current operation)
        //if pte.a = 0 or pte.d = 0 and store raise a page fault
        if(flags[6] == 1'b0 || (flags[7] == 1'b0 && store)) begin
            //page-fault exception
            exception = 1'b1;
            exception_idx = 3'h5;
        end

        //Step 8 (Success)
        //pa.pageoff = va.pageoff
        //if i > 0, then this is a superpage -> pa.ppn[i-1 : 0] = va.vpn[i-1 : 0]
        //pa.ppn[NUM_LEVELS-1 : 0] = pte.ppn[NUM_LEVELS-1 : 0] 
        translated_addr[11:0] = page_offset;
        if(i > 0) 
            //pa.ppn[i-1 : 0] = va.vpn[i-1 : 0]
            translated_addr[21:12] = vpn[0];
        else
            //pa.ppn[NUM_LEVELS-1 : i] = pte.ppn[NUM_LEVELS-1 : i]
            translated_addr[21:12] = ppn_0;
        translated_addr[31:22] = ppn_1[9:0];

    end
    else begin //Pointer PTE
        //i_next = i - 1;
        //i = 0;
        //a = {pte.ppn, 12'b0};
        if(i-1 < 0) begin
            exception = 1'b1;
            exception_idx = 3'h6;
        end

        if(translate == 1'b1) begin
            pte_addr = a | {20'b0, vpn[i], 2'b00}; 
            pt_read = 1'b1;
        end
    end
end

endmodule