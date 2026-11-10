const std = @import("std");
const m = @import("math3d.zig");
const Vec3 = m.Vec3;
const Body = @import("planets.zig").Body;

pub const Frag = struct {
    u: f32,
    v: f32,
    normal: Vec3,
    pos: Vec3,
};

const ambient = 0.04;

pub fn shade(b: *const Body, f: Frag, sun: Vec3, cam: Vec3, t: f32) Vec3 {
    const n = f.normal.normalize();
    const l = sun.sub(f.pos).normalize();
    const diffuse = @max(n.dot(l), 0.0); // Lambert
    const light = ambient + diffuse;

    switch (b.kind) {
        // emisivo: dos capas de la textura moviéndose a distinta velocidad + pulso
        .sol => {
            const a = b.texture.rgb(f.u + t * 0.004, f.v);
            const c = b.texture.rgb(f.u * 2.0 - t * 0.007, f.v);
            const pulse = 1.0 + 0.08 * @sin(t * 2.0);
            return a.add(c).scale(0.55 * pulse);
        },
        // la lava (canal alfa) brilla sola, también de noche
        .ignis => {
            const base = b.texture.rgb(f.u, f.v).scale(light);
            const lava = b.texture.alpha(f.u, f.v) * (0.6 + 0.4 * @sin(t * 2.5 + f.u * 60.0));
            return base.add(Vec3.init(1.0, 0.4, 0.05).scale(lava));
        },
        // nubes transparentes que se mueven sobre la superficie
        .terra => {
            const ground = b.texture.rgb(f.u, f.v).scale(light);
            const clouds = b.clouds.?.alpha(f.u + t * 0.006, f.v) * 0.8;
            return ground.lerp(Vec3.init(light, light, light), clouds);
        },
        // cada banda (latitud) se mueve a su propia velocidad
        .zephyr => {
            const speed = 0.012 * @sin(f.v * std.math.pi * 9.0) + 0.004;
            return b.texture.rgb(f.u + t * speed, f.v).scale(light);
        },
        // borde brillante (fresnel) que late
        .glacia => {
            const view = cam.sub(f.pos).normalize();
            const rim = std.math.pow(f32, 1.0 - @max(n.dot(view), 0.0), 3.0);
            const glow = rim * (0.7 + 0.3 * @sin(t * 2.0));
            return b.texture.rgb(f.u, f.v).scale(light).add(Vec3.init(0.4, 0.85, 1.0).scale(glow));
        },
    }
}
