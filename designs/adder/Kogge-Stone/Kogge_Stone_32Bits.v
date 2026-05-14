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
wire [32:0] C;          // Carry signals {C[0]=Cin … C[32]=Cout}
                        // Cout is not a output as we are intersted in signed addition

wire [31:0] sum_comb;
wire overflow_comb;

// Pre-Processing (Generate and Propagate computation)
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : gen_pre_process
        pre_process u_pre (
            .a(A[i]),
            .b(B[i]),
            .g(g[i]),
            .p(p[i])
        );
    end
endgenerate


// Kogge-Stone Prefix Computation
// Stage 1 (31 dot operations)
wire [31:0] p_stage1, g_stage1;

// bit 0 passes through unchanged
assign g_stage1[0] = g[0];
assign p_stage1[0] = p[0];
generate
    for (i = 1; i < 32; i = i + 1) begin : gen_stage1
        dot_operator u_stage1 (
            .gi(g[i-1]),
            .pi(p[i-1]),
            .gj(g[i]),
            .pj(p[i]),
            .gk(g_stage1[i]),
            .pk(p_stage1[i])
        );
        end
endgenerate

// Stage 2 (30 dot operations)
wire [31:0] p_stage2, g_stage2;

// bits 0->1 passes through unchanged
generate
    for (i = 0; i < 2; i = i + 1) begin : gen_stage2_pass
        assign g_stage2[i] = g_stage1[i];
        assign p_stage2[i] = p_stage1[i];
    end
endgenerate

generate
    for (i = 2; i < 32; i = i + 1) begin : gen_stage2
        dot_operator u_stage2 (
            .gi(g_stage1[i-2]),
            .pi(p_stage1[i-2]),
            .gj(g_stage1[i]),
            .pj(p_stage1[i]),
            .gk(g_stage2[i]),
            .pk(p_stage2[i])
        );
    end
endgenerate


// Stage 3 (28 dot operations)
wire [31:0] p_stage3, g_stage3;

// bits 0->3 passes through unchanged
generate
    for (i = 0; i < 4; i = i + 1) begin : gen_stage3_pass
        assign g_stage3[i] = g_stage2[i];
        assign p_stage3[i] = p_stage2[i];
    end
endgenerate

generate
    for (i = 4; i < 32; i = i + 1) begin : gen_stage3
        dot_operator u_stage3 (
            .gi(g_stage2[i-4]),
            .pi(p_stage2[i-4]),
            .gj(g_stage2[i]),
            .pj(p_stage2[i]),
            .gk(g_stage3[i]),
            .pk(p_stage3[i])
        );
    end
endgenerate

// Stage 4 (24 dot operations)
wire [31:0] p_stage4, g_stage4;

// bits 0->7 passes through unchanged
generate
    for (i = 0; i < 8; i = i + 1) begin : gen_stage4_pass
        assign g_stage4[i] = g_stage3[i];
        assign p_stage4[i] = p_stage3[i];
    end
endgenerate

generate
    for (i = 8; i < 32; i = i + 1) begin : gen_stage4
        dot_operator u_stage4 (
            .gi(g_stage3[i-8]),
            .pi(p_stage3[i-8]),
            .gj(g_stage3[i]),
            .pj(p_stage3[i]),
            .gk(g_stage4[i]),
            .pk(p_stage4[i])
        );
    end
endgenerate


// Stage 5 (16 dot operations)
wire [31:0] p_stage5, g_stage5;

// bits 0->15 passes through unchanged
generate
    for (i = 0; i < 16; i = i + 1) begin : gen_stage5_pass
        assign g_stage5[i] = g_stage4[i];
        assign p_stage5[i] = p_stage4[i];
    end
endgenerate

generate
    for (i = 16; i < 32; i = i + 1) begin : gen_stage5
        dot_operator u_stage5 (
            .gi(g_stage4[i-16]),
            .pi(p_stage4[i-16]),
            .gj(g_stage4[i]),
            .pj(p_stage4[i]),
            .gk(g_stage5[i]),
            .pk(p_stage5[i])
        );
    end
endgenerate


// Calculate carries
assign C[0] = Cin;

generate
    for (i = 0; i < 32; i = i + 1) begin : gen_carry_calc
        calc_carry u_carry_calc (
            .g(g_stage5[i]),
            .p(p_stage5[i]),
            .carry_in(Cin),
            .carry_out(C[i+1])
        );
    end
endgenerate

// Post-processing (Sum computation)
generate
    for (i = 0; i < 32; i = i + 1) begin : gen_post_process
        post_process u_post_process (
            .c(C[i]),
            .p(p[i]),
            .sum(sum_comb[i])
        );
    end
endgenerate

// Overflow detection for signed addition
assign overflow_comb = (A[31] & B[31] & ~sum_comb[31]) | (~A[31] & ~B[31] & sum_comb[31]);

// Registering the outputs
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
