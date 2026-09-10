#pragma once
// =============================================================================
//  GL loader compatibility shim.
//
//  Two incompatible generations of glad are in circulation and the download
//  pages do not make the difference obvious:
//
//    glad1 (glad.dav1d.de)  ->  src/glad.c, <glad/glad.h>, gladLoadGLLoader()
//    glad2 (gen.glad.sh)    ->  src/gl.c,   <glad/gl.h>,   gladLoadGL()
//
//  Including this header instead of glad directly makes the project build with
//  either one. It also fixes the include order for you: the loader must be
//  included before GLFW, which is the other classic way this goes wrong.
// =============================================================================

#if defined(__has_include)
#  if __has_include(<glad/glad.h>)
#    define PROJECT_GLAD_V1 1
#  elif __has_include(<glad/gl.h>)
#    define PROJECT_GLAD_V2 1
#  endif
#else
   // No __has_include: assume glad1, the more common download.
#  define PROJECT_GLAD_V1 1
#endif

#if defined(PROJECT_GLAD_V1)
#  include <glad/glad.h>
#elif defined(PROJECT_GLAD_V2)
#  include <glad/gl.h>
#else
#  error "No glad header found. Expected external/glad/include/glad/glad.h (glad1) or external/glad/include/glad/gl.h (glad2). See external/glad/README.md"
#endif

// GLFW must come after the loader.
#include <GLFW/glfw3.h>

// Resolves every GL entry point through GLFW. Call once, after the context is
// current. Returns false if loading failed.
inline bool projectLoadGLFunctions()
{
#if defined(PROJECT_GLAD_V1)
    return gladLoadGLLoader(reinterpret_cast<GLADloadproc>(glfwGetProcAddress)) != 0;
#else
    return gladLoadGL(reinterpret_cast<GLADloadfunc>(glfwGetProcAddress)) != 0;
#endif
}
