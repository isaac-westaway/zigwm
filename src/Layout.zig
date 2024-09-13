const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const XWorkspace = @import("Workspace.zig").XWorkspace;

pub const XLayout = struct {
    allocator: std.mem.Allocator,

    workspace: XWorkspace,
    current: usize,
    dimensions: struct {
        width: u16,
        height: u16,
    },

    // workspaces

    pub fn init(self: *XLayout, dimensions: struct { width: u16, height: u16 }, workspace: XWorkspace) !void {
        self.current = 0;
        self.dimensions.height = dimensions.height;
        self.dimensions.width = dimensions.width;

        self.workspace = workspace;
        self.workspace.init() catch {
            // TODO: logging
            std.debug.print("errork", .{});
        };
    }

    pub fn close(self: XLayout) void {
        _ = self;
    }

    pub fn mapWindow() !void {}
};
