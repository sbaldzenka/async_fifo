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

module async_fifo_tb
#(
    // sim parameters
    parameter CLK_WR_PERIOD = 10,
    parameter CLK_RD_PERIOD = 20,
    // fifo parameters
    parameter FIFO_DEPTH = 8,
    parameter DATA_WIDTH = 8
);

    integer               index;

    reg                   clk_wr;
    reg                   clk_rd;
    reg                   aresetn;

    reg                   wr_en;
    reg  [DATA_WIDTH-1:0] wr_data;

    reg                   rd_en;
    wire                  rd_valid;
    wire [DATA_WIDTH-1:0] rd_data;

    wire                  full;
    wire                  empty;
    wire                  overflow;
    wire                  underflow;

    task areset_system();
        begin
            aresetn = 1'b0;
            #200;
            aresetn = 1'b1;
        end
    endtask

    task write_data;
        input integer number_of_words;

        begin
            #1000;
            @(negedge clk_wr);
            for (index = 0; index < number_of_words; index = index + 1) begin
                wr_en   = 1'b1;
                wr_data = wr_data + 1'b1;
                #CLK_WR_PERIOD;
            end

            wr_en   = 1'b0;
            wr_data = 'b0;
        end
    endtask

    task read_data;
        input integer number_of_words;

        begin
            #1000;
            @(negedge clk_rd);
            rd_en = 1'b1;
            #(CLK_RD_PERIOD*number_of_words);
            rd_en = 1'b0;
        end
    endtask

    always #(CLK_WR_PERIOD/2) clk_wr = ~clk_wr;
    always #(CLK_RD_PERIOD/2) clk_rd = ~clk_rd;

    initial begin
        clk_wr  = 1'b0;
        clk_rd  = 1'b0;
        rd_en   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 'b0;
    end

    initial begin
        areset_system();
        write_data(4);
        read_data(4);
        read_data(16);
        write_data(16);
        read_data(8);
    end

    defparam DUT_inst.FIFO_DEPTH = FIFO_DEPTH;
    defparam DUT_inst.DATA_WIDTH = DATA_WIDTH;

    async_fifo DUT_inst
    (
        .i_wr_clk    ( clk_wr    ),
        .i_rd_clk    ( clk_rd    ),
        .i_aresetn   ( aresetn   ),
        .i_wr_en     ( wr_en     ),
        .i_wr_data   ( wr_data   ),
        .i_rd_en     ( rd_en     ),
        .o_rd_valid  ( rd_valid  ),
        .o_rd_data   ( rd_data   ),
        .o_full      ( full      ),
        .o_empty     ( empty     ),
        .o_overflow  ( overflow  ),
        .o_underflow ( underflow )
    );

endmodule