Use the pre-compiled **MinGW-w64** binaries from https://www.glfw.org/download

  include/GLFW/glfw3.h        -> external/glfw/include/GLFW/glfw3.h
  include/GLFW/glfw3native.h  -> external/glfw/include/GLFW/glfw3native.h
  lib-mingw-w64/libglfw3.a    -> external/glfw/lib/libglfw3.a

Use libglfw3.a (static). libglfw3dll.a + glfw3.dll also work, but then drop
-DGLFW_STATIC from CPPFLAGS in the Makefile and ship glfw3.dll next to app.exe.
