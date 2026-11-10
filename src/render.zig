const std = @import("std");
const Vec3 = @import("math3d.zig").Vec3;
const cam_mod = @import("camera.zig");
const Camera = cam_mod.Camera;
const fb_mod = @import("framebuffer.zig");
const Framebuffer = fb_mod.Framebuffer;
const Body = @import("planets.zig").Body;
const shaders = @import("shaders.zig");

const Vert = struct {
    world: Vec3,
    normal: Vec3,
    view: Vec3,
    u: f32,
    v: f32,
};

pub const Renderer = struct {
    fb: *Framebuffer,
    cam: *const Camera,
    buffer: []Vert,
    culling: bool = true,
    triangles: u32 = 0,
    culled: u32 = 0,
    time: f32 = 0,
    sun: Vec3 = Vec3.init(0, 0, 0),

    pub fn init(alloc: std.mem.Allocator, fb: *Framebuffer, cam: *const Camera, max_vertices: usize) !Renderer {
        return .{ .fb = fb, .cam = cam, .buffer = try alloc.alloc(Vert, max_vertices) };
    }

    pub fn drawBody(self: *Renderer, b: *const Body) void {
        // todo el cuerpo está detrás de la cámara
        if (self.cam.toView(b.pos).z < -b.radius * 1.5) return;

        // vertex shader: girar la esfera, escalarla y moverla a su lugar
        const c = @cos(b.spin);
        const s = @sin(b.spin);
        for (b.mesh.vertices, 0..) |vert, i| {
            const normal = Vec3.init(vert.pos.x * c - vert.pos.z * s, vert.pos.y, vert.pos.x * s + vert.pos.z * c);
            const world = normal.scale(b.radius).add(b.pos);
            self.buffer[i] = .{ .world = world, .normal = normal, .view = self.cam.toView(world), .u = vert.u, .v = vert.v };
        }

        for (b.mesh.triangles) |t| {
            self.triangles += 1;
            const v0 = self.buffer[t[0]];
            const v1 = self.buffer[t[1]];
            const v2 = self.buffer[t[2]];

            // back-face culling: si la normal del triángulo no apunta hacia la cámara, no se dibuja
            if (self.culling) {
                const n = v1.world.sub(v0.world).cross(v2.world.sub(v0.world));
                if (n.dot(self.cam.pos.sub(v0.world)) <= 0) {
                    self.culled += 1;
                    continue;
                }
            }

            // sin recorte: los triángulos con un vértice detrás de la cámara se saltan.
            // Las colisiones no dejan acercarse tanto como para que se note.
            if (v0.view.z < cam_mod.near or v1.view.z < cam_mod.near or v2.view.z < cam_mod.near) continue;

            self.rasterize(b, v0, v1, v2);
        }
    }

    fn rasterize(self: *Renderer, b: *const Body, v0: Vert, v1_in: Vert, v2_in: Vert) void {
        var v1 = v1_in;
        var v2 = v2_in;
        const p0 = self.cam.project(v0.view);
        var p1 = self.cam.project(v1.view);
        var p2 = self.cam.project(v2.view);

        var area = edge(p0, p1, p2);
        if (area == 0) return;
        if (area < 0) { // vértices en el otro orden
            std.mem.swap(Vert, &v1, &v2);
            std.mem.swap([2]f32, &p1, &p2);
            area = -area;
        }

        // rectángulo que encierra al triángulo, recortado a la pantalla
        const w: f32 = @floatFromInt(self.fb.width);
        const h: f32 = @floatFromInt(self.fb.height);
        const min_x = @max(@floor(@min(p0[0], p1[0], p2[0])), 0);
        const max_x = @min(@ceil(@max(p0[0], p1[0], p2[0])), w - 1);
        const min_y = @max(@floor(@min(p0[1], p1[1], p2[1])), 0);
        const max_y = @min(@ceil(@max(p0[1], p1[1], p2[1])), h - 1);
        if (min_x > max_x or min_y > max_y) return;

        var y: usize = @intFromFloat(min_y);
        while (y <= @as(usize, @intFromFloat(max_y))) : (y += 1) {
            var x: usize = @intFromFloat(min_x);
            while (x <= @as(usize, @intFromFloat(max_x))) : (x += 1) {
                const p = [2]f32{ @as(f32, @floatFromInt(x)) + 0.5, @as(f32, @floatFromInt(y)) + 0.5 };

                const w0 = edge(p1, p2, p) / area;
                const w1 = edge(p2, p0, p) / area;
                const w2 = edge(p0, p1, p) / area;
                if (w0 < 0 or w1 < 0 or w2 < 0) continue;

                // perspectiva: se interpola 1/z y cada atributo dividido entre z
                const k0 = w0 / v0.view.z;
                const k1 = w1 / v1.view.z;
                const k2 = w2 / v2.view.z;
                const z = 1.0 / (k0 + k1 + k2);

                const idx = y * self.fb.width + x;
                if (z >= self.fb.depth[idx]) continue; // z-buffer
                self.fb.depth[idx] = z;

                const frag: shaders.Frag = .{
                    .u = (k0 * v0.u + k1 * v1.u + k2 * v2.u) * z,
                    .v = (k0 * v0.v + k1 * v1.v + k2 * v2.v) * z,
                    .normal = mix(v0.normal, v1.normal, v2.normal, k0, k1, k2, z),
                    .pos = mix(v0.world, v1.world, v2.world, k0, k1, k2, z),
                };
                const color = shaders.shade(b, frag, self.sun, self.cam.pos, self.time);
                self.fb.color[idx] = fb_mod.toColor(color.x, color.y, color.z);
            }
        }
    }
};

fn edge(a: [2]f32, b: [2]f32, p: [2]f32) f32 {
    return (p[0] - a[0]) * (b[1] - a[1]) - (p[1] - a[1]) * (b[0] - a[0]);
}

fn mix(a: Vec3, b: Vec3, c: Vec3, k0: f32, k1: f32, k2: f32, z: f32) Vec3 {
    return a.scale(k0).add(b.scale(k1)).add(c.scale(k2)).scale(z);
}
