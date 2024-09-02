const std = @import("std");

pub fn readString(allocator: *std.mem.Allocator, file: std.fs.File) ![]u8 {
    const stream = file.reader();

    const len = try stream.readInt(u16, .big);
    const buf = try allocator.alloc(u8, len);
    errdefer allocator.free(buf);

    try stream.readNoEof(buf);
    return buf;
}

pub fn xpad(n: usize) usize {
    return @as(usize, @bitCast((-%@as(isize, @bitCast(n))) & 3));
}
