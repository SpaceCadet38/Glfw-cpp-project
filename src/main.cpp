// =============================================================================
//  GLFW + Glad + GLM + Dear ImGui starter
//
//  Draws a rotating triangle through a small GLSL program (GLM supplies the
//  matrices) with an ImGui control panel on top. If this builds and runs, all
//  four libraries are wired up correctly.
// =============================================================================

// Pulls in glad (either generation) and then GLFW, in the required order.
#include "gl_loader.h"

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <cstdio>
#include <cstdlib>

// ---- Shaders ---------------------------------------------------------------
static const char* kVertexShader = R"(
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

uniform mat4 uMVP;

out vec3 vColor;

void main()
{
    gl_Position = uMVP * vec4(aPos, 1.0);
    vColor = aColor;
}
)";

static const char* kFragmentShader = R"(
#version 330 core
in vec3 vColor;
out vec4 FragColor;

uniform float uMix;

void main()
{
    FragColor = vec4(mix(vColor, vec3(1.0), uMix), 1.0);
}
)";

// ---- Helpers ---------------------------------------------------------------
static void glfwErrorCallback(int error, const char* description)
{
    std::fprintf(stderr, "[GLFW] error %d: %s\n", error, description);
}

static void framebufferSizeCallback(GLFWwindow* /*window*/, int width, int height)
{
    glViewport(0, 0, width, height);
}

// Compiles one shader stage and reports the driver's log on failure.
static GLuint compileShader(GLenum type, const char* source)
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);

    GLint ok = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok)
    {
        char log[1024];
        glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
        std::fprintf(stderr, "[GL] shader compile failed: %s\n", log);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

static GLuint createProgram(const char* vsSource, const char* fsSource)
{
    GLuint vs = compileShader(GL_VERTEX_SHADER, vsSource);
    GLuint fs = compileShader(GL_FRAGMENT_SHADER, fsSource);
    if (vs == 0 || fs == 0)
        return 0;

    GLuint program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);

    GLint ok = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &ok);
    if (!ok)
    {
        char log[1024];
        glGetProgramInfoLog(program, sizeof(log), nullptr, log);
        std::fprintf(stderr, "[GL] program link failed: %s\n", log);
        glDeleteProgram(program);
        program = 0;
    }

    // The program keeps its own copy once linked.
    glDeleteShader(vs);
    glDeleteShader(fs);
    return program;
}

// =============================================================================
int main()
{
    glfwSetErrorCallback(glfwErrorCallback);

    if (!glfwInit())
    {
        std::fprintf(stderr, "Failed to initialise GLFW\n");
        return EXIT_FAILURE;
    }

    // OpenGL 3.3 core - matches the #version 330 core shaders above.
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(1280, 720, "GLFW + Glad + ImGui", nullptr, nullptr);
    if (window == nullptr)
    {
        std::fprintf(stderr, "Failed to create GLFW window\n");
        glfwTerminate();
        return EXIT_FAILURE;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1); // vsync
    glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    // Glad needs a current context before it can resolve any entry point.
    if (!projectLoadGLFunctions())
    {
        std::fprintf(stderr, "Failed to initialise Glad\n");
        glfwDestroyWindow(window);
        glfwTerminate();
        return EXIT_FAILURE;
    }

    std::printf("OpenGL %s\n", glGetString(GL_VERSION));
    std::printf("Renderer %s\n", glGetString(GL_RENDERER));

    // ---- Dear ImGui --------------------------------------------------------
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    // ---- Geometry ----------------------------------------------------------
    // Interleaved: position (xyz) then colour (rgb).
    const float vertices[] = {
        // position            // colour
        -0.6f, -0.5f, 0.0f,    1.0f, 0.2f, 0.2f,
         0.6f, -0.5f, 0.0f,    0.2f, 1.0f, 0.2f,
         0.0f,  0.6f, 0.0f,    0.2f, 0.4f, 1.0f,
    };

    GLuint vao = 0, vbo = 0;
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);

    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float),
                          reinterpret_cast<void*>(0));
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float),
                          reinterpret_cast<void*>(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    glBindVertexArray(0);

    GLuint program = createProgram(kVertexShader, kFragmentShader);
    if (program == 0)
    {
        std::fprintf(stderr, "Shader setup failed\n");
        return EXIT_FAILURE;
    }

    const GLint mvpLocation = glGetUniformLocation(program, "uMVP");
    const GLint mixLocation = glGetUniformLocation(program, "uMix");

    // ---- UI state ----------------------------------------------------------
    glm::vec3 clearColor(0.10f, 0.11f, 0.13f);
    float rotationSpeed = 45.0f;   // degrees / second
    float scale         = 1.0f;
    float whiteMix      = 0.0f;
    bool  animate       = true;
    bool  showDemo      = false;
    float angle         = 0.0f;

    double lastTime = glfwGetTime();

    // ---- Main loop ---------------------------------------------------------
    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents();

        const double now = glfwGetTime();
        const float deltaTime = static_cast<float>(now - lastTime);
        lastTime = now;

        if (animate)
            angle += rotationSpeed * deltaTime;

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("Controls");
        ImGui::Text("%.1f FPS (%.3f ms/frame)",
                    ImGui::GetIO().Framerate, 1000.0f / ImGui::GetIO().Framerate);
        ImGui::Separator();
        ImGui::Checkbox("Animate", &animate);
        ImGui::SliderFloat("Speed (deg/s)", &rotationSpeed, -360.0f, 360.0f);
        ImGui::SliderFloat("Scale", &scale, 0.1f, 2.0f);
        ImGui::SliderFloat("Fade to white", &whiteMix, 0.0f, 1.0f);
        ImGui::ColorEdit3("Background", glm::value_ptr(clearColor));
        if (ImGui::Button("Reset"))
        {
            angle = 0.0f;
            scale = 1.0f;
            whiteMix = 0.0f;
            rotationSpeed = 45.0f;
        }
        ImGui::Checkbox("Show ImGui demo window", &showDemo);
        ImGui::End();

        if (showDemo)
            ImGui::ShowDemoWindow(&showDemo);

        ImGui::Render();

        int width = 0, height = 0;
        glfwGetFramebufferSize(window, &width, &height);
        glViewport(0, 0, width, height);

        glClearColor(clearColor.r, clearColor.g, clearColor.b, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // GLM builds the transform; aspect keeps the triangle from stretching.
        const float aspect = (height > 0)
            ? static_cast<float>(width) / static_cast<float>(height)
            : 1.0f;

        glm::mat4 projection = glm::ortho(-aspect, aspect, -1.0f, 1.0f, -1.0f, 1.0f);
        glm::mat4 model(1.0f);
        model = glm::rotate(model, glm::radians(angle), glm::vec3(0.0f, 0.0f, 1.0f));
        model = glm::scale(model, glm::vec3(scale));
        const glm::mat4 mvp = projection * model;

        glUseProgram(program);
        glUniformMatrix4fv(mvpLocation, 1, GL_FALSE, glm::value_ptr(mvp));
        glUniform1f(mixLocation, whiteMix);

        glBindVertexArray(vao);
        glDrawArrays(GL_TRIANGLES, 0, 3);
        glBindVertexArray(0);

        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    // ---- Shutdown ----------------------------------------------------------
    glDeleteVertexArrays(1, &vao);
    glDeleteBuffers(1, &vbo);
    glDeleteProgram(program);

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();
    return EXIT_SUCCESS;
}
