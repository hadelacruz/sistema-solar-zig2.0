const std = @import("std");

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }
    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return init(a.x + b.x, a.y + b.y, a.z + b.z);
    }
    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return init(a.x - b.x, a.y - b.y, a.z - b.z);
    }
    pub fn scale(a: Vec3, s: f32) Vec3 {
        return init(a.x * s, a.y * s, a.z * s);
    }
    pub fn mul(a: Vec3, b: Vec3) Vec3 {
        return init(a.x * b.x, a.y * b.y, a.z * b.z);
    }
    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return init(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
    }
    pub fn length(a: Vec3) f32 {
        return @sqrt(a.dot(a));
    }
    pub fn normalize(a: Vec3) Vec3 {
        const l = a.length();
        if (l == 0) return a;
        return a.scale(1.0 / l);
    }
    pub fn lerp(a: Vec3, b: Vec3, t: f32) Vec3 {
        return a.add(b.sub(a).scale(t));
    }
};

pub fn smoothstep(e0: f32, e1: f32, x: f32) f32 {
    const t = std.math.clamp((x - e0) / (e1 - e0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}
