# =============================================================================
#  C++ / GLFW / OpenGL project - MinGW (gcc/g++) build, no CMake required.
#
#  Usage (from the project root, using the MinGW-w64 shipped make):
#      mingw32-make            # debug build   -> build/debug/app.exe
#      mingw32-make CONFIG=release
#      mingw32-make run
#      mingw32-make clean
#
#  The compiler is NOT assumed to be on PATH. Point MINGW_BIN at the folder
#  that contains g++.exe, either by editing the default below, by exporting
#  MINGW_BIN in your environment, or on the command line:
#      mingw32-make MINGW_BIN=D:/tools/mingw64/bin
# =============================================================================

# ---- Toolchain --------------------------------------------------------------
# PLACEHOLDER: change this to the real location of your MinGW bin folder.
MINGW_BIN ?= C:/mingw64/bin

CXX := $(MINGW_BIN)/g++
CC  := $(MINGW_BIN)/gcc

# ---- Configuration (debug | release) ---------------------------------------
CONFIG ?= debug

ifeq ($(CONFIG),release)
  CONFIG_FLAGS := -O2 -DNDEBUG
else
  CONFIG_FLAGS := -g3 -O0 -DDEBUG
endif

# ---- Layout -----------------------------------------------------------------
SRC_DIR      := src
EXT_DIR      := external
BUILD_DIR    := build/$(CONFIG)
OBJ_DIR      := $(BUILD_DIR)/obj
TARGET       := $(BUILD_DIR)/app.exe

GLAD_DIR  := $(EXT_DIR)/glad
GLFW_DIR  := $(EXT_DIR)/glfw
GLM_DIR   := $(EXT_DIR)/glm
IMGUI_DIR := $(EXT_DIR)/imgui

# ---- Include paths ----------------------------------------------------------
INCLUDES := \
  -I$(SRC_DIR) \
  -I$(GLAD_DIR)/include \
  -I$(GLFW_DIR)/include \
  -I$(GLM_DIR) \
  -I$(IMGUI_DIR) \
  -I$(IMGUI_DIR)/backends

# ---- Sources ----------------------------------------------------------------
# Project sources: every .cpp under src/ (recursively, one level of nesting).
SRC_CPP   := $(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/**/*.cpp)

# Dear ImGui core + the two backends this project needs.
IMGUI_CPP := $(wildcard $(IMGUI_DIR)/*.cpp) \
             $(wildcard $(IMGUI_DIR)/backends/imgui_impl_glfw.cpp) \
             $(wildcard $(IMGUI_DIR)/backends/imgui_impl_opengl3.cpp)

# Glad is C, compiled with gcc.
GLAD_C    := $(wildcard $(GLAD_DIR)/src/*.c)

# ---- Objects ----------------------------------------------------------------
OBJS := $(patsubst %.cpp,$(OBJ_DIR)/%.o,$(SRC_CPP) $(IMGUI_CPP)) \
        $(patsubst %.c,$(OBJ_DIR)/%.o,$(GLAD_C))
DEPS := $(OBJS:.o=.d)

# ---- Flags ------------------------------------------------------------------
# Recursively expanded (=, not :=) so the per-directory override below can
# swap WARNINGS out for third-party objects.
WARNINGS   = -Wall -Wextra -Wpedantic -Wno-unused-parameter
COMMON     = $(CONFIG_FLAGS) $(WARNINGS) $(INCLUDES) -MMD -MP
CXXFLAGS   = -std=c++17 $(COMMON)
CFLAGS     = -std=c11   $(COMMON)

# Glad and Dear ImGui are vendored code we do not maintain; warning on them
# only buries the warnings that come from src/. Silence just those objects.
$(OBJ_DIR)/$(EXT_DIR)/%.o: WARNINGS = -w

# GLFW_STATIC is required when linking against the static libglfw3.a.
CPPFLAGS  := -DGLFW_INCLUDE_NONE -DGLFW_STATIC

# ---- Linking ----------------------------------------------------------------
# -static-libgcc/-static-libstdc++ so the .exe runs without the MinGW DLLs.
LDFLAGS := -L$(GLFW_DIR)/lib -static-libgcc -static-libstdc++

# glfw3 must come before the Win32 system libraries it depends on.
LDLIBS  := -lglfw3 -lopengl32 -lgdi32 -luser32 -lshell32 -lkernel32 -limm32

# Release builds hide the console window; debug keeps it for printf/stderr.
ifeq ($(CONFIG),release)
  LDFLAGS += -mwindows
endif

# ---- Shell helpers ----------------------------------------------------------
# Works with both cmd.exe (native mingw32-make) and a POSIX shell (MSYS/Git Bash).
ifeq ($(OS),Windows_NT)
  ifeq ($(SHELL),/bin/sh)
    MKDIR = mkdir -p $(1)
    RMDIR = rm -rf $(1)
  else
    MKDIR = if not exist "$(subst /,\,$(1))" mkdir "$(subst /,\,$(1))"
    RMDIR = if exist "$(subst /,\,$(1))" rmdir /s /q "$(subst /,\,$(1))"
  endif
else
  MKDIR = mkdir -p $(1)
  RMDIR = rm -rf $(1)
endif

# =============================================================================
#  Rules
# =============================================================================
.PHONY: all run clean rebuild info release debug

all: $(TARGET)

debug:
	@$(MAKE) CONFIG=debug

release:
	@$(MAKE) CONFIG=release

$(TARGET): $(OBJS)
	@$(call MKDIR,$(dir $@))
	$(CXX) $(OBJS) -o $@ $(LDFLAGS) $(LDLIBS)
	@echo === Built $@ ===

$(OBJ_DIR)/%.o: %.cpp
	@$(call MKDIR,$(dir $@))
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.c
	@$(call MKDIR,$(dir $@))
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

run: $(TARGET)
	@echo === Running $(TARGET) ===
	@./$(TARGET)

clean:
	@$(call RMDIR,build)
	@echo === Cleaned ===

rebuild: clean all

# Prints the resolved configuration - handy when a path placeholder is wrong.
info:
	@echo CONFIG      = $(CONFIG)
	@echo CXX         = $(CXX)
	@echo TARGET      = $(TARGET)
	@echo SRC_CPP     = $(SRC_CPP)
	@echo IMGUI_CPP   = $(IMGUI_CPP)
	@echo GLAD_C      = $(GLAD_C)

-include $(DEPS)
