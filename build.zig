const std = @import("std");

const pkgs = struct {
    const zwl = std.build.Pkg{
        .name = "zwl",
        .path = "deps/zwl/src/zwl.zig",
    };

    const gl = std.build.Pkg{
        .name = "gl",
        .path = "deps/opengl/gl.zig",
    };
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("hello-triangle", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackage(pkgs.zwl);
    exe.addPackage(pkgs.gl);
    exe.install();

    exe.linkLibC();

    if (target.isWindows()) {
        exe.linkSystemLibrary("opengl32");
    } else {
        exe.linkLibC();
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("GL");
    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
