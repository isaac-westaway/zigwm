//! The entry point for the Zig Window Manager

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

// ideally, I want to get rid of these two import statements
const Structs = @import("x11/structs.zig");
const Atoms = @import("x11/atoms.zig");
const Events = @import("x11/events.zig");

const XInit = @import("Init.zig").XInit;
const XConnection = @import("Connection.zig").XConnection;
const XId = @import("Xid.zig").XId;
const XWindow = @import("Window.zig").XWindow;

pub fn main() !void {
    // for top level allocation

    std.log.scoped(.main).info("Initializing startup process", .{});

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    // startx :2 vt2 ~/Documents/zig/zigwm/zig-out/zigwm
    var socket: std.net.Stream = try std.net.connectUnixSocket("/tmp/.X11-unix/X0");
    defer socket.close();

    const x_authority: std.fs.File = try std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{});
    defer x_authority.close();

    var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&hostname_buf);

    // for child allocators
    var heap_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    var arena_allocator = heap_arena_allocator.allocator();
    defer heap_arena_allocator.deinit();

    std.log.scoped(.main).info("Completed startup process initialization", .{});
    std.log.scoped(.main_x_init).info("Beginning X Initialization process", .{});

    var x_init: XInit = XInit{
        .allocator = allocator,
        .auth_info = undefined,
    };

    std.log.scoped(.main_x_init).info("Trying x_init.init", .{});
    try x_init.init(x_authority, hostname, arena_allocator);

    // make sure authorisation uses mit magic cookies
    std.debug.assert(std.mem.eql(u8, x_init.auth_info.name, "MIT-MAGIC-COOKIE-1"));
    std.log.scoped(.main_x_init).info("Successfully completed x_init initialization", .{});

    std.log.scoped(.main_x_connection).info("Beginning x_connection initialization", .{});

    // ! The Window Manager is inserted here `XConnection`
    var x_connection: XConnection = XConnection{
        .allocator = allocator,
        .stream = socket,
        .formats = undefined,
        .screens = undefined,
        .setup = undefined,
        .status = undefined,
    };

    // Initiate a setup
    std.log.scoped(.main_x_connection).info("Trying x_connection.initiateConnection", .{});
    try x_connection.initiateConnection(
        x_init,
        &arena_allocator,
    );
    std.log.scoped(.main_x_connection).info("Successfully completed connection instantiation", .{});

    // maybe there is a better way to do this, maybe this is the best most readable way
    var xid: XId = XId{
        .last = undefined,
        .max = undefined,
        .base = undefined,
        .inc = undefined,
    };

    if (x_connection.status == .Ok) {} else {
        try xid.init(x_connection);
    }

    var x_root_window: XWindow = XWindow{
        .handle = x_connection.screens[0].root,
        .connection = x_connection,
    };

    try x_root_window.initializeRootWindow();

    const root_event_mask = Events.Mask{
        .substructure_redirect = true,
        .substructure_notify = true,
        .structure_notify = true,
        .property_change = true,
    };

    // Change the attributes of the root window for compliance
    try x_root_window.changeAttributes(&[_]Structs.ValueMask{.{
        .mask = .event_mask,
        .value = root_event_mask.toInt(),
    }});

    std.debug.print("Completed Successfully, starting event loop!\n", .{});

    const argv: []const []const u8 = &[_][]const u8{
        "kitty",
    };

    const echo = try std.process.Child.run(.{ .allocator = allocator, .argv = argv });
    _ = echo;

    while (true) {}
}
