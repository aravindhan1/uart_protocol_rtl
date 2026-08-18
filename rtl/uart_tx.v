`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.08.2026 15:54:02
// Design Name: 
// Module Name: uart_tx
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
module uart_tx (
    input  wire       clk,
    input  wire       reset,
    input  wire       tx_tick,
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output reg        tx,
    output reg        tx_busy
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
    reg [7:0] tx_data_reg;
    reg [2:0] bit_index;
    // ============================================================
    // UART TX sequential logic
    // ============================================================
    always @(posedge clk) begin
        if (reset) begin
            state       <= STATE_IDLE;
            tx_data_reg <= 8'd0;
            bit_index   <= 3'd0;
            tx          <= 1'b1;
            tx_busy     <= 1'b0;
        end
        else begin
            case (state)
                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------
                STATE_IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        bit_index   <= 3'd0;
                        tx          <= 1'b0;
                        tx_busy     <= 1'b1;
                        state <= STATE_START;
                    end
                end
                // ------------------------------------------------
                // START BIT
                // ------------------------------------------------
                STATE_START: begin
                    tx_busy <= 1'b1;
                    if (tx_tick) begin
                        tx <= tx_data_reg[0];
                        state <= STATE_DATA;
                    end
                end
                // ------------------------------------------------
                // DATA BITS
                // ------------------------------------------------
                STATE_DATA: begin
                    tx_busy <= 1'b1;
                    if (tx_tick) begin
                        if (bit_index == 3'd7) begin
                            tx <= 1'b1;
                            state <= STATE_STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                            tx <= tx_data_reg[bit_index + 1'b1];
                        end
                    end
                end
                // ------------------------------------------------
                // STOP BIT
                // ------------------------------------------------
                STATE_STOP: begin
                    tx_busy <= 1'b1;
                    tx      <= 1'b1;
                    if (tx_tick) begin
                        state   <= STATE_IDLE;
                        tx_busy <= 1'b0;
                    end
                end
                // ------------------------------------------------
                // Default recovery
                // ------------------------------------------------
                default: begin
                    state       <= STATE_IDLE;
                    tx_data_reg <= 8'd0;
                    bit_index   <= 3'd0;
                    tx          <= 1'b1;
                    tx_busy     <= 1'b0;
                end
            endcase
        end
    end
endmodule
