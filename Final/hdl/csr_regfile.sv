module csr_regfile
import rv32i_types::*;
(
    input logic clk, rst,
    input logic[31:0] write_data,
    //input csr_id in_csr, out_csr,
    input logic[11:0] in_csr, out_csr,
    input logic load_csr, //exception,

    output logic[31:0] read_data
    //output logic[31:0] mstatus_out, satp_out,
    //output logic flush_tlb
);

logic[31:0] mscratch_r, mscratch_w;
logic[31:0] mepc_r, mepc_w;
logic[31:0] mtvec_r, mtvec_w;
logic[31:0] mcause_r, mcause_w;
logic[31:0] mtval_r, mtval_w;
logic[31:0] mstatus_r, mstatus_w;
logic[31:0] mip_r, mip_w;
logic[31:0] mie_r, mie_w;
logic[31:0] mcycle_r, mcycle_w;
logic[31:0] mtime_r, mtime_w;
logic[31:0] mtimeh_r, mtimeh_w;
logic[31:0] mhartid_r, mhartid_w;
logic[31:0] misa_r, misa_w;
logic[31:0] satp_r, satp_w;

//assign mstatus_out = mstatus_r;
//assign satp_out = satp_r;

always_comb begin
    mscratch_w = mscratch_r;
    mepc_w = mepc_r;
    mtvec_w = mtvec_r;
    mcause_w = mcause_r;
    mtval_w = mtval_r;
    mstatus_w = mstatus_r;
    mip_w = mip_r;
    mie_w = mie_r;
    mcycle_w = mcycle_r;
    mtime_w = mtime_r;
    mtimeh_w = mtimeh_r;
    mhartid_w = mhartid_r;
    misa_w = misa_r;
    satp_w = satp_r;
    read_data = '0;

    //flush_tlb = 1'b0;

    unique case(csr_id'(in_csr))
        mscratch: begin
            if(load_csr == 1'b1)
                mscratch_w = write_data;
        end
        mepc: begin
            if(load_csr == 1'b1)
                mepc_w = write_data;
        end
        mtvec: begin
            if(load_csr == 1'b1)
                mtvec_w = write_data;
        end
        mcause: begin
            if(load_csr == 1'b1)
                mcause_w = write_data;
        end
        mtval: begin
            if(load_csr == 1'b1)
                mtval_w = write_data;
        end
        mstatus: begin
            if(load_csr == 1'b1)
                mstatus_w = write_data;
        end
        mip: begin
            if(load_csr == 1'b1)
                mip_w = write_data;
        end
        mie: begin
            if(load_csr == 1'b1)
                mie_w = write_data;
        end
        mcycle: begin
            if(load_csr == 1'b1)
                mcycle_w = write_data;
        end
        mtime: begin
            if(load_csr == 1'b1)
                mtime_w = write_data;
        end
        mtimeh: begin
            if(load_csr == 1'b1)
                mtimeh_w = write_data;
        end
        mhartid: begin
            if(load_csr == 1'b1)
                mhartid_w = write_data;
        end
        misa: begin
            if(load_csr == 1'b1)
                misa_w = write_data;
        end
        satp: begin
            if(load_csr == 1'b1) begin
                satp_w = write_data;
                //flush_tlb = 1'b1;
            end
        end
        default: ;
    endcase


        unique case(csr_id'(out_csr))
        mscratch: begin
            read_data = mscratch_r; 
        end
        mepc: begin
            read_data = mepc_r;
        end
        mtvec: begin
            read_data = mtvec_r;
        end
        mcause: begin
            read_data = mcause_r;
        end
        mtval: begin
            read_data = mtval_r;
        end
        mstatus: begin
            read_data = mstatus_r;
        end
        mip: begin
            read_data = mip_r;
        end
        mie: begin
            read_data = mie_r;
        end
        mcycle: begin
            read_data = mcycle_r;
        end
        mtime: begin
            read_data = mtime_r;
        end
        mtimeh: begin
            read_data = mtimeh_r;
        end
        mhartid: begin
            read_data = mhartid_r;
        end
        misa: begin
            read_data = misa_r;
        end
        satp: begin
            read_data = satp_r;
        end
        default:
            read_data = 32'b0;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        mscratch_r <= '0;
        mepc_r <= '0;
        mtvec_r <= '0;
        mcause_r <= '0;
        mtval_r <= '0;
        mstatus_r <= '0;
        mip_r <= '0;
        mie_r <= '0;
        mcycle_r <= '0;
        mtime_r <= '0;
        mtimeh_r <= '0;
        mhartid_r <= '0;
        misa_r <= '0;
        satp_r <= {1'b1, 9'b0, 2'b00, 20'hf0000};
    end
    else begin
        mscratch_r <= mscratch_w;
        mepc_r <= mepc_w;
        mtvec_r <= mtvec_w;
        mcause_r <= mcause_w;
        mtval_r <= mtval_w;
        mstatus_r <= mstatus_w;
        mip_r <= mip_w;
        mie_r <= mie_w;
        mcycle_r <= mcycle_w;
        mtime_r <= mtime_w;
        mtimeh_r <= mtimeh_w;
        mhartid_r <= mhartid_w;
        misa_r <= misa_w;
        satp_r <= satp_w;
    end
end

endmodule