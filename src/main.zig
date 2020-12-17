const std = @import("std");
const zwl = @import("zwl");
const gl = @import("gl");
const math = @import("zigmath");
const Vec2f = math.Vec(2, f32);
const vec2f = Vec2f.init;
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

    var text = try TextRender.init(global_allocator, "assets/adobe-source-code-pro");
    try text.setText(vec2f(10, 10), vec2f(640, 480), "Hello, World! I am typing a bunch to see what happens");
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
