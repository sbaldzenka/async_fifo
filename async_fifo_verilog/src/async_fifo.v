/*
---------------------------------------------------------------------------------------

MIT License

Copyright (c) 2026 Siarhei Baldzenka

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---------------------------------------------------------------------------------------

project     : async_fifo_verilog
version     : 1.0
date        : 22.08.2026
author      : siarhei baldzenka
e-mail      : sbaldzenka@proton.me
description : https://github.com/sbaldzenka/async_fifo

---------------------------------------------------------------------------------------
*/

`timescale 1ns/100ps

module async_fifo
#(
    parameter FIFO_DEPTH = 8,
    parameter DATA_WIDTH = 8
)
(
    // global signals
    input  wire                  i_wr_clk,
    input  wire                  i_rd_clk,
    input  wire                  i_aresetn,
    // write port
    input  wire                  i_wr_en,
    input  wire [DATA_WIDTH-1:0] i_wr_data,
    // read data
    input  wire                  i_rd_en,
    output reg                   o_rd_valid,
    output reg  [DATA_WIDTH-1:0] o_rd_data,
    // status signals
    output wire                  o_full,
    output wire                  o_empty,
    output reg                   o_overflow,
    output reg                   o_underflow
);

    // parameters
    parameter ADDR_WIDTH  = $clog2(FIFO_DEPTH);

    // signals
    reg  [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

    reg                   rd_valid;
    reg  [DATA_WIDTH-1:0] rd_data;

    reg  [  ADDR_WIDTH:0] push_pointer;
    reg  [  ADDR_WIDTH:0] pop_pointer;

    wire [  ADDR_WIDTH:0] push_pointer_gray;
    reg  [  ADDR_WIDTH:0] push_pointer_gray_sync_ff1;
    reg  [  ADDR_WIDTH:0] push_pointer_gray_sync_ff2;

    wire [  ADDR_WIDTH:0] pop_pointer_gray;
    reg  [  ADDR_WIDTH:0] pop_pointer_gray_sync_ff1;
    reg  [  ADDR_WIDTH:0] pop_pointer_gray_sync_ff2;

    reg                   full_flag;
    reg                   empty_flag;

    // push pointer
    always @(posedge i_wr_clk or negedge i_aresetn) begin
        if (!i_aresetn) begin
            push_pointer <= 'b0;
        end else begin
            if (i_wr_en && !full_flag) begin
                push_pointer <= push_pointer + 1'b1;
            end
        end
    end

    // pop pointer
    always @(posedge i_rd_clk or negedge i_aresetn) begin
        if (!i_aresetn) begin
            pop_pointer <= 'b0;
        end else begin
            if (i_rd_en && !empty_flag) begin
                pop_pointer <= pop_pointer + 1'b1;
            end
        end
    end

    // write data to memory
    always @(posedge i_wr_clk) begin
        if (i_wr_en && !full_flag) begin
            mem[push_pointer[ADDR_WIDTH-1:0]] <= i_wr_data;
        end
    end

    // read data from memory
    always @(posedge i_rd_clk) begin
        if (i_rd_en &&!empty_flag) begin
            rd_valid <= 1'b1;
            rd_data  <= mem[pop_pointer[ADDR_WIDTH-1:0]];
        end else begin
            rd_valid <= 1'b0;
            rd_data  <= 'b0;
        end

        o_rd_valid <= rd_valid;
        o_rd_data  <= rd_data;
    end

    // binary code to gray code
    assign push_pointer_gray = push_pointer ^ (push_pointer >> 1);
    assign pop_pointer_gray = pop_pointer ^ (pop_pointer >> 1);

    // write to read domain synchronizer
    always @(posedge i_rd_clk or negedge i_aresetn) begin
        if (!i_aresetn) begin
            {push_pointer_gray_sync_ff2,
             push_pointer_gray_sync_ff1} <= 'b0;
        end else begin
            {push_pointer_gray_sync_ff2,
             push_pointer_gray_sync_ff1} <= {push_pointer_gray_sync_ff1,
                                             push_pointer_gray};
        end
    end

    // read to write domain synchronizer
    always @(posedge i_wr_clk or negedge i_aresetn) begin
        if (!i_aresetn) begin
            {pop_pointer_gray_sync_ff2,
             pop_pointer_gray_sync_ff1} <= 'b0;
        end else begin
            {pop_pointer_gray_sync_ff2,
             pop_pointer_gray_sync_ff1} <= {pop_pointer_gray_sync_ff1,
                                            pop_pointer_gray};
        end
    end

    // full flag
    always @(*) begin
        if (!i_aresetn) begin
            full_flag = 1'b0;
        end else begin
            if (push_pointer_gray == {~pop_pointer_gray_sync_ff2[ADDR_WIDTH:ADDR_WIDTH-1],
                                       pop_pointer_gray_sync_ff2[ADDR_WIDTH-2:0]}) begin
                full_flag = 1'b1;
            end else begin
                full_flag = 1'b0;
            end
        end
    end

    assign o_full = full_flag;

    // empty flag
    always @(posedge i_rd_clk or negedge i_aresetn) begin
        if (!i_aresetn) begin
            empty_flag <= 1'b1;
        end else begin
            if (pop_pointer_gray == push_pointer_gray_sync_ff2) begin
                empty_flag <= 1'b1;
            end else begin
                empty_flag <= 1'b0;
            end
        end
    end

    assign o_empty = empty_flag;

    // overflow
    always @(posedge i_wr_clk) begin
        if (full_flag && i_wr_en) begin
            o_overflow <= 1'b1;
        end else begin
            o_overflow <= 1'b0;
        end
    end

    // underflow
    always @(posedge i_rd_clk) begin
        if (empty_flag && i_rd_en) begin
            o_underflow <= 1'b1;
        end else begin
            o_underflow <= 1'b0;
        end
    end

endmodule