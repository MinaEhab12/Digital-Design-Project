module SYNCHRONIZER #(
    parameter SYNC_WIDTH = 5   
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [SYNC_WIDTH-1:0] async_in,
    output wire [SYNC_WIDTH-1:0] sync_out
);

    reg [SYNC_WIDTH-1:0] ff1, ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ff1 <= 0;
            ff2 <= 0;
        end else begin
            ff1 <= async_in;
            ff2 <= ff1;
        end
    end

    assign sync_out = ff2;

endmodule