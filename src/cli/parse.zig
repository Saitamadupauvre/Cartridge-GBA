const std = @import("std");
const clap = @import("clap");

/// Parses `iter` against `params`/`value_parsers`, reporting a diagnostic and
/// propagating the error on failure. `terminating_positional` is forwarded to
/// clap as-is; pass `null` to let clap consume the whole remaining input.
pub fn parse(
    comptime Id: type,
    comptime params: []const clap.Param(Id),
    comptime value_parsers: anytype,
    init: std.process.Init,
    allocator: std.mem.Allocator,
    iter: *std.process.Args.Iterator,
    terminating_positional: ?usize,
) !clap.ResultEx(Id, params, value_parsers) {
    var diag = clap.Diagnostic{};

    return clap.parseEx(Id, params, value_parsers, iter, .{
        .diagnostic = &diag,
        .allocator = allocator,
        .terminating_positional = terminating_positional orelse std.math.maxInt(usize),
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
}
