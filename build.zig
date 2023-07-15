const std = @import("std");
const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const tests = b.option(bool, "Tests", "Build tests [default: false]") orelse false;

    const boost = boostLibraries(b);
    const lib = b.addStaticLibrary(.{
        .name = "unordered",
        .target = target,
        .optimize = optimize,
    });
    lib.addIncludePath("include");
    for (boost.include_dirs.items) |include| {
        lib.include_dirs.append(include) catch {};
    }
    // zig-pkg bypass for header-only
    lib.addCSourceFile("test/empty.cc", cxxFlags);

    if (target.getAbi() == .msvc)
        lib.linkLibC()
    else
        lib.linkLibCpp();
    lib.installHeadersDirectory("include", "");
    lib.step.dependOn(&boost.step);

    if (tests) {
        buildTest(b, .{
            .path = "examples/case_insensitive_test.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/string.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/string_view.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/uuid.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/uint32.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/uint64.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/word_size.cpp",
            .lib = lib,
        });
        buildTest(b, .{
            .path = "benchmark/word_count.cpp",
            .lib = lib,
        });
    }
}

const cxxFlags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-std=c++20",
};

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.lib.optimize,
        .target = info.lib.target,
    });
    for (info.lib.include_dirs.items) |include| {
        test_exe.include_dirs.append(include) catch {};
    }
    test_exe.step.dependOn(&info.lib.step);
    test_exe.addIncludePath("test");
    test_exe.addIncludePath("examples");
    test_exe.addCSourceFile(info.path, cxxFlags);
    // test_exe.linkLibrary(info.lib);
    if (test_exe.target.getAbi() == .msvc)
        test_exe.linkLibC()
    else
        test_exe.linkLibCpp();
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("{s}", .{info.filename()}),
        b.fmt("Run the {s} test", .{info.filename()}),
    );
    run_step.dependOn(&run_cmd.step);
}

