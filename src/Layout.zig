const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("x11/structs.zig");
const Events = @import("x11/events.zig");

const XWindow = @import("Window.zig").XWindow;
const XWorkspace = @import("Workspace.zig").XWorkspace;

pub const XLayout = struct {
    allocator: std.mem.Allocator,

    workspaces: [6]XWorkspace,
    current: usize,
    dimensions: struct {
        width: u16,
        height: u16,
    },

    // workspaces

    pub fn init(self: *XLayout, dimensions: struct { width: u16, height: u16 }) !void {
        self.current = 0;
        self.dimensions.height = dimensions.height;
        self.dimensions.width = dimensions.width;

        for (self.workspaces, 0..) |ws, index| {
            var unconst_ws: XWorkspace = @constCast(&ws).*;
            self.workspaces[index] = unconst_ws.init(index);
        }
    }

    pub fn mapWindow(self: *const XLayout, window: XWindow) !void {
        var workspace = self.workspaces[self.current];

        try workspace.add(@constCast(&self.allocator), window);

        // what if we dont remap the windows and just check if it works first
        // TODO: try self.remapWindows(workspace);

        const window_event_mask = Events.Mask{
            .enter_window = true,
            .focus_change = true,
        };

        var _window: XWindow = @constCast(&window).*;

        try _window.changeAttributes(&[_]Structs.ValueMask{.{
            .mask = .event_mask,
            .value = window_event_mask.toInt(),
        }});

        try _window.map();

        // TODO: logging
    }

    pub fn close(self: XLayout) void {
        // ! temporary fix to workspace.deinit
        self.allocator.destroy(&self.workspaces);
    }
};
