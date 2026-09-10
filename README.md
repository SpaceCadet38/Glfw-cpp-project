# C++ / GLFW / OpenGL starter — MinGW + VS Code, no CMake

A ready-to-build OpenGL 3.3 project wired for **GLFW**, **Glad**, **GLM** and
**Dear ImGui**, built with **MinGW g++/gcc + the GNU make that ships in your
MinGW `bin` folder**. No CMake. Works with either generation of glad.

The libraries themselves are not vendored here — drop in the copies you already
have (see [`external/README.md`](external/README.md)) and build.

## 1. Point the build at your compiler

The toolchain is **not** assumed to be on `PATH`. Replace the placeholder
`C:/mingw64/bin` with the folder that actually contains `g++.exe` in these
four places:

| File | Key |
|---|---|
| `Makefile` | `MINGW_BIN ?=` |
| `.vscode/tasks.json` | `options.env.MINGW_BIN` and `MAKE_EXE` |
| `.vscode/launch.json` | `miDebuggerPath` and the `PATH` env entry |
| `.vscode/c_cpp_properties.json` | `compilerPath` |
| `scripts/build.bat` (fallback) | `set "MINGW_BIN=..."` |

Paths containing spaces (`C:/Program Files/mingw64/bin`) are fine — the
Makefile quotes them. Use forward slashes.
You can also override it per-invocation without editing anything:

```
mingw32-make MINGW_BIN=D:/tools/mingw64/bin
```

Or set `MINGW_BIN=` (empty) to use whatever `g++` is already on `PATH`.

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
- `Ctrl+Shift+P → Tasks: Run Task` — release / rebuild / run / clean /
  **check setup**

**From a terminal:**

```
mingw32-make              # debug   -> build/debug/app.exe
mingw32-make CONFIG=release
mingw32-make run
mingw32-make clean
mingw32-make check        # report which libraries are present/missing
mingw32-make info         # print resolved paths + detected sources
```

If your make is named `make.exe` rather than `mingw32-make.exe`, use that name
and update `MAKE_EXE` in `.vscode/tasks.json`. Check with
`dir C:\mingw64\bin\*make*`.

**If a build fails oddly, run `make check` first.** Unlike a build it does not
stop at the first problem — it lists every library that is missing:

```
--- libraries ---
glad source : external/glad/src/gl.c
glad header : external/glad/include/glad/gl.h
glfw lib    : MISSING - MinGW build, not MSVC .lib
imgui       : ok
```

### Fallback without make

`scripts\build.bat` builds the same project by calling g++/gcc directly, if
you ever need it. The Makefile is the supported path.

## glad: both generations work

There are two incompatible glad generators, and the download pages do not
make the difference obvious:

| | glad1 (`glad.dav1d.de`) | glad2 (`gen.glad.sh`) |
|---|---|---|
| Source | `src/glad.c` | `src/gl.c` |
| Header | `<glad/glad.h>` | `<glad/gl.h>` |
| Loader | `gladLoadGLLoader(GLADloadproc)` | `gladLoadGL(GLADloadfunc)` |

Drop in **either one** — the build globs `external/glad/src/*.c` instead of
assuming a filename, and `src/gl_loader.h` picks the right header and loader
call via `__has_include`. `src/main.cpp` just calls
`projectLoadGLFunctions()`.

That header also fixes the include order for you (the loader must precede
GLFW), so include `"gl_loader.h"` rather than glad and GLFW separately.

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
src/gl_loader.h   glad1/glad2 shim + correct glad-before-GLFW include order
external/         drop your libraries here (see its README)
Makefile          the build
scripts/build.bat fallback build, if make is ever unavailable
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
| `mingw32-make: not found` | Your make may be `make.exe` — `dir C:\mingw64\bin\*make*` |
| `No glad C source found` | Neither `glad.c` nor `gl.c` is in `external/glad/src/` |
| `cannot find -lglfw3` | `libglfw3.a` missing, or it's the MSVC `.lib` instead of the MinGW `.a` |
| `undefined reference to __imp_glfw*` | Linking a DLL import lib while `GLFW_STATIC` is defined (or 32/64-bit mismatch) |
| `glad.h`/`gl.h`: No such file | Glad headers not copied — see `external/glad/README.md` |
| Blank window / GL calls crash | `gladLoadGLLoader` not called, or glad generated for the wrong GL version |
| IntelliSense squiggles but build works | Fix `compilerPath` in `.vscode/c_cpp_properties.json`, then `C/C++: Reset IntelliSense Database` |
