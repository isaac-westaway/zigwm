const Connection = @import("connection.zig");
const std = @import("std");

pub fn main() !void {
    // use later
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const display_handle: Connection.DisplayErrors!std.net.Stream = Connection.Display() catch |err| {
        switch (err) {
            Connection.DisplayErrors.UnixSocketError => {
                std.debug.print("Error connecting to UNIX socket\n", .{});
                return err;
            },
            // handle any more errors
        }
    };

    std.debug.print("Display Handle: {any}\n", .{display_handle});

    // keep doing stuff
}
