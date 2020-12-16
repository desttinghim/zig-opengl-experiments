const std = @import("std");
const gl = @import("gl");
const glUtil = @import("./gl_util.zig");

const Vertex = extern struct {
    x: f32,
    y: f32,
    u: f32,
    v: f32,
};

pub const TriangleRender = struct {
    shader_program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,

    pub fn init(allocator: *std.mem.Allocator) !@This() {
        const triangle_program = try glUtil.compileShader(
            allocator,
            @embedFile("triangle.vert"),
            @embedFile("triangle.frag"),
        );

        // create the vertex buffer
        var vertex_buffer: gl.GLuint = 0;
        gl.genBuffers(1, &vertex_buffer);
        if (vertex_buffer == 0)
            return error.OpenGlFailure;

        {
            const vertices = [_]Vertex{
                Vertex{ // top
                    .x = 0,
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
                Vertex{ // bot right
                    .x = 0.5,
                    .y = -0.5,
                    .u = 1,
                    .v = 1,
                },
            };

            gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
            gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
            gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        }

        // Create a vertex array that describes the vertex buffer layout
        var vao: gl.GLuint = 0;
        gl.genVertexArrays(1, &vao);
        if (vao == 0)
            return error.OpenGlFailure;

        gl.bindVertexArray(vao);

        gl.enableVertexAttribArray(0); // Position attribute
        gl.enableVertexAttribArray(1); // UV attributte

        gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "x")));
        gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "u")));
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);

        return @This(){
            .shader_program = triangle_program,
            .vao = vao,
            .vbo = vertex_buffer,
        };
    }

    pub fn deinit(this: @This()) void {
        gl.deleteProgram(this.shader_program);
        gl.deleteVertexArrays(1, &this.vao);
        gl.deleteBuffers(1, &this.vbo);
    }

    pub fn render(this: @This()) void {
        gl.useProgram(this.shader_program);
        gl.bindVertexArray(this.vao);

        gl.drawArrays(gl.TRIANGLES, 0, 3);
    }
};
