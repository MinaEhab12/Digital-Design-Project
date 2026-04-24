module calc_carry (
    input wire g, p, carry_in,
    output wire carry_out
);

assign carry_out = g | (p & carry_in);

endmodule
