`timescale 1ns / 1ps

module uart_rx_tb;

    // ============================================================
    // Parameters
    // ============================================================

    localparam integer CLOCK_FREQ = 100_000_000;
    localparam integer BAUD_RATE  = 115_200;
    localparam integer OVERSAMPLE = 16;

    // UART bit period:
    //
    // 1 / 115200 = 8.680556 us
    //
    // Rounded for testbench waveform generation.
    localparam integer BIT_PERIOD_NS = 8681;


    // ============================================================
    // Testbench signals
    // ============================================================

    reg clk;
    reg reset;

    reg rx;

    wire rx_tick;

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_busy;


    // ============================================================
    // Baud Tick Generator
    //
    // This is the actual Stage 1 module.
    // ============================================================

    baud_tick_gen #(
        .CLOCK_FREQ (CLOCK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .OVERSAMPLE (OVERSAMPLE)
    ) baud_gen (
        .clk      (clk),
        .reset    (reset),

        .tx_tick  (),
        .rx_tick  (rx_tick)
    );


    // ============================================================
    // UART RX
    //
    // Device Under Test
    // ============================================================

    uart_rx dut (
        .clk      (clk),
        .reset    (reset),

        .rx_tick  (rx_tick),

        .rx       (rx),

        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .rx_busy  (rx_busy)
    );


    // ============================================================
    // 100 MHz FPGA clock
    //
    // Period = 10 ns
    // ============================================================

    always #5 clk = ~clk;


    // ============================================================
    // Task: Send one UART bit
    //
    // This represents an external UART transmitter.
    //
    // UART line is held at the requested level for one
    // complete UART bit period.
    // ============================================================

    task send_bit;

        input bit_value;

        begin

            rx = bit_value;

            #(BIT_PERIOD_NS);

        end

    endtask


    // ============================================================
    // Task: Send one UART byte
    //
    // UART format = 8-N-1
    //
    // START = 0
    // DATA  = LSB first
    // STOP  = 1
    // ============================================================

    task send_uart_byte;

        input [7:0] data;

        integer i;

        begin

            $display("");
            $display("----------------------------------------------");

            $display(
                "[TX MODEL] Sending byte 0x%02h",
                data
            );

            $display("----------------------------------------------");


            // ----------------------------------------------------
            // START BIT
            // ----------------------------------------------------

            send_bit(1'b0);


            // ----------------------------------------------------
            // DATA BITS
            //
            // LSB first
            // ----------------------------------------------------

            for (i = 0; i < 8; i = i + 1) begin

                $display(
                    "[TX MODEL] Bit %0d = %b",
                    i,
                    data[i]
                );

                send_bit(data[i]);

            end


            // ----------------------------------------------------
            // STOP BIT
            // ----------------------------------------------------

            send_bit(1'b1);


            // ----------------------------------------------------
            // Return line to UART idle state
            // ----------------------------------------------------

            rx = 1'b1;


            // Give RX some time to assert rx_valid.
            //
            // The actual baud tick generator determines the
            // exact internal sampling timing.

            #(BIT_PERIOD_NS);


        end

    endtask


    // ============================================================
    // Task: Check received byte
    // ============================================================

task check_received_byte;

    input [7:0] expected_data;

    begin

        // --------------------------------------------------------
        // Wait until RX reports a valid byte.
        // --------------------------------------------------------

        wait (rx_valid == 1'b1);


        // --------------------------------------------------------
        // Check received data.
        // --------------------------------------------------------

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


        // --------------------------------------------------------
        // Wait for the actual falling edge of rx_valid.
        //
        // rx_valid is intended to be a one-clock pulse.
        // --------------------------------------------------------

        @(negedge rx_valid);


        // --------------------------------------------------------
        // Confirm rx_valid is now LOW.
        // --------------------------------------------------------

        if (rx_valid !== 1'b0) begin

            $display(
                "[FAIL] rx_valid did not return low."
            );

        end

        else begin

            $display(
                "[PASS] rx_valid pulse completed."
            );

        end

    end

endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        clk   = 1'b0;
        reset = 1'b1;

        // UART idle state is HIGH.
        rx = 1'b1;


        // --------------------------------------------------------
        // Header
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("             UART RX TEST");
        $display("==============================================");

        $display(
            "Clock Frequency : %0d Hz",
            CLOCK_FREQ
        );

        $display(
            "Baud Rate       : %0d",
            BAUD_RATE
        );

        $display(
            "Oversampling    : %0d",
            OVERSAMPLE
        );

        $display(
            "Bit Period      : %0d ns",
            BIT_PERIOD_NS
        );

        $display("==============================================");


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #100;

        reset = 1'b0;

        $display("");

        $display(
            "[TEST] Reset released at %0t",
            $time
        );


        // --------------------------------------------------------
        // Make sure line remains idle before first frame.
        // --------------------------------------------------------

        rx = 1'b1;

        #(BIT_PERIOD_NS);


        // ========================================================
        // TEST 1 - 0x00
        // ========================================================

        fork

            send_uart_byte(8'h00);

            check_received_byte(8'h00);

        join


        // --------------------------------------------------------
        // Idle gap
        // --------------------------------------------------------

        #(BIT_PERIOD_NS);


        // ========================================================
        // TEST 2 - 0xFF
        // ========================================================

        fork

            send_uart_byte(8'hFF);

            check_received_byte(8'hFF);

        join


        #(BIT_PERIOD_NS);


        // ========================================================
        // TEST 3 - 0x55
        // ========================================================

        fork

            send_uart_byte(8'h55);

            check_received_byte(8'h55);

        join


        #(BIT_PERIOD_NS);


        // ========================================================
        // TEST 4 - 0xAA
        // ========================================================

        fork

            send_uart_byte(8'hAA);

            check_received_byte(8'hAA);

        join


        #(BIT_PERIOD_NS);


        // ========================================================
        // TEST 5 - ASCII 'A'
        // ========================================================

        fork

            send_uart_byte(8'h41);

            check_received_byte(8'h41);

        join


        #(BIT_PERIOD_NS);


        // ========================================================
        // TEST 6 - ASCII 'Z'
        // ========================================================

        fork

            send_uart_byte(8'h5A);

            check_received_byte(8'h5A);

        join


        // --------------------------------------------------------
        // Final idle period
        // --------------------------------------------------------

        rx = 1'b1;

        #(BIT_PERIOD_NS * 2);


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("          UART RX TEST COMPLETE");
        $display("==============================================");
        $display("");

        #100;

        $finish;

    end

endmodule