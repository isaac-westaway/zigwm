//! The entry point for the Zig Window Manager

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Logger = @import("Log.zig");

const ZWM = @import("ZWM.zig").ZWM;

pub fn main() !void {
    // for top level allocation
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var heap_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    defer heap_arena_allocator.deinit();
    const arena_allocator = heap_arena_allocator.allocator();

    Logger.initializeLogging(@constCast(&allocator)) catch {
        return;
    };
    defer Logger.Log.close();

    try Logger.Log.info("MAIN", try std.fmt.allocPrint(allocator, "{d}", .{std.time.timestamp()}));
    try Logger.Log.info("MAIN", "Initializing startup process");

    // TODO: error handling
    const zwm: ZWM = try ZWM.init(@constCast(&allocator), arena_allocator);
    defer zwm.close();

    try Logger.Log.info("MAIN: ", "Completed zwm initialization method");

    try zwm.run();
}
