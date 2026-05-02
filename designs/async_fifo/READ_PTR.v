module READ_PTR #(
   parameter FIFO_DEPTH = 16,
   localparam ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
   input  wire                    rclk,
   input  wire                    rrst_n,
   input  wire                    rinc,
   input  wire [ADDR_WIDTH:0]     wptr_gray_sync,   
   output wire [ADDR_WIDTH-1:0]   raddr,
   output wire [ADDR_WIDTH:0]     rptr_gray,        
   output wire                    empty
);

   reg [ADDR_WIDTH:0] rptr;  

   binary_to_gray_converter #(
        .FIFO_DEPTH (FIFO_DEPTH)
    ) rbin2gray (
        .binary_addr (rptr),
        .gray_addr   (rptr_gray)
    );

   // Empty condition: when the read pointer gray equals the synchronized write pointer gray
   assign empty = (rptr_gray == wptr_gray_sync);

   assign raddr = rptr[ADDR_WIDTH-1:0];

   always @(posedge rclk or negedge rrst_n) begin
      if (!rrst_n) begin
         rptr <= 0;
      end else if (rinc && !empty) begin
         rptr <= rptr + 1;
      end
   end

endmodule