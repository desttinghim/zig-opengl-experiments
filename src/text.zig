const std = @import("std");
const gl = @import("gl");
const glUtil = @import("./gl_util.zig");

const Vertex = extern struct {
    x: f32,
    y: f32,
    u: f32,
    v: f32,
};

pub const TextRender = struct {
    program: gl.GLuint,
    vertex_array_object: gl.GLuint,
    vertex_buffer_object: gl.GLuint,
    font_texture: gl.GLuint,

    pub fn init(allocator: *std.mem.Allocator, texture: gl.GLuint) !@This() {
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
                    .x = -0.5,
                    .y = 0.5,
                    .u = 0,
                    .v = 0,
                },
                Vertex{ // bot left
                    .x = -0.5,
                    .y = -0.5,
                    .u = 0,
                    .v = 1,
                },
                Vertex{ // top right
                    .x = 0.5,
                    .y = 0.5,
                    .u = 1,
                    .v = 0,
                },
                Vertex{ // bot left
                    .x = -0.5,
                    .y = -0.5,
                    .u = 0,
                    .v = 1,
                },
                Vertex{ // top right
                    .x = 0.5,
                    .y = 0.5,
                    .u = 1,
                    .v = 0,
                },
                Vertex{ // bot right
                    .x = 0.5,
                    .y = -0.5,
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

        return @This(){
            .program = program,
            .vertex_array_object = vao,
            .vertex_buffer_object = vbo,
            .font_texture = texture,
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
        gl.bindVertexArray(this.vertex_array_object);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
    }
};
