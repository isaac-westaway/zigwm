//! The Zig Window Manager object
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

const Config = @import("Config.zig");

const XInit = @import("Init.zig").XInit;
const XConnection = @import("Connection.zig").XConnection;
const XId = @import("Xid.zig").XId;
const XWindow = @import("Window.zig").XWindow;

pub const ZWM = struct {
    /// General purpose allocator
    allocator: std.mem.Allocator,

    /// X Stuff
    x_init: XInit,
    x_connection: XConnection,
    x_root_window: XWindow,

    /// ZWM handlers
    /// The currently active screen
    screen: Structs.Screen,
    keysym_table: Input.KeysymTable,
    root_event_mask: Events.Mask,

    // create  struct of initialization data, one place of consistency, especially for streams and auth info

    pub fn init(allocator: *std.mem.Allocator, arena_allocator: std.mem.Allocator) !ZWM {
        // need to do this better
        var zwm: ZWM = ZWM{
            .allocator = allocator.*,
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

        std.log.scoped(.zwm).info("Completed startup process initialization", .{});
        std.log.scoped(.zwm).info("Beginning X Initialization process", .{});

        try zwm.x_init.init(zwm.x_init.x_authority, hostname, arena_allocator);

        std.log.scoped(.zwm).info("Trying x_connection.initiateConnection", .{});
        try zwm.x_connection.initiateConnection(
            zwm.x_init,
            @constCast(&arena_allocator),
        );
        std.log.scoped(.zwm).info("Successfully completed connection instantiation", .{});

        var xid: XId = XId{
            .last = undefined,
            .max = undefined,
            .base = undefined,
            .inc = undefined,
        };

        if (zwm.x_connection.status == .Ok) {
            std.log.scoped(.zwm).info("XId Status OK", .{});
        } else {
            try xid.init(zwm.x_connection);
        }

        zwm.screen = zwm.x_connection.screens[0];

        zwm.x_root_window = XWindow{
            .handle = zwm.x_connection.screens[0].root,
            .connection = zwm.x_connection,
        };

        std.log.scoped(.zwm).info("Initializing Root Window", .{});
        try zwm.x_root_window.initializeRootWindow();

        // Change the attributes of the root window for compliance
        std.log.scoped(.zwm).info("Changing Attributes", .{});
        try zwm.x_root_window.changeAttributes(&[_]Structs.ValueMask{.{
            .mask = .event_mask,
            .value = zwm.root_event_mask.toInt(),
        }});

        std.log.scoped(.zwm).info("Grabbing Keys", .{});
        try zwm.grabKeys();
        std.log.scoped(.zwm).info("Completed Grabbing Keys", .{});

        std.log.scoped(.zwm).info("Completed Initialization, returning", .{});

        return zwm;
    }

    pub fn close(self: ZWM) void {
        self.x_connection.stream.close();
        self.x_init.x_authority.close();
        self.keysym_table.deinit(@constCast(&self.allocator));
    }

    pub fn run(self: ZWM) !void {
        std.log.scoped(.zwm).info("Inside Run Process", .{});

        while (true) {
            var bytes: [32]u8 = undefined;
            try self.x_connection.stream.reader().readNoEof(&bytes);

            switch (bytes[0]) {
                // 0 => self.handleError(bytes),
                1 => unreachable,
                2...34 => {
                    std.log.scoped(.zwm_run_while_switch).info("Handling Event", .{});
                    try self.handleEvent(bytes);
                    return;
                },
                else => {}, // unahandled
            }
        }
    }

    // handle logging
    fn grabKeys(self: *ZWM) !void {
        std.log.scoped(.zwm_grabKeys).info("UNgrabbing keys", .{});
        try Input.ungrabKey(&self.x_connection, 0, self.x_root_window, Input.Modifiers.any);
        std.log.scoped(.zwm_grabKeys).info("UNgrabbed keys", .{});

        std.log.scoped(.zwm_grabKeys).info("Initializing keysym table", .{});
        self.keysym_table = try Input.KeysymTable.init(&self.x_connection);

        std.log.scoped(.zwm_grabKeys).info("Completed Initializing keysym table", .{});
    }

    fn handleEvent(self: ZWM, buffer: [32]u8) !void {
        const event = Events.Event.fromBytes(buffer);
        const argv: []const []const u8 = &[_][]const u8{"kitty"};

        switch (event) {
            .key_press => |key| {
                std.log.scoped(.zwm).info("Handling Key Press Event", .{});
                try runCmd(self.allocator, argv);
                try self.onKeyPress(key);
            },
            // .map_request => |map| try self.onMap(map),
            // .configure_request => |conf| try self.onMap(conf),
            else => {},
        }
    }

    fn onKeyPress(self: ZWM, event: Events.InputDeviceEvent) !void {
        inline for (Config.default_config.bindings) |binding| {
            if (binding.symbol == self.keysym_table.keycodeToKeysym(event.detail) and binding.modifier.toInt() == event.state) {
                switch (binding.action) {
                    .cmd => |cmd| {
                        return runCmd(self.allocator, cmd);
                    },
                    .function => |func| {
                        return self.callAction(func.action, func.arg);
                    },
                }
            }
        }
    }

    fn runCmd(allocator: std.mem.Allocator, cmd: []const []const u8) !void {
        if (cmd.len == 0) return;

        _ = try std.process.Child.run(.{ .allocator = allocator, .argv = cmd });
    }

    fn callAction(self: *ZWM, action: anytype, arg: anytype) !void {
        const Fn = @typeInfo(@TypeOf(action)).Fn;
        const args = Fn.params;

        if (args.len == 1) try action(self);
        if (args.len == 2) try action(self, arg);
    }
};
