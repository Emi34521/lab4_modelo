const rl = @import("raylib");

pub const Framebuffer = struct {
    width: i32,
    height: i32,
    color_buff: rl.Image,
    background_color: rl.Color,
    current_color: rl.Color,
    texture: ?rl.Texture = null,

    pub fn init(width: i32, height: i32, background_color: ?rl.Color, draw_color: ?rl.Color) Framebuffer {
        const bg_color = background_color orelse rl.Color.black;
        const color = draw_color orelse rl.Color.white;
        return .{
            .color_buff = rl.genImageColor(width, height, bg_color),
            .width = width,
            .height = height,
            .background_color = bg_color,
            .current_color = color,
        };
    }
    // esta función es reutilizada de mi lab 1 y, básicamente, al fibujar ignora los pixeles fuera de la
    // pantalla
    pub fn draw_line(self: *Framebuffer, x0: i32, y0: i32, x1: i32, y1: i32, color: rl.Color) void {
        var x = x0;
        var y = y0;
        const dx: i32 = @intCast(@abs(x1 - x0));
        const dy: i32 = -@as(i32, @intCast(@abs(y1 - y0)));
        const sx: i32 = if (x0 < x1) 1 else -1;
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err = dx + dy;

        while (true) {
            if (x >= 0 and y >= 0 and x < self.width and y < self.height) {
                self.color_buff.drawPixel(x, y, color);
            }
            if (x == x1 and y == y1) break;
            const e2 = 2 * err;
            if (e2 >= dy) {
                err += dy;
                x += sx;
            }
            if (e2 <= dx) {
                err += dx;
                y += sy;
            }
        }
    }

    pub fn clear(self: *Framebuffer) void {
        self.color_buff.clearBackground(self.background_color);
        if (self.texture) |texture| {
            rl.unloadTexture(texture);
        }
    }

    pub fn set_pixel(self: *Framebuffer, x: i32, y: i32, color: rl.Color) !void {
        if (x >= self.width or y >= self.height) return error.BadCoordinates;
        self.color_buff.drawPixel(x, y, color);
    }

    pub fn set_background_color(self: *Framebuffer, color: rl.Color) void {
        self.background_color = color;
    }

    pub fn set_current_color(self: *Framebuffer, color: rl.Color) void {
        self.current_color = color;
    }

    pub fn render_to_file(self: Framebuffer, filename: []const u8) !void {
        if (!self.color_buff.exportToFile(@ptrCast(filename))) return error.CouldntWriteFile;
    }

    pub fn swap_buffers(self: *Framebuffer) !void {
        rl.beginDrawing();
        defer rl.endDrawing();

        // Raylib maneja los conceptos de Image y Texture
        // En esencia son lo mismo, un buffer de color, o imagen.
        // Pero Image está en la RAM, mientras que Texture está en la VRAM.
        // (La RAM del CPU vs la del GPU)
        // Para que la GPU pueda operar sobre una imagen, esta tiene que estar en la VRAM.
        // En este caso, solo estamos cargando a la GPU la imagen que dibujamos para poder mostrarla.
        const texture = try rl.loadTextureFromImage(self.color_buff);
        rl.drawTexture(texture, 0, 0, .white);

        //Por lo general, el swap es entre 2 buffers. Uno es el que el usuario está viendo,
        //mientras que escribimos en el otro para preparar nuestro siguiente frame.
        //Cada uno de los frame buffers intercambian su rol.
        //Sobrescribir es mucho más amigable para la computadora que tener que estar malabareando la memoria
        //para crear, destruir y volver a crear buffers.

        //¡Pero como nosotros insistimos en usar el CPU para dibujar los frames, no podemos hacer eso!
        //Siempre tendremos que guardar la textura para luego poder borrarla en clean. Si no, nos quedamos sin memoria en la GPU.
        rl.drawFPS(10, 10); //dibujar fps
        self.texture = texture;
    }
};
