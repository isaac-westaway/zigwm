//! The entry point for the Zig Window Manager

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const ZWM = @import("ZWM.zig").ZWM;

pub fn main() !void {
    // for top level allocation
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var heap_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    defer heap_arena_allocator.deinit();
    const arena_allocator = heap_arena_allocator.allocator();

    std.log.scoped(.main).info("Initializing startup process", .{});

    const zwm = try ZWM.init(@constCast(&allocator), arena_allocator);
    defer zwm.close();

    // ! this no longer works because the real window managing logic is yet to be implemented
    // ! the reason this worked before is becose calling this would write it directly to the root window, which is useless.
    // const argv: []const []const u8 = &[_][]const u8{
    //     "kitty",
    // };
    // const echo = try std.process.Child.run(.{ .allocator = allocator, .argv = argv });
    // _ = echo;
    // !

    while (true) {}
}
