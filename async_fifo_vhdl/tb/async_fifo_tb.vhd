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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity async_fifo_tb is
generic
(
    CLK_WR_PERIOD : time    := 20 ns;
    CLK_RD_PERIOD : time    := 10 ns;
    FIFO_DEPTH    : integer := 8;
    DATA_WIDTH    : integer := 8
);
end async_fifo_tb;

architecture behavioral of async_fifo_tb is

    component async_fifo is
    generic
    (
        FIFO_DEPTH : integer;
        DATA_WIDTH : integer
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
    end component;

    -- signals
    signal clk_wr        : std_logic;
    signal clk_rd        : std_logic;
    signal aresetn       : std_logic;

    signal wr_en         : std_logic;
    signal wr_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal wr_en_ff      : std_logic;
    signal wr_data_in_ff : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal rd_en         : std_logic;
    signal rd_en_ff      : std_logic;
    signal valid         : std_logic;
    signal data_out      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal full          : std_logic;
    signal empty         : std_logic;
    signal overflow      : std_logic;
    signal underflow     : std_logic;

begin

    CLK_WR_GENERATE: process
    begin
        clk_wr <= '0';
        wait for CLK_WR_PERIOD/2;
        clk_wr <= '1';
        wait for CLK_WR_PERIOD/2;
    end process;

    CLK_RD_GENERATE: process
    begin
        clk_rd <= '0';
        wait for CLK_RD_PERIOD/2;
        clk_rd <= '1';
        wait for CLK_RD_PERIOD/2;
    end process;

    ARESETN_GENERATE: process
    begin
        aresetn <= '0';
        wait for 0.1 us;
        aresetn <= '1';
        wait;
    end process;

    DATA_WR_PROC: process
    begin
        wr_en      <= '0';
        rd_en      <= '0';

        wr_data_in <= (others => '0');
        wait for 1 us;
        wait until falling_edge(clk_wr);

        for index in 0 to 8 loop
            wr_en      <= '1';
            wr_data_in <= wr_data_in + '1';
            wait for CLK_WR_PERIOD;
        end loop;

        wr_en <= '0';
        wait for 1 us;

        wait for 1 us;
        wait until falling_edge(clk_rd);
        rd_en <= '1';
        wait for CLK_RD_PERIOD*9;
        rd_en <= '0';
        wait;
    end process;

    SIGNALS_FF_WR: process(clk_wr)
    begin
        if rising_edge(clk_wr) then
            wr_en_ff      <= wr_en;
            wr_data_in_ff <= wr_data_in;
        end if;
    end process;

    SIGNALS_FF_RD: process(clk_rd)
    begin
        if rising_edge(clk_rd) then
            rd_en_ff <= rd_en;
        end if;
    end process;

   DUT_inst: async_fifo
   generic map
   (
       FIFO_DEPTH => FIFO_DEPTH,
       DATA_WIDTH => DATA_WIDTH
   )
   port map
   (
       i_wr_clk    => clk_wr,
       i_rd_clk    => clk_rd,
       i_aresetn   => aresetn,
       i_wr_en     => wr_en_ff,
       i_wr_data   => wr_data_in_ff,
       i_rd_en     => rd_en_ff,
       o_rd_valid  => valid,
       o_rd_data   => data_out,
       o_full      => full,
       o_empty     => empty,
       o_overflow  => overflow,
       o_underflow => underflow
   );

end behavioral;
