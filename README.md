# x86 Assembly Project

Welcome to the land of **x86 assembly programming**—where every byte counts, every error is cryptic, and every second of debugging makes you rookie question your life choices. 

This repository exists because, for some reason, I thought writing assembly programs for **Win32/64** would be a good idea. And now I’m too lazy to explain it properly, so here’s a half-decent README written by an AI that doesn’t have the privilege of being lazy. (The repository's page on GitHub looks too empty.)

---

## Features

- **Win32 and Win64 builds**: Because we don’t talk about Linux... yet. (It’ll happen when I feel like it.)
- A **batch script** that automates the tedious crap like assembling and linking, so you can focus on figuring out why your program crashes.
- Modular-ish structure, because shoving everything into one folder would be too chaotic—even for me.

---

## Project Structure

Here’s the general layout, in case you feel like poking around:

```plaintext
x86-asm/
│
└── win/                      # Windows builds (obviously)
    ├── win32/                # 32-bit programs (why would you?)
    │   └── hello_world/      # Example program for Win32
    ├── win64/                # 64-bit programs
    │   └── hello_world/      # Example program for Win64
    │       ├── user_input_count/  # Example alternative version or submodule of the program
    │       └── ...           # More folders, same existential dread
    │
    ├── compile_win.bat       # The script that saves you from command-line purgatory
    └── README.md             # The mess you're reading right now
```

---

## Prerequisites

### **NASM + GCC Toolchain**

To assemble and link programs, you need **NASM** (for assembling) and **GCC** (for linking). Luckily, someone at **WinLibs** had the brilliant idea to bundle them together, so you don’t have to hunt them down separately.

#### Setup Instructions (for Windows, because who cares about MacOS right now)

1. **Download the Toolchain**:
   - Go to [WinLibs.com](https://winlibs.com/).
   - Get the latest **UCRT runtime** ZIP file:
     - Example: `winlibs-x86_64-posix-seh-gcc-14.2.0-mingw-w64ucrt-12.0.0-r2.7z`.
     - Pick the version **without LLVM/Clang/LLD/LLDB**—unless you like bloating your disk for no reason.

2. **Extract the Damn Thing**:
   - Dump it somewhere sensible, like `C:\mingw64`. If you’re the kind of person who extracts files to their desktop, stop reading now.
   - Use **Windows Explorer**, **WinRar**, **7-Zip**, or even the command line (if you’re trying to be cool):
     ```cmd
     tar -xf winlibs-x86_64-posix-seh-gcc-14.2.0-mingw-w64ucrt-12.0.0-r2.7z -C C:\mingw64
     ```

3. **Add the `/bin` Folder to PATH**:
   - Temporarily (for this session):
     ```cmd
     set PATH=C:\mingw64\bin;%PATH%
     ```
     ```powershell
     $env:PATH="C:\mingw64\bin;$env:PATH"
     ```

   - Permanently (for next time, if you even make it that far):
     **CMD:**
     ```cmd
     setx PATH "C:\mingw64\bin;%PATH%"
     ```
     **PowerShell:**
     ```powershell
     [System.Environment]::SetEnvironmentVariable("Path", "C:\mingw64\bin;$env:PATH", "Machine")
     ```

4. **Verify Installation**:
   - Check if NASM and GCC are working. If they aren’t, cry into your keyboard or blame me:
     ```cmd
     nasm -v
     gcc --version
     ```

---

## Usage

### Compiling Programs

There’s a batch script called `compile_win.bat` that does the heavy lifting. All you need to do is point it to a directory with `.asm` files and tell it whether you want a 32-bit or 64-bit build. It’s not rocket science.

#### Syntax:
```cmd
compile_win.bat [directory] [architecture]
```

#### Arguments:
- `directory`: The folder with your `.asm` files (defaults to the current directory because I’m generous).
- `architecture`: Either `win32` or `win64`. Defaults to `win64` because it’s 2024, not 1995.

#### Example:
```cmd
.\compile_win.bat win\win64\hello_world\hard_coded_count win64
```
or go into the directory and
```
..\..\..\..\compile_win.bat
```

This assembles and links all `.asm` files in `hello_world` for 64-bit Windows. If it doesn’t work, at least you tried.

## Future Plans

- **Linux Support**: Maybe one day when I feel like staring at `make` scripts for hours.
- **More Programs**: Expect more stuff that solve problems nobody actually has - or better yet: Don't.

---

## Acknowledgments

- **NASM**: For making sure assembly doesn’t stay in the stone age.
- **MinGW-w64**: For linking my broken dreams into somewhat functional executables.
- **WinLibs**: For bundling everything and saving me the hassle.
- **You**: For actually reading this far. I don’t know whether to be impressed or concerned.

---

## Final Words by the Prompt Engineer

Looks about right.