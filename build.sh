already_exists=$(ls calculator 2>&1 >> /dev/null)
if [ already_exists = 0 ]; then
    rm calculator
fi
nasm -f elf64 -o calculator.o calculator.asm
ld -o calculator calculator.o
rm calculator.o