const std = @import("std");
const gl = @import("gl");
const glUtil = @import("./gl_util.zig");
const math = @import("zigmath");
const Mat4f = math.Mat4(f32);

const Vertex = extern struct {
    x: f32,
    y: f32,
    u: f32,
    v: f32,
};

const Bounds = struct {
    left: f32,
    right: f32,
    top: f32,
    bottom: f32,
};

const GlyphInfo = struct {
    unicode: u64,
    advance: f64,
    atlasBounds: Bounds,
    planeBounds: Bounds,
};

const AtlasType = enum {
    msdf,
};

const AtlasMetrics = struct {
    lineHeight: f32,
    ascender: f32,
    descender: f32,
    underlineY: f32,
    underlineThickness: f32,
};

const AtlasGlyph = struct {
    unicode: u32,
    advance: f32,
    planeBounds: ?Bounds = null,
    atlasBounds: ?Bounds = null,
};

const AtlasDescription = struct {
    @"type": []const u8, // AtlasType,
    distanceRange: f32,
    size: f32,
    width: u64,
    height: u64,
    yOrigin: []const u8,
};

const AtlasFile = struct {
    atlas: AtlasDescription,
    metrics: AtlasMetrics,
    glyphs: []AtlasGlyph,
    kerning: []const u8,
};

fn atlasParse(allocator: *std.mem.Allocator, path: []const u8) !AtlasFile {
    const cwd = std.fs.cwd();
    const atlas_contents = try cwd.readFileAlloc(allocator, path, 50000);
    defer allocator.free(atlas_contents);

    var tokenStream = std.json.TokenStream.init(atlas_contents);

    const jsonOpt = .{
        .allocator = allocator,
    };
    var atlasFile = try std.json.parse(AtlasFile, &tokenStream, jsonOpt);
    // defer std.json.parseFree(AtlasFile, atlasFile, jsonOpt);

    return atlasFile;
}

pub const TextRender = struct {
    program: gl.GLuint,
    vertex_array_object: gl.GLuint,
    vertex_buffer_object: gl.GLuint,
    font_texture: gl.GLuint,
    atlas_file: AtlasFile,
    projectionMatrixUniform: gl.GLint,
    // modelMatrixUniform: gl.GLint,

    /// Font should be the name of the font texture and csv minus their extensions
    pub fn init(allocator: *std.mem.Allocator, fontPath: []const u8) !@This() {
        const program = try glUtil.compileShader(
            allocator,
            @embedFile("text.vert"),
            @embedFile("text.frag"),
        );

        const texturePath = try std.fmt.allocPrint(allocator, "{}.png", .{fontPath});
        defer allocator.free(texturePath);
        const atlasPath = try std.fmt.allocPrint(allocator, "{}.json", .{fontPath});
        defer allocator.free(atlasPath);
        const atlas_file = try atlasParse(allocator, atlasPath);

        var vbo: gl.GLuint = 0;
        gl.genBuffers(1, &vbo);
        if (vbo == 0)
            return error.OpenGlFailure;

        {
            const width = @intToFloat(f32, atlas_file.atlas.width);
            const height = @intToFloat(f32, atlas_file.atlas.height);
            var bounds = Bounds{
                .left = 0,
                .right = 1,
                .top = 0,
                .bottom = 1,
            };
            if (atlas_file.glyphs[1].atlasBounds) |atlasBounds| {
                bounds = atlasBounds;
                bounds.left = bounds.left / width;
                bounds.right = bounds.right / width;
                bounds.top = 1 - (bounds.top / height);
                bounds.bottom = 1 - (bounds.bottom / height);
            }
            var plane = Bounds{
                .left = 0,
                .right = 1,
                .top = 0,
                .bottom = 1,
            };
            if (atlas_file.glyphs[1].planeBounds) |planeBounds| {
                plane = planeBounds;
                const size = atlas_file.atlas.size;
                plane.left = plane.left * size;
                plane.right = plane.right * size;
                plane.top = 720 - (plane.top * size);
                plane.bottom = 720 - (plane.bottom * size);
            }
            const vertices = [_]Vertex{
                Vertex{ // top left
                    .x = plane.left,
                    .y = plane.top,
                    .u = bounds.left,
                    .v = bounds.top,
                },
                Vertex{ // bot left
                    .x = plane.left,
                    .y = plane.bottom,
                    .u = bounds.left,
                    .v = bounds.bottom,
                },
                Vertex{ // top right
                    .x = plane.right,
                    .y = plane.top,
                    .u = bounds.right,
                    .v = bounds.top,
                },
                Vertex{ // bot left
                    .x = plane.left,
                    .y = plane.bottom,
                    .u = bounds.left,
                    .v = bounds.bottom,
                },
                Vertex{ // top right
                    .x = plane.right,
                    .y = plane.top,
                    .u = bounds.right,
                    .v = bounds.top,
                },
                Vertex{ // bot right
                    .x = plane.right,
                    .y = plane.bottom,
                    .u = bounds.right,
                    .v = bounds.bottom,
                },
            };

            gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
            gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(Vertex), &vertices, gl.STATIC_DRAW);
            gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        }

        var vao: gl.GLuint = 0;
        gl.genVertexArrays(1, &vao);
        if (vao == 0)
            return error.OpenGlFailure;

        gl.bindVertexArray(vao);

        gl.enableVertexAttribArray(0); // Position attribute
        gl.enableVertexAttribArray(1); // UV attribute

        gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "x")));
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "u")));
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);

        const projection = gl.getUniformLocation(program, "mvp");
        // const model = gl.getUniformLocation(program, "model");

        return @This(){
            .program = program,
            .vertex_array_object = vao,
            .vertex_buffer_object = vbo,
            .font_texture = try glUtil.loadTexture(allocator, texturePath),
            .atlas_file = atlas_file,
            .projectionMatrixUniform = projection,
            // .modelMatrixUniform = model,
        };
    }

    pub fn deinit(this: @This()) void {
        gl.deleteProgram(this.program);
        gl.deleteVertexArrays(1, &this.vertex_array_object);
        gl.deleteBuffers(1, &this.vertex_buffer_object);
    }

    pub fn render(this: @This()) void {
        gl.useProgram(this.program);

        gl.bindTexture(gl.TEXTURE_2D, this.font_texture);

        const perspective = Mat4f.orthographic(0, 1280, 720, 0, -1, 1);
        // const perspective = Mat4f.orthoScreen(1280, 720);
        gl.uniformMatrix4fv(this.projectionMatrixUniform, 1, gl.FALSE, &perspective.v);
        // gl.uniformMatrix4fv(this.modelMatrixUniform, 1, gl.FALSE, &math.Mat4(f32).ident().v);

        gl.bindVertexArray(this.vertex_array_object);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
    }
};
