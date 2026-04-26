module Kogge_Stone_32Bits (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [31:0] A,
    input wire [31:0] B,
    input wire Cin,
    output reg [31:0] Sum,
    output reg overflow,
    output reg valid_out
);

wire [31:0] g, p;       // Generate and Propagate signals
wire [32:0] C;          // Carry signals

wire [31:0] sum_comb;
wire overflow_comb;
wire valid_out_comb;

// Pre-Processing (Generate and Propagate computation)
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : gen_pre_process
        pre_process g_and_p (
            .a(A[i]),
            .b(B[i]),
            .g(g[i]),
            .p(p[i])
        );
    end
endgenerate


// Kogge-Stone Prefix Computation
// Stage 1 (31 dot operations)
wire [30:0] p_stage1, g_stage1;
generate
    for (i = 0; i < 31; i = i + 1) begin : gen_stage1
        dot_operator stage1 (
            .gi(g[i]),
            .pi(p[i]),
            .gj(g[i+1]),
            .pj(p[i+1]),
            .gk(g_stage1[i]),
            .pk(p_stage1[i])
        );
        end
endgenerate

// Stage 2 (30 dot operations)
wire [29:0] p_stage2, g_stage2;
generate
    for (i = 0; i < 30; i = i + 1) begin : gen_stage2
        if (i == 0) begin : gen_stage2_first
            dot_operator stage2 (
                .gi(g[i]),
                .pi(p[i]),
                .gj(g_stage1[i+1]),
                .pj(p_stage1[i+1]),
                .gk(g_stage2[i]),
                .pk(p_stage2[i])
            );
        end else begin : gen_stage2_rest
            dot_operator stage2 (
                .gi(g_stage1[i-1]),
                .pi(p_stage1[i-1]),
                .gj(g_stage1[i+1]),
                .pj(p_stage1[i+1]),
                .gk(g_stage2[i]),
                .pk(p_stage2[i])
            );
        end
    end
endgenerate


// Stage 3 (28 dot operations)
wire [27:0] p_stage3, g_stage3;
generate
    for (i = 0; i < 28; i = i + 1) begin : gen_stage3
        if (i < 2) begin : gen_stage3_first
            dot_operator stage3 (
                .gi(g[i]),
                .pi(p[i]),
                .gj(g_stage2[i+2]),
                .pj(p_stage2[i+2]),
                .gk(g_stage3[i]),
                .pk(p_stage3[i])
            );
        end else begin : gen_stage3_rest
            dot_operator stage3 (
                .gi(g_stage2[i-2]),
                .pi(p_stage2[i-2]),
                .gj(g_stage2[i+2]),
                .pj(p_stage2[i+2]),
                .gk(g_stage3[i]),
                .pk(p_stage3[i])
            );
        end
    end
endgenerate

// Stage 4 (24 dot operations)
wire [23:0] p_stage4, g_stage4;
generate
    for (i = 0; i < 24; i = i + 1) begin : gen_stage4
        if (i < 4) begin : gen_stage4_first
            dot_operator stage4 (
                .gi(g[i]),
                .pi(p[i]),
                .gj(g_stage3[i+4]),
                .pj(p_stage3[i+4]),
                .gk(g_stage4[i]),
                .pk(p_stage4[i])
            );
        end else begin : gen_stage4_rest
            dot_operator stage4 (
                .gi(g_stage3[i-4]),
                .pi(p_stage3[i-4]),
                .gj(g_stage3[i+4]),
                .pj(p_stage3[i+4]),
                .gk(g_stage4[i]),
                .pk(p_stage4[i])
            );
        end
    end
endgenerate


// Stage 5 (16 dot operations)
wire [15:0] p_stage5, g_stage5;
generate
    for (i = 0; i < 16; i = i + 1) begin : gen_stage5
        if (i < 8) begin : gen_stage5_first
            dot_operator stage5 (
                .gi(g[i]),
                .pi(p[i]),
                .gj(g_stage4[i+8]),
                .pj(p_stage4[i+8]),
                .gk(g_stage5[i]),
                .pk(p_stage5[i])
            );
        end else begin : gen_stage5_rest
            dot_operator stage5 (
                .gi(g_stage4[i-8]),
                .pi(p_stage4[i-8]),
                .gj(g_stage4[i+8]),
                .pj(p_stage4[i+8]),
                .gk(g_stage5[i]),
                .pk(p_stage5[i])
            );
        end
    end
endgenerate


// Calculate carries
assign C[0] = Cin;

generate
    for (i = 1; i < 33; i = i + 1) begin : gen_carry_calc
        if (i == 1) begin : gen_carry_calc0
            calc_carry carry_calc0 (
                .g(g[i-1]),
                .p(p[i-1]),
                .carry_in(C[i-1]),
                .carry_out(C[i])
            );
        end else if (i == 2) begin : gen_carry_calc1
            calc_carry carry_calc1 (
                .g(g_stage1[i-2]),
                .p(p_stage1[i-2]),
                .carry_in(C[i-1]),
                .carry_out(C[i])
            );
        end else if (i >= 3 && i <= 4) begin : gen_carry_calc2
            calc_carry carry_calc2 (
                .g(g_stage2[i-3]),
                .p(p_stage2[i-3]),
                .carry_in(C[i-1]),
                .carry_out(C[i])
            );
        end else if (i >= 5 && i <= 8) begin : gen_carry_calc3
            calc_carry carry_calc3 (
                .g(g_stage3[i-5]),
                .p(p_stage3[i-5]),
                .carry_in(C[i-1]),
                .carry_out(C[i])
            );
        end else if (i >= 9 && i <= 16) begin : gen_carry_calc4
            calc_carry carry_calc4 (
                .g(g_stage4[i-9]),
                .p(p_stage4[i-9]),
                .carry_in(C[i-1]),
                .carry_out(C[i])
            );
        end else if (i >= 17 && i <= 32) begin : gen_carry_calc5
            calc_carry carry_calc5 (
                .g(g_stage5[i-17]),
                .p(p_stage5[i-17]),
                .carry_in(C[i-1]),
                .carry_out(C[i])
            );
        end
    end
endgenerate

// Post-processing (Sum computation)
generate
    for (i = 0; i < 32; i = i + 1) begin : gen_post_process
        post_process sum_comp (
            .c(C[i]),
            .p(p[i]),
            .sum(sum_comb[i])
        );
    end
endgenerate

assign overflow_comb = (A[31] & B[31] & ~sum_comb[31]) | (~A[31] & ~B[31] & sum_comb[31]);

// Registering the sum output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Sum <= 32'b0;
        overflow <= 1'b0;
        valid_out <= 1'b0;
    end else if (valid_in) begin
        Sum <= sum_comb;
        overflow <= overflow_comb;
        valid_out <= valid_in;
    end
    else begin
        valid_out <= 1'b0;
    end
end

endmodule
