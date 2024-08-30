const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Connection = @import("connection.zig");

const AuthInfo = struct {
    // endiannes
    family: u16 = undefined,
    address: []const u8 = undefined,
    number: []const u8 = undefined,
    name: []const u8 = undefined,
    data: []const u8 = undefined,
};

pub const SetupRequest = extern struct {
    byte_order: u8 = if (builtin.target.cpu.arch.endian() == .big) 0x42 else 0x6c,
    pad0: u8 = 0,
    major_version: u16 = 11,
    minor_version: u16 = 0,
    name_len: u16,
    data_len: u16,
    pad1: [2]u8 = [_]u8{ 0, 0 },
};

const ConnectionReader = struct {
    stream: std.net.Stream,

    fn reader(self: *ConnectionReader) std.io.Reader(*ConnectionReader, std.fs.File.ReadError, read) {
        return .{ .context = self };
    }

    fn read(self: *ConnectionReader, buffer: []u8) std.fs.File.ReadError!usize {
        return std.posix.read(self.stream.handle, buffer);
    }
};

pub fn main() !void {
    // for top level allocation
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var socket: std.net.Stream = try std.net.connectUnixSocket("/tmp/.X11-unix/X0");
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
        const auth_info = try Connection.deserialize(AuthInfo, @constCast(&arena_allocator), x_authority);
        if (std.mem.eql(u8, auth_info.address, hostname)) {
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
    try Connection.send(socket, SetupRequest{
        .name_len = @intCast(auth_info.name.len),
        .data_len = @intCast(auth_info.data.len),
    });
    try Connection.send(socket, auth_info.name);
    try Connection.send(socket, pad[0..Connection.xpad(auth_info.name.len)]);
    try Connection.send(socket, auth_info.data);
    try Connection.send(socket, pad[0..Connection.xpad(auth_info.data.len)]);

    // Read the setup response
    var connection = ConnectionReader{
        .stream = socket,
    };
    const stream = connection.reader();

    const SetupGeneric = extern struct {
        status: u8,
        pad0: [5]u8,
        length: u16,
    };

    const header = try stream.readStruct(SetupGeneric);

    const setup_buffer = try allocator.alloc(u8, header.length * 4);
    defer allocator.free(setup_buffer);

    try stream.readNoEof(setup_buffer);

    // make sure authorization is required, else don't authorize. authorization will always be required
    std.debug.print("Header Status: {}\n", .{header.status});
    std.debug.assert(header.status == 1);

    // Send the Xauthroity file contents, auth_info.data and auth_info.name
}
