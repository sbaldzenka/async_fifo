-- project     : async_fifo_verilog
-- version     : 1.0
-- date        : 22.08.2026
-- author      : siarhei baldzenka
-- e-mail      : sbaldzenka@proton.me
-- description : https://github.com/sbaldzenka/async_fifo

-- Waves:
add wave -noupdate -divider testbench
add wave -noupdate -format Logic -radix HEXADECIMAL -group {testbench} /async_fifo_tb/*

add wave -noupdate -divider DUT
add wave -noupdate -format Logic -radix HEXADECIMAL -group {async_fifo} /async_fifo_tb/DUT_inst/*

-- Toggle leaf names command:
config wave -signalnamewidth 1