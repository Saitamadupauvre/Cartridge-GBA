const std = @import("std");
const clap = @import("clap");
const args = @import("../args.zig");
const parse = @import("../parse.zig").parse;
const help = @import("../help.zig");

pub fn parseAndRun(init: std.process.Init, allocator: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
    var res = try parse(clap.Help, &args.hdr_params, args.hdr_parsers, init, allocator, iter, 0);
    defer res.deinit();

    if (res.args.help != 0) {
        try help.print(init, clap.Help, &args.hdr_params, "cartridge-gba build [OPTIONS]", "build abstraction");
        return;
    }

    const result = try std.process.run(
        init.gpa,
        init.io,
        .{
            .argv = &.{"make", "compile"},
        }
    );

    defer init.gpa.free(result.stdout);
    defer init.gpa.free(result.stderr);

    if (!result.term.success()) {
        std.debug.print("Command failed:\n{s}", .{result.stderr});
        return error.CommandFailed;
    }

    std.debug.print("{s}", .{result.stdout});
}
