uniform int border_thickness<
    string label = "Border Thickness";
    string widget_type = "slider";
    int minimum = 2;
    int maximum = 1000;
    int step = 1;
> = 5;

uniform float4 color1;   // Color for the left and top sides
uniform float4 color2;   // Color for the right and bottom sides

uniform bool border_outside<
    string label = "Border Outside";
    string widget_type = "checkbox";
> = true;

// Helper function to check if we're in the border area
bool isInBorder(float2 st, float border_thickness_uv_x, float border_thickness_uv_y) {
    return st.x < border_thickness_uv_x || st.y < border_thickness_uv_y ||
           st.x > (1.0 - border_thickness_uv_x) || st.y > (1.0 - border_thickness_uv_y);
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

    // Determine if we're in the border area
    bool isInBorderArea = isInBorder(st, border_thickness_uv_x, border_thickness_uv_y);

    // Check if we're inside the object area (excluding the border)
    if (!border_outside && !isInBorderArea) {
        // Return the original texture color if we are inside the object area for inside border
        return output_color;
    }

    float4 border_color = color2;

    // Calculate the relative position within the border area
    float2 border_uv = st / float2(border_thickness_uv_x, border_thickness_uv_y);

    // Determine the color based on the 45-degree diagonal split within the border area
    if ((st.x < border_thickness_uv_x && st.y < border_thickness_uv_y) || 
        (st.x > (1.0 - border_thickness_uv_x) && st.y > (1.0 - border_thickness_uv_y))) {
        if (border_uv.x + border_uv.y < 1.0) {
            border_color = color1; // Apply color1 to left and top sides
        }
    } else if ((st.x < border_thickness_uv_x && st.y > (1.0 - border_thickness_uv_y)) || 
               (st.x > (1.0 - border_thickness_uv_x) && st.y < border_thickness_uv_y)) {
        if (border_uv.x + border_uv.y >= 1.0) {
            border_color = color1; // Apply color1 to left and top sides
        }
    } else {
        if (st.x < border_thickness_uv_x || st.y < border_thickness_uv_y) {
            border_color = color1; // Apply color1 to left and top sides
        }
    }

    // Add squares with 45-degree split at lower left and upper right corners
    float2 corner_size_uv = float2(border_thickness_uv_x, border_thickness_uv_y);

    // Lower left corner
    if (st.x < border_thickness_uv_x && st.y > (1.0 - border_thickness_uv_y)) {
        float2 corner_uv = (st - float2(0.0, 1.0 - border_thickness_uv_y)) / corner_size_uv;
        if (corner_uv.x + corner_uv.y < 1.0) {
            border_color = color1;
        } else {
            border_color = color2;
        }
    }

    // Upper right corner
    if (st.x > (1.0 - border_thickness_uv_x) && st.y < border_thickness_uv_y) {
        float2 corner_uv = (st - float2(1.0 - border_thickness_uv_x, 0.0)) / corner_size_uv;
        if (corner_uv.x + corner_uv.y < 1.0) {
            border_color = color1;
        } else {
            border_color = color2;
        }
    }

    // Ensure the upper left corner is fully color1
    if (st.x < border_thickness_uv_x && st.y < border_thickness_uv_y) {
        border_color = color1;
    }

    // Return the border color if we're in the border area
    if (isInBorderArea) {
        return border_color;
    }

    // Return the original texture color if we are not inside the border area
    return output_color;
}