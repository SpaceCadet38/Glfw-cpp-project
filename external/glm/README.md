GLM is header-only - nothing to compile or link.

Unzip so the headers end up at:
  external/glm/glm/glm.hpp
  external/glm/glm/gtc/matrix_transform.hpp
  ...

The Makefile adds -Iexternal/glm, so #include <glm/glm.hpp> resolves.
