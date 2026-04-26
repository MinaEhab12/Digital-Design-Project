`timescale 1ns/1ps

module tb_brent_kung_32;

    logic        clk;
    logic        rst_n;
    logic        valid_in;
    logic [31:0] A, B;
    logic        Cin;

    wire [31:0] Sum;
    wire        overflow;
    wire        valid_out;

    brent_kung_32 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_in (valid_in),
        .A        (A),
        .B        (B),
        .Cin      (Cin),
        .Sum      (Sum),
        .overflow (overflow),
        .valid_out(valid_out)
    );

    // =========================
    // Clock  — 100 MHz → T=10ns
    // =========================
    initial clk = 0;
    always #5 clk = ~clk;

    // =========================
    // Counters
    // =========================
    int pass_count = 0;
    int fail_count = 0;

    // =========================
    // Section header helper
    // =========================
    task automatic section(input string name);
        $display("|");
        $display("+-- %-55s", name);
        $display("|");
    endtask

    // =========================
    // Apply & Check Task (Simple flow, Original detailed checks)
    // =========================
    task automatic apply(input logic [31:0] a, input logic [31:0] b, input logic cin);
        logic [32:0] expected;
        begin
            // 1. Drive inputs
            @(negedge clk);
            A = a; B = b; Cin = cin;
            valid_in = 1;

            // 2. Wait for DUT to assert valid_out
            @(posedge clk iff valid_out);

            // 3. Original detailed check logic
            expected = a + b + cin;

            if (Sum !== expected) begin
                fail_count++;
                $display("| %-6s | #%-4d | A=%12d  B=%12d  Cin=%0b | Got=%10d  Exp=%10d  Ovf=%0b | <-- MISMATCH",
                         "FAIL", pass_count + fail_count,
                         $signed(a), $signed(b), cin,
                         $signed(Sum), $signed(expected[31:0]), overflow);
                $stop;
            end else begin
                pass_count++;
                $display("| %-6s | #%-4d | A=%12d  B=%12d  Cin=%0b | Sum=%12d  Ovf=%0b |",
                         "PASS", pass_count,
                         $signed(a), $signed(b), cin,
                         $signed(Sum), overflow);
            end

            // 4. Clear valid_in so we don't double-trigger
            @(negedge clk);
            valid_in = 0;
        end
    endtask

    // =========================
    // STIMULUS SEQUENCE
    // =========================
    initial begin
        $dumpfile("tb_brent_kung_32.vcd");
        $dumpvars(0, tb_brent_kung_32);

        // Initialization
        A = 0; B = 0; Cin = 0; valid_in = 0;
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("");
        $display("+===============================================================+");
        $display("|                  Brent-Kung 32-bit Adder                      |");
        $display("+===============================================================+");
        $display("");

        // ── Zero / Identity -----------------------------------------------──
        // section("ZERO / IDENTITY");
        // apply(32'd0,          32'd0,          1'b0);
        // apply(32'd0,          32'd0,          1'b1);
        // apply(32'hFFFFFFFF,   32'd0,          1'b0);
        // apply(32'd0,          32'hFFFFFFFF,   1'b0);
        // apply(32'd1,          32'd0,          1'b0);
        // apply(32'd0,          32'd1,          1'b0);

        // ── Unsigned boundary -----------------------------------------------
        // section("UNSIGNED BOUNDARY");
        // apply(32'hFFFFFFFF,   32'd1,          1'b0);
        // apply(32'hFFFFFFFF,   32'd0,          1'b1);
        // apply(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b0);
        // apply(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b1);
        // apply(32'h80000000,   32'h80000000,   1'b0);
        // apply(32'h80000000,   32'h7FFFFFFF,   1'b0);
        // apply(32'h80000000,   32'h7FFFFFFF,   1'b1);

        // // ── Signed overflow -----------------------------------------------
        // section("SIGNED OVERFLOW — positive wrap");
        apply(32'sh7FFFFFFF,  32'sh00000001,  1'b0);
        // apply(32'sh7FFFFFFF,  32'sh7FFFFFFF,  1'b0);
        // apply(32'sh7FFFFFFE,  32'sh00000001,  1'b1);
        // apply(32'sh40000000,  32'sh40000000,  1'b0);
        // apply(32'sh7FFFFFFF,  32'sh00000000,  1'b1);

        // section("SIGNED OVERFLOW — negative wrap");
        // apply(32'sh80000000,  32'shFFFFFFFF,  1'b0);
        // apply(32'sh80000000,  32'sh80000000,  1'b0);
        // apply(32'sh80000001,  32'shFFFFFFFF,  1'b0);
        // apply(32'shC0000000,  32'shC0000000,  1'b0);
        // apply(32'sh80000000,  32'sh00000000,  1'b1);

        // // ── Alternating bit patterns ----------------------------------------
        // section("ALTERNATING BIT PATTERNS");
        // apply(32'hAAAAAAAA,   32'h55555555,   1'b0);
        // apply(32'hAAAAAAAA,   32'h55555555,   1'b1);
        // apply(32'h55555555,   32'hAAAAAAAA,   1'b0);
        // apply(32'hAAAAAAAA,   32'hAAAAAAAA,   1'b0);
        // apply(32'h55555555,   32'h55555555,   1'b0);
        // apply(32'h55555555,   32'h55555555,   1'b1);

        // // ── All ones / all zeros --------------------------------------------
        // section("ALL-ONES / ALL-ZEROS");
        // apply(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b0);
        // apply(32'hFFFFFFFF,   32'hFFFFFFFF,   1'b1);
        // apply(32'h00000000,   32'h00000000,   1'b0);
        // apply(32'h00000000,   32'h00000000,   1'b1);
        // apply(32'hFFFFFFFF,   32'h00000000,   1'b1);
        // apply(32'h00000000,   32'hFFFFFFFF,   1'b1);

        // // ── Directed random -------------------------------------------------
        // section("DIRECTED RANDOM (100)");
        // for (int i = 0; i < 100; i++) begin
        //     apply($random, $random, $random % 2);
        // end

        // ── Summary ---------------------------------------------------------
        $display("");
        $display("+===============================================================+");
        if (fail_count == 0) begin
            $display("|                     ALL TESTS PASSED                         |");
            $display("|           Total: %-4d passed,  0 failed                      |", pass_count);
        end else begin
            $display("|                   *** FAILURES DETECTED *** |");
            $display("|           Total: %-4d passed,  %-4d failed                   |", pass_count, fail_count);
        end
        $display("+===============================================================+");
        $display("");
        
        $finish;
    end

endmodule