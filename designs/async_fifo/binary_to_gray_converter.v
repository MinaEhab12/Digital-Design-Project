module binary_to_gray_converter #(
    parameter FIFO_DEPTH = 16,
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH)    // log2(FIFO_DEPTH)
  ) (
    input  wire [ADDR_WIDTH : 0] binary_addr,
    output wire [ADDR_WIDTH : 0] gray_addr
);

  assign gray_addr = binary_addr ^ (binary_addr >> 1);
    
endmodule
