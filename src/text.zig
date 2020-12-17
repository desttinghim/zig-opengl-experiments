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
    left: f64,
    right: f64,
    top: f64,
    bottom: f64,
};

const GlyphInfo = struct {
    unicode: u64,
    advance: f64,
    atlasBounds: Bounds,
    planeBounds: Bounds,
};

pub const TextRender = struct {
    program: gl.GLuint,
    vertex_array_object: gl.GLuint,
    vertex_buffer_object: gl.GLuint,
    font_texture: gl.GLuint,
    font_info: []GlyphInfo,
    projectionMatrixUniform: gl.GLint,
    // modelMatrixUniform: gl.GLint,

    /// Font should be the name of the font texture and csv minus their extensions
    pub fn init(allocator: *std.mem.Allocator, fontPath: []const u8) !@This() {
        const program = try glUtil.compileShader(
            allocator,
            @embedFile("text.vert"),
            @embedFile("text.frag"),
        );

        var vbo: gl.GLuint = 0;
        gl.genBuffers(1, &vbo);
        if (vbo == 0)
            return error.OpenGlFailure;

        {
            const vertices = [_]Vertex{
                Vertex{ // top left
                    .x = 0,
                    .y = 0,
                    .u = 0,
                    .v = 0,
                },
                Vertex{ // bot left
                    .x = 0,
                    .y = 720,
                    .u = 0,
                    .v = 1,
                },
                Vertex{ // top right
                    .x = 1280,
                    .y = 0,
                    .u = 1,
                    .v = 0,
                },
                Vertex{ // bot left
                    .x = 0,
                    .y = 720,
                    .u = 0,
                    .v = 1,
                },
                Vertex{ // top right
                    .x = 1280,
                    .y = 0,
                    .u = 1,
                    .v = 0,
                },
                Vertex{ // bot right
                    .x = 1280,
                    .y = 720,
                    .u = 1,
                    .v = 1,
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
            .font_texture = try glUtil.loadTexture(allocator, fontPath),
            .font_info = undefined,
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
