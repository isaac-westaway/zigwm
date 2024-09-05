// manager
// struct
// allocator as input.

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("x11/structs.zig");
const Atoms = @import("x11/atoms.zig");
const Events = @import("x11/events.zig");
const Input = @import("x11/input.zig");

const XInit = @import("Init.zig").XInit;
const XConnection = @import("Connection.zig").XConnection;
const XId = @import("Xid.zig").XId;
const XWindow = @import("Window.zig").XWindow;

pub const ZWM = struct {
    // X Stuff
    x_init: XInit,
    x_connection: XConnection,
    x_root_window: XWindow,

    // ZWM handlers
    screen: Structs.Screen,
    keysym_table: Input.KeysymTable,
    root_event_mask: Events.Mask,

    // create  struct of initialization data, one place of consistency, especially for streams and auth info

    pub fn init(allocator: *std.mem.Allocator, arena_allocator: std.mem.Allocator) !ZWM {
        // need to do this better
        var zwm: ZWM = ZWM{
            .x_init = XInit{
                .allocator = allocator.*,
                .x_auth_info = undefined,
                .x_authority = undefined,
            },
            .x_connection = XConnection{
                .allocator = allocator.*,
                .stream = undefined,
                .formats = undefined,
                .screens = undefined,
                .setup = undefined,
                .status = undefined,
            },
            .x_root_window = XWindow{
                .connection = undefined,
                .handle = undefined,
            },
            .screen = undefined,
            .keysym_table = undefined,
            .root_event_mask = Events.Mask{
                .substructure_redirect = true,
                .substructure_notify = true,
                .structure_notify = true,
                .property_change = true,
            },
        };

        const socket: std.net.Stream = try std.net.connectUnixSocket("/tmp/.X11-unix/X0");
        // ! refer to sticky note
        zwm.x_connection.stream = socket;

        const x_authority: std.fs.File = try std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{});
        zwm.x_init.x_authority = x_authority;

        var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
        const hostname = try std.posix.gethostname(&hostname_buf);

        std.log.scoped(.main).info("Completed startup process initialization", .{});
        std.log.scoped(.main_x_init).info("Beginning X Initialization process", .{});

        try zwm.x_init.init(zwm.x_init.x_authority, hostname, arena_allocator);

        std.log.scoped(.main_x_connection).info("Trying x_connection.initiateConnection", .{});
        try zwm.x_connection.initiateConnection(
            zwm.x_init,
            @constCast(&arena_allocator),
        );
        std.log.scoped(.main_x_connection).info("Successfully completed connection instantiation", .{});

        var xid: XId = XId{
            .last = undefined,
            .max = undefined,
            .base = undefined,
            .inc = undefined,
        };

        if (zwm.x_connection.status == .Ok) {} else {
            try xid.init(zwm.x_connection);
        }

        zwm.x_root_window = XWindow{
            .handle = zwm.x_connection.screens[0].root,
            .connection = zwm.x_connection,
        };

        try zwm.x_root_window.initializeRootWindow();

        // Change the attributes of the root window for compliance
        try zwm.x_root_window.changeAttributes(&[_]Structs.ValueMask{.{
            .mask = .event_mask,
            .value = zwm.root_event_mask.toInt(),
        }});

        return zwm;
    }

    pub fn close(self: *ZWM) !void {
        self.x_connection.stream.close();
        self.x_init.x_authority.close();
    }
};
