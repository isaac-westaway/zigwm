const std = @import("std");

// convert an array of ascii integers into an array of characters
pub fn AsciiToText(allocator: *std.mem.Allocator, ascii: []const u8) ![]u8 {
    const ascii_string = try allocator.alloc(u8, ascii.len);
    defer allocator.free(ascii_string);

    // why do we need a 0..?
    for (ascii) |i| {
        std.debug.print("Ascii: {}\n", .{ascii[i]});
        // ascii_string. = ascii[i];
    }

    return ascii_string;
}
