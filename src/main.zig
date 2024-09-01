const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("structs.zig");
const Atoms = @import("atoms.zig");

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
    var socket: std.net.Stream = try std.net.connectUnixSocket("/tmp/.X11-unix/X2");
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
    // initiate a connection to the XServer unix domain socket
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
        // std.debug.print("Error initializing XID", .{});
        try xid.init(x_connection);
    }

    const root_window_xid: u32 = try xid.genXId(&x_connection);

    var x_root_window: XWindow = XWindow{
        .handle = root_window_xid,
        .connection = x_connection,
    };

    try x_root_window.initializeRootWindow();
    // event loop to prevent auto shutdown

    // const argv: []const []const u8 = &[_][]const u8{
    //     // terminal
    //     "kitty",
    // };

    // const echo = try std.process.Child.run(.{ .allocator = allocator, .argv = argv });
    // _ = echo;

    while (true) {}
}
