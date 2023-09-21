#ifndef DATA_GLSL
#define DATA_GLSL

struct Vertex {
    u16vec4 position;      // 0..7     
    u8vec4 color;          // 8..11
    u16vec2 block_texture; // 12..15
    u16vec2 light_texture; // 16..19
    u16vec2 mid_tex_coord; // 20..23
    i8vec4 tangent;        // 24..27
    i8vec3 normal;         // 28..30
    uint8_t padA__;        // 31..31
    i16vec2 block_id;      // 32..35
    i8vec3 mid_block;      // 36..38
    uint8_t padB__;        // 39..39
}; // 40 bytes

struct Quad {
    Vertex vertices[4];
};


#endif // DATA_GLSL