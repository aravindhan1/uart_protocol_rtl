`timescale 1ns / 1ps

module uart_tx_tb;

    // ============================================================
    // Parameters
    // ============================================================

    localparam integer CLOCK_FREQ = 100_000_000;
    localparam integer BAUD_RATE  = 115_200;

    // 1 / 115200 = 8680.556 ns
    localparam integer BIT_PERIOD_NS = 8681;


    // ============================================================
    // Testbench signals
    // ============================================================

    reg clk;
    reg reset;

    reg tx_tick;

    reg [7:0] tx_data;
    reg       tx_start;

    wire tx;
    wire tx_busy;


    // ============================================================
    // DUT
    // ============================================================

    uart_tx dut (
        .clk      (clk),
        .reset    (reset),
        .tx_tick  (tx_tick),
        .tx_data  (tx_data),
        .tx_start (tx_start),
        .tx       (tx),
        .tx_busy  (tx_busy)
    );


    // ============================================================
    // 100 MHz clock
    // ============================================================

    always #5 clk = ~clk;


    // ============================================================
    // TX tick generator
    //
    // Stage 1 already verified the baud generator.
    // Therefore, Stage 2 directly supplies tx_tick.
    // ============================================================

    initial begin

        tx_tick = 1'b0;

        forever begin

            #(BIT_PERIOD_NS - 5);

            @(posedge clk);

            tx_tick = 1'b1;

            @(posedge clk);

            tx_tick = 1'b0;

        end

    end


    // ============================================================
    // Send one byte and check complete UART frame
    // ============================================================

    task send_and_check_byte;

        input [7:0] expected_data;

        integer i;

        reg [7:0] received_data;

        begin

            // ----------------------------------------------------
            // Wait until TX is idle
            // ----------------------------------------------------

            wait (tx_busy == 1'b0);


            // ----------------------------------------------------
            // Put data on TX input
            // ----------------------------------------------------

            @(posedge clk);

            tx_data  <= expected_data;
            tx_start <= 1'b1;

            @(posedge clk);

            tx_start <= 1'b0;


            // ----------------------------------------------------
            // Wait for START bit
            // ----------------------------------------------------

            @(negedge tx);


            $display("");
            $display("==============================================");

            $display(
                "Checking UART frame for 0x%02h",
                expected_data
            );

            $display("==============================================");


            // ----------------------------------------------------
            // Check START bit
            // ----------------------------------------------------

            #(BIT_PERIOD_NS / 2);

            if (tx !== 1'b0) begin

                $display("[FAIL] Start bit is not 0.");

            end
            else begin

                $display("[PASS] Start bit = 0.");

            end


            // ----------------------------------------------------
            // Move from START center to DATA0 center
            // ----------------------------------------------------

            #(BIT_PERIOD_NS);


            received_data = 8'd0;


            // ----------------------------------------------------
            // Sample 8 data bits
            // LSB first
            // ----------------------------------------------------

            for (i = 0; i < 8; i = i + 1) begin

                if (tx === 1'b1)

                    received_data[i] = 1'b1;

                else

                    received_data[i] = 1'b0;


                $display(
                    "[DATA] Bit %0d = %b",
                    i,
                    received_data[i]
                );


                #(BIT_PERIOD_NS);

            end


            // ----------------------------------------------------
            // Check received byte
            // ----------------------------------------------------

            if (received_data === expected_data) begin

                $display(
                    "[PASS] Data = 0x%02h",
                    received_data
                );

            end
            else begin

                $display(
                    "[FAIL] Expected 0x%02h, received 0x%02h",
                    expected_data,
                    received_data
                );

            end


            // ----------------------------------------------------
            // Check STOP bit
            // ----------------------------------------------------

            if (tx !== 1'b1) begin

                $display("[FAIL] Stop bit is not 1.");

            end
            else begin

                $display("[PASS] Stop bit = 1.");

            end


            $display("----------------------------------------------");

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        clk      = 1'b0;
        reset    = 1'b1;

        tx_data  = 8'd0;
        tx_start = 1'b0;


        // --------------------------------------------------------
        // Header
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("          UART TRANSMITTER TEST");
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


        // ========================================================
        // TEST 1 - 0x00
        // ========================================================

        send_and_check_byte(8'h00);


        // ========================================================
        // TEST 2 - 0xFF
        // ========================================================

        send_and_check_byte(8'hFF);


        // ========================================================
        // TEST 3 - 0x55
        // ========================================================

        send_and_check_byte(8'h55);


        // ========================================================
        // TEST 4 - 0xAA
        // ========================================================

        send_and_check_byte(8'hAA);


        // ========================================================
        // TEST 5 - ASCII A
        // ========================================================

        send_and_check_byte(8'h41);


        // ========================================================
        // TEST 6 - ASCII Z
        // ========================================================

        send_and_check_byte(8'h5A);


        // --------------------------------------------------------
        // Wait for TX to become idle
        // --------------------------------------------------------

        wait (tx_busy == 1'b0);


        #(BIT_PERIOD_NS);


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("       UART TX TEST COMPLETE");
        $display("==============================================");
        $display("");

        #100;

        $finish;

    end

endmodule