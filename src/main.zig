const Connection = @import("connection.zig");
const std = @import("std");

pub fn main() !void {
    const page_alloc = std.heap.page_allocator;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const home = try std.process.getEnvVarOwned(gpa.allocator(), "HOME");
    defer gpa.allocator().free(home);

    var dir = try std.fs.cwd().openDir(home, .{});
    defer dir.close();

    const xau = try dir.openFile(".Xauthority", .{});
    defer xau.close();

    // const stream = &xau.reader();
    // const data = try stream.readInt([]u8, .little);

    // std.debug.print("{any}", .{data});

    var connection: Connection.Connection = Connection.Connection{
        .stream = undefined,
        .gpa = @constCast(&gpa.allocator()),
    };

    connection.stream = Connection.Display() catch |err| {
        switch (err) {
            Connection.DisplayErrors.UnixSocketError => {
                std.debug.print("Error connecting to UNIX socket\n", .{});
                return err;
            },
            // handle any more errors
        }
    };
    errdefer connection.stream.close();

    std.debug.print("Successfully Connected {any}\n", .{connection.stream});

    _ = Connection.ConnectionSetup(connection.stream) catch |err| {
        switch (err) {
            Connection.ConnectionErrors.InvalidSetupResponse => {
                std.debug.print("Something went wrong setting up", .{});

                return err;
            },
            Connection.ConnectionErrors.StreamError => {
                std.debug.print("Something went wrong setting up", .{});

                return err;
            },
            Connection.ConnectionErrors.UnableToConnect => {
                std.debug.print("Something went wrong setting up", .{});

                return err;
            },
        }
    };

    _ = Connection.ConnectionResponse(@constCast(&page_alloc), connection.stream) catch {
        return;
    };

    // initialize connection setup
}
