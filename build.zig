const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
    });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const boot_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .link_libcpp = false,
    });

    boot_module.addCSourceFile(.{
        .file = b.path("src/arch/x86/boot.S"),
        .language = .assembly,
    });

    const boot_executable = b.addExecutable(.{
        .name = "zoot_bin",
        .root_module = boot_module,
    });

    boot_executable.setLinkerScript(b.path("src/arch/x86/link.ld"));

    b.installArtifact(boot_executable);
}
