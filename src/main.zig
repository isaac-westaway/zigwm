const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Connection = @import("connection.zig");
const Structs = @import("structs.zig");

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

    // for child allocators inside functions
    var heap_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    var arena_allocator = heap_arena_allocator.allocator();
    defer heap_arena_allocator.deinit();

    const auth_info = while (true) {
        const auth_info = try Connection.deserialize(Structs.AuthInfo, @constCast(&arena_allocator), x_authority);

        // ! more cookie encoding types handled here
        if (std.mem.eql(u8, auth_info.address, hostname) and std.mem.eql(u8, "MIT-MAGIC-COOKIE-1", auth_info.name)) {
            std.debug.print("Good\n", .{});

            break auth_info;
        } else {
            Connection.deallocateAllStrings(@constCast(&allocator), auth_info);
        }
    };

    // make sure authorisation uses mit magic cookies
    std.debug.print("Info: {s}\n", .{auth_info.name});
    std.debug.assert(std.mem.eql(u8, auth_info.name, "MIT-MAGIC-COOKIE-1"));

    // Initiate a setup
    const pad = [3]u8{ 0, 0, 0 };
    try Connection.send(socket, Structs.SetupRequest{
        .name_len = @intCast(auth_info.name.len),
        .data_len = @intCast(auth_info.data.len),
    });
    try Connection.send(socket, auth_info.name);
    try Connection.send(socket, pad[0..Connection.xpad(auth_info.name.len)]);
    try Connection.send(socket, auth_info.data);
    try Connection.send(socket, pad[0..Connection.xpad(auth_info.data.len)]);

    // Read the setup response
    var connection: Structs.XConnection = Structs.XConnection{
        .stream = socket,
        .formats = undefined,
        .screen = undefined,
        .status = undefined,
        .setup = undefined,
    };
    var xid: Structs.XId = undefined;

    const stream = connection.reader();

    const header: Structs.SetupGeneric = try stream.readStruct(Structs.SetupGeneric);

    const setup_buffer: []u8 = try allocator.alloc(u8, header.length * 4);
    defer allocator.free(setup_buffer);

    try stream.readNoEof(setup_buffer);

    // assert a success, otherwise there is a system error
    std.debug.print("Header Status: {}\n", .{header.status});
    if (header.status == 1) {
        connection.status = .Ok;
        xid = Structs.XId.init(connection);
    } else if (header.status == 0) {
        // warning means authentication error. should implement logic to fix this by sending Xauthority
        // contents to the XServer unix domain socket for authentication
        connection.status = .Warning;
    } else {
        connection.status = .Error;
    }

    try Connection.parseSetup(@constCast(&arena_allocator), &connection, setup_buffer);

    std.debug.print("{any}\n", .{connection});

    const window_xid: u32 = try Connection.genXId(&connection, socket, xid);

    std.debug.print("{any}\n", .{window_xid});

    // access the connection root integer (it is the windowID) and use it to craete windows

    // const options: Structs.CreateWindowOptions = comptime Structs.CreateWindowOptions{
    //     .width = 800,
    //     .height = 600,
    // };

    // const mask: u32 = blk: {
    //     var tmp: u32 = 0;
    //     for (options.values) |val| tmp |= val.mask.toInt();
    //     break :blk tmp;
    // };

    // const window_request = Structs.CreateWindowRequest{
    //     .length = @sizeOf(Structs.CreateWindowRequest) / 4 + @intCast(options.values.len),
    // };
}
