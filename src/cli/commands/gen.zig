const std = @import("std");
const clap = @import("clap");
const args = @import("../args.zig");
const parse = @import("../parse.zig").parse;
const help = @import("../help.zig");
const core = @import("core");

pub fn parseAndRun(init: std.process.Init, allocator: std.mem.Allocator, iter: *std.process.Args.Iterator) !void {
    var res = try parse(clap.Help, &args.gen_params, clap.parsers.default, init, allocator, iter, null);
    defer res.deinit();

    try run(init, allocator, .{
        .help = res.args.help != 0,
        .binary = res.args.binary,
        .output = res.args.output,
        .name = res.args.name,
    });
}

fn makeTitle(name: ?[]const u8) ![12]u8 {
    const src = name orelse "game";
    if (src.len > 12) return error.NameTooLong;

    var title: [12]u8 = @splat(0);
    @memcpy(title[0..src.len], src);
    return title;
}

pub fn run(init: std.process.Init, allocator: std.mem.Allocator, options: args.GenOptions) !void {
    if (options.help) {
        try help.print(init, clap.Help, &args.gen_params, "cartridge-gba hdr gen", "header generation");
        return;
    }

    const binary_path = options.binary orelse {
        std.debug.print("Error: --binary is required.\n", .{});
        return;
    };
    const output_path = options.output orelse {
        std.debug.print("Error: --output is required.\n", .{});
        return;
    };

    const title = makeTitle(options.name) catch {
        std.debug.print("Error: \"{s}\" exceeds 12 bytes size\n", .{options.name.?});
        return;
    };

    var header: core.Header = .{
        .entry_point = .{ 0x2e, 0x00, 0x00, 0xea }, // b 0xc0
        .nintendo_logo = core.nintendo_logo,
        .game_title = title,
        .game_code = "AA2E".*,
        .maker_code = "01".*,
        .fixed_value = 0x96,
        .main_unit_code = 0,
        .device_type = 0,
        .reserved = @splat(0),
        .software_version = 0,
        .complement_check = 0,
        .checksum_reserved = @splat(0),
    };

    const header_bytes: *[192]u8 = @ptrCast(&header);
    header.complement_check = core.Header.computeChecksum(header_bytes);

    const cwd: std.Io.Dir = std.Io.Dir.cwd();

    const binary_file = cwd.openFile(init.io, binary_path, .{}) catch |err| {
        std.debug.print("Error: could not open '{s}': {s}\n", .{ binary_path, @errorName(err) });
        return;
    };
    defer binary_file.close(init.io);

    const binary_stat = try binary_file.stat(init.io);
    const binary_contents = try allocator.alloc(u8, binary_stat.size);
    defer allocator.free(binary_contents);
    const read = try binary_file.readPositionalAll(init.io, binary_contents, 0);
    if (read != binary_contents.len) {
        std.debug.print("Error: failed to read '{s}' fully.\n", .{binary_path});
        return;
    }

    const output_file = cwd.createFile(init.io, output_path, .{}) catch |err| {
        std.debug.print("Error: could not create '{s}': {s}\n", .{ output_path, @errorName(err) });
        return;
    };
    defer output_file.close(init.io);

    try output_file.writePositionalAll(init.io, header_bytes, 0);
    try output_file.writePositionalAll(init.io, binary_contents, header_bytes.len);

    std.debug.print("{s}: header written ({d} bytes total)\n", .{ output_path, header_bytes.len + binary_contents.len });
}
