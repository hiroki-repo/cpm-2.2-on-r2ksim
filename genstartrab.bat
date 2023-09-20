@echo off
sdasrab -los startrab.asm
sdld -i startrab.rel
packihx startrab.ihx > startrab.hex
makebin -s 0x10000 startrab.hex > startrab.bin
