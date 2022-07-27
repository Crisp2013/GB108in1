rgbasm -h -o main.o main.asm
rgblink -n menu108.sym -o menu108.gb main.o
rgbfix -cjv -k 01 -l 0x33 -m 0x03 -p 0 -r 00 -t "TEST" menu108.gb
pause