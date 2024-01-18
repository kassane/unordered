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
    lib.addIncludePath(.{ .path = "include" });
    for (boost.root_module.include_dirs.items) |include| {
        lib.root_module.include_dirs.append(b.allocator, include) catch {};
    }
    // zig-pkg bypass for header-only
    lib.addCSourceFile(.{ .file = .{ .path = "test/empty.cc" }, .flags = cxxFlags });

    if (lib.rootModuleTarget().abi == .msvc)
        lib.linkLibC()
    else
        lib.linkLibCpp();
    lib.installHeadersDirectory("include", "");
    lib.step.dependOn(&boost.step);
    b.installArtifact(lib);

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
        .optimize = info.lib.root_module.optimize orelse .Debug,
        .target = info.lib.root_module.resolved_target orelse b.host,
    });
    for (info.lib.root_module.include_dirs.items) |include| {
        test_exe.root_module.include_dirs.append(b.allocator, include) catch {};
    }
    test_exe.step.dependOn(&info.lib.step);
    test_exe.addIncludePath(.{ .path = "test" });
    test_exe.addIncludePath(.{ .path = "examples" });
    test_exe.addCSourceFile(.{ .file = .{ .path = info.path }, .flags = cxxFlags });
    // test_exe.linkLibrary(info.lib);
    if (test_exe.rootModuleTarget().abi == .msvc)
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
        var split = std.mem.splitSequence(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};

fn boostLibraries(b: *std.Build) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "boost",
        .target = b.host,
        .optimize = .ReleaseFast,
    });

    const boostCore = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/core.git",
        .branch = "develop",
        .sha = "ba6360e8edcc053c226e924af86996c79494c796",
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
        .sha = "ccff36321ff514de097a2c27a74235bfe6d9a115",
        .fetch_enabled = true,
    });
    const boostAssert = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/assert.git",
        .branch = "develop",
        .sha = "5227f10a99442da67415e9649be2b4d9df53b61e",
        .fetch_enabled = true,
    });
    const boostTraits = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/type_traits.git",
        .branch = "develop",
        .sha = "821c53c0b45529dca508fadc7d018fb1bb6ece21",
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
        .sha = "48a306dcf236ae460d9ba55648d449ed7bea1dee",
        .fetch_enabled = true,
    });
    const boostDescribe = GitRepoStep.create(b, .{
        .url = "https://github.com/boostorg/describe.git",
        .branch = "develop",
        .sha = "c89e4dd3db81eb4f2867b2bc965d161f51cc316c",
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
        .sha = "845567f026b6e7606b237c92aa8337a1457b672b",
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
        .sha = "614546d6fac1e68cd3511d3289736f31d5aed1eb",
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
        .sha = "a95a4f6580c65be5861cf4c40dbf9ed64a344ee6",
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
    lib.addCSourceFile(.{ .file = .{ .path = "test/empty.cc" }, .flags = cxxFlags });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostCore.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostAlg.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostConfig.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostAssert.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostFunctional.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostMP11.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostTraits.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostRange.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostPreprocessor.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostHash.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostDescribe.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostMpl.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostStaticAssert.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostIterator.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostMove.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostDetail.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostThrow.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostTuple.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostPredef.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostCCheck.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostUtil.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostRegex.path, "include/" }) });
    lib.addIncludePath(.{ .path = b.pathJoin(&.{ boostEndian.path, "include/" }) });

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
