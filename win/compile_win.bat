@echo off
setlocal enabledelayedexpansion

REM ================================================
REM Assemble and link x86 assembly files (Win32/64)
REM REMARKS: Totally not written by ChatGPT (Fuck Batch for some reason)
REM USAGE:
REM compile.bat [directory] [win32|win64]
REM [directory] - Directory containing .asm files (default is current directory)
REM [win32|win64] - Architecture to compile for (default is win64)
REM Example: compile.bat ..\path\to\project win32
REM ================================================

REM Set default values
set "targetDir=%cd%"
set "arch=win64"

REM Parse arguments
if not "%~1"=="" set "targetDir=%~1"
if not "%~2"=="" set "arch=%~2"

REM Validate architecture
if /i not "%arch%"=="win32" if /i not "%arch%"=="win64" (
    echo ERROR: Invalid architecture: %arch%. Use win32 or win64.
    exit /b 1
)

REM Change to the target directory
cd /d "%targetDir%" || (
    echo ERROR: Failed to change to directory: %targetDir%.
    exit /b 1
)

REM Ensure .asm files exist
if not exist "*.asm" (
    echo ERROR: No .asm files found in %cd%.
    exit /b 1
)

REM Clean up old files
echo Cleaning up old object and executable files...
del /q *.o 2>nul
del /q *.exe 2>nul

REM Initialize variables
set asmCount=0
set "lastAsmFile="
set "objectFiles="

REM Process .asm files
for %%f in (*.asm) do (
    echo Found file: %%f
    nasm -f %arch% %%f -o %%~nf.o
    if errorlevel 1 (
        echo ERROR: NASM failed to assemble %%f. Exiting.
        exit /b 1
    )
    echo Successfully assembled %%f to %%~nf.o
    
    set /a asmCount+=1
    set lastAsmFile=%%~nf

    REM Append to object file list
    set "objectFiles=!objectFiles! %%~nf.o"
)

REM Determine output file name
set "outputName=output"
REM ...but use the file name if there was only 1
if %asmCount% EQU 1 set "outputName=%lastAsmFile%"

REM Link object files into an executable
echo Linking object files into %outputName%.exe...
gcc -o %outputName%.exe %objectFiles% -nostdlib -nodefaultlibs -lkernel32
if errorlevel 1 (
    echo ERROR: GCC failed to link. Exiting.
    exit /b 1
)

REM Success message
if exist "%outputName%.exe" (
    echo Build successful: %outputName%.exe
) else (
    echo ERROR: Build failed. Please check errors.
    exit /b 1
)

exit /b 0
