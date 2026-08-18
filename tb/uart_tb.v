`timescale 1ns / 1ps

module uart_tb;

    // ============================================================
    // UART PARAMETERS
    // ============================================================

    parameter integer CLOCK_FREQ = 100_000_000;
    parameter integer BAUD_RATE  = 115_200;
    parameter integer OVERSAMPLE = 16;

    // UART bit period
    parameter integer BIT_PERIOD_NS =
        1_000_000_000 / BAUD_RATE;


    // ============================================================
    // TESTBENCH SIGNALS
    // ============================================================

    reg clk;
    reg reset;

    reg  [7:0] tx_data;
    reg        tx_start;

    wire       tx;
    wire       rx;

    wire       tx_busy;

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_busy;


    // ============================================================
    // LOOPBACK CONNECTION
    //
    // UART TX is directly connected to UART RX.
    // ============================================================

    assign rx = tx;


    // ============================================================
    // UART DUT
    // ============================================================

    uart #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(OVERSAMPLE)
    ) dut (

        .clk(clk),
        .reset(reset),

        .rx(rx),
        .tx(tx),

        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy)
    );


    // ============================================================
    // CLOCK GENERATION
    //
    // 100 MHz clock
    // Period = 10 ns
    // ============================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    // ============================================================
    // RESET
    // ============================================================

    initial begin

        reset    = 1'b1;
        tx_data  = 8'h00;
        tx_start = 1'b0;

        #100;

        reset = 1'b0;

        $display("");
        $display("==============================================");
        $display("       UART FULL LOOPBACK TEST");
        $display("==============================================");
        $display("Clock Frequency : %0d Hz", CLOCK_FREQ);
        $display("Baud Rate       : %0d", BAUD_RATE);
        $display("Bit Period      : %0d ns", BIT_PERIOD_NS);
        $display("==============================================");
        $display("");

    end


    // ============================================================
    // TASK: SEND ONE BYTE
    // ============================================================

    task send_byte;

        input [7:0] data;

        begin

            // Wait until transmitter is idle.
            wait (tx_busy == 1'b0);

            // Put byte on TX interface.
            tx_data = data;

            // Generate one-clock start pulse.
            @(posedge clk);
            tx_start = 1'b1;

            @(posedge clk);
            tx_start = 1'b0;

            $display("----------------------------------------------");
            $display("[TX] Sending byte 0x%02h", data);
            $display("----------------------------------------------");

            // Wait until transmission begins.
            wait (tx_busy == 1'b1);

            // Wait until complete UART frame has been transmitted.
            wait (tx_busy == 1'b0);

        end

    endtask


    // ============================================================
    // TASK: CHECK RECEIVED BYTE
    // ============================================================

    task check_byte;

        input [7:0] expected_data;

        begin

            // Wait for receiver to report valid data.
            wait (rx_valid == 1'b1);

            // Check received data.
            if (rx_data === expected_data) begin

                $display(
                    "[PASS] RX data = 0x%02h",
                    rx_data
                );

            end

            else begin

                $display(
                    "[FAIL] Expected 0x%02h, received 0x%02h",
                    expected_data,
                    rx_data
                );

            end

            // Wait for rx_valid to return LOW.
            @(negedge rx_valid);

            if (rx_valid === 1'b0) begin

                $display("[PASS] rx_valid pulse completed.");

            end

            else begin

                $display("[FAIL] rx_valid pulse error.");

            end

            $display("");

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // Wait until reset is released.
        wait (reset == 1'b0);

        // Give the design a little time after reset.
        #1000;


        // --------------------------------------------------------
        // TEST 1
        // --------------------------------------------------------

        fork
            send_byte(8'h00);
            check_byte(8'h00);
        join


        // --------------------------------------------------------
        // TEST 2
        // --------------------------------------------------------

        fork
            send_byte(8'hFF);
            check_byte(8'hFF);
        join


        // --------------------------------------------------------
        // TEST 3
        // --------------------------------------------------------

        fork
            send_byte(8'h55);
            check_byte(8'h55);
        join


        // --------------------------------------------------------
        // TEST 4
        // --------------------------------------------------------

        fork
            send_byte(8'hAA);
            check_byte(8'hAA);
        join


        // --------------------------------------------------------
        // TEST 5
        // --------------------------------------------------------

        fork
            send_byte(8'h41);
            check_byte(8'h41);
        join


        // --------------------------------------------------------
        // TEST 6
        // --------------------------------------------------------

        fork
            send_byte(8'h5A);
            check_byte(8'h5A);
        join


        // --------------------------------------------------------
        // TEST COMPLETE
        // --------------------------------------------------------

        $display("==============================================");
        $display("       UART LOOPBACK TEST COMPLETE");
        $display("==============================================");
        $display("");

        $finish;

    end

endmodule