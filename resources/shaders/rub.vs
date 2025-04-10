#version 330 core // Or your target version

layout (location = 0) in vec2 aPos;      // Vertex position (usually screen quad)
layout (location = 1) in vec2 aTexCoord; // Input texture coordinates

out vec2 vTexCoord; // Pass texture coordinates to fragment shader

void main() {
    vTexCoord = aTexCoord;
    // Output position typically ranges from -1 to 1 in clip space for a full-screen quad
    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);
}



