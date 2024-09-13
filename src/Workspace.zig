const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Types = @import("x11/types.zig");

const XWindow = @import("Window.zig").XWindow;

pub const ScreenMode = enum { tiled, fullscreen };

pub const XWorkspace = struct {
    window_list: std.ArrayListUnmanaged(XWindow),
    mode: ScreenMode,
    focused: ?XWindow,
    id: usize,
    name: ?[]const u8,

    pub fn init(self: *XWorkspace, idx: usize) XWorkspace {
        return .{
            .window_list = self.window_list,
            .mode = .tiled,
            .focused = null,
            .id = idx,
            .name = null,
        };
    }

    pub fn add(self: *XWorkspace, allocator: *std.mem.Allocator, window: XWindow) error{OutOfMemory}!void {
        std.debug.assert(!self.contains(window.handle));

        (try self.window_list.addOne(allocator.*)).* = window;
    }

    pub fn contains(self: *XWorkspace, handle: Types.Types.Window) bool {
        for (self.items()) |w| if (w.handle == handle) return true;
        return false;
    }

    pub fn items(self: *XWorkspace) []const XWindow {
        return self.window_list.items;
    }

    // TODO: get support on this issue
    // THis does not work for some reason, it may be an error in the compiler
    // pub fn deinit(self: XWorkspace, allocator: *std.mem.Allocator) void {
    //     self.window_list.deinit(@constCast(allocator));
    // }
};

// test for the window list
test "window_list_ptr_test" {}
