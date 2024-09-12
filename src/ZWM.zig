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
    logfile: std.fs.File,

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

    // TODO: error handling
    pub fn init(allocator: *std.mem.Allocator, arena_allocator: std.mem.Allocator, logfile: std.fs.File) !ZWM {
        // need to do this better
        var zwm: ZWM = ZWM{
            .allocator = allocator.*,
            .logfile = logfile,
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

        _ = try zwm.logfile.write("ZWM_INIT: Initializing Unix Stream\n");
        const socket: std.net.Stream = std.net.connectUnixSocket("/tmp/.X11-unix/X0") catch {
            _ = try zwm.logfile.write("ZWM: FAILED to initialize Unix Stream\n");

            return undefined;
        };
        std.debug.assert(@TypeOf(socket) == std.net.Stream);
        zwm.x_connection.stream = socket;
        _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY opened a unix stream\n");

        _ = try zwm.logfile.write("ZWM_INIT: Opening XAUTHORITY file\n");
        const x_authority: std.fs.File = std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{}) catch {
            _ = try zwm.logfile.write("ZWM_INIT: FAILED to open XAUTHIRTY\n");

            return undefined;
        };
        std.debug.assert(@TypeOf(x_authority) == std.fs.File);
        zwm.x_init.x_authority = x_authority;
        _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY opened XAUTHORITY file\n");

        _ = try zwm.logfile.write("ZWM_INIT: Getting hostname\n");
        var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
        const hostname: []u8 = std.posix.gethostname(&hostname_buf) catch {
            _ = try zwm.logfile.write("ZWM_INIT: FAILED to get hostname\n");

            return undefined;
        };
        std.debug.assert(@TypeOf(hostname) == []u8);
        _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY fetched hostname\n");

        _ = try zwm.logfile.write("ZWM_INIT: Attempting X Initializaiton\n");
        zwm.x_init.init(zwm.x_init.x_authority, hostname, arena_allocator) catch {
            _ = try zwm.logfile.write("ZWM_INIT: FAILED X Initialization\n");
        };
        _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY completed X Initialization\n");

        _ = try zwm.logfile.write("ZWM_INIT: Attempting X Connection Initiation\n");
        zwm.x_connection.initiateConnection(
            zwm.x_init,
            @constCast(&arena_allocator),
        ) catch {
            _ = try zwm.logfile.write("ZWM_INIT: FAILED X Connection Initiation\n");
        };

        var xid: XId = XId{
            .last = undefined,
            .max = undefined,
            .base = undefined,
            .inc = undefined,
        };

        if (zwm.x_connection.status == .Ok) {
            _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY completed X Connection Initiation\n");
        } else {
            try xid.init(zwm.x_connection);
            _ = try zwm.logfile.write("ZWM_INIT: Initializing XID\n");
        }

        // TODO: initilize the layout manager and workspace manager

        zwm.screen = zwm.x_connection.screens[0];

        zwm.x_root_window = XWindow{
            .handle = zwm.x_connection.screens[0].root,
            .connection = zwm.x_connection,
        };

        // _ = try zwm.logfile.write("ZWM_INIT: Initializing root window\n");
        // zwm.x_root_window.initializeRootWindow() catch {
        //     _ = try zwm.logfile.write("ZWM_INIT: FAILED to initialize the root window");
        // };
        // _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY initialized the root window\n");

        // Change the attributes of the root window for compliance
        _ = try zwm.logfile.write("ZWM_INIT: Changing attributes of the root window\n");
        zwm.x_root_window.changeAttributes(&[_]Structs.ValueMask{.{
            .mask = .event_mask,
            .value = zwm.root_event_mask.toInt(),
        }}) catch {
            _ = try zwm.logfile.write("ZWM_INIT: FAILED to change attributes of the root window\n");
        };

        _ = try zwm.logfile.write("ZWM_INIT: Grabbing keys\n");
        zwm.grabKeys() catch {
            _ = try zwm.logfile.write("ZWM_INIT: FAILED to grab keys\n");
        };
        _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY Grabbed all keys\n");

        _ = try zwm.logfile.write("ZWM_INIT: SUCCESSFULLY completed zwm initialization\n");

        return zwm;
    }

    pub fn close(self: ZWM) void {
        self.x_connection.stream.close();
        self.x_init.x_authority.close();
        self.keysym_table.deinit(@constCast(&self.allocator));
    }

    pub fn run(self: ZWM) !void {
        while (true) {
            var bytes: [32]u8 = undefined;
            try self.x_connection.stream.reader().readNoEof(&bytes);

            switch (bytes[0]) {
                // 0 => self.handleError(bytes),
                1 => _ = try self.logfile.write("ZWM_RUN: ERROR READING EVENT STREAM\n"),
                2...34 => try self.handleEvent(bytes),
                else => {}, // unahandled
            }
        }
    }

    // TODO: handle logging
    fn grabKeys(self: *ZWM) !void {
        // std.log.scoped(.zwm_grabKeys).info("UNgrabbing keys", .{});
        // try Input.ungrabKey(&self.x_connection, 0, self.x_root_window, Input.Modifiers.any);
        // std.log.scoped(.zwm_grabKeys).info("UNgrabbed keys", .{});

        // std.log.scoped(.zwm_grabKeys).info("Initializing keysym table", .{});
        self.keysym_table = try Input.KeysymTable.init(&self.x_connection);

        // std.log.scoped(.zwm_grabKeys).info("Completed Initializing keysym table", .{});
    }

    fn handleEvent(self: ZWM, buffer: [32]u8) !void {
        _ = try self.logfile.write("ZWM_RUN_HANDLEEVENT: Event Notification\n");
        const event = Events.Event.fromBytes(buffer);
        // const argv: []const []const u8 = &[_][]const u8{"kitty"};

        switch (event) {
            .key_press => |key| {
                _ = try self.logfile.write("ZWM_RUN_HANDLEEVENT_SWITCH: KEYPRESS event notification\n");
                // try runCmd(self.allocator, argv);
                try self.onKeyPress(key);
            },
            .map_request => |map| try self.onMap(map),
            // .configure_request => |conf| try self.onMap(conf),

            // enter notify,
            // leave notify
            else => {},
        }
    }

    fn onKeyPress(self: ZWM, event: Events.InputDeviceEvent) !void {
        _ = try self.logfile.write("ZWM_RUN_HANDLEEVENT_ONKEYPRESS: Attempting to Handle keypress event\n");

        // ! the oiginal error

        const string = try std.fmt.allocPrint(self.allocator, "event: .code = {}, .detail = {}, .sequence = {}, .time = {}, .root = {}, .event = {}, .root_x = {}, .root_y = {}, .event_x = {}, .event_y = {}, .state = {}, .same_screen = {}, .pad = {}\n", .{ event.code, event.detail, event.sequence, event.time, event.root, event.event, event.root_x, event.root_y, event.event_x, event.event_y, event.state, event.same_screen, event.pad });

        _ = try self.logfile.write(string);
        // inline for (Config.default_config.bindings) |binding| {
        //     if (binding.symbol == self.keysym_table.keycodeToKeysym(event.detail) and binding.modifier.toInt() == event.state) {
        //         switch (binding.action) {
        //             .cmd => |cmd| {
        //                 return runCmd(self.allocator, cmd);
        //             },
        //             .function => |func| {
        //                 return self.callAction(func.action, func.arg);
        //             },
        //         }
        //     }
        // }
    }

    fn onMap(self: ZWM, event: Events.MapRequest) !void {
        const window = XWindow{ .connection = self.x_connection, .handle = event.window };
        _ = window;

        // map the window in a layout manager
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
