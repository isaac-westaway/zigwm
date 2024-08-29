const Connection = @import("connection.zig");
const std = @import("std");
const utils = @import("utils.zig");

pub fn main() !void {
    const page = std.heap.page_allocator;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // error handling for correct types
    const current_user = std.process.getEnvVarOwned(page, "USER") catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };

    // Convert the result into an array of u8
    const text: []u8 = current_user;

    const new = utils.AsciiToText(@constCast(&page), text);

    std.debug.print("user: {any}\n", .{new});

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

    // try Connection.ConnectionSetup(connection.stream) catch |err| {
    //     switch (err) {
    //         Connection.ConnectionErrors.InvalidSetupResponse => {
    //             std.debug.print("Something went wrong setting up");

    //             return err;
    //         },
    //     }
    // };

    // initialize connection setup
}
