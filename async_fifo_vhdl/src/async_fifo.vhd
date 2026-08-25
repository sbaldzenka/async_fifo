---------------------------------------------------------------------------------------
--
-- MIT License
--
-- Copyright (c) 2026 Siarhei Baldzenka
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- ---------------------------------------------------------------------------------------
--
-- project     : async_fifo_vhdl
-- version     : 1.0
-- date        : 24.08.2026
-- author      : siarhei baldzenka
-- e-mail      : sbaldzenka@proton.me
-- description : https://github.com/sbaldzenka/async_fifo
--
-- ---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use Ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity async_fifo is
generic
(
    FIFO_DEPTH : integer := 8;
    DATA_WIDTH : integer := 8
);
port
(
    -- global signals
    i_wr_clk    : in  std_logic;
    i_rd_clk    : in  std_logic;
    i_aresetn   : in  std_logic;
    -- write data signals
    i_wr_en     : in  std_logic;
    i_wr_data   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    -- read data signals
    i_rd_en     : in  std_logic;
    o_rd_valid  : out std_logic;
    o_rd_data   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    -- status signals
    o_full      : out std_logic;
    o_empty     : out std_logic;
    o_overflow  : out std_logic;
    o_underflow : out std_logic
);
end async_fifo;

architecture rtl of async_fifo is

    -- types
    type mem_array is array(FIFO_DEPTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);

    -- constants
    constant ADDR_WIDTH          : integer := integer(ceil(log2(real(FIFO_DEPTH))));

    -- signals
    signal mem                   : mem_array;

    signal push_pointer          : std_logic_vector(ADDR_WIDTH downto 0);
    signal push_pointer_gray     : std_logic_vector(ADDR_WIDTH downto 0);
    signal push_pointer_gray_ff1 : std_logic_vector(ADDR_WIDTH downto 0);
    signal push_pointer_gray_ff2 : std_logic_vector(ADDR_WIDTH downto 0);

    signal pop_pointer           : std_logic_vector(ADDR_WIDTH downto 0);
    signal pop_pointer_gray      : std_logic_vector(ADDR_WIDTH downto 0);
    signal pop_pointer_gray_ff1  : std_logic_vector(ADDR_WIDTH downto 0);
    signal pop_pointer_gray_ff2  : std_logic_vector(ADDR_WIDTH downto 0);

    signal full_flag        : std_logic;
    signal empty_flag       : std_logic;

begin

    PUSH_POINTER_INC: process(i_wr_clk, i_aresetn)
    begin
        if (i_aresetn = '0') then
            push_pointer <= (others => '0');
        elsif rising_edge(i_wr_clk) then
            if (i_wr_en = '1' and full_flag = '0') then
                push_pointer <= push_pointer + '1';
            end if;
        end if;
    end process;

    WRITE_DATA_TO_MEM: process(i_wr_clk)
    begin
        if rising_edge(i_wr_clk) then
            if (i_wr_en = '1' and full_flag = '0') then
                mem(conv_integer(push_pointer(ADDR_WIDTH-1 downto 0))) <= i_wr_data;
            end if;
        end if;
    end process;

    push_pointer_gray <= push_pointer xor ('0' & push_pointer(ADDR_WIDTH downto 1));

    PUSH_POINTER_SYNC: process(i_rd_clk, i_aresetn)
    begin
        if (i_aresetn = '0') then
            push_pointer_gray_ff1 <= (others => '0');
            push_pointer_gray_ff2 <= (others => '0');
        elsif rising_edge(i_wr_clk) then
            push_pointer_gray_ff1 <= push_pointer_gray;
            push_pointer_gray_ff2 <= push_pointer_gray_ff1;
        end if;
    end process;

    POP_POINTER_INC: process(i_rd_clk, i_aresetn)
    begin
        if (i_aresetn = '0') then
            pop_pointer <= (others => '0');
        elsif rising_edge(i_rd_clk) then
            if (i_rd_en = '1' and empty_flag = '0') then
                pop_pointer <= pop_pointer + '1';
            end if;
        end if;
    end process;

    READ_DATA_FROM_MEM: process(i_rd_clk)
    begin
        if rising_edge(i_rd_clk) then
            if (i_rd_en = '1' and empty_flag = '0') then
                o_rd_valid <= '1';
                o_rd_data  <= mem(conv_integer(pop_pointer(ADDR_WIDTH-1 downto 0)));
            else
                o_rd_valid <= '0';
                o_rd_data  <= (others => '0');
            end if;
        end if;
    end process;

    pop_pointer_gray <= pop_pointer xor ('0' & pop_pointer(ADDR_WIDTH downto 1));

    POP_POINTER_SYNC: process(i_wr_clk, i_aresetn)
    begin
        if (i_aresetn = '0') then
            pop_pointer_gray_ff1 <= (others => '0');
            pop_pointer_gray_ff2 <= (others => '0');
        elsif rising_edge(i_wr_clk) then
            pop_pointer_gray_ff1 <= pop_pointer_gray;
            pop_pointer_gray_ff2 <= pop_pointer_gray_ff1;
        end if;
    end process;

    full_flag  <= '1' when (push_pointer_gray = (not pop_pointer_gray_ff2(ADDR_WIDTH downto ADDR_WIDTH-1)
                            & pop_pointer_gray_ff2(ADDR_WIDTH-2 downto 0))) else '0';
    empty_flag <= '1' when (pop_pointer_gray = push_pointer_gray_ff2) else '0';
    o_full     <= full_flag;
    o_empty    <= empty_flag;

    OVERFLOW_GEN: process(i_wr_clk)
    begin
        if rising_edge(i_wr_clk) then
            if (i_wr_en = '1' and full_flag = '1') then
                o_overflow <= '1';
            else
                o_overflow <= '0';
            end if;
        end if;
    end process;

    UNDERFLOW_GEN: process(i_rd_clk)
    begin
        if rising_edge(i_rd_clk) then
            if (i_rd_en = '1' and empty_flag = '1') then
                o_underflow <= '1';
            else
                o_underflow <= '0';
            end if;
        end if;
    end process;

end rtl;