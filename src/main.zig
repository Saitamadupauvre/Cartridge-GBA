const std = @import("std");
const cli = @import("cli/root.zig");

pub fn main(init: std.process.Init) !void {
    var safe: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{});
    defer {
        const leaks = safe.deinit();
        if (leaks != 0) {
            std.debug.print("Warning: memory allocator leak\n", .{});
        }
    }

    const allocator = safe.allocator();

    try cli.parseAndRun(init, allocator);
}
