const std = @import("std");
const clap = @import("clap");

pub fn print(
    init: std.process.Init,
    comptime Id: type,
    params: []const clap.Param(Id),
    command: []const u8,
    about: []const u8,
) !void {
    var buf: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(init.io, &buf);
    const w = &writer.interface;

    try w.writeAll("Usage: ");
    try w.writeAll(command);
    try w.writeAll(" ");
    try clap.usage(w, Id, params);
    try w.writeAll("\n\n");
    try w.writeAll(about);
    try w.writeAll("\n\nOptions:\n");
    try clap.help(w, Id, params, .{});
    try w.flush();
}
