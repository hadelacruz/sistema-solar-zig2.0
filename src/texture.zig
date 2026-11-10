const std = @import("std");
const rl = @import("raylib");
const Vec3 = @import("math3d.zig").Vec3;

pub const Texture = struct {
    width: usize,
    height: usize,
    pixels: []rl.Color,

    pub fn fromPng(data: []const u8) !Texture {
        const image = try rl.loadImageFromMemory(".png", data);
        defer rl.unloadImage(image);
        return .{
            .width = @intCast(image.width),
            .height = @intCast(image.height),
            .pixels = try rl.loadImageColors(image),
        };
    }

    // vecino más cercano; u se repite, v se recorta
    pub fn get(self: *const Texture, u: f32, v: f32) rl.Color {
        const uu = u - @floor(u);
        const vv = std.math.clamp(v, 0.0, 0.999);
        const x: usize = @min(@as(usize, @intFromFloat(uu * @as(f32, @floatFromInt(self.width)))), self.width - 1);
        const y: usize = @intFromFloat(vv * @as(f32, @floatFromInt(self.height)));
        return self.pixels[y * self.width + x];
    }

    pub fn rgb(self: *const Texture, u: f32, v: f32) Vec3 {
        const c = self.get(u, v);
        return Vec3.init(@as(f32, @floatFromInt(c.r)) / 255.0, @as(f32, @floatFromInt(c.g)) / 255.0, @as(f32, @floatFromInt(c.b)) / 255.0);
    }

    pub fn alpha(self: *const Texture, u: f32, v: f32) f32 {
        return @as(f32, @floatFromInt(self.get(u, v).a)) / 255.0;
    }
};
