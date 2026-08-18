`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.08.2026 14:47:41
// Design Name: 
// Module Name: baud_tick_gen_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module baud_tick_gen_tb;
    // ============================================================
    // Parameters
    // ============================================================
    localparam integer CLOCK_FREQ = 100_000_000;
    localparam integer BAUD_RATE  = 115_200;
    localparam integer OVERSAMPLE = 16;

    localparam real TX_PERIOD_NS =
        1_000_000_000.0 / BAUD_RATE;

    localparam real RX_PERIOD_NS =
        1_000_000_000.0 / (BAUD_RATE * OVERSAMPLE);
    // ============================================================
    // Testbench signals
    // ===========================================================
    reg clk;
    reg reset;

    wire tx_tick;
    wire rx_tick;
    // ============================================================
    // Test counters
    // ============================================================
    integer tx_tick_count;
    integer rx_tick_count;

    integer error_count;

    time last_tx_tick_time;
    time last_rx_tick_time;

    time tx_period_measured;
    time rx_period_measured;
    // ============================================================
    // Instantiate DUT
    // DUT = Device Under Test
    // ============================================================
    baud_tick_gen #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(OVERSAMPLE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .tx_tick(tx_tick),
        .rx_tick(rx_tick)
    );
    // ============================================================
    // 100 MHz clock generation
    //
    // Period = 10 ns
    // Half period = 5 ns
    // ============================================================
    always #5 clk = ~clk;
    // ============================================================
    // TX tick monitor
    // ============================================================
    always @(posedge clk) begin
        if (!reset && tx_tick) begin
            tx_tick_count = tx_tick_count + 1;
            if (last_tx_tick_time != 0) begin
                tx_period_measured =
                    $time - last_tx_tick_time;
                $display(
                    "[TX] Tick %0d : time = %0t ns, period = %0t ns",
                    tx_tick_count,
                    $time,
                    tx_period_measured
                );
            end
            else begin
                $display(
                    "[TX] First tick at %0t ns",
                    $time
                );
            end
            last_tx_tick_time = $time;
        end
    end
    // ============================================================
    // RX tick monitor
    // ============================================================
    always @(posedge clk) begin
        if (!reset && rx_tick) begin
           rx_tick_count = rx_tick_count + 1;
            if (last_rx_tick_time != 0) begin
                rx_period_measured =
                    $time - last_rx_tick_time;
                $display(
                    "[RX] Tick %0d : time = %0t ns, period = %0t ns",
                    rx_tick_count,
                    $time,
                    rx_period_measured
                );
            end
            else begin
                $display(
                    "[RX] First tick at %0t ns",
                    $time
                );
            end
            last_rx_tick_time = $time;
        end
    end
    // ============================================================
    // Main test sequence
    // ============================================================
    initial begin
        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------
        clk = 1'b0;
        reset = 1'b1;

        tx_tick_count = 0;
        rx_tick_count = 0;

        error_count = 0;

        last_tx_tick_time = 0;
        last_rx_tick_time = 0;

        tx_period_measured = 0;
        rx_period_measured = 0;
        // --------------------------------------------------------
        // Start simulation
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display(" UART BAUD TICK GENERATOR TEST");
        $display("==============================================");

        $display("Clock Frequency : %0d Hz", CLOCK_FREQ);
        $display("Baud Rate       : %0d", BAUD_RATE);
        $display("Oversample      : %0d", OVERSAMPLE);

        $display(
            "Expected TX period : %0.3f ns",
            TX_PERIOD_NS
        );

        $display(
            "Expected RX period : %0.3f ns",
            RX_PERIOD_NS
        );

        $display("==============================================");
        $display("");
        // --------------------------------------------------------
        // Hold reset
        // --------------------------------------------------------
        #100;
        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------
        reset = 1'b0;
        $display(
            "[TEST] Reset released at %0t ns",
            $time
        );
        $display("");
        // --------------------------------------------------------
        // Run long enough to observe several ticks
        // --------------------------------------------------------
        #30_000;
        // --------------------------------------------------------
        // Stop simulation
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display(" TEST RESULTS");
        $display("==============================================");
        $display(
            "TX ticks detected : %0d",
            tx_tick_count
        );
        $display(
            "RX ticks detected : %0d",
            rx_tick_count
        );
        // --------------------------------------------------------
        // Check that TX ticks occurred
        // --------------------------------------------------------
        if (tx_tick_count < 2) begin

            $display(
                "[FAIL] Not enough TX ticks detected."
            );
            error_count = error_count + 1;
        end
        else begin
            $display(
                "[PASS] TX tick generation is active."
            );
        end
        // --------------------------------------------------------
        // Check that RX ticks occurred
        // --------------------------------------------------------
        if (rx_tick_count < 10) begin
            $display(
                "[FAIL] Not enough RX ticks detected."
            );
            error_count = error_count + 1;
        end
        else begin
            $display(
                "[PASS] RX tick generation is active."
            );
        end
        // --------------------------------------------------------
        // Check TX period
        // Expected ? 8680.556 ns
        // Our clock resolution is 10 ns, so allow ±20 ns.
        // --------------------------------------------------------
        if (tx_tick_count >= 2) begin
           if ((tx_period_measured < 8660) ||
                (tx_period_measured > 8700)) begin
                $display(
                    "[FAIL] TX period incorrect: %0t ns",
                    tx_period_measured
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "[PASS] TX period is correct: %0t ns",
                    tx_period_measured
                );
            end
        end
        // --------------------------------------------------------
        // Check RX period
        // Expected ? 542.535 ns
        // Because the FPGA clock is 10 ns resolution,
        // allow ±20 ns.
        // --------------------------------------------------------
        if (rx_tick_count >= 2) begin
            if ((rx_period_measured < 520) ||
                (rx_period_measured > 565)) begin
                $display(
                    "[FAIL] RX period incorrect: %0t ns",
                    rx_period_measured
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "[PASS] RX period is correct: %0t ns",
                    rx_period_measured
                );
            end
        end
        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        if (error_count == 0) begin
            $display("          STAGE 1 : PASS");
            $display("==============================================");
            $display("");
            $display(
                "Baud tick generator verification successful."
            );
        end
        else begin
            $display("          STAGE 1 : FAIL");
            $display("==============================================");
            $display(
                "Number of errors = %0d",
                error_count
            );
        end
        $display("");
        $finish;
    end
endmodule