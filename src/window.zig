const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("structs.zig");
const Enums = @import("enums.zig");
const XTypes = @import("types.zig");
const Atoms = @import("atoms.zig");
const Connection = @import("connection.zig");

fn xpad(n: usize) usize {
    return @as(usize, @bitCast((-%@as(isize, @bitCast(n))) & 3));
}

pub fn ChangeProperty(
    window: Structs.Window,
    socket: std.net.Stream,
    mode: Enums.PropertyMode,
    property: XTypes.Types.Atom,
    prop_type: Atoms.Atoms,
    data: Enums.Property,
) !void {
    const total_length = @as(u16, @sizeOf(Structs.ChangePropertyRequest) + data.len() + xpad(data.len())) / 4;

    std.debug.assert(switch (data) {
        .int => prop_type == .integer,
        .string => prop_type == .string,
    });

    const request = Structs.ChangePropertyRequest{
        .mode = @intFromEnum(mode),
        .length = total_length,
        .window = window.handle,
        .property = property,
        .prop_type = prop_type.toInt(),
        .data_len = data.len(),
    };

    try Connection.send(socket, request);
    try switch (data) {
        .int => |int| Connection.send(int),
        .string => |string| Connection.send(string),
    };
    // padding to end the data property
    try Connection.send(request.pad0[0..xpad(data.len())]) catch std.debug.print("error", .{});
}
