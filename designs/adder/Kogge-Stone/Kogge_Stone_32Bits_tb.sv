// verilog_lint: waive-start explicit-parameter-storage-type
// verilog_lint: waive-start parameter-name-style
// verilog_lint: waive-start line-length
// verilog_lint: waive-start explicit-function-task-parameter-type

`timescale 1ns/1ps

module Kogge_Stone_32Bits_tb ();

logic clk;
logic rst_n;
logic valid_in;
logic [31:0] A;
logic [31:0] B;
logic Cin;
logic [31:0] Sum;
logic Cout;
logic overflow;
logic valid_out;

logic [31:0] Expected_sum;
logic Expected_Cout;
logic Expected_overflow;

Kogge_Stone_32Bits DUT(.*);

localparam clock_period = 10;

int pass_count, fail_count;

initial begin
    clk = 1'b0;
    forever #(clock_period/2) clk = ~clk;
end

initial begin
    $dumpfile("Kogge_Stone_32Bits_tb.vcd");
    $dumpvars(0, Kogge_Stone_32Bits_tb);

    // Initialize inputs and apply reset
    rst_n = 1'b0;
    A = 32'b0;
    B = 32'b0;
    Cin = 1'b0;
    valid_in = 1'b0;
    pass_count = 0;
    fail_count = 0;

    @(negedge clk);
    rst_n = 1'b1;

    $display("+===============================================================+");
    $display("|                    Kogge-Stone 32-bit Adder                   |");
    $display("+===============================================================+");

    section("ZERO / IDENTITY");
    apply_and_check(32'd0,          32'd0,          1'b0);
    apply_and_check(32'd0,          32'd0,          1'b1);
    apply_and_check(-32'd1,         32'd0,          1'b0);
    apply_and_check(32'd0,          -32'd1,         1'b0);
    apply_and_check(32'd1,          32'd0,          1'b0);
    apply_and_check(32'd0,          32'd1,          1'b0);


    section("UNSIGNED BOUNDARY");
    apply_and_check(32'hFFFFFFFF,   32'd1,          1'b0);
    apply_and_check(32'hFFFFFFFF,   32'd0,          1'b1);
    apply_and_check(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b0);
    apply_and_check(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b1);
    apply_and_check(32'h80000000,   32'h80000000,   1'b0);
    apply_and_check(32'h80000000,   32'h7FFFFFFF,   1'b0);
    apply_and_check(32'h80000000,   32'h7FFFFFFF,   1'b1);

    section("SIGNED OVERFLOW - positive wrap");
    apply_and_check(32'sh7FFFFFFF,  32'sh00000001,  1'b0);
    apply_and_check(32'sh7FFFFFFF,  32'sh7FFFFFFF,  1'b0);
    apply_and_check(32'sh7FFFFFFE,  32'sh00000001,  1'b1);
    apply_and_check(32'sh40000000,  32'sh40000000,  1'b0);
    apply_and_check(32'sh7FFFFFFF,  32'sh00000000,  1'b1);

    section("SIGNED OVERFLOW - negative wrap");
    apply_and_check(32'sh80000000,  32'shFFFFFFFF,  1'b0);
    apply_and_check(32'sh80000000,  32'sh80000000,  1'b0);
    apply_and_check(32'sh80000001,  32'shFFFFFFFF,  1'b0);
    apply_and_check(32'shC0000000,  32'shC0000000,  1'b0);
    apply_and_check(32'sh80000000,  32'sh00000000,  1'b1);

    section("ALTERNATING BIT PATTERNS");
    apply_and_check(32'hAAAAAAAA,   32'h55555555,   1'b0);
    apply_and_check(32'hAAAAAAAA,   32'h55555555,   1'b1);
    apply_and_check(32'h55555555,   32'hAAAAAAAA,   1'b0);
    apply_and_check(32'hAAAAAAAA,   32'hAAAAAAAA,   1'b0);
    apply_and_check(32'h55555555,   32'h55555555,   1'b0);
    apply_and_check(32'h55555555,   32'h55555555,   1'b1);

    section("ALL-ONES / ALL-ZEROS");
    apply_and_check(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b0);
    apply_and_check(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b1);
    apply_and_check(32'h00000000,   32'h00000000,   1'b0);
    apply_and_check(32'h00000000,   32'h00000000,   1'b1);
    apply_and_check(32'hFFFFFFFF,   32'h00000000,   1'b1);
    apply_and_check(32'h00000000,   32'hFFFFFFFF,   1'b1);


    section("RANDOM TESTS");
    for (int i = 0; i < 100; i++) begin
        A = $urandom();
        B = $urandom();
        Cin = $urandom() % 2;

        apply_and_check(A, B, Cin);
    end

    $display("\nNumber of correct test cases = %0d", pass_count);
    $display("Number of failed test cases  = %0d\n", fail_count);

    #20;
    $stop;
end

task automatic apply_and_check(input logic [31:0] a, b, input logic cin);
    begin
        @(negedge clk);
        A        = a;
        B        = b;
        Cin      = cin;
        valid_in = 1'b1;

        @(negedge clk);
        valid_in = 1'b0;
        check();
    end
endtask

task automatic check();
    begin
        {Expected_Cout, Expected_sum} = A + B + Cin;
        Expected_overflow = (A[31] & B[31] & ~Expected_sum[31]) | (~A[31] & ~B[31] & Expected_sum[31]);

        if (Sum == Expected_sum && Cout == Expected_Cout && valid_out && overflow == Expected_overflow) begin
            pass_count++;
            $display("| %-6sat time %0t | #%-4d | A=%12d  B=%12d  Cin=%0b | Sum=%12d  Cout=%0b  Ovf=%0b |",
                         "PASS", $time/1000.0, pass_count,
                         $signed(A), $signed(B), Cin,
                         $signed(Sum), Cout, overflow);
        end else begin
            fail_count++;
            $display("| %-6sat time %0t | #%-4d | A=%12d  B=%12d  Cin=%0b | Got=%10d  Exp=%10d  Cout=%0b  Ovf=%0b | <-- MISMATCH",
                         "FAIL", $time/1000.0, pass_count + fail_count,
                         $signed(A), $signed(B), Cin,
                         $signed(Sum), $signed(Expected_sum), Cout, overflow);
        end
    end
endtask

task automatic section(input string name);
    $display("|");
    $display("+-- %-55s", name);
    $display("|");
endtask

endmodule
