# C++ / GLFW / OpenGL starter — MinGW + VS Code, no CMake

A ready-to-build OpenGL 3.3 project wired for **GLFW**, **Glad**, **GLM** and
**Dear ImGui**, built with **MinGW g++/gcc only**. No CMake anywhere.

The libraries themselves are not vendored here — drop in the copies you already
have (see [`external/README.md`](external/README.md)) and build.

## 1. Point the build at your compiler

The toolchain is **not** assumed to be on `PATH`. Replace the placeholder
`C:/mingw64/bin` with the folder that actually contains `g++.exe` in these
four places:

| File | Key |
|---|---|
| `Makefile` | `MINGW_BIN ?=` |
| `.vscode/tasks.json` | `options.env.MINGW_BIN` and `PATH` |
| `.vscode/launch.json` | `miDebuggerPath` and the `PATH` env entry |
| `.vscode/c_cpp_properties.json` | `compilerPath` |

You can also override it per-invocation without editing anything:

```
mingw32-make MINGW_BIN=D:/tools/mingw64/bin
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

Nothing in the build hardcodes a file list — the Makefile globs these folders,
so extra ImGui files or extra `src/*.cpp` are picked up automatically.

## 3. Build, run, debug

**In VS Code** (install the C/C++ extension, `ms-vscode.cpptools`):

- `Ctrl+Shift+B` — build debug
- `F5` — build then launch under GDB, breakpoints included
- `Ctrl+Shift+P → Tasks: Run Task` — release / clean / rebuild / run

**From a terminal:**

```
mingw32-make              # debug   -> build/debug/app.exe
mingw32-make CONFIG=release
mingw32-make run
mingw32-make clean
mingw32-make info         # print resolved paths + detected sources
```

**Without make at all** (calls g++/gcc directly):

```
scripts\build.bat          # or: scripts\build.bat release
```

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
scripts/build.bat make-free direct g++ build
Makefile          the build
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
- `-MMD -MP` generates header dependencies, so editing a header rebuilds
  everything that includes it.
- Warnings are `-Wall -Wextra -Wpedantic` for `src/` but suppressed for
  `external/` — vendored code shouldn't bury your own warnings.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `g++: not found` / `mingw32-make: not found` | `MINGW_BIN` still points at the placeholder |
| `cannot find -lglfw3` | `libglfw3.a` missing, or it's the MSVC `.lib` instead of the MinGW `.a` |
| `undefined reference to __imp_glfw*` | Linking a DLL import lib while `GLFW_STATIC` is defined (or 32/64-bit mismatch) |
| `glad.h: No such file` | Glad files not copied — see `external/glad/README.md` |
| Blank window / GL calls crash | `gladLoadGLLoader` not called, or glad generated for the wrong GL version |
| IntelliSense squiggles but build works | Fix `compilerPath` in `.vscode/c_cpp_properties.json`, then `C/C++: Reset IntelliSense Database` |
