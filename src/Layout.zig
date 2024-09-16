const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("x11/structs.zig");
const Events = @import("x11/events.zig");

const XWindow = @import("Window.zig").XWindow;
const XWorkspace = @import("Workspace.zig").XWorkspace;

const Logger = @import("Log.zig");

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
        try Logger.Log.info("ZWM_INIT_LAYOUT_INIT", "Initializng the Layout Manager");
        self.current = 0;
        self.dimensions.height = dimensions.height;
        self.dimensions.width = dimensions.width;

        for (&self.workspaces, 0..) |*ws, index| {
            ws.* = ws.*.init(index);
        }
    }

    pub fn mapWindow(self: *const XLayout, window: XWindow) !void {
        var workspace: *XWorkspace = @constCast(&self.workspaces[self.current]);

        try workspace.add(@constCast(&self.allocator), window);

        const combined = try std.fmt.allocPrint(self.allocator, "Mapped window on: {d} With Workspace: {d}", .{ window.handle, workspace.id });
        try Logger.Log.info("ZWM_RUN_HANDLEEVENT_ONMAP_MAPWINDOW", combined);

        // TODO: try self.remapWindows(workspace);

        const window_event_mask = Events.Mask{
            .enter_window = true,
            .focus_change = true,
        };

        try window.changeAttributes(&[_]Structs.ValueMask{.{
            .mask = .event_mask,
            .value = window_event_mask.toInt(),
        }});
        // change property to update the net client list

        try window.map();

        try self.focusWindow(window);

        // implement window focusing, also implement onConfigure
    }

    pub fn focusWindow(self: *const XLayout, window: XWindow) !void {
        const old_focused = self.workspaces[self.current].focused;
        _ = old_focused;
        // TODO: change border of old focused

        @constCast(&self.workspaces[self.current].focused).* = window;

        try window.inputFocus();

        try window.changeAttributes(&[_]Structs.ValueMask{.{ .mask = .border_pixel, .value = 0x014c82 }});
    }

    pub fn close(self: XLayout) void {
        for (self.workspaces) |workspace| {
            var wl: *XWorkspace = @constCast(&workspace);
            try wl.deinit(@constCast(&self.allocator));
        }
    }
};
