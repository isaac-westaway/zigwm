const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const AuthInfo = struct {
    // endiannes
    family: u16 = 0,
    address: []const u8 = "",
    number: []const u8 = "",
    name: []const u8 = "",
    data: []const u8 = "",
};

fn readString(gpa: *std.mem.Allocator, file: std.fs.File) ![]u8 {
    const stream = file.reader();

    const len = try stream.readInt(u16, .big);
    const buf = try gpa.alloc(u8, len);
    errdefer gpa.free(buf);

    try stream.readNoEof(buf);
    return buf;
}

fn deserialize(comptime Struct: type, allocator: *std.mem.Allocator, file: std.fs.File) !Struct {
    const reader = file.reader();

    var auth_info = Struct{};
    inline for (@typeInfo(Struct).Struct.fields) |field| {
        @field(auth_info, field.name) = brk: {
            if (@typeInfo(field.type) == .Int) {
                break :brk try reader.readInt(field.type, .big);
            } else {
                break :brk try readString(allocator, file);
            }
        };
    }

    return auth_info;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    var allocator = general_purpose_allocator.allocator();

    var socket = try std.net.connectUnixSocket("/tmp/.X11-unix/X0");
    defer socket.close();

    const x_authority = try std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{});
    defer x_authority.close();

    var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&hostname_buf);
    _ = hostname;

    const auth_info = try deserialize(AuthInfo, @constCast(&allocator), x_authority);
    _ = auth_info;
}
