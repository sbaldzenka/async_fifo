-- project     : async_fifo_verilog
-- version     : 1.0
-- date        : 22.08.2026
-- author      : siarhei baldzenka
-- e-mail      : sbaldzenka@proton.me
-- description : https://github.com/sbaldzenka/async_fifo

vlib work
vmap work work

vlog ../tb/async_fifo_tb.v
vlog ../src/async_fifo.v

vsim -t 1ps -voptargs=+acc=lprn -lib work async_fifo_tb

do wave_test.do
view wave
run 12 us