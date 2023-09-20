@echo off
sdasrab -los cpmbios.asm
sdld -i cpmbios.rel
packihx cpmbios.ihx > cpmbios.hex
makebin -s 0x10000 cpmbios.hex > cpmbios.bin
