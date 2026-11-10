const std = @import("std");
const rl = @import("raylib");

pub const Framebuffer = struct {
    width: usize,
    height: usize,
    color: []rl.Color,
    depth: []f32,
    texture: rl.Texture,

    pub fn init(alloc: std.mem.Allocator, width: usize, height: usize) !Framebuffer {
        const image = rl.genImageColor(@intCast(width), @intCast(height), .black);
        defer rl.unloadImage(image);
        return .{
            .width = width,
            .height = height,
            .color = try alloc.alloc(rl.Color, width * height),
            .depth = try alloc.alloc(f32, width * height),
            .texture = try rl.loadTextureFromImage(image),
        };
    }

    pub fn clear(self: *Framebuffer, c: rl.Color) void {
        @memset(self.color, c);
        @memset(self.depth, std.math.inf(f32));
    }

    pub fn setPixel(self: *Framebuffer, x: usize, y: usize, c: rl.Color) void {
        self.color[y * self.width + x] = c;
    }

    // sube los pixeles a la textura y la muestra una sola vez, escalada
    pub fn present(self: *Framebuffer, scale: f32) void {
        rl.updateTexture(self.texture, self.color.ptr);
        rl.beginDrawing();
        rl.drawTextureEx(self.texture, .{ .x = 0, .y = 0 }, 0, scale, .white);
        rl.endDrawing();
    }
};

pub fn toColor(r: f32, g: f32, b: f32) rl.Color {
    return .{
        .r = @intFromFloat(std.math.clamp(r, 0.0, 1.0) * 255.0),
        .g = @intFromFloat(std.math.clamp(g, 0.0, 1.0) * 255.0),
        .b = @intFromFloat(std.math.clamp(b, 0.0, 1.0) * 255.0),
        .a = 255,
    };
}
