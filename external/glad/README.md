Either generation of glad works - the build detects which one you dropped in.

## glad1 - https://glad.dav1d.de/
  Language: C/C++  |  Specification: OpenGL
  API gl: Version 3.3  |  Profile: Core  |  Generate a loader: yes

  include/glad/glad.h        -> external/glad/include/glad/glad.h
  include/KHR/khrplatform.h  -> external/glad/include/KHR/khrplatform.h
  src/glad.c                 -> external/glad/src/glad.c

## glad2 - https://gen.glad.sh/
  Generator: C/C++  |  APIs gl: Version 3.3  |  Profile: Core
  Options: check "loader"

  include/glad/gl.h          -> external/glad/include/glad/gl.h
  include/KHR/khrplatform.h  -> external/glad/include/KHR/khrplatform.h
  src/gl.c                   -> external/glad/src/gl.c

Do not mix the two - use the header and source from the same download.

The build globs external/glad/src/*.c, so the filename does not matter, and
src/gl_loader.h selects the matching header and loader function. glad.c / gl.c
is compiled with gcc as C, not C++.

Generate for OpenGL 3.3 core: src/main.cpp requests a 3.3 core context.
