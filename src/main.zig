const std = @import("std");
const rl = @import("raylib");
const Vec3 = @import("math3d.zig").Vec3;
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const Texture = @import("texture.zig").Texture;
const sphere = @import("sphere.zig");
const Camera = @import("camera.zig").Camera;
const Renderer = @import("render.zig").Renderer;
const planets = @import("planets.zig");
const Body = planets.Body;
const Skybox = @import("skybox.zig").Skybox;
const Travel = @import("travel.zig").Travel;

const width = 640;
const height = 360;
const scale = 2; // ventana de 1280 x 720

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    rl.setTraceLogLevel(.warning);
    rl.initWindow(width * scale, height * scale, "Sistema Solar");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    rl.disableCursor();

    var fb = try Framebuffer.init(alloc, width, height);

    const sol = try Texture.fromPng(@embedFile("assets/sol.png"));
    const ignis = try Texture.fromPng(@embedFile("assets/ignis.png"));
    const terra = try Texture.fromPng(@embedFile("assets/terra.png"));
    const nubes = try Texture.fromPng(@embedFile("assets/nubes.png"));
    const zephyr = try Texture.fromPng(@embedFile("assets/zephyr.png"));
    const glacia = try Texture.fromPng(@embedFile("assets/glacia.png"));

    const ball = try sphere.make(alloc, 48, 24);

    var bodies = [_]Body{
        .{ .name = "Sol", .kind = .sol, .radius = 8, .mesh = &ball, .texture = &sol, .spin_speed = 0.03 },
        .{ .name = "Ignis", .kind = .ignis, .radius = 1.4, .mesh = &ball, .texture = &ignis, .orbit_radius = 20, .orbit_speed = 0.067, .orbit_phase = 0.4, .spin_speed = 0.25 },
        .{ .name = "Terra", .kind = .terra, .radius = 2.2, .mesh = &ball, .texture = &terra, .clouds = &nubes, .orbit_radius = 34, .orbit_speed = 0.03, .orbit_phase = 2.2, .spin_speed = 0.12 },
        .{ .name = "Zephyr", .kind = .zephyr, .radius = 4.5, .mesh = &ball, .texture = &zephyr, .orbit_radius = 56, .orbit_speed = 0.014, .orbit_phase = 4.0, .spin_speed = 0.2 },
        .{ .name = "Glacia", .kind = .glacia, .radius = 1.9, .mesh = &ball, .texture = &glacia, .orbit_radius = 80, .orbit_speed = 0.0084, .orbit_phase = 5.5, .spin_speed = 0.15 },
    };

    var cam: Camera = .{ .pos = Vec3.init(0, 75, -135) };
    cam.lookAt(Vec3.init(0, 0, 0));

    var renderer = try Renderer.init(alloc, &fb, &cam, ball.vertices.len);
    const sky = try Skybox.init(alloc, 3000);
    var travel: Travel = .{};
    var time: f32 = 0;
    var title: [128]u8 = undefined;

    while (!rl.windowShouldClose()) {
        const dt = @min(rl.getFrameTime(), 0.05);
        time += dt;
        planets.update(&bodies, time);

        // teclas 1..5: viaje rápido a cada cuerpo
        const keys = [_]rl.KeyboardKey{ .one, .two, .three, .four, .five };
        for (keys, 0..) |k, i| {
            if (rl.isKeyPressed(k)) travel.begin(&cam, i);
        }
        if (rl.isKeyPressed(.b)) renderer.culling = !renderer.culling;

        if (travel.active) {
            travel.update(&cam, &bodies, dt);
        } else {
            const mouse = rl.getMouseDelta();
            cam.yaw -= mouse.x * 0.0025;
            cam.pitch -= mouse.y * 0.0025;
            cam.update(width, height);

            var speed: f32 = 12;
            if (rl.isKeyDown(.left_shift)) speed *= 4;
            var move = Vec3.init(0, 0, 0);
            if (rl.isKeyDown(.w)) move = move.add(cam.forward);
            if (rl.isKeyDown(.s)) move = move.sub(cam.forward);
            if (rl.isKeyDown(.d)) move = move.add(cam.right);
            if (rl.isKeyDown(.a)) move = move.sub(cam.right);
            if (rl.isKeyDown(.space)) move = move.add(Vec3.init(0, 1, 0));
            if (rl.isKeyDown(.left_control)) move = move.sub(Vec3.init(0, 1, 0));
            cam.pos = cam.pos.add(move.normalize().scale(speed * dt));
        }
        cam.pos = planets.pushOut(&bodies, cam.pos);
        cam.update(width, height);

        // dibujar
        fb.clear(.black);
        sky.draw(&fb, &cam, travel.warp());
        renderer.time = time;
        renderer.sun = bodies[0].pos;
        renderer.triangles = 0;
        renderer.culled = 0;
        for (&bodies) |*b| renderer.drawBody(b);
        fb.present(scale);

        const text = std.fmt.bufPrintSentinel(&title, "Sistema Solar | {d} FPS | triangulos {d} | culled {d} | culling {s}", .{
            rl.getFPS(), renderer.triangles, renderer.culled, if (renderer.culling) "ON" else "OFF",
        }, 0) catch "Sistema Solar";
        rl.setWindowTitle(text);
    }
}
