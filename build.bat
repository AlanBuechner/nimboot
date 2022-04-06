@echo off
set arg1=%1
nasm src/BootLoader.asm -f bin -o BootLoader.flp

if "%arg1%" == "run" start ./bochsrc.bxrc