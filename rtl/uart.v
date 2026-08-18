`timescale 1ns / 1ps

module uart #(
    parameter integer CLOCK_FREQ = 100_000_000,
    parameter integer BAUD_RATE  = 115_200,
    parameter integer OVERSAMPLE = 16
)(
    input  wire       clk,
    input  wire       reset,

    // UART serial pins
    input  wire       rx,
    output wire       tx,

    // Transmit interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_busy,

    // Receive interface
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       rx_busy
);

    // ------------------------------------------------------------
    // Baud tick signals
    // ------------------------------------------------------------

    wire tx_tick;
    wire rx_tick;


    // ------------------------------------------------------------
    // Baud Tick Generator
    // ------------------------------------------------------------

    baud_tick_gen #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(OVERSAMPLE)
    ) baud_gen (
        .clk(clk),
        .reset(reset),

        .tx_tick(tx_tick),
        .rx_tick(rx_tick)
    );


    // ------------------------------------------------------------
    // UART Transmitter
    // ------------------------------------------------------------

    uart_tx tx_unit (
        .clk(clk),
        .reset(reset),

        .tx_tick(tx_tick),
        .tx_data(tx_data),
        .tx_start(tx_start),

        .tx(tx),
        .tx_busy(tx_busy)
    );


    // ------------------------------------------------------------
    // UART Receiver
    // ------------------------------------------------------------

    uart_rx rx_unit (
        .clk(clk),
        .reset(reset),

        .rx(rx),
        .rx_tick(rx_tick),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy)
    );

endmodule