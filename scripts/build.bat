@echo off
REM ===========================================================================
REM  Build without make - calls g++/gcc directly.
REM  Usage:  scripts\build.bat [debug|release]
REM ===========================================================================
setlocal enabledelayedexpansion

REM PLACEHOLDER: folder containing g++.exe and gcc.exe
if "%MINGW_BIN%"=="" set "MINGW_BIN=C:\mingw64\bin"

set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=debug"

pushd "%~dp0.."
set "ROOT=%CD%"

set "OUT=%ROOT%\build\%CONFIG%"
if not exist "%OUT%" mkdir "%OUT%"

set "INCLUDES=-I"%ROOT%\src" -I"%ROOT%\external\glad\include" -I"%ROOT%\external\glfw\include" -I"%ROOT%\external\glm" -I"%ROOT%\external\imgui" -I"%ROOT%\external\imgui\backends""
set "DEFINES=-DGLFW_INCLUDE_NONE -DGLFW_STATIC"

if /i "%CONFIG%"=="release" (
    set "CFG_FLAGS=-O2 -DNDEBUG"
    set "LINK_EXTRA=-mwindows"
) else (
    set "CFG_FLAGS=-g3 -O0 -DDEBUG"
    set "LINK_EXTRA="
)

REM ---- Collect sources ------------------------------------------------------
set "SOURCES="
for /r "%ROOT%\src" %%f in (*.cpp) do set "SOURCES=!SOURCES! "%%f""
for %%f in ("%ROOT%\external\imgui\*.cpp") do set "SOURCES=!SOURCES! "%%f""
for %%f in ("%ROOT%\external\imgui\backends\imgui_impl_glfw.cpp" "%ROOT%\external\imgui\backends\imgui_impl_opengl3.cpp") do (
    if exist %%f set "SOURCES=!SOURCES! "%%~f""
)

set "GLAD_SRC=%ROOT%\external\glad\src\glad.c"
if not exist "%GLAD_SRC%" (
    echo ERROR: %GLAD_SRC% not found. See external\glad\README.md
    popd & exit /b 1
)

REM ---- Compile glad (C) -----------------------------------------------------
echo [1/2] Compiling glad.c
"%MINGW_BIN%\gcc.exe" -std=c11 %CFG_FLAGS% %DEFINES% %INCLUDES% -c "%GLAD_SRC%" -o "%OUT%\glad.o"
if errorlevel 1 ( popd & exit /b 1 )

REM ---- Compile + link everything else (C++) ---------------------------------
echo [2/2] Compiling C++ and linking
"%MINGW_BIN%\g++.exe" -std=c++17 %CFG_FLAGS% -Wall -Wextra %DEFINES% %INCLUDES% ^
    !SOURCES! "%OUT%\glad.o" ^
    -o "%OUT%\app.exe" ^
    -L"%ROOT%\external\glfw\lib" ^
    -static-libgcc -static-libstdc++ %LINK_EXTRA% ^
    -lglfw3 -lopengl32 -lgdi32 -luser32 -lshell32 -lkernel32 -limm32
if errorlevel 1 ( popd & exit /b 1 )

echo === Built %OUT%\app.exe ===
popd
endlocal
