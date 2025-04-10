#version 330 core // Or your target version

in vec2 vTexCoord; // Interpolated texture coordinates from vertex shader

out vec4 FragColor; // Final pixel color output

// --- Uniforms (Set these from your application) ---
uniform sampler2D uTexture;          // The input 2D texture you want to modify

uniform vec3 uRubyColor;        // Target ruby color (e.g., vec3(0.7, 0.05, 0.1))
uniform float uContrast;        // Multiplier for contrast (e.g., 1.5 - 3.0)
uniform float uBrightness;      // Overall brightness adjustment (e.g., 1.0 - 1.5)
uniform float uGlintThreshold;  // Luminance threshold for adding glints (e.g., 0.8)
uniform float uGlintIntensity;  // How bright the fake glints are (e.g., 0.5 - 1.0)

// --- Helper Function: Luminance ---
float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722)); // Standard luminance calculation
}

void main() {
    // 1. Sample the original texture
    vec4 originalColor = texture(uTexture, vTexCoord);

    // 2. Calculate Luminance of the original pixel
    float luminance = getLuminance(originalColor.rgb);

    // 3. Apply Contrast (Simple power curve)
    // Values > 1 increase contrast, < 1 decrease contrast
    float contrastedLuminance = pow(luminance, uContrast);

    // 4. Create the Ruby Base Color
    // Use the contrasted luminance to modulate the brightness of the target ruby color.
    // This preserves the texture's pattern but applies the ruby hue.
    vec3 rubyBase = uRubyColor * contrastedLuminance * uBrightness;

    // 5. Add Fake Glints/Highlights
    // Find bright spots (based on original or contrasted luminance) and add a white highlight.
    // Using contrastedLuminance makes glints appear on newly brightened areas too.
    float glintFactor = smoothstep(uGlintThreshold, uGlintThreshold + 0.1, contrastedLuminance);
    // Sharpen the glint effect
    glintFactor = pow(glintFactor, 4.0);

    // Add white color based on the glint factor
    vec3 finalColor = rubyBase + vec3(1.0) * glintFactor * uGlintIntensity;

    // Optional: Blend original color slightly to retain some texture color variation
    // finalColor = mix(finalColor, originalColor.rgb * uRubyColor, 0.1); // Example: 10% blend

    // 6. Output the final color, preserving original alpha
    FragColor = vec4(clamp(finalColor, 0.0, 1.0), originalColor.a);
}