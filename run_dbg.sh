#!/bin/bash


exit_status_cal=$(ls calculator 2>&1 >> /dev/null)
exit_status_cal_o=$(ls calculator.o 2>&1 >> /dev/null)
if [ exit_status_cal = 0 ]; then
    rm calculator
fi
if [ exit_status_cal_o = 0 ]; then
    rm calculator.o
fi
nasm -f elf64 -g -o calculator.o calculator.asm
ld -o calculator calculator.o
gdb calculator
(rm calculator && rm calculator.o)
