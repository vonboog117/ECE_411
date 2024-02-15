module lru (
    input logic clk, rst,
    input logic[1:0] hit_tag,
    input logic load_lru, hit,
    output logic [3:0] lru_out
);

logic [1:0] lru_queue [4];
logic [1:0] hit_queue [4];

always_comb begin
    lru_out = 4'b0000;
    hit_queue = lru_queue;

    unique case(lru_queue[0])
    2'b00:
        lru_out = 4'b0001;
    2'b01:
        lru_out = 4'b0010;
    2'b10:
        lru_out = 4'b0100;
    2'b11:
        lru_out = 4'b1000;
    default:
        lru_out = 4'b0000;
    endcase

    if (hit_tag == lru_queue[0]) begin
        hit_queue = {lru_queue[1], lru_queue[2], lru_queue[3], hit_tag};
    end
    else if (hit_tag == lru_queue[1]) begin
        hit_queue = {lru_queue[0], lru_queue[2], lru_queue[3], hit_tag};
    end
    else if (hit_tag == lru_queue[2]) begin
        hit_queue = {lru_queue[0], lru_queue[1], lru_queue[3], hit_tag};
    end
    else if (hit_tag == lru_queue[3]) begin
        hit_queue = {lru_queue[0], lru_queue[1], lru_queue[2], hit_tag}; //Should be the same as lru_queue
    end
end


always_ff @(posedge clk) begin
    if (rst) begin
        lru_queue <= {2'b00, 2'b01, 2'b10, 2'b11};
    end
    else if(hit) begin
        lru_queue <= hit_queue;
    end
    else if(load_lru) begin //Writing to the TLB
        lru_queue <= {lru_queue[1], lru_queue[2], lru_queue[3], lru_queue[0]};
    end
end

endmodule