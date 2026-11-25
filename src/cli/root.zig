const std = @import("std");
const clap = @import("clap");
const args = @import("args.zig");
const parse = @import("parse.zig").parse;
const help = @import("help.zig");
const hdr = @import("commands/hdr.zig");
const build = @import("commands/build_cmd.zig");
const emu = @import("commands/emu.zig");

fn printHelp(init: std.process.Init) !void {
    try help.print(init, clap.Help, &args.main_params, "cartridge-gba", "Cartridge SDK CLI entry");
    std.debug.print("\nCommands:\n  hdr    Header-related commands\n", .{});
}

pub fn parseAndRun(init: std.process.Init, allocator: std.mem.Allocator) !void {
    var iter = try init.minimal.args.iterateAllocator(allocator);
    defer iter.deinit();
    _ = iter.next();

    var res = try parse(clap.Help, &args.main_params, args.main_parsers, init, allocator, &iter, 0);
    defer res.deinit();

    if (res.args.help != 0) {
        try printHelp(init);
        return;
    }

    const command = res.positionals[0] orelse {
        try printHelp(init);
        return;
    };

    switch (command) {
        .hdr => try hdr.parseAndRun(init, allocator, &iter),
        .build => try build.parseAndRun(init, allocator, &iter),
        .emu => try emu.parseAndRun(init, allocator, &iter),
    }
}
