uniform int border_thickness<
    string label = "Border Thickness";
    string widget_type = "slider";
    int minimum = 2;  // Minimum of 2 to ensure no single step gradient
    int maximum = 1000;  // Extended maximum border thickness
    int step = 1;
> = 5;

uniform float4 color1;   // Color for one end of the gradient
uniform float4 color2;   // Color for the other end of the gradient

uniform float gradient_angle<
    string label = "Gradient Angle";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 360.0;
    float step = 0.1;
> = 0.0;

uniform int gradient_steps<
    string label = "Gradient Steps";
    string widget_type = "slider";
    int minimum = 2;
    int maximum = 100;
    int step = 1;
> = 2;

uniform bool border_outside<
    string label = "Border Outside";
    string widget_type = "checkbox";
> = true;

// Helper function to check if we're in the border area for inside border
bool isInBorderInside(float2 st, float border_thickness_uv_x, float border_thickness_uv_y) {
    return st.x < border_thickness_uv_x || st.y < border_thickness_uv_y ||
           st.x > (1.0 - border_thickness_uv_x) || st.y > (1.0 - border_thickness_uv_y);
}

// Helper function to check if we're in the border area for outside border
bool isInBorderOutside(float2 st, float border_thickness_uv_x, float border_thickness_uv_y) {
    return st.x < -border_thickness_uv_x || st.y < -border_thickness_uv_y ||
           st.x > 1.0 + border_thickness_uv_x || st.y > 1.0 + border_thickness_uv_y;
}

float4 mainImage(VertData v_in) : TARGET {
    float2 st = v_in.uv;  // UV coordinates of the pixel

    // Convert border thickness from pixels to UV space
    float border_thickness_uv_x = float(border_thickness) * uv_pixel_interval.x;
    float border_thickness_uv_y = float(border_thickness) * uv_pixel_interval.y;

    // Adjust UV scale for outside border
    float2 adjusted_uv = v_in.uv;
    if (border_outside) {
        adjusted_uv = v_in.uv * (1.0 - 2.0 * max(border_thickness_uv_x, border_thickness_uv_y)) + float2(border_thickness_uv_x, border_thickness_uv_y);
    }

    float4 output_color = image.Sample(textureSampler, adjusted_uv);  // Sample the texture color

    // Determine if we're in the border area based on the border_outside parameter
    bool isInBorder = border_outside ? isInBorderOutside(st, border_thickness_uv_x, border_thickness_uv_y)
                                     : isInBorderInside(st, border_thickness_uv_x, border_thickness_uv_y);

    // If border is outside, ensure the border thickness is not applied inside the object
    if (border_outside && !isInBorderOutside(st, border_thickness_uv_x, border_thickness_uv_y)) {
        isInBorder = false;
    }

    // Check if we're inside the object area (excluding the border) for inside border
    if (!border_outside && !isInBorderInside(st, border_thickness_uv_x, border_thickness_uv_y)) {
        // Return the original texture color if we are inside the object area for inside border
        return output_color;
    }

    // Calculate the gradient direction based on the angle
    float angle_rad = radians(gradient_angle);
    float2 gradient_dir = float2(cos(angle_rad), sin(angle_rad));

    // Center the gradient factor calculation
    float2 centered_st = st - 0.5;
    float gradient_factor = dot(centered_st, gradient_dir);

    // Normalize the gradient factor to the range [0, 1]
    gradient_factor = (gradient_factor + 0.5) / 1.0;

    // Quantize the gradient factor based on the number of steps
    float step_size = 1.0 / float(gradient_steps);
    gradient_factor = floor(gradient_factor / step_size) * step_size;

    // Clamp the gradient factor to the range [0, 1]
    gradient_factor = clamp(gradient_factor, 0.0, 1.0);

    // Calculate the final border color using the quantized gradient factor
    float4 border_color = lerp(color1, color2, gradient_factor);

    // Return the border color if we're in the border area
    if (isInBorder) {
        return border_color;
    }

    // Return the original texture color if we are not inside the border area
    return output_color;
}