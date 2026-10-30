const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const Object = @import("Object.zig");

const Clock = std.Io.Clock.real;

const width = 1300;
const height = 900;

const block_sz: i32 = 100;
// como en el proyecto 2 ya podía cargar un modelo. Entonces simplemente cópio la lógica de dicho proyecto
// https://github.com/Emi34521/proyecto_compu2 este sería el repo y en el video explico más o menos la lógia detrás
// de todo lo que hice. Como tal estaré reutilizando la función de cargar el modelo, framebuffer (aunque podría usar raylib)
// El main si sufre cambios al eliminar la parte del raytracer y dejando solo lo básico de la ventana de raylib

pub fn main() !void {
    var alloc = switch (builtin.mode) {
        .Debug, .ReleaseSafe => std.heap.DebugAllocator(.{}).init,
        .ReleaseFast, .ReleaseSmall => std.heap.smp_allocator,
    };
    const gpa: std.mem.Allocator = switch (builtin.mode) {
        .Debug, .ReleaseSafe => alloc.allocator(),
        .ReleaseFast, .ReleaseSmall => std.heap.smp_allocator,
    };
    defer switch (builtin.mode) {
        .Debug, .ReleaseSafe => _ = alloc.deinit(),
        .ReleaseFast, .ReleaseSmall => {},
    };

    var threaded: std.Io.Threaded = .init(gpa, .{});
    const io = threaded.io();
    var framebuffer = Framebuffer.init(width, height, .black, .white);

    rl.initWindow(width, height, "Raytracer!!!");
    rl.setTraceLogLevel(.warning);
    defer rl.closeWindow();
    rl.setTargetFPS(30);

    var last_frame_time = Clock.now(io);
    var delta: i64 = 1;

    while (!rl.windowShouldClose()) {
        defer {
            const now = Clock.now(io);
            delta = last_frame_time.durationTo(now).toMicroseconds();
            last_frame_time = now;
        }
        framebuffer.clear();

        const dt: f32 = @as(f32, @floatFromInt(delta)) / 1_000_000;
        _ = dt;
        // siempre con try porque puede llegar a fallar la carga del archivo.
        const modelo = try Object.cargarArchivo(io, gpa, "src/mono.obj", 1, rl.Vector3.zero());
        defer modelo.deinit(gpa);

        try framebuffer.swap_buffers();
    }
}
