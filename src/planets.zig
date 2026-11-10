const std = @import("std");
const Vec3 = @import("math3d.zig").Vec3;
const Texture = @import("texture.zig").Texture;
const Mesh = @import("sphere.zig").Mesh;

pub const Kind = enum { sol, ignis, terra, zephyr, glacia };

pub const Body = struct {
    name: []const u8,
    kind: Kind,
    radius: f32,
    mesh: *const Mesh,
    texture: *const Texture,
    clouds: ?*const Texture = null,
    orbit_radius: f32 = 0,
    orbit_speed: f32 = 0,
    orbit_phase: f32 = 0,
    spin_speed: f32 = 0,
    pos: Vec3 = Vec3.init(0, 0, 0),
    spin: f32 = 0,
};

// todos orbitan al Sol, que está en el origen
pub fn update(bodies: []Body, time: f32) void {
    for (bodies) |*b| {
        const angle = b.orbit_phase + time * b.orbit_speed;
        b.pos = Vec3.init(@cos(angle), 0, @sin(angle)).scale(b.orbit_radius);
        b.spin = time * b.spin_speed;
    }
}

// si la cámara entró a un cuerpo, la saca hasta su superficie más un margen
pub fn pushOut(bodies: []const Body, pos: Vec3) Vec3 {
    var p = pos;
    for (bodies) |b| {
        const min_dist = b.radius * 1.3 + 0.3;
        const d = p.sub(b.pos);
        if (d.length() < min_dist) p = b.pos.add(d.normalize().scale(min_dist));
    }
    return p;
}
