const std = @import("std");
const Vec3 = @import("math3d.zig").Vec3;

pub const near: f32 = 0.05;

pub const Camera = struct {
    pos: Vec3,
    yaw: f32 = 0,
    pitch: f32 = 0,
    fov: f32 = 65, // grados
    forward: Vec3 = Vec3.init(0, 0, 1),
    right: Vec3 = Vec3.init(-1, 0, 0),
    up: Vec3 = Vec3.init(0, 1, 0),
    focal: f32 = 1,
    cx: f32 = 0,
    cy: f32 = 0,

    pub fn update(self: *Camera, width: usize, height: usize) void {
        const limit = std.math.degreesToRadians(@as(f32, 89));
        self.pitch = std.math.clamp(self.pitch, -limit, limit);
        self.forward = Vec3.init(@cos(self.pitch) * @sin(self.yaw), @sin(self.pitch), @cos(self.pitch) * @cos(self.yaw));
        self.right = self.forward.cross(Vec3.init(0, 1, 0)).normalize();
        self.up = self.right.cross(self.forward);
        self.cx = @as(f32, @floatFromInt(width)) / 2;
        self.cy = @as(f32, @floatFromInt(height)) / 2;
        self.focal = self.cy / @tan(std.math.degreesToRadians(self.fov) / 2);
    }

    // mundo - cámara (x derecha, y arriba, z adelante)
    pub fn toView(self: *const Camera, p: Vec3) Vec3 {
        const d = p.sub(self.pos);
        return Vec3.init(d.dot(self.right), d.dot(self.up), d.dot(self.forward));
    }

    // cámara - pantalla
    pub fn project(self: *const Camera, v: Vec3) [2]f32 {
        return .{ self.cx + v.x / v.z * self.focal, self.cy - v.y / v.z * self.focal };
    }

    pub fn lookAt(self: *Camera, target: Vec3) void {
        const d = target.sub(self.pos).normalize();
        self.yaw = std.math.atan2(d.x, d.z);
        self.pitch = std.math.asin(std.math.clamp(d.y, -1.0, 1.0));
    }
};
