const std = @import("std");
const zwl = @import("zwl");
const gl = @import("gl");
const zigimg = @import("zigimg");
const TriangleRender = @import("./triangle.zig").TriangleRender;
const TextRender = @import("./text.zig").TextRender;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = &gpa.allocator;

pub const WindowPlatform = zwl.Platform(.{
    .platforms_enabled = .{
        .x11 = false,
        .xlib = (std.builtin.os.tag == .linux),
        .wayland = false,
        .windows = (std.builtin.os.tag == .windows),
    },
    .backends_enabled = .{ .opengl = true },
    .single_window = true,
    .x11_use_xcb = false,
});

pub fn main() !void {
    defer _ = gpa.deinit();

    // Initialize the window platform:

    var platform = try WindowPlatform.init(global_allocator, .{});
    defer platform.deinit();

    var window = try platform.createWindow(.{
        .title = "Hello Triangle",
        .width = 1280,
        .height = 720,
        .resizeable = false,
        .track_damage = true, // workaround for a ZWL bug
        .visible = true,
        .decorations = true,
        .track_mouse = false,
        .track_keyboard = true,
        .backend = zwl.Backend{ .opengl = .{ .major = 3, .minor = 0, .core = false } },
    });
    defer window.deinit();

    // Load the OpenGL function pointers
    try gl.load(window.platform, WindowPlatform.getOpenGlProcAddress);

    // Print information about the selected OpenGL context:
    std.log.info("OpenGL Version:  {}", .{std.mem.span(gl.getString(gl.VERSION))});
    std.log.info("OpenGL Vendor:   {}", .{std.mem.span(gl.getString(gl.VENDOR))});
    std.log.info("OpenGL Renderer: {}", .{std.mem.span(gl.getString(gl.RENDERER))});

    // Initialize and triangle renderer
    // const triangle = try TriangleRender.init(global_allocator);
    // defer triangle.deinit();

    const font_texture = try loadTexture(global_allocator, "assets/adobe-source-code-pro-atlas.png");
    std.log.debug("Image loaded successfully", .{});
    const text = try TextRender.init(global_allocator, font_texture);
    defer text.deinit();

    // Run the main loop:

    main_loop: while (true) {
        const event = try platform.waitForEvent();

        const repaint = switch (event) {
            .WindowResized => |win| blk: {
                const size = win.getSize();
                gl.viewport(0, 0, size[0], size[1]);
                break :blk true;
            },

            .WindowDestroyed, .ApplicationTerminated => break :main_loop,

            .WindowDamaged, .WindowVBlank => true,

            .KeyDown => |ev| blk: {
                // this is escape
                if (ev.scancode == 1)
                    break :main_loop;
                break :blk false;
            },

            else => false,
        };

        if (repaint) {
            gl.clearColor(0.3, 0.3, 0.3, 1.0);
            gl.clear(gl.COLOR_BUFFER_BIT);

            // triangle.render();
            text.render();

            try window.present();
        }
    }

    return;
}

fn loadTexture(alloc: *std.mem.Allocator, filePath: []const u8) !gl.GLuint {
    const cwd = std.fs.cwd();
    const image_contents = try cwd.readFileAlloc(alloc, filePath, 500000);
    defer alloc.free(image_contents);

    const load_res = try zigimg.Image.fromMemory(alloc, image_contents);
    defer load_res.deinit();
    if (load_res.pixels == null) return error.ImageLoadFailed;

    var pixelData = try alloc.alloc(u8, load_res.width * load_res.height * 4);
    defer alloc.free(pixelData);

    // TODO: skip converting to RGBA and let OpenGL handle it by telling it what format it is in
    var pixelsIterator = zigimg.color.ColorStorageIterator.init(&load_res.pixels.?);

    var i: usize = 0;
    while (pixelsIterator.next()) |color| : (i += 1) {
        const integer_color = color.toIntegerColor8();
        pixelData[i * 4 + 0] = integer_color.R;
        pixelData[i * 4 + 1] = integer_color.G;
        pixelData[i * 4 + 2] = integer_color.B;
        pixelData[i * 4 + 3] = integer_color.A;
    }

    var tex: gl.GLuint = 0;
    gl.genTextures(1, &tex);
    if (tex == 0)
        return error.OpenGLFailure;

    gl.bindTexture(gl.TEXTURE_2D, tex);
    const width = @intCast(c_int, load_res.width);
    const height = @intCast(c_int, load_res.height);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, pixelData.ptr);
    gl.generateMipmap(gl.TEXTURE_2D);

    return tex;
}
