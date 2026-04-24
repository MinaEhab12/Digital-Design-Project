module dot_operator(
    input wire gi, pi, gj, pj,
    output wire gk, pk
);
    assign gk = gj | (gi & pj);
    assign pk = pi & pj;
endmodule
