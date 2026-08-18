`timescale 1ns / 1ps

module uart_rx (
    input  wire       clk,
    input  wire       reset,

    input  wire       rx_tick,

    input  wire       rx,

    output reg [7:0]  rx_data,
    output reg        rx_valid,
    output reg        rx_busy
);

    // ============================================================
    // FSM states
    // ============================================================

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;


    // ============================================================
    // Internal registers
    // ============================================================

    reg [1:0] state;

    // Counts RX oversampling ticks.
    // 0 to 15 = one UART bit.
    reg [3:0] sample_count;

    // Counts received data bits.
    // 0 to 7 = eight data bits.
    reg [2:0] bit_index;

    // Temporary storage for received byte.
    reg [7:0] rx_shift_reg;


    // ============================================================
    // UART RX sequential logic
    // ============================================================

    always @(posedge clk) begin

        if (reset) begin

            state        <= STATE_IDLE;

            sample_count <= 4'd0;

            bit_index    <= 3'd0;

            rx_shift_reg <= 8'd0;

            rx_data      <= 8'd0;

            rx_valid     <= 1'b0;

            rx_busy      <= 1'b0;

        end

        else begin

            // ----------------------------------------------------
            // rx_valid is a one-clock pulse.
            //
            // It is asserted when a complete valid byte has
            // been received.
            // ----------------------------------------------------

            rx_valid <= 1'b0;


            case (state)


                // =================================================
                // IDLE
                // =================================================

                STATE_IDLE: begin

                    rx_busy <= 1'b0;

                    sample_count <= 4'd0;

                    bit_index <= 3'd0;


                    // UART idle line = 1
                    //
                    // A transition to 0 indicates a possible
                    // START bit.

                    if (rx == 1'b0) begin

                        rx_busy <= 1'b1;

                        sample_count <= 4'd0;

                        state <= STATE_START;

                    end

                end


                // =================================================
                // START BIT
                // =================================================

                STATE_START: begin

                    rx_busy <= 1'b1;


                    if (rx_tick) begin

                        // Wait 8 oversampling ticks.
                        //
                        // This places us approximately at the
                        // center of the START bit.

                        if (sample_count == 4'd7) begin

                            sample_count <= 4'd0;

                            // Confirm START bit is still low.

                            if (rx == 1'b0) begin

                                bit_index <= 3'd0;

                                state <= STATE_DATA;

                            end

                            else begin

                                // False start.
                                // Return to idle.

                                state <= STATE_IDLE;

                                rx_busy <= 1'b0;

                            end

                        end

                        else begin

                            sample_count <= sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // DATA BITS
                // =================================================

                STATE_DATA: begin

                    rx_busy <= 1'b1;


                    if (rx_tick) begin

                        // Wait 16 oversampling ticks between
                        // data-bit samples.

                        if (sample_count == 4'd15) begin

                            sample_count <= 4'd0;


                            // Sample current data bit.
                            //
                            // UART sends LSB first.

                            rx_shift_reg[bit_index] <= rx;


                            if (bit_index == 3'd7) begin

                                // All 8 data bits received.

                                state <= STATE_STOP;

                            end

                            else begin

                                bit_index <= bit_index + 1'b1;

                            end

                        end

                        else begin

                            sample_count <= sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // STOP BIT
                // =================================================

                STATE_STOP: begin

                    rx_busy <= 1'b1;


                    if (rx_tick) begin

                        // Wait one complete bit period after DATA7.

                        if (sample_count == 4'd15) begin

                            sample_count <= 4'd0;


                            // STOP bit must be logic 1.

                            if (rx == 1'b1) begin

                                // Transfer received byte
                                // to output.

                                rx_data <= rx_shift_reg;

                                // Indicate a valid byte.

                                rx_valid <= 1'b1;

                            end


                            // Whether stop bit is valid or not,
                            // return to idle.

                            state <= STATE_IDLE;

                            rx_busy <= 1'b0;

                        end

                        else begin

                            sample_count <= sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state        <= STATE_IDLE;

                    sample_count <= 4'd0;

                    bit_index    <= 3'd0;

                    rx_shift_reg <= 8'd0;

                    rx_data      <= 8'd0;

                    rx_valid     <= 1'b0;

                    rx_busy      <= 1'b0;

                end

            endcase

        end

    end

endmodule