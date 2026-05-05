module fifo_ks_top #(
        parameter DATA_WIDTH = 32,
        parameter FIFO_DEPTH = 16
    ) (

        input  wire                  wclk,
        input  wire                  wrst_n,
        input  wire                  winc,
        input  wire [DATA_WIDTH-1:0] wdata,
        
        input  wire                  rclk,
        input  wire                  rrst_n,
        input  wire [DATA_WIDTH-1:0]  A,
        input  wire                   Cin,

        output wire [DATA_WIDTH-1:0]  Sum,
        output wire                   overflow,
        output wire                   valid_out,

        output wire                  empty,
        output wire                  wfull
);

reg rinc;
reg valid_in;
wire [DATA_WIDTH-1:0] rdata;

ASYNC_FIFO #(
    .DATA_WIDTH (DATA_WIDTH),
    .FIFO_DEPTH (FIFO_DEPTH)
) async_fifo (
    .wclk       (wclk),
    .wrst_n     (wrst_n),
    .winc       (winc),
    .wdata      (wdata),
    .wfull      (wfull),
    .rclk       (rclk),
    .rrst_n     (rrst_n),
    .rinc       (rinc),
    .rdata      (rdata),
    .empty      (empty)
);

Kogge_Stone_32Bits kogge_stone (
    .clk        (rclk),
    .rst_n      (rrst_n),
    .valid_in   (valid_in),
    .A          (A),
    .B          (rdata),
    .Cin        (Cin),
    .Sum        (Sum),
    .overflow   (overflow),
    .valid_out  (valid_out)
);

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        rinc <= 1'b0;
        valid_in <= 1'b0;
    end
    else if (!empty) begin
        rinc <= 1'b1;
        valid_in <= 1'b1;
    end
    else begin
        rinc <= 1'b0;
        valid_in <= 1'b0;
    end
end   

endmodule
