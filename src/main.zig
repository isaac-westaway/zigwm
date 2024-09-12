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

    const logfile: std.fs.File = try std.fs.cwd().createFile("zigwm.log", .{ .read = true });
    defer logfile.close();

    const message = "MAIN: Initializing Startup Process\n";
    const time = try std.fmt.allocPrint(allocator, "{d} ", .{std.time.timestamp()});
    const combine: [2][]const u8 = [_][]const u8{ time, message };

    const combined = try std.mem.concat(allocator, u8, &combine);
    _ = try logfile.write(combined);

    // TODO: error handling
    const zwm: ZWM = try ZWM.init(@constCast(&allocator), arena_allocator, logfile);
    defer zwm.close();

    _ = try logfile.write("MAIN: Completed zwm initialization method\n");

    _ = try logfile.write("Running WIndow Manager\n");
    try zwm.run();
}
