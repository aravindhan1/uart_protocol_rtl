`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.08.2026 14:47:17
// Design Name: 
// Module Name: baud_tick_gen
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


module baud_tick_gen #(
    parameter integer CLOCK_FREQ = 100_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer OVERSAMPLE = 16
)(
    input  wire clk,
    input  wire reset,

    output reg  tx_tick,
    output reg  rx_tick
);

    localparam integer TX_TICK_FREQ = BAUD_RATE;
    localparam integer RX_TICK_FREQ = BAUD_RATE * OVERSAMPLE;

    localparam [63:0] TX_PHASE_INC_CALC = (64'd4294967296 * TX_TICK_FREQ) / CLOCK_FREQ;

    localparam [63:0] RX_PHASE_INC_CALC = (64'd4294967296 * RX_TICK_FREQ) / CLOCK_FREQ;

    localparam [31:0] TX_PHASE_INC = TX_PHASE_INC_CALC[31:0];
    localparam [31:0] RX_PHASE_INC = RX_PHASE_INC_CALC[31:0];
    
    reg [31:0] tx_accumulator;
    reg [31:0] rx_accumulator;
    
    reg [32:0] tx_sum;
    reg [32:0] rx_sum;
    
    always @(posedge clk) begin
        if (reset) begin
            tx_accumulator <= 32'd0;
            rx_accumulator <= 32'd0;

            tx_tick <= 1'b0;
            rx_tick <= 1'b0;
        end
        else begin
            tx_sum = {1'b0, tx_accumulator} + {1'b0, TX_PHASE_INC};
            rx_sum = {1'b0, rx_accumulator} + {1'b0, RX_PHASE_INC};

            tx_accumulator <= tx_sum[31:0];
            rx_accumulator <= rx_sum[31:0];

            tx_tick <= tx_sum[32];
            rx_tick <= rx_sum[32];
        end
    end
endmodule
