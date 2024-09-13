const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const XWindow = @import("Window.zig").XWindow;

pub const ScreenMode = enum { tiled, fullscreen };

pub const XWorkspace = struct {
    windows: std.ArrayListUnmanaged(XWindow),

    pub fn init(self: *XWorkspace) !void {
        _ = self;
    }

    pub fn close() !void {}
};
