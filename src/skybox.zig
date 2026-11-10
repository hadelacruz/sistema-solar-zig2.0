const std = @import("std");
const rl = @import("raylib");
const Vec3 = @import("math3d.zig").Vec3;
const Camera = @import("camera.zig").Camera;
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const toColor = @import("framebuffer.zig").toColor;

const Star = struct {
    dir: Vec3,
    bright: f32,
};

pub const Skybox = struct {
    stars: []Star,

    pub fn init(alloc: std.mem.Allocator, count: usize) !Skybox {
        var prng = std.Random.DefaultPrng.init(42);
        const rand = prng.random();
        const stars = try alloc.alloc(Star, count);
        for (stars) |*s| {
            // punto al azar en una esfera
            const z = rand.float(f32) * 2 - 1;
            const angle = rand.float(f32) * 2 * std.math.pi;
            const r = @sqrt(1 - z * z);
            s.dir = Vec3.init(r * @cos(angle), z, r * @sin(angle));
            s.bright = 0.2 + 0.8 * rand.float(f32) * rand.float(f32);
        }
        return .{ .stars = stars };
    }

    // Las estrellas son direcciones: solo se rotan con la cámara, no se trasladan,
    // por eso parecen infinitamente lejanas. Con warp > 0 se estiran en líneas.
    pub fn draw(self: *const Skybox, fb: *Framebuffer, cam: *const Camera, warp: f32) void {
        const w: f32 = @floatFromInt(fb.width);
        const h: f32 = @floatFromInt(fb.height);
        for (self.stars) |s| {
            const v = Vec3.init(s.dir.dot(cam.right), s.dir.dot(cam.up), s.dir.dot(cam.forward));
            if (v.z <= 0) continue;
            const p = cam.project(v);
            const c = toColor(s.bright, s.bright, s.bright);

            // línea desde la estrella hacia afuera del centro de la pantalla
            const len = warp * 0.5;
            const steps: usize = @intFromFloat(1 + @max(@abs(p[0] - cam.cx), @abs(p[1] - cam.cy)) * len);
            for (0..steps) |i| {
                const t = @as(f32, @floatFromInt(i)) * len / @as(f32, @floatFromInt(steps));
                const x = p[0] + (p[0] - cam.cx) * t;
                const y = p[1] + (p[1] - cam.cy) * t;
                if (x < 0 or y < 0 or x >= w or y >= h) break;
                fb.setPixel(@intFromFloat(x), @intFromFloat(y), c);
            }
        }
    }
};
