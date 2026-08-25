-- project     : async_fifo_vhdl
-- version     : 1.0
-- date        : 24.08.2026
-- author      : siarhei baldzenka
-- e-mail      : sbaldzenka@proton.me
-- description : https://github.com/sbaldzenka/async_fifo

vlib work
vmap work work

vcom -93 ../tb/async_fifo_tb.vhd
vcom -93 ../src/async_fifo.vhd

vsim -t 1ps -voptargs=+acc=lprn -lib work async_fifo_tb

do wave_test.do
view wave
run 12 us