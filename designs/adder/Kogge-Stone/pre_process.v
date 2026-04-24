module pre_process (
    input wire a, b,
    output wire g, p
);

assign g = a & b;
assign p = a ^ b;

endmodule
