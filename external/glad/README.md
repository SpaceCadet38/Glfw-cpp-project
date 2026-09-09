Generate at https://glad.dav1d.de/ with:
  Language: C/C++   |   Specification: OpenGL
  API gl: Version 3.3   |   Profile: Core   |   Generate a loader: yes

Then copy:
  include/glad/glad.h        -> external/glad/include/glad/glad.h
  include/KHR/khrplatform.h  -> external/glad/include/KHR/khrplatform.h
  src/glad.c                 -> external/glad/src/glad.c

glad.c is compiled with gcc by the Makefile (GLAD_C target).
