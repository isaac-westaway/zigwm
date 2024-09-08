// ! Well you can fix the Config.zig compile error for line 16 by removing all error return types

/// Under run method, copied and pasted from juicebox
const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");
const ZWM = @import("ZWM.zig");

const log = std.log.scoped(.ZWM_actions);

// pub fn switchWorkspace(manager: *ZWM, arg: u4) void {
//     var layout = manager.layout_manager;
//     if (arg >= layout.workspaces.len) {
//         log.notice(
//             "arg for action [switchWorkspace] is too big. Only {d} workspaces exist",
//             .{layout.workspaces.len},
//         );
//         return;
//     }

//     try layout.switchTo(arg);
// }

// pub fn closeWindow(manager: *ZWM, arg: u4) void {
//     _ = arg;
//     if (manager.layout_manager.active().focused) |focused| {
//         // this will trigger a destroy_notify so layout manager will handle the rest
//         try focused.close();
//     }
// }

// pub fn moveWindow(manager: *ZWM, arg: u4) void {
//     var layout = manager.layout_manager;
//     if (arg >= layout.workspaces.len) {
//         log.notice(
//             "arg for action [switchWorkspace] is too big. Only {d} workspaces exist",
//             .{layout.workspaces.len},
//         );
//         return;
//     }

//     // if a window is focused, move it to the given workspace
//     if (layout.active().focused) |focused_window| try layout.moveWindow(focused_window, arg);
// }

// pub fn toggleFullscreen(manager: *ZWM, arg: u4) void {
//     _ = arg;
//     try manager.layout_manager.toggleFullscreen();
// }

// pub fn swapWindow(manager: *ZWM, comptime arg: @Type(.EnumLiteral)) !void {
//     switch (arg) {
//         .left, .right, .up, .down => try manager.layout_manager.swapWindow(arg),
//         else => return error.InvalidEnum,
//     }
// }

// pub fn swapFocus(manager: *ZWM, comptime arg: @Type(.EnumLiteral)) !void {
//     switch (arg) {
//         .left, .right, .up, .down => try manager.layout_manager.swapFocus(arg),
//         else => return error.InvalidEnum,
//     }
// }

// pub fn pinFocus(manager: *ZWM) !void {
//     try manager.layout_manager.pinFocus();
// }
