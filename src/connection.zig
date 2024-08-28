const std = @import("std");

// const Connection = @This();

pub const DisplayErrors = error{
    UnixSocketError,
};

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
