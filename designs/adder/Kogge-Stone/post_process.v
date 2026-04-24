module post_process (
    input wire c, p,
    output wire sum
);

assign sum = c ^ p;

endmodule
