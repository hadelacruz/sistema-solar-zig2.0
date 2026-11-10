const std = @import("std");
const Vec3 = @import("math3d.zig").Vec3;

pub const Vertex = struct {
    pos: Vec3, // en una esfera de radio 1 la posición también es la normal
    u: f32,
    v: f32,
};

pub const Mesh = struct {
    vertices: []Vertex,
    triangles: [][3]u32,
};

pub fn make(alloc: std.mem.Allocator, slices: u32, stacks: u32) !Mesh {
    const cols = slices + 1; // la columna u=1 se repite para la costura de la textura
    var verts = try alloc.alloc(Vertex, cols * (stacks + 1));
    for (0..stacks + 1) |i| {
        const v = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(stacks));
        const lat = (0.5 - v) * std.math.pi;
        for (0..cols) |j| {
            const u = @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(slices));
            const lon = u * 2.0 * std.math.pi;
            verts[i * cols + j] = .{
                .pos = Vec3.init(@cos(lat) * @cos(lon), @sin(lat), @cos(lat) * @sin(lon)),
                .u = u,
                .v = v,
            };
        }
    }

    var tris: std.ArrayList([3]u32) = .empty;
    for (0..stacks) |i| {
        for (0..slices) |j| {
            const a: u32 = @intCast(i * cols + j);
            const b = a + cols;
            const c = b + 1;
            const d = a + 1;
            // orden con la normal hacia afuera; en los polos un triángulo se degenera
            if (i != stacks - 1) try tris.append(alloc, .{ a, c, b });
            if (i != 0) try tris.append(alloc, .{ a, d, c });
        }
    }
    return .{ .vertices = verts, .triangles = try tris.toOwnedSlice(alloc) };
}
