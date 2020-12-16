const gl = @import("gl");

const TextRender = struct {
    program: gl.GLuint,
    vertex_array_object: gl.GLuint,
    vertex_buffer_object: gl.GLuint,
    font_texture: gl.GLuint,

    pub fn init(allocator: *std.mem.Allocator) @This() {
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
                    .x = -0.5,
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
                    .x = -0.5,
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
            gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
            gl.bindBuffer(gl.ARRAY_BUFFER, 0);

            var vao: gl.GLuint = 0;
            gl.genVertexArrays(1, &vao);
            if (vao == 0)
                return error.OpenGlFailure;

            gl.bindVertexArray(vao);

            gl.enableVertexAttribArray(0); // Position attribute
            gl.enableVertexAttribArray(1); // UV attribute

            gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
            gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "x")));
            gl.vertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), @intToPtr(?*const c_void, @byteOffsetOf(Vertex, "u")));
            gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        }
    }

    pub fn deinit(this: *@This()) void {
        // gl.delete
    }

    pub fn render(this: *@This()) void {
        // render
    }
};
