const std = @import("std");

const x11 = @import("x11.zig");

pub const Connection = struct {
    stream: DisplayErrors!std.net.Stream,
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
    errdefer stream.close();

    std.debug.print("Connected successfully: {}\n", .{stream});

    return stream;
}

// read contents of .XAuthority and pass it in
pub fn ConnectionSetup(stream: std.net.Stream, auth: []u8) ConnectionErrors!void {
    stream.writeAll(x11.SetupRequest{
        .authorization_protocol_data = auth,
    });
}

// Non-public subroutines
