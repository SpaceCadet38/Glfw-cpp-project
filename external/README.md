# external/ - third-party libraries

Drop the libraries you already have into the folders below. The build reads
these paths directly (see `Makefile` -> `INCLUDES` / `LDFLAGS`), so nothing
else needs to change once the files are in place.

```
external/
├── glad/
│   ├── include/
│   │   ├── glad/glad.h          <- from the glad zip
│   │   └── KHR/khrplatform.h    <- from the glad zip
│   └── src/glad.c               <- compiled into the app, do not skip
│
├── glfw/
│   ├── include/GLFW/
│   │   ├── glfw3.h
│   │   └── glfw3native.h
│   └── lib/
│       └── libglfw3.a           <- the MinGW build, NOT the MSVC .lib
│
├── glm/
│   └── glm/                     <- header-only; the inner "glm" folder
│       ├── glm.hpp
│       └── ...
│
└── imgui/
    ├── imgui.cpp, imgui_draw.cpp, imgui_tables.cpp,
    │   imgui_widgets.cpp, imgui_demo.cpp, imgui.h, ...
    └── backends/
        ├── imgui_impl_glfw.cpp / .h
        └── imgui_impl_opengl3.cpp / .h  (+ imgui_impl_opengl3_loader.h)
```

## Notes that save an hour of linker errors

- **Use the MinGW GLFW build.** The GLFW download page ships separate MSVC and
  MinGW binaries. `libglfw3.a` from the MinGW folder is the right one; a `.lib`
  from the MSVC folder will not link with g++.
- **Match the architecture.** A 64-bit g++ needs the 64-bit `libglfw3.a`.
- **Glad must match the GL version.** `src/main.cpp` asks for an OpenGL 3.3
  core context, so generate glad for gl 3.3, core profile.
- **GLM path.** Point at the folder *containing* `glm/`, which is why the
  include flag is `-Iexternal/glm` and the code says `#include <glm/glm.hpp>`.
  If you unzip glm so the headers land in `external/glm/glm/glm.hpp`, it is
  already correct.
- **Link order matters.** `-lglfw3` comes before `-lopengl32 -lgdi32 ...` in
  the Makefile; g++ resolves symbols left to right and reordering these
  produces "undefined reference to `__imp_glfwInit`" style errors.
