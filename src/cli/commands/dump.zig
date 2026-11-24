const std = @import("std");
const clap = @import("clap");
const args = @import("../args.zig");
const parse = @import("../parse.zig").parse;
const help = @import("../help.zig");
const core = @import("core");

pub fn parseAndRun(init: std.process.Init, allocator: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
    var res = try parse(clap.Help, &args.dump_params, clap.parsers.default, init, allocator, iter, null);
    defer res.deinit();

    try run(init, .{ .help = res.args.help != 0 }, res.positionals[0]);
}

pub fn run(init: std.process.Init, options: args.DumpOptions, positionals: []const []const u8) !void {
    if (options.help) {
        try help.print(init, clap.Help, &args.dump_params, "cartridge-gba hdr dump", "dump / display cartridge header information");
        return;
    }

    if (positionals.len == 0) {
        std.debug.print("Error: no GBA file given.\n", .{});
        return;
    }

    const cwd: std.Io.Dir = std.Io.Dir.cwd();
    for (positionals) |file_path| {
        const file = cwd.openFile(init.io, file_path, .{}) catch |err| {
            std.debug.print("Error: could not open '{s}': {s}\n", .{ file_path, @errorName(err) });
            continue;
        };
        defer file.close(init.io);

        var content: [192]u8 = undefined;
        const read = try file.readPositionalAll(init.io, &content, 0);
        if (read != content.len) {
            std.debug.print("Error: '{s}' is too small to contain a GBA header.\n", .{file_path});
            continue;
        }
        
        const header = core.Header.parse(&content);
        printHeader(file_path, &header, &content);
    }
}

fn validStr(valid: bool) []const u8 {
    return if (valid) "valid" else "invalid";
}

fn printHeader(file_path: []const u8, header: *const core.Header, content: *const [192]u8) void {
    std.debug.print("{s}:\n", .{file_path});

    std.debug.print("├── entry\n", .{});
    std.debug.print("│   ├── valid: {s}\n", .{validStr(header.entryValid())});
    std.debug.print("│   ├── raw: 0x{x:0>8}\n", .{header.entryRaw()});
    if (header.entryOpcode()) |opcode| {
        std.debug.print("│   └── opcode: b 0x{x}\n", .{opcode.target});
    } else {
        std.debug.print("│   └── opcode: ??\n", .{});
    }

    std.debug.print("├── nintendo logo: {s}\n", .{validStr(header.logoValid())});
    std.debug.print("├── game title: {s}\n", .{header.game_title});

    std.debug.print("├── game code:\n", .{});
    std.debug.print("│   ├── code: {s}\n", .{header.game_code});
    std.debug.print("│   └── region: {s}\n", .{header.gameRegion()});

    std.debug.print("├── maker code:\n", .{});
    std.debug.print("│   ├── id: {s}\n", .{header.maker_code});
    std.debug.print("│   └── developer: {s}\n", .{header.makerName()});

    std.debug.print("├── fixed value: {s} ({x:0>2}h)\n", .{ validStr(header.fixedValueValid()), header.fixed_value });
    std.debug.print("├── unit code: {x:0>2}h\n", .{header.main_unit_code});
    std.debug.print("├── device type: {x:0>2}h\n", .{header.device_type});
    std.debug.print("├── reserved: {s}\n", .{validStr(header.reservedValid())});
    std.debug.print("├── software version: {x:0>2}h\n", .{header.software_version});

    std.debug.print("└── checksum:\n", .{});
    std.debug.print("    ├── valid: {s}\n", .{validStr(header.checksumValid(content))});
    std.debug.print("    ├── rom: {x:0>2}\n", .{header.complement_check});
    std.debug.print("    └── our: {x:0>2}\n", .{core.Header.computeChecksum(content)});
}
