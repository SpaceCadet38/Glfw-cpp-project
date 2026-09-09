# C++ / GLFW / OpenGL starter — MinGW + VS Code, no CMake

A ready-to-build OpenGL 3.3 project wired for **GLFW**, **Glad**, **GLM** and
**Dear ImGui**, built with **MinGW g++/gcc only**. No CMake, and **no GNU make
required** — the default build calls the compiler directly.

The libraries themselves are not vendored here — drop in the copies you already
have (see [`external/README.md`](external/README.md)) and build.

## 1. Point the build at your compiler

The toolchain is **not** assumed to be on `PATH`. Replace the placeholder
`C:/mingw64/bin` with the folder that actually contains `g++.exe` in these
four places:

| File | Key |
|---|---|
| `scripts/build.bat` | `set "MINGW_BIN=..."` |
| `.vscode/tasks.json` | `options.env.MINGW_BIN` |
| `Makefile` (optional) | `MINGW_BIN ?=` |
| `.vscode/launch.json` | `miDebuggerPath` and the `PATH` env entry |
| `.vscode/c_cpp_properties.json` | `compilerPath` |

You can also override it per-invocation without editing anything:

```
set MINGW_BIN=D:\tools\mingw64\bin
scripts\build.bat
```

## 2. Drop in the libraries

Copy your headers and binaries into `external/` exactly as laid out in
[`external/README.md`](external/README.md). The short version:

```
external/glad/include/glad/glad.h      external/glfw/include/GLFW/glfw3.h
external/glad/include/KHR/khrplatform.h  external/glfw/lib/libglfw3.a
external/glad/src/glad.c               external/glm/glm/glm.hpp
external/imgui/*.cpp                   external/imgui/backends/imgui_impl_{glfw,opengl3}.cpp
```

Nothing in the build hardcodes a file list — both build paths scan these
folders, so extra ImGui files or extra `src/*.cpp` are picked up
automatically. The build stops with a specific message naming the missing
file (and its README) if something has not been dropped in yet.

## 3. Build, run, debug

**In VS Code** (install the C/C++ extension, `ms-vscode.cpptools`):

- `Ctrl+Shift+B` — build debug
- `F5` — build then launch under GDB, breakpoints included
- `Ctrl+Shift+P → Tasks: Run Task` — release / rebuild / run / clean

**From a terminal** — no make involved:

```
scripts\build.bat                 debug   -> build\debug\app.exe
scripts\build.bat release         release -> build\release\app.exe
scripts\build.bat debug run       build then run
scripts\build.bat debug rebuild   force a full recompile
scripts\build.bat clean           delete build\
```

The script is incremental in the way that matters: ImGui and glad are compiled
**once** and reused, so only your own `src\` files are rebuilt on each run.
The first build is the slow one. After editing a header inside `external\`,
use `rebuild`.

### Optional: the Makefile

`Makefile` is included for parallel builds (`-j`) and precise header
dependency tracking, but it is **not required** — not every MinGW distribution
ships `mingw32-make`. Check yours with:

```
dir C:\mingw64\bin\*make*
```

| Distribution | Ships make? |
|---|---|
| WinLibs, TDM-GCC, niXman / SourceForge builds | yes (`mingw32-make.exe`) |
| w64devkit | yes (`make.exe`) |
| MSYS2 `mingw-w64-x86_64-gcc` | no — install `mingw-w64-x86_64-make` |

If you have it:

```
mingw32-make              # debug
mingw32-make CONFIG=release
mingw32-make run
mingw32-make clean
mingw32-make info         # print resolved paths + detected sources
```

VS Code exposes these as the `make: …` tasks.

## What it does

`src/main.cpp` opens a GLFW window with an OpenGL 3.3 core context, loads
entry points through Glad, draws a rotating gradient triangle with matrices
built by GLM, and overlays an ImGui panel with live controls (speed, scale,
colour, fade, ImGui demo window). If it builds and runs, all four libraries
are correctly wired.

## Layout

```
.vscode/          tasks / launch / IntelliSense config
src/main.cpp      the application
external/         drop your libraries here (see its README)
scripts/build.bat the default build - g++/gcc directly, no make
Makefile          optional build, if you have mingw32-make
build/<config>/   output — app.exe + .o/.d files (gitignored)
```

## Build details worth knowing

- **Debug** is `-g3 -O0` and keeps the console window (so `printf`/`stderr`
  are visible). **Release** is `-O2 -DNDEBUG` and adds `-mwindows` to hide it.
- `-DGLFW_STATIC` is set because the build links the static `libglfw3.a`. If
  you switch to `libglfw3dll.a`, drop that define and put `glfw3.dll` next to
  `app.exe`.
- `-static-libgcc -static-libstdc++` so the `.exe` runs on machines without
  the MinGW runtime DLLs.
- Link order is deliberate: `-lglfw3` precedes `-lopengl32 -lgdi32 …` because
  g++ resolves left to right.
- `-MMD -MP` (Makefile path) generates header dependencies, so editing a
  header rebuilds everything that includes it. The batch path approximates
  this by always recompiling `src/`.
- Warnings are `-Wall -Wextra -Wpedantic` for `src/` but suppressed for
  `external/` — vendored code shouldn't bury your own warnings.
- The batch build passes objects to the linker via a response file, so a
  project with many sources cannot hit cmd.exe's ~8191-character command-line
  limit.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `g++ not found at ...` | `MINGW_BIN` still points at the placeholder |
| `mingw32-make: not found` | Your MinGW has no make — use `scripts\build.bat` instead |
| `cannot find -lglfw3` | `libglfw3.a` missing, or it's the MSVC `.lib` instead of the MinGW `.a` |
| `undefined reference to __imp_glfw*` | Linking a DLL import lib while `GLFW_STATIC` is defined (or 32/64-bit mismatch) |
| `glad.h: No such file` | Glad files not copied — see `external/glad/README.md` |
| Blank window / GL calls crash | `gladLoadGLLoader` not called, or glad generated for the wrong GL version |
| IntelliSense squiggles but build works | Fix `compilerPath` in `.vscode/c_cpp_properties.json`, then `C/C++: Reset IntelliSense Database` |
