`timescale 1ns/1ps

module fifo_bk_top_tb;

    parameter DATA_WIDTH = 32;

    reg wclk = 0;
    reg rclk = 0;

    always #25 wclk = ~wclk; 
    always #5  rclk = ~rclk;  

    reg wrst_n, rrst_n;
    reg winc;
    reg [31:0] wdata;
    reg [31:0] A;
    reg Cin;

    wire [31:0] Sum;
    wire overflow;
    wire valid_out;
    wire empty, wfull;

    fifo_bk_top dut (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .A(A),
        .Cin(Cin),
        .Sum(Sum),
        .overflow(overflow),
        .valid_out(valid_out),
        .empty(empty),
        .wfull(wfull)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    reg [31:0] expected_sum;
    reg expected_overflow;

    reg [31:0] fifo_model [0:100];
    integer wr_ptr = 0;
    integer rd_ptr = 0;

    // -----------------------------------
    // Task: Reset
    // -----------------------------------
    task reset_system;
    begin
        wrst_n = 0;
        rrst_n = 0;
        winc   = 0;
        A      = 0;
        Cin    = 0;
        repeat(2) @(posedge wclk);
        wrst_n = 1;
        rrst_n = 1;
    end
    endtask

    task write_fifo(input [31:0] data);
    begin
        @(posedge wclk);
        if (!wfull) begin
            winc  = 1;
            wdata = data;
            fifo_model[wr_ptr] = data;
            wr_ptr = wr_ptr + 1;
        end
        @(posedge wclk);
        winc = 0;
    end
    endtask

    task compute_expected(input [31:0] A_t, B_t, input Cin_t);
        reg [32:0] tmp;
    begin
        tmp = A_t + B_t + Cin_t;
        expected_sum = tmp[31:0];

        expected_overflow =
            (A_t[31] & B_t[31] & ~expected_sum[31]) |
            (~A_t[31] & ~B_t[31] & expected_sum[31]);
    end
    endtask

    task check_result(input [31:0] A_t, B_t, input Cin_t);
    begin
        compute_expected(A_t, B_t, Cin_t);
        wait(valid_out);

        if (Sum === expected_sum && overflow === expected_overflow) begin
            pass_count = pass_count + 1;
            $display("PASS: A=%h B=%h Sum=%h", A_t, B_t, Sum);
        end else begin
            fail_count = fail_count + 1;
            $display("FAIL: A=%h B=%h Expected=%h Got=%h",
                     A_t, B_t, expected_sum, Sum);
        end
    end
    endtask

    task directed_tests;
    begin
        write_fifo(32'h00000001);
        A = 32'h00000001; Cin = 0;
        check_result(A, fifo_model[rd_ptr++], Cin);

        write_fifo(32'h7FFFFFFF);
        A = 32'h00000001; Cin = 0;
        check_result(A, fifo_model[rd_ptr++], Cin);

        write_fifo(32'hFFFFFFFF);
        A = 32'h00000001; Cin = 0;
        check_result(A, fifo_model[rd_ptr++], Cin);
    end
    endtask

    task random_tests;
        integer i;
        reg [31:0] rand_data;
    begin
        for (i = 0; i < 20; i = i + 1) begin
            rand_data = $random;
            write_fifo(rand_data);
            @(posedge rclk);
            A   = $random;
            Cin = $random % 2;
            check_result(A, fifo_model[rd_ptr++], Cin);
        end
    end
    endtask

    initial begin
        reset_system();

        directed_tests();
        random_tests();

        repeat(10) @(posedge wclk);
        $display("TOTAL PASS = %0d", pass_count);
        $display("TOTAL FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED");

        $stop;
    end
endmodule