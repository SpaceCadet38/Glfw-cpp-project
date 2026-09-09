Copy from the Dear ImGui repository root:

  imgui.cpp, imgui_draw.cpp, imgui_tables.cpp, imgui_widgets.cpp,
  imgui_demo.cpp, imgui.h, imgui_internal.h, imstb_*.h, imconfig.h
      -> external/imgui/

  backends/imgui_impl_glfw.cpp / .h
  backends/imgui_impl_opengl3.cpp / .h
  backends/imgui_impl_opengl3_loader.h
      -> external/imgui/backends/

The Makefile compiles every .cpp in external/imgui/ plus exactly those two
backends - other backends (DirectX, SDL, Vulkan) are ignored, so it is safe to
copy the whole backends folder if that is easier.
