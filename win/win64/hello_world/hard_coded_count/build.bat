@echo off
REM Change to the directory where the batch script is located
cd /d "%~dp0"

REM Delete all .o and .exe files in the current directory
echo Cleaning up old object and executable files...
del /q *.o 2>nul
del /q *.exe 2>nul

REM Count the number of .asm files in the directory
set asmCount=0
for %%f in (*.asm) do (
    set /a asmCount+=1
    set lastAsmFile=%%~nf
)

REM Determine the output file name
set outputName=output

if "%1"=="" (
    if %asmCount%==1 (
        REM Use the name of the single .asm file
        set outputName=%lastAsmFile%
    )
) else (
    REM Use the passed argument as the output name
    set outputName=%~1
)

REM Assemble all .asm files
for %%f in (*.asm) do (
    echo Assembling %%f to %%~nf.o...
    nasm -f win64 %%f -o %%~nf.o
)

REM Create the executable
echo Linking all .o files into %outputName%.exe...
gcc -o %outputName%.exe *.o -nostdlib -nodefaultlibs -lkernel32

REM Check if the output executable was successfully created
if exist %outputName%.exe (
    echo Build complete! Output is %outputName%.exe.
) else (
    echo Build failed. Please check for errors.
)
