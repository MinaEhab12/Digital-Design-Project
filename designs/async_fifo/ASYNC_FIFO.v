module ASYNC_FIFO #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16,
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  winc,
    input  wire [DATA_WIDTH-1:0] wdata,
    output wire                  wfull,

    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rinc,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire                  empty
);

    wire [ADDR_WIDTH-1:0]   waddr, raddr;
    wire [ADDR_WIDTH:0]     wptr_gray, rptr_gray;      
    wire [ADDR_WIDTH:0]     wptr_gray_sync, rptr_gray_sync;
    wire                    wclken;

    WRITE_PTR #(.FIFO_DEPTH(FIFO_DEPTH)) u_write_ptr (
        .wclk           (wclk),
        .wrst_n         (wrst_n),
        .winc           (winc),
        .rptr_gray_sync (rptr_gray_sync),
        .waddr          (waddr),
        .wptr_gray      (wptr_gray),
        .wclken         (wclken),
        .wfull          (wfull)
    );

    READ_PTR #(.FIFO_DEPTH(FIFO_DEPTH)) u_read_ptr (
        .rclk           (rclk),
        .rrst_n         (rrst_n),
        .rinc           (rinc),
        .wptr_gray_sync (wptr_gray_sync),
        .raddr          (raddr),
        .rptr_gray      (rptr_gray),
        .empty          (empty)
    );

    SYNCHRONIZER #(.SYNC_WIDTH(ADDR_WIDTH+1)) u_sync_w2r (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .async_in (wptr_gray),
        .sync_out (wptr_gray_sync)
    );

    SYNCHRONIZER #(.SYNC_WIDTH(ADDR_WIDTH+1)) u_sync_r2w (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .async_in (rptr_gray),
        .sync_out (rptr_gray_sync)
    );

    DUAL_PORT_MEM #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) u_mem (
        .wdata  (wdata),
        .waddr  (waddr),
        .raddr  (raddr),
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .wclken (wclken),
        .rdata  (rdata)
    );

endmodule