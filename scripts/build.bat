@echo off
REM ===========================================================================
REM  Build the project with MinGW g++/gcc directly.
REM  No GNU make, no CMake - plain cmd.exe.
REM
REM  Usage:
REM     scripts\build.bat                 debug build
REM     scripts\build.bat release         release build
REM     scripts\build.bat debug run       build then run
REM     scripts\build.bat clean           delete the build folder
REM     scripts\build.bat debug rebuild   force a full recompile
REM
REM  Incremental: third-party objects (ImGui / glad) are compiled once and
REM  reused; sources under src\ are always recompiled. So edits to your own
REM  code are fast, and you only pay the ImGui cost on the first build.
REM  After editing a header inside external\, run a "rebuild".
REM ===========================================================================
setlocal enabledelayedexpansion

REM --- PLACEHOLDER: folder containing g++.exe and gcc.exe -------------------
REM Override without editing:  set MINGW_BIN=D:\tools\mingw64\bin
if "%MINGW_BIN%"=="" set "MINGW_BIN=C:\mingw64\bin"

set "CXX=%MINGW_BIN%\g++.exe"
set "CC=%MINGW_BIN%\gcc.exe"

REM --- Arguments ------------------------------------------------------------
set "CONFIG=debug"
set "DO_RUN="
set "DO_CLEAN="
set "DO_REBUILD="

for %%a in (%*) do (
    if /i "%%a"=="debug"   set "CONFIG=debug"
    if /i "%%a"=="release" set "CONFIG=release"
    if /i "%%a"=="run"     set "DO_RUN=1"
    if /i "%%a"=="clean"   set "DO_CLEAN=1"
    if /i "%%a"=="rebuild" set "DO_REBUILD=1"
)

pushd "%~dp0.."
set "ROOT=%CD%"

set "OUT=%ROOT%\build\%CONFIG%"
set "OBJ=%OUT%\obj"

REM --- clean / rebuild ------------------------------------------------------
if defined DO_CLEAN (
    if exist "%ROOT%\build" rmdir /s /q "%ROOT%\build"
    echo === Cleaned ===
    popd & endlocal & exit /b 0
)
if defined DO_REBUILD (
    if exist "%OUT%" rmdir /s /q "%OUT%"
)

REM --- Sanity checks: fail with a useful message, not a wall of errors ------
if not exist "%CXX%" (
    echo ERROR: g++ not found at "%CXX%"
    echo        Set MINGW_BIN to the folder containing g++.exe, e.g.
    echo            set MINGW_BIN=D:\tools\mingw64\bin
    goto :fail
)
if not exist "%ROOT%\external\glad\src\glad.c" (
    echo ERROR: external\glad\src\glad.c not found - see external\glad\README.md
    goto :fail
)
if not exist "%ROOT%\external\glad\include\glad\glad.h" (
    echo ERROR: external\glad\include\glad\glad.h not found - see external\glad\README.md
    goto :fail
)
if not exist "%ROOT%\external\glfw\include\GLFW\glfw3.h" (
    echo ERROR: external\glfw\include\GLFW\glfw3.h not found - see external\glfw\README.md
    goto :fail
)
if not exist "%ROOT%\external\glfw\lib\libglfw3.a" (
    echo ERROR: external\glfw\lib\libglfw3.a not found - see external\glfw\README.md
    echo        Use the MinGW build of GLFW, not the MSVC .lib
    goto :fail
)
if not exist "%ROOT%\external\glm\glm\glm.hpp" (
    echo ERROR: external\glm\glm\glm.hpp not found - see external\glm\README.md
    goto :fail
)
if not exist "%ROOT%\external\imgui\imgui.cpp" (
    echo ERROR: external\imgui\imgui.cpp not found - see external\imgui\README.md
    goto :fail
)

if not exist "%OBJ%" mkdir "%OBJ%"

REM --- Flags ----------------------------------------------------------------
set "INCLUDES=-I"%ROOT%\src" -I"%ROOT%\external\glad\include" -I"%ROOT%\external\glfw\include" -I"%ROOT%\external\glm" -I"%ROOT%\external\imgui" -I"%ROOT%\external\imgui\backends""
set "DEFINES=-DGLFW_INCLUDE_NONE -DGLFW_STATIC"

if /i "%CONFIG%"=="release" (
    set "CFG_FLAGS=-O2 -DNDEBUG"
    set "LINK_EXTRA=-mwindows"
) else (
    set "CFG_FLAGS=-g3 -O0 -DDEBUG"
    set "LINK_EXTRA="
)

set "WARN=-Wall -Wextra -Wpedantic -Wno-unused-parameter"

REM Objects are listed in a response file: a long project can otherwise blow
REM past the ~8191 character cmd.exe command-line limit.
set "RSP=%OUT%\objects.rsp"
if exist "%RSP%" del /q "%RSP%"

REM --- 1. Third-party: compile once, reuse afterwards -----------------------
REM Vendored code is built with -w; its warnings are not ours to fix and
REM would bury the ones from src\.

if not exist "%OBJ%\ext_glad.o" (
    echo [glad] glad.c
    "%CC%" -std=c11 %CFG_FLAGS% -w %DEFINES% %INCLUDES% -c "%ROOT%\external\glad\src\glad.c" -o "%OBJ%\ext_glad.o"
    if errorlevel 1 goto :fail
)
echo "%OBJ%\ext_glad.o">>"%RSP%"

for %%f in ("%ROOT%\external\imgui\*.cpp") do (
    if not exist "%OBJ%\ext_%%~nf.o" (
        echo [imgui] %%~nxf
        "%CXX%" -std=c++17 %CFG_FLAGS% -w %DEFINES% %INCLUDES% -c "%%~ff" -o "%OBJ%\ext_%%~nf.o"
        if errorlevel 1 goto :fail
    )
    echo "%OBJ%\ext_%%~nf.o">>"%RSP%"
)

REM Only the two backends this project uses; other backends in the folder
REM (DirectX, SDL, Vulkan) are ignored on purpose.
for %%f in ("imgui_impl_glfw" "imgui_impl_opengl3") do (
    if not exist "%ROOT%\external\imgui\backends\%%~f.cpp" (
        echo ERROR: external\imgui\backends\%%~f.cpp not found - see external\imgui\README.md
        goto :fail
    )
    if not exist "%OBJ%\ext_%%~f.o" (
        echo [imgui] backends\%%~f.cpp
        "%CXX%" -std=c++17 %CFG_FLAGS% -w %DEFINES% %INCLUDES% -c "%ROOT%\external\imgui\backends\%%~f.cpp" -o "%OBJ%\ext_%%~f.o"
        if errorlevel 1 goto :fail
    )
    echo "%OBJ%\ext_%%~f.o">>"%RSP%"
)

REM --- 2. Project sources: always recompiled --------------------------------
set /a N=0
for /r "%ROOT%\src" %%f in (*.cpp) do (
    set /a N+=1
    echo [src] %%~nxf
    "%CXX%" -std=c++17 %CFG_FLAGS% %WARN% %DEFINES% %INCLUDES% -c "%%~ff" -o "%OBJ%\src_!N!.o"
    if errorlevel 1 goto :fail
    echo "%OBJ%\src_!N!.o">>"%RSP%"
)

if %N%==0 (
    echo ERROR: no .cpp files found under src\
    goto :fail
)

REM --- 3. Link --------------------------------------------------------------
REM -lglfw3 must precede the Win32 libraries: g++ resolves left to right.
echo [link] app.exe
"%CXX%" @"%RSP%" -o "%OUT%\app.exe" ^
    -L"%ROOT%\external\glfw\lib" ^
    -static-libgcc -static-libstdc++ %LINK_EXTRA% ^
    -lglfw3 -lopengl32 -lgdi32 -luser32 -lshell32 -lkernel32 -limm32
if errorlevel 1 goto :fail

echo === Built %OUT%\app.exe ===

if defined DO_RUN (
    echo === Running ===
    pushd "%ROOT%"
    "%OUT%\app.exe"
    popd
)

popd
endlocal
exit /b 0

:fail
echo *** BUILD FAILED ***
popd
endlocal
exit /b 1
