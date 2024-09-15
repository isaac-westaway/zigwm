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
const Keys = @import("x11/keys.zig");

const XInit = @import("Init.zig").XInit;
const XConnection = @import("Connection.zig").XConnection;
const XId = @import("Xid.zig").XId;
const XWindow = @import("Window.zig").XWindow;
const XLayout = @import("Layout.zig").XLayout;
const XWorkspace = @import("Workspace.zig").XWorkspace;

const Logger = @import("Log.zig");

pub const ZWM = struct {
    /// General purpose allocator
    allocator: std.mem.Allocator,

    /// X Stuff
    x_init: XInit,
    x_connection: XConnection,
    x_root_window: XWindow,
    // x_workspace: XWorkspace,
    x_layout: XLayout,

    /// ZWM handlers
    /// The currently active screen
    screen: Structs.Screen,
    keysym_table: Input.KeysymTable,
    root_event_mask: Events.Mask,

    // create  struct of initialization data, one place of consistency, especially for streams and auth info

    // TODO: error handling
    pub fn init(allocator: *std.mem.Allocator, arena_allocator: std.mem.Allocator) !ZWM {
        // TODO: need to do this better
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
            // .x_workspace = XWorkspace{
            //     .focused = undefined,
            //     .mode = .tiled,
            //     .name = undefined,
            //     .id = undefined,
            //     .window_list = undefined,
            // },
            .x_layout = XLayout{
                .allocator = allocator.*,
                .current = undefined,
                .dimensions = .{ .height = undefined, .width = undefined },
                .workspaces = undefined,
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

        // TODO: Crash window manager if this fails
        try Logger.Log.info("ZWM_INIT", "Opening Unix Stream Socket");
        const socket: std.net.Stream = std.net.connectUnixSocket("/tmp/.X11-unix/X0") catch {
            try Logger.Log.fatal("ZWM_INIT_SOCKET", "Failed to Open Stream Socket, terminating");
            return undefined;
        };
        // This is redundant due to the fatal log
        std.debug.assert(@TypeOf(socket) == std.net.Stream);
        zwm.x_connection.stream = socket;
        try Logger.Log.info("ZWM_INIT", "Successfully Openend Unix Stream Socket");

        try Logger.Log.info("ZWM_INIT", "Opening XAUTHORITY file");
        const x_authority: std.fs.File = std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{}) catch {
            try Logger.Log.fatal("ZWM_INIT_AUTHORITY", "Failed to open XAuthority, terminating");
            return undefined;
        };
        std.debug.assert(@TypeOf(x_authority) == std.fs.File);
        zwm.x_init.x_authority = x_authority;
        try Logger.Log.info("ZWM_INIT", "Successfully opened XAuthority");

        try Logger.Log.info("ZWM_INIT", "Getting Hostname");
        var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
        const hostname: []u8 = std.posix.gethostname(&hostname_buf) catch {
            try Logger.Log.fatal("ZWM_INIT_HOSTNAME", "Failed to get hostname, terminating");
            return undefined;
        };
        std.debug.assert(@TypeOf(hostname) == []u8);
        try Logger.Log.info("ZWM_INIT", "Successfully fetched hostname");

        try Logger.Log.info("ZWM_INIT", "Initializing the X Connection");
        zwm.x_init.init(zwm.x_init.x_authority, hostname, arena_allocator) catch {
            try Logger.Log.fatal("ZWM_INIT", "Failed to initialize the X Connection");
        };
        try Logger.Log.info("ZWM_INIT", "Successfully initialized the X Connection");

        try Logger.Log.info("ZWM_INIT", "Initiating a Connection");
        zwm.x_connection.initiateConnection(
            zwm.x_init,
            @constCast(&arena_allocator),
        ) catch {
            try Logger.Log.fatal("ZWM_INIT", "Failed to initiate a connection");
        };
        try Logger.Log.info("ZWM_INIT", "Succesfully completed X connection initiation");

        var xid: XId = XId{
            .last = undefined,
            .max = undefined,
            .base = undefined,
            .inc = undefined,
        };

        // TODO: is xid even necessary?
        if (zwm.x_connection.status == .Ok) {
            try Logger.Log.info("ZWM_INIT", "Beginning root XID initialization");
            xid.init(zwm.x_connection) catch {
                try Logger.Log.info("ZWM_INIT", "Failed to initialize root XID");
            };
        } else {
            try Logger.Log.info("ZWM_INIX", "XConnection is NOT ok, unable to proceed");
            try zwm.close();
        }

        // TODO: initilize the layout manager and workspace manager

        zwm.screen = zwm.x_connection.screens[0];
        zwm.x_root_window = XWindow{
            .handle = zwm.x_connection.screens[0].root,
            .connection = zwm.x_connection,
        };

        // Change the attributes of the root window
        try Logger.Log.info("ZWM_INIT", "Changing attributes of root window");
        zwm.x_root_window.changeAttributes(&[_]Structs.ValueMask{.{
            .mask = .event_mask,
            .value = zwm.root_event_mask.toInt(),
        }}) catch {
            try Logger.Log.fatal("ZWM_INIT", "Unable to change root attributes, unable to proceed, terminating");
        };
        try Logger.Log.info("ZWM_INIT", "Successfully modified attributes to grab events");

        // Grab Keys
        Input.ungrabKey(&zwm.x_connection, 0, zwm.x_root_window, Input.Modifiers.any) catch {
            try Logger.Log.err("ZWM_INIT", "Unable to clean and ungrab all keys, proceeding");
        };
        try Logger.Log.info("ZWM_INIT", "Initializing keysym table");
        zwm.keysym_table = Input.KeysymTable.init(&zwm.x_connection) catch {
            try Logger.Log.fatal("ZWM_INIT", "Unable to initilize keysym table");
            return undefined;
        };
        std.debug.assert(@TypeOf(zwm.keysym_table) == Input.KeysymTable);
        Input.grabKey(&zwm.x_connection, .{ .grab_window = zwm.x_root_window, .modifiers = .{ .mod4 = true }, .key_code = zwm.keysym_table.keysymToKeycode(Keys.XK_Return) }) catch {
            try Logger.Log.fatal("ZWM_INIT", "Unable to grab XK_ENTER");
        };
        Input.grabKey(&zwm.x_connection, .{ .grab_window = zwm.x_root_window, .modifiers = .{ .mod4 = true }, .key_code = zwm.keysym_table.keysymToKeycode(Keys.XK_Escape) }) catch {
            try Logger.Log.fatal("ZWM_INIT", "Unable to grab XK_ESCAPE");
        };
        try Logger.Log.info("ZWM_INIT", "Successfully grabbed keys");

        // Initialize the layout manager
        try Logger.Log.info("ZWM_INIT", "Initializing the Layout Manager");
        zwm.x_layout.init(.{
            .width = zwm.x_connection.screens[0].width_pixel,
            .height = zwm.x_connection.screens[0].height_pixel,
        }) catch {
            try Logger.Log.fatal("ZWM_INIT", "Failed to initialize the layout manager");
        };

        try Logger.Log.info("ZWM_INIT", "Successfully completed Window Manager initialization");
        return zwm;
    }

    pub fn close(self: ZWM) !void {
        // TODO: make all these close functions errorable
        // Can technically be closed in any order
        // No need to close XWorkspace because it is closed in x_layout
        try Logger.Log.info("ZWM_CLOSE", "Closing Down");

        self.x_layout.close();
        self.keysym_table.deinit(@constCast(&self.allocator));
        self.x_connection.stream.close();
        self.x_init.deallocateAllStrings(self.x_init.x_auth_info);
        self.x_init.x_authority.close();

        std.posix.exit(1);
    }

    pub fn run(self: ZWM) !void {
        try Logger.Log.info("ZWM_RUN", "Inside the Run loop");
        while (true) {
            var bytes: [32]u8 = undefined;
            try self.x_connection.stream.reader().readNoEof(&bytes);

            switch (bytes[0]) {
                0 => _ = {
                    try Logger.Log.err("ZWM_RUN", "0: error reading Event Stream");
                },
                1 => _ = {
                    try Logger.Log.fatal("ZWM_RUN", "1: Should NOT be here");
                },
                2...34 => try self.handleEvent(bytes),
                else => {},
            }
        }
    }

    fn handleEvent(self: ZWM, buffer: [32]u8) !void {
        try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Handling Event");

        const event: Events.Event = Events.Event.fromBytes(buffer);

        switch (event) {
            .key_press => |key| {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Key press notification");
                try self.onKeyPress(key);
            },

            .map_request => |map| {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Map request notification");
                try self.onMap(map);
            },

            .configure_request => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Configure request notification");
            },

            .map_notify => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Map notify notification");
            },

            .mapping_notify => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Mapping notify notification");
            },

            .create_notify => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Create notify notification");
            },

            .destroy_notify => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Destroy notify notification");
            },

            .enter_notify => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Enter notify notification");
            },

            .leave_notify => {
                try Logger.Log.info("ZWM_RUN_HANDLEEVENT", "Leave notify notification");
            },

            else => {
                const formatted_event = try std.fmt.allocPrint(self.allocator, "Unhandled Event: {any}\n", .{@intFromEnum(event)});
                try Logger.Log.warn("ZWM_RUN_HANDLEEVENT", formatted_event);
            },
        }
    }

    fn onKeyPress(self: ZWM, event: Events.InputDeviceEvent) !void {
        // _ = try self.logfile.write("ZWM_RUN_HANDLEEVENT_ONKEYPRESS: Attempting to Handle keypress event\n");

        const mod4 = Input.Modifiers{
            .mod4 = true,
        };
        const argv = &[_][]const u8{"kitty"};

        if (Keys.XK_Return == self.keysym_table.keycodeToKeysym(event.detail) and mod4.toInt() == event.state) {
            // _ = try self.logfile.write("Trying to open cmd\n");
            runCmd(self.allocator, argv) catch {
                // _ = try self.logfile.write("ZWM_RUN_HANDLEEVENT_ONKEYPRESS_IF_XKRETURN: FAILED to run command\n");
            };
            // _ = try self.logfile.write("Opened cmd\n");
        }

        if (Keys.XK_Escape == self.keysym_table.keycodeToKeysym(event.detail) and mod4.toInt() == event.state) {
            try self.close();
        }
    }

    fn onMap(self: ZWM, event: Events.MapRequest) !void {
        const window = XWindow{ .connection = self.x_connection, .handle = event.window };
        try self.x_layout.mapWindow(window);

        // map the window in a layout manager
    }

    fn runCmd(allocator: std.mem.Allocator, cmd: []const []const u8) !void {
        if (cmd.len == 0) return;

        var process = std.process.Child.init(cmd, allocator);

        try process.spawn();
    }

    fn callAction(self: *ZWM, action: anytype, arg: anytype) !void {
        const Fn = @typeInfo(@TypeOf(action)).Fn;
        const args = Fn.params;

        if (args.len == 1) try action(self);
        if (args.len == 2) try action(self, arg);
    }
};
