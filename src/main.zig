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
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var socket: std.net.Stream = try std.net.connectUnixSocket("/tmp/.X11-unix/X1");
    defer socket.close();

    const x_authority: std.fs.File = try std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{});
    defer x_authority.close();

    var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&hostname_buf);

    var x_init: XInit = XInit{
        .allocator = allocator,
        .auth_info = undefined,
    };

    // for child allocators
    var heap_arena_allocator = std.heap.ArenaAllocator.init(x_init.allocator);
    var arena_allocator = heap_arena_allocator.allocator();
    defer heap_arena_allocator.deinit();

    try x_init.init(x_authority, hostname, arena_allocator);

    // make sure authorisation uses mit magic cookies
    std.debug.print("Info: {s}\n", .{x_init.auth_info.data});
    std.debug.assert(std.mem.eql(u8, x_init.auth_info.name, "MIT-MAGIC-COOKIE-1"));

    // Initiate a connection to the XServer unix domain socket
    var x_connection: XConnection = XConnection{
        .allocator = allocator,
        .stream = socket,
        .formats = undefined,
        .screens = undefined,
        .setup = undefined,
        .status = undefined,
    };

    // Initiate a setup
    try x_connection.initiateConnection(
        x_init,
        &arena_allocator,
    );
    var xid: XId = XId{
        .last = undefined,
        .max = undefined,
        .base = undefined,
        .inc = undefined,
    };

    if (x_connection.status == .Ok) {} else {
        std.debug.print("Error initializing XID", .{});
        try xid.init(x_connection);
    }

    const root_window_xid: u32 = try xid.genXId(&x_connection);

    var x_root_window: XWindow = XWindow{
        .handle = root_window_xid,
        .connection = x_connection,
    };

    // access the connection root integer (it is the windowID) and use it to craete windows

    const options: Structs.CreateWindowOptions = comptime Structs.CreateWindowOptions{
        .width = 800,
        .height = 600,
    };

    const mask: u32 = blk: {
        var tmp: u32 = 0;
        for (options.values) |val| tmp |= val.mask.toInt();
        break :blk tmp;
    };
    // // _ = mask;

    const window_request = Structs.CreateWindowRequest{
        .length = @sizeOf(Structs.CreateWindowRequest) / 4 + @as(u16, options.values.len),
        .wid = x_root_window.handle,
        .parent = x_connection.screens[0].root,
        .width = options.width,
        .height = options.height,
        .visual = x_connection.screens[0].root_visual,
        .value_mask = mask,
        .class = options.class.toInt(),
    };

    try x_connection.send(window_request);
    for (options.values) |val| {
        try x_connection.send(val.value);
    }

    std.debug.print("Window: {any}", .{x_root_window});
    if (options.title) |title| {
        try x_root_window.ChangeProperty(socket, .replace, Atoms.Atoms.wm_name, Atoms.Atoms.string, .{ .string = title });
    }

    try x_root_window.map();
}
