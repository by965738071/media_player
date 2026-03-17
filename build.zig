const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const core = b.addLibrary(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/core/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .name = "core",
    });

    const media = b.addLibrary(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/media/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .name = "media",
    });

    media.root_module.addImport("core", core.root_module);

    const ffmpeg_dep = b.dependency("ffmpeg", .{});
    media.root_module.addImport("ffmpeg", ffmpeg_dep.artifact("ffmpeg").root_module);
    media.root_module.addImport("ffmpeg", ffmpeg_dep.module("av"));

    // media.root_module.linkSystemLibrary("avformat", .{});
    // media.root_module.linkSystemLibrary("avcodec", .{});
    // media.root_module.linkSystemLibrary("avutil", .{});

    const platform = b.addLibrary(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/platform/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .name = "platform",
    });

    const sdl3 = b.dependency("sdl3", .{});

    platform.root_module.addImport("sdl3", sdl3.module("sdl3"));

    const mod = b.addModule("media_player", .{
        .root_source_file = b.path("src/root.zig"),

        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "media_player",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),

            .target = target,
            .optimize = optimize,

            .imports = &.{
                .{ .name = "media_player", .module = mod },
            },
        }),
    });
    exe.root_module.addImport("core", core.root_module);
    exe.root_module.addImport("platform", platform.root_module);
    exe.root_module.addImport("media", media.root_module);
    exe.root_module.addImport("sdl3", sdl3.module("sdl3"));
    media.root_module.addImport("ffmpeg", ffmpeg_dep.module("av"));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    // 添加 demuxer 测试
    const demuxer_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/media/demuxer_test.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    demuxer_test.root_module.addImport("ffmpeg", ffmpeg_dep.module("av"));
    demuxer_test.root_module.addImport("core", core.root_module);

    const run_demuxer_test = b.addRunArtifact(demuxer_test);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_demuxer_test.step);
}

// 辅助函数：递归收集目录下的所有 .c 文件
fn collectCFiles(b: *std.Build, dir_path: []const u8, files: *std.ArrayList([]const u8)) !void {
    var threaded = std.Io.Threaded.init(b.allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var dir = try std.Io.Dir.openDir(std.Io.Dir.cwd(), io, dir_path, .{ .iterate = true });
    defer dir.close(io);

    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind == .file) {
            // 检查是否是 .c 文件
            if (std.mem.endsWith(u8, entry.name, ".c")) {
                const full_path = try std.fs.path.join(b.allocator, &.{ dir_path, entry.name });
                try files.append(b.allocator, full_path);
            }
        } else if (entry.kind == .directory) {
            // 递归子目录（可选）
            const sub_path = try std.fs.path.join(b.allocator, &.{ dir_path, entry.name });
            try collectCFiles(b, sub_path, files);
        }
    }
}
