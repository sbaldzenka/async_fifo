-- project     : async_fifo_vhdl
-- version     : 1.0
-- date        : 24.08.2026
-- author      : siarhei baldzenka
-- e-mail      : sbaldzenka@proton.me
-- description : https://github.com/sbaldzenka/async_fifo

-- Waves:
add wave -noupdate -divider testbench
add wave -noupdate -format Logic -radix HEXADECIMAL -group {testbench} /async_fifo_tb/*

add wave -noupdate -divider async_fifo
add wave -noupdate -format Logic -radix HEXADECIMAL -group {async_fifo} /async_fifo_tb/DUT_inst/*

-- Toggle leaf names command:
config wave -signalnamewidth 1