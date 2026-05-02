`timescale 1ns/1ps
module ASYNC_FIFO_tb ();

parameter  DATA_WIDTH = 32;
parameter  FIFO_DEPTH = 16;
parameter  WRITE_CLK_PERIOD = 50;
parameter  READ_CLK_PERIOD  = 10;
reg  wclk_tb;
reg  wrst_n_tb;
reg  winc_tb;
reg  [DATA_WIDTH - 1 : 0] wdata_tb;
wire  wfull_tb;
reg  rclk_tb;
reg  rrst_n_tb;
reg  rinc_tb;
wire [DATA_WIDTH - 1 : 0] rdata_tb;
wire empty_tb;
integer iter;
integer error_count;
reg [DATA_WIDTH - 1 : 0] expected_data;

ASYNC_FIFO #(
    .DATA_WIDTH (DATA_WIDTH),
    .FIFO_DEPTH (FIFO_DEPTH)
) async_fifo_dut (
    .wclk       (wclk_tb),
    .wrst_n     (wrst_n_tb),
    .winc       (winc_tb),
    .wdata      (wdata_tb),
    .wfull      (wfull_tb),
    .rclk       (rclk_tb),
    .rrst_n     (rrst_n_tb),
    .rinc       (rinc_tb),
    .rdata      (rdata_tb),
    .empty      (empty_tb)
);

initial begin
    wclk_tb = 1'b0;
    forever begin
        #(WRITE_CLK_PERIOD/2) wclk_tb = ~wclk_tb;
    end
end

initial begin
    rclk_tb = 1'b0;
    forever begin
        #(READ_CLK_PERIOD/2) rclk_tb = ~rclk_tb;
    end
end

initial begin
    $display("=== ASYNC FIFO Self-Test Started ===");
    $display("Time: %0t", $time);
    initialize_write_task ();
    initialize_read_task  ();
    // Test 1: Write until full, verify full flag
    $display("\nTest 1: Write until FIFO is full");

    write_until_full_task();

    $display("\nTest 2: Read until FIFO is empty");

    read_until_empty_task();

    $display("\nTest 3: Mixed read/write operations");
    winc_tb = 1'b1;
    wdata_tb = $random();
    @(negedge wclk_tb);
    wdata_tb = $random();
    @(negedge wclk_tb);
    for (iter=0; iter<20; iter=iter+1) begin
        mixed_write_read_task($random(), iter);
    end

    if (error_count == 0) begin
            $display("OVERALL RESULT: PASS");
            $display("All tests completed successfully!");
        end else begin
            $display("OVERALL RESULT: FAIL");
            $display("Tests failed with %0d errors", error_count);
        end
        
        $display("=== Test completed at time: %0t ===", $time);
    $stop();
end

task initialize_write_task ();
  begin
    wrst_n_tb = 1'b0;
    winc_tb   = 1'b0;
    wdata_tb  = 'b0;
    error_count = 'b0;
    @(negedge wclk_tb);
    wrst_n_tb = 1'b1;
  end 
endtask

task initialize_read_task ();
  begin
    rrst_n_tb = 1'b0;
    rinc_tb   = 1'b0;
    @(negedge rclk_tb);
    rrst_n_tb = 1'b1;
  end
endtask

// Task to write until FIFO is full
task write_until_full_task();
  integer i;
  begin
    begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            if (wfull_tb == 1'b1) begin
            $display("ERROR: Full flag asserted before writing %d items at time: %0t", FIFO_DEPTH, $time);
            error_count = error_count + 1;
            end else begin
            $display("PASS: Full flag correctly doesn't asserted before writing %d items", FIFO_DEPTH);
            end
            write_data_task($random(), i);
            
        end
        
        // Verify full flag is asserted
        @(negedge wclk_tb);
        if (wfull_tb !== 1'b1) begin
            $display("ERROR: Full flag not asserted after writing %d items at time: %0t", FIFO_DEPTH, $time);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Full flag correctly asserted after writing %d items", FIFO_DEPTH);
        end
        
        // Try to write when full (should be blocked)
        winc_tb = 1'b1;
        wdata_tb = $random();
        @(negedge wclk_tb);
        if (wdata_tb == async_fifo_dut.u_mem.mem[0]) begin
            $display("ERROR: Fifo overwrires!");
        end
        else begin
            $display("PASS: FIFO doesn't overwrites");
        end
        winc_tb = 1'b0;
        $display("Attempted write when full at time: %0t", $time);
    end
  end
    
endtask

// Individual write task
task write_data_task(input [DATA_WIDTH - 1 : 0] data_in, input integer iter);
    begin
        if (wfull_tb) begin
            $display("WARNING: Cannot write - FIFO full at iter %d, time: %0t", iter, $time);
        end
        
        winc_tb = 1'b1;
        wdata_tb = data_in;
        @(negedge wclk_tb);
        winc_tb = 1'b0;
         
        $display("WRITE: Data=0x%h, Iter=%d, Time=%0t", data_in, iter, $time);
    end
endtask

// Task to read until FIFO is empty
task read_until_empty_task();
    integer i;
    begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                if (empty_tb == 1'b1) 
                  begin
                    $display("ERROR: Empty flag asserted before reading %d items at time: %0t", FIFO_DEPTH, $time);
                    error_count = error_count + 1;
                  end 
                else 
                  begin
                    $display("PASS: Empty flag correctly doesn't asserted before reading %d items", FIFO_DEPTH);
                   end
                expected_data = async_fifo_dut.u_mem.mem[i];
                
                read_and_verify_task(expected_data, i);
        end
        
        // Verify empty flag is asserted
        @(negedge rclk_tb);
        if (empty_tb !== 1'b1) begin
            $display("ERROR: Empty flag not asserted after reading %d items at time: %0t", FIFO_DEPTH, $time);
            error_count = error_count + 1;
        end else begin
            $display("PASS: Empty flag correctly asserted after reading %d items", FIFO_DEPTH);
        end
        
        // Try to read when empty (should get old data or zeros)
        rinc_tb = 1'b1;
        @(negedge rclk_tb);
        if (rdata_tb == async_fifo_dut.u_mem.mem[1]) begin
            $display("ERROR: Fifo read old data again!");
        end
        else begin
            $display("PASS: FIFO doesn't read old data ");
        end
        rinc_tb = 1'b0;
        $display("Attempted read when empty at time: %0t", $time);
    end
endtask
// Individual read and verify task
task read_and_verify_task(input [DATA_WIDTH - 1 : 0] expected_data, input integer iter);
    begin
        if (empty_tb) begin
            $display("WARNING: Cannot read - FIFO empty at iter %d, time: %0t", iter, $time);
            
        end
        
        rinc_tb = 1'b1;
        @(negedge rclk_tb);
        
        if (rdata_tb !== expected_data) begin
            $display("ERROR: Data mismatch! Expected=0x%h, Actual=0x%h, Iter=%d, Time=%0t", 
                     expected_data, rdata_tb, iter, $time);
            error_count = error_count + 1;
        end else begin
            $display("READ:  Data=0x%h, Iter=%d, Time=%0t - PASS", 
                     rdata_tb, iter, $time);
        end
    end
endtask
task mixed_write_read_task(input [DATA_WIDTH - 1 : 0] data_in, input integer iter);
  begin
    fork
        begin
          winc_tb = 1'b1;
          wdata_tb = data_in;
          @(negedge wclk_tb);
        end

        begin
          rinc_tb = 1'b1;
          @(negedge rclk_tb);
          if (rdata_tb != async_fifo_dut.u_mem.mem[iter]) begin
                    $display("ERROR: Mixed operation data mismatch! Expected=0x%h, Actual=0x%h, Iter=%d, Time=%0t", 
                             async_fifo_dut.u_mem.mem[iter], rdata_tb, iter, $time);
                    error_count = error_count + 1;
                end else begin
                    $display("MIXED_READ:  Data=0x%h, Iter=%d, Time=%0t - PASS", 
                             rdata_tb, iter, $time);
                end
        end
    join
  end
endtask

endmodule
