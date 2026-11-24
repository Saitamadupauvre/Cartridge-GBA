const std = @import("std");
const clap = @import("clap");
const args = @import("../args.zig");
const parse = @import("../parse.zig").parse;
const help = @import("../help.zig");
const dump = @import("dump.zig");
const gen = @import("gen.zig");

pub fn parseAndRun(init: std.process.Init, allocator: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
    var res = try parse(clap.Help, &args.hdr_params, args.hdr_parsers, init, allocator, iter, 0);
    defer res.deinit();

    if (res.args.help != 0) {
        try help.print(init, clap.Help, &args.hdr_params, "cartridge-gba hdr", "Cartridge header interface");
        std.debug.print("\nCommands:\n  dump    Dump a header\n  gen     Generate a header\n", .{});
        return;
    }

    const sub = res.positionals[0] orelse {
        std.debug.print("No hdr subcommand given\n", .{});
        return;
    };

    switch (sub) {
        .dump => try dump.parseAndRun(init, allocator, iter),
        .gen => try gen.parseAndRun(init, allocator, iter),
    }
}
