const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("structs.zig");

// what is this magic?
pub fn xpad(n: usize) usize {
    return @as(usize, @bitCast((-%@as(isize, @bitCast(n))) & 3));
}

pub fn send(stream: std.net.Stream, data: anytype) !void {
    const dataType = @TypeOf(data);

    switch (dataType) {
        []u8, []const u8 => {
            std.debug.print("Sending strings \n", .{});
            try stream.writeAll(data);
        },
        else => {
            std.debug.print("Sending bytes \n", .{});
            try stream.writeAll(std.mem.asBytes(&data));
        },
    }
}

pub fn readString(allocator: *std.mem.Allocator, file: std.fs.File) ![]u8 {
    const stream = file.reader();

    const len = try stream.readInt(u16, .big);
    const buf = try allocator.alloc(u8, len);
    errdefer allocator.free(buf);

    try stream.readNoEof(buf);
    return buf;
}

pub fn deallocateAllStrings(allocator: *std.mem.Allocator, Struct: anytype) void {
    inline for (comptime @typeInfo(@TypeOf(Struct)).Struct.fields) |field| {
        // TODO: type []const u8
        if (comptime @typeInfo(field.type) != .Int) {
            allocator.free(@field(Struct, field.name));
        }
    }
}

pub fn deserialize(comptime Struct: type, allocator: *std.mem.Allocator, file: std.fs.File) !Struct {
    const reader = file.reader();

    var auth_info = Struct{};
    inline for (@typeInfo(Struct).Struct.fields) |field| {
        @field(auth_info, field.name) = brk: {
            if (comptime @typeInfo(field.type) == .Int) {
                break :brk try reader.readInt(field.type, .big);

                // TODO: fix to check u8 const []
            } else if (comptime @typeInfo(field.type) != .Int) {
                break :brk try readString(allocator, file);
            } else {
                @compileError("Unknown field type");
            }
        };
    }

    return auth_info;
}

// this is also magic
pub fn parseSetupType(wanted: anytype, buffer: []u8) usize {
    std.debug.assert(@typeInfo(@TypeOf(wanted)) == .Pointer);
    var size: usize = 0;

    var new = @constCast(wanted);

    if (@TypeOf(new) == []Structs.VisualType) {
        size = @sizeOf(@TypeOf(new[0]));
        new = std.mem.bytesToValue(@TypeOf(new), buffer[0..size]);
    } else {
        size = @sizeOf(@TypeOf(new.*));
        new.* = std.mem.bytesToValue(@TypeOf(new.*), buffer[0..size]);
    }

    return size;
}
