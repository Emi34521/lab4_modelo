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

    // siempre con try porque puede llegar a fallar la carga del archivo.
    const modelo = try Object.cargarArchivo(io, gpa, "src/mono.obj", 1, rl.Vector3.zero());
    defer modelo.deinit(gpa);
    if (modelo.faces.len == 0) return error.ModeloVacio;

    // agora intentaré algo "nuevo" y, en lugar de una esfera envolvente haré un cuadro envolvente
    // para esto estaré calculando los puntos más bajos y más altos de cualquier vértice del objeto
    var min_y: f32 = modelo.faces[0].a.position.y;
    var min_x: f32 = modelo.faces[0].a.position.x;
    var min_z: f32 = modelo.faces[0].a.position.z;

    var max_y: f32 = modelo.faces[0].a.position.y;
    var max_x: f32 = modelo.faces[0].a.position.x;
    var max_z: f32 = modelo.faces[0].a.position.z;

    for (modelo.faces) |cara| {
        // para ahorrarme líneas de código, hice un array para guardar los vértices y este se recorrerá
        const vertices = [_]Object.Vertice{
            cara.a,
            cara.b,
            cara.c,
        };

        // encontré esto y me lo propuso claudeIA para ahorrar tantos if's "if (p.x < min_x) {
        // min_x = p.x;}" este sería el equivalente.
        for (vertices) |vertice| {
            const p = vertice.position;

            min_x = @min(min_x, p.x);
            min_y = @min(min_y, p.y);
            min_z = @min(min_z, p.z);

            max_x = @max(max_x, p.x);
            max_y = @max(max_y, p.y);
            max_z = @max(max_z, p.z);
        }
    }
    // se arma el centro con los vértices que obtuve
    const centro_x: f32 = (min_x + max_x) / 2;
    const centro_y: f32 = (min_y + max_y) / 2;
    const centro_z: f32 = (min_z + max_z) / 2;
    // se guarda como un vector y, ahora si, se conseguirá el radio.
    // al igual que antes, se estará recorriendo otra vez el modelo y se conseguirá la distancia max
    const centro_caja = rl.Vector3.init(centro_x, centro_y, centro_z);
    var radio: f32 = 0.0;

    for (modelo.faces) |cara| {
        // vector que va hacía el centro de la caja
        const vectorA = cara.a.position.subtract(centro_caja);
        const vectorB = cara.b.position.subtract(centro_caja);
        const vectorC = cara.c.position.subtract(centro_caja);

        // distancia al cuadrado de cada vector, siempre apuntando hacía el centro
        const distanciaA = vectorA.dotProduct(vectorA);
        const distanciaB = vectorB.dotProduct(vectorB);
        const distanciaC = vectorC.dotProduct(vectorC);

        if (distanciaA > radio) {
            radio = distanciaA;
        }
        if (distanciaB > radio) {
            radio = distanciaB;
        }
        if (distanciaC > radio) {
            radio = distanciaC;
        }
    }
    // como siempre, el radio será la raíz cuadrada de la distancia mayor
    radio = std.math.sqrt(radio);

    while (!rl.windowShouldClose()) {
        defer {
            const now = Clock.now(io);
            delta = last_frame_time.durationTo(now).toMicroseconds();
            last_frame_time = now;
        }
        framebuffer.clear();

        const dt: f32 = @as(f32, @floatFromInt(delta)) / 1_000_000;
        _ = dt;

        try framebuffer.swap_buffers();
    }
}
