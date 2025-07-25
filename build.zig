const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = std.builtin.OptimizeMode.Debug;

    const exe = b.addExecutable(.{
        .name = "zigDOOM",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const install_exe = b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{ .custom = "" } } });
    const install_wad = b.addInstallFile(b.path("DOOM.WAD"), "DOOM.WAD");

    b.default_step.dependOn(&install_exe.step);
    b.default_step.dependOn(&install_wad.step);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.default_step);

    if (b.args) |args| run_exe.addArgs(args);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
