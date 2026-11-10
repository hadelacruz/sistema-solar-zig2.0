const std = @import("std");
const m = @import("math3d.zig");
const Vec3 = m.Vec3;
const Camera = @import("camera.zig").Camera;
const Body = @import("planets.zig").Body;

pub const Travel = struct {
    active: bool = false,
    t: f32 = 0,
    start: Vec3 = Vec3.init(0, 0, 0),
    target: usize = 0,

    pub fn begin(self: *Travel, cam: *const Camera, target: usize) void {
        self.active = true;
        self.t = 0;
        self.start = cam.pos;
        self.target = target;
    }

    // 0 al inicio, 1 a la mitad, 0 al llegar
    pub fn warp(self: *const Travel) f32 {
        if (!self.active) return 0;
        return @sin(std.math.pi * self.t);
    }

    pub fn update(self: *Travel, cam: *Camera, bodies: []const Body, dt: f32) void {
        if (!self.active) return;
        self.t = @min(self.t + dt / 2.5, 1.0);

        const b = bodies[self.target];
        const to_sun = if (b.kind == .sol) self.start.sub(b.pos).normalize() else b.pos.scale(-1).normalize();
        const dest = b.pos.add(to_sun.add(Vec3.init(0, 0.4, 0)).normalize().scale(b.radius * 4));

        const s = m.smoothstep(0, 1, self.t);
        const arc = @sin(std.math.pi * s) * self.start.sub(dest).length() * 0.3;
        cam.pos = self.start.lerp(dest, s).add(Vec3.init(0, arc, 0));
        cam.lookAt(b.pos);
        cam.fov = 65 + 30 * self.warp();

        if (self.t >= 1) {
            self.active = false;
            cam.fov = 65;
        }
    }
};
