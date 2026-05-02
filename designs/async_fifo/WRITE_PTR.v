module WRITE_PTR #(
    parameter FIFO_DEPTH = 16,
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH)    // log2(FIFO_DEPTH)
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [ADDR_WIDTH:0]     rptr_gray_sync,   
    output reg  [ADDR_WIDTH-1:0]   waddr,
    output wire [ADDR_WIDTH:0]     wptr_gray,        
    output wire                    wclken,
    output wire                    wfull
);
    reg [ADDR_WIDTH:0] wptr;  

    binary_to_gray_converter #(
        .FIFO_DEPTH (FIFO_DEPTH)
    ) Wbin2gray (
        .binary_addr (wptr),
        .gray_addr   (wptr_gray)
    );
    
    // Full condition: when the next wptr_gray would equal the synchronized rptr_gray
    assign wfull = (wptr_gray[ADDR_WIDTH]   != rptr_gray_sync[ADDR_WIDTH])   &&
                   (wptr_gray[ADDR_WIDTH-1] != rptr_gray_sync[ADDR_WIDTH-1]) &&
                   (wptr_gray[ADDR_WIDTH-2:0] == rptr_gray_sync[ADDR_WIDTH-2:0]);

    assign wclken = winc && !wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr <= 0;
            wptr  <= 0;
        end else if (winc && !wfull) begin
            waddr <= wptr[ADDR_WIDTH-1:0] + 1;
            wptr  <= wptr + 1;
        end
    end

endmodule