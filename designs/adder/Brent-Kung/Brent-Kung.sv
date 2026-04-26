module brent_kung_32 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic        Cin,
    output logic [31:0] Sum,
    output logic        overflow,
    output logic        valid_out
);

    // =========================
    // Combinational logic (unchanged)
    // =========================
    logic [31:0] G [0:5];
    logic [31:0] P [0:5];

    assign G[0] = A & B;
    assign P[0] = A ^ B;

    genvar i;

    generate
        for (i = 0; i < 32; i++) begin : stage1
            if (i == 0) begin
                assign G[1][i] = G[0][i];
                assign P[1][i] = P[0][i];
            end else begin
                assign G[1][i] = G[0][i] | (P[0][i] & G[0][i-1]);
                assign P[1][i] = P[0][i] & P[0][i-1];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i++) begin : stage2
            if (i < 2) begin
                assign G[2][i] = G[1][i];
                assign P[2][i] = P[1][i];
            end else begin
                assign G[2][i] = G[1][i] | (P[1][i] & G[1][i-2]);
                assign P[2][i] = P[1][i] & P[1][i-2];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i++) begin : stage3
            if (i < 4) begin
                assign G[3][i] = G[2][i];
                assign P[3][i] = P[2][i];
            end else begin
                assign G[3][i] = G[2][i] | (P[2][i] & G[2][i-4]);
                assign P[3][i] = P[2][i] & P[2][i-4];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i++) begin : stage4
            if (i < 8) begin
                assign G[4][i] = G[3][i];
                assign P[4][i] = P[3][i];
            end else begin
                assign G[4][i] = G[3][i] | (P[3][i] & G[3][i-8]);
                assign P[4][i] = P[3][i] & P[3][i-8];
            end
        end
    endgenerate

    generate
        for (i = 0; i < 32; i++) begin : stage5
            if (i < 16) begin
                assign G[5][i] = G[4][i];
                assign P[5][i] = P[4][i];
            end else begin
                assign G[5][i] = G[4][i] | (P[4][i] & G[4][i-16]);
                assign P[5][i] = P[4][i] & P[4][i-16];
            end
        end
    endgenerate

    logic [32:0] C;
    assign C[0] = Cin;
    generate
        for (i = 0; i < 32; i++) begin : carry
            assign C[i+1] = G[5][i] | (P[5][i] & C[0]);
        end
    endgenerate

    logic [31:0] Sum_comb;
    logic        overflow_comb;

    generate
        for (i = 0; i < 32; i++) begin : sum_comb
            assign Sum_comb[i] = P[0][i] ^ C[i];
        end
    endgenerate

    assign overflow_comb = (A[31] & B[31] & ~Sum_comb[31]) |
                           (~A[31] & ~B[31] & Sum_comb[31]);

    // =========================
    // Single output register
    // =========================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Sum       <= '0;
            overflow  <= '0;
            valid_out <= '0;
        end else if(valid_in) begin
            Sum       <= Sum_comb;
            overflow  <= overflow_comb;
            valid_out <= 1'b1;
        end
        else begin
            valid_out <= 1'b0;
        end
    end

endmodule