const BuildInfo = struct {
    lib: *std.Build.Step.Compile,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.split(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};

fn boostLibraries(b: *std.Build) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "boost",
        .target = .{},
        .optimize = .ReleaseFast,
    });

    const boostCore = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/core.git",
        .branch = "develop",
        .sha = "216999e552e7f73e63c7bcc88b8ce9c179bbdbe2",
        .fetch_enabled = true,
    });
    const boostAlg = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/algorithm.git",
        .branch = "develop",
        .sha = "faac048d59948b1990c0a8772a050d8e47279343",
        .fetch_enabled = true,
    });
    const boostConfig = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/config.git",
        .branch = "develop",
        .sha = "a1cf5d531405e62927b0257b5cbecc66a545b508",
        .fetch_enabled = true,
    });
    const boostAssert = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/assert.git",
        .branch = "develop",
        .sha = "02256c84fd0cd58a139d9dc1b25b5019ca976ada",
        .fetch_enabled = true,
    });
    const boostTraits = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/type_traits.git",
        .branch = "develop",
        .sha = "1ebd31e60eab91bd8bdc586d8df00586ecfb53e4",
        .fetch_enabled = true,
    });
    const boostMP11 = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/mp11.git",
        .branch = "develop",
        .sha = "ef7608b463298b881bc82eae4f45a4385ed74fca",
        .fetch_enabled = true,
    });
    const boostRange = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/range.git",
        .branch = "develop",
        .sha = "3920ef2e7ad91354224010ea27f9e0c8116ffe7d",
        .fetch_enabled = true,
    });
    const boostFunctional = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/functional.git",
        .branch = "develop",
        .sha = "6a573e4b8333ee63ee62ce95558c3667348db233",
        .fetch_enabled = true,
    });
    const boostPreprocessor = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/preprocessor.git",
        .branch = "develop",
        .sha = "667e87b3392db338a919cbe0213979713aca52e3",
        .fetch_enabled = true,
    });
    const boostHash = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/container_hash.git",
        .branch = "develop",
        .sha = "226eb066e949adbf37b220e993d64ecefeeaae99",
        .fetch_enabled = true,
    });
    const boostDescribe = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/describe.git",
        .branch = "develop",
        .sha = "a0eafb08100eb15a57b6dae6d270c0012a56aa21",
        .fetch_enabled = true,
    });
    const boostMpl = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/mpl.git",
        .branch = "develop",
        .sha = "b440c45c2810acbddc917db057f2e5194da1a199",
        .fetch_enabled = true,
    });
    const boostIterator = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/iterator.git",
        .branch = "develop",
        .sha = "80bb1ac9e401d0d679718e29bef2f2aaf0123fcb",
        .fetch_enabled = true,
    });
    const boostStaticAssert = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/static_assert.git",
        .branch = "develop",
        .sha = "45eec41c293bc5cd36ec3ed83671f70bc1aadc9f",
        .fetch_enabled = true,
    });
    const boostMove = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/move.git",
        .branch = "develop",
        .sha = "60f782350aa7c64e06ac6d2a6914ff6f6ff35ce1",
        .fetch_enabled = true,
    });
    const boostDetail = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/detail.git",
        .branch = "develop",
        .sha = "b75c261492862448cdc5e1c0d5900203497122d6",
        .fetch_enabled = true,
    });
    const boostThrow = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/throw_exception.git",
        .branch = "develop",
        .sha = "23dd41e920ecd91237500ac6428f7d392a7a875c",
        .fetch_enabled = true,
    });
    const boostTuple = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/tuple.git",
        .branch = "develop",
        .sha = "453e061434be75ddd9e4bc578114a4ad9ce0f706",
        .fetch_enabled = true,
    });
    const boostPredef = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/predef.git",
        .branch = "develop",
        .sha = "e508ed842c153b5dd4858e2cdafd58d2ede418d4",
        .fetch_enabled = true,
    });
    const boostCCheck = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/concept_check.git",
        .branch = "develop",
        .sha = "37c9bddf0bdefaaae0ca5852c1a153d9fc43f278",
        .fetch_enabled = true,
    });
    const boostUtil = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/utility.git",
        .branch = "develop",
        .sha = "eb721609af5ba8eea53e405ae6d901718866605f",
        .fetch_enabled = true,
    });
    const boostEndian = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/endian.git",
        .branch = "develop",
        .sha = "56bd7c23aeafe6410b73d2ca69684611eb69eec2",
        .fetch_enabled = true,
    });
    const boostRegex = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/regex.git",
        .branch = "develop",
        .sha = "237e69caf65906d0313c9b852541b07fa84a99c1",
        .fetch_enabled = true,
    });
    lib.addCSourceFile("test/empty.cc", cxxFlags);
    lib.addIncludePath(b.pathJoin(&.{ boostCore.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostAlg.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostConfig.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostAssert.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostFunctional.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostMP11.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostTraits.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostRange.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostPreprocessor.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostHash.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostDescribe.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostMpl.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostStaticAssert.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostIterator.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostMove.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostDetail.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostThrow.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostTuple.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostPredef.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostCCheck.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostUtil.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostRegex.path, "include/" }));
    lib.addIncludePath(b.pathJoin(&.{ boostEndian.path, "include/" }));

    lib.step.dependOn(&boostCore.step);
    boostCore.step.dependOn(&boostTraits.step);
    boostCore.step.dependOn(&boostAssert.step);
    boostCore.step.dependOn(&boostMP11.step);
    boostCore.step.dependOn(&boostAlg.step);
    boostCore.step.dependOn(&boostConfig.step);
    boostCore.step.dependOn(&boostFunctional.step);
    boostCore.step.dependOn(&boostRange.step);
    boostCore.step.dependOn(&boostPreprocessor.step);
    boostCore.step.dependOn(&boostHash.step);
    boostCore.step.dependOn(&boostDescribe.step);
    boostCore.step.dependOn(&boostMpl.step);
    boostCore.step.dependOn(&boostIterator.step);
    boostCore.step.dependOn(&boostStaticAssert.step);
    boostCore.step.dependOn(&boostMove.step);
    boostCore.step.dependOn(&boostDetail.step);
    boostCore.step.dependOn(&boostThrow.step);
    boostCore.step.dependOn(&boostTuple.step);
    boostCore.step.dependOn(&boostPredef.step);
    boostCore.step.dependOn(&boostCCheck.step);
    boostCore.step.dependOn(&boostUtil.step);
    boostCore.step.dependOn(&boostRegex.step);
    boostCore.step.dependOn(&boostEndian.step);
    return lib;
}
