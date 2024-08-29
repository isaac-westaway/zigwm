const std = @import("std");

const x11 = @import("x11.zig");

pub const Connection = struct {
    stream: std.net.Stream,
    gpa: *std.mem.Allocator,
};

pub const DisplayErrors = error{
    UnixSocketError,
};

pub const ConnectionErrors = error{
    UnableToConnect,
    InvalidSetupResponse,
    StreamError,
};

// public subroutines to be used in main
// return a handle to the X11 unix socket, to be read and written from later
pub fn Display() DisplayErrors!std.net.Stream {
    // $ Xephyr :1 -ac -screen 800x600
    const stream: std.net.Stream = std.net.connectUnixSocket("/tmp/.X11-unix/X1") catch {
        std.debug.print("Failed to connect to the Unix socket\n", .{});
        return DisplayErrors.UnixSocketError;
    };

    return stream;
}

// read contents of .XAuthority and pass it in
pub fn ConnectionSetup(stream: std.net.Stream) ConnectionErrors!void {
    // const zigwm = x11.SetupRequest{
    //     .byte_order = 0x6C,
    //     .major_version = 11,
    //     .minor_version = 0,
    // };

    // stream.writeAll(std.mem.asBytes(&zigwm)) catch {
    //     return;
    // };

    stream.writeAll("Hello") catch {
        return;
    };
}

pub fn ConnectionResponse(allocator: *std.mem.Allocator, stream: std.net.Stream) !void {
    const buffer = try allocator.alloc(u8, 32);
    defer allocator.free(buffer);

    const streamer = try stream.read(buffer);

    std.debug.print("{any}", .{streamer});
}

// Non-public subroutines
