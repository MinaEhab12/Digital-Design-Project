module DUAL_PORT_MEM #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16,
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [ADDR_WIDTH-1:0] raddr,
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  wclken,
    input  wire                  rclk,    
    input  wire                  rrst_n,  
    output reg  [DATA_WIDTH-1:0] rdata    
);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    integer i;

    // Synchronous write
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i=0; i<FIFO_DEPTH; i=i+1)
                mem[i] <= 'b0;
        end
        else if (wclken)
            mem[waddr] <= wdata;
    end

    // Synchronous read
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 'b0;
        else
            rdata <= mem[raddr];
    end

endmodule