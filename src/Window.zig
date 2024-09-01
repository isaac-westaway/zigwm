const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("structs.zig");
const Enums = @import("enums.zig");
const XTypes = @import("types.zig");
const Atoms = @import("atoms.zig");

const XConnection = @import("Connection.zig").XConnection;
const XInit = @import("Init.zig").XInit;
const Utils = @import("utils.zig");

pub const XWindow = struct {
    handle: u32,
    connection: XConnection,

    pub fn ChangeProperty(
        self: *XWindow,
        socket: std.net.Stream,
        mode: Enums.PropertyMode,
        property: XTypes.Types.Atom,
        prop_type: Atoms.Atoms,
        data: Enums.Property,
    ) !void {
        const total_length = @as(u16, @sizeOf(Structs.ChangePropertyRequest) + data.len() + Utils.xpad(data.len())) / 4;

        std.debug.assert(switch (data) {
            .int => prop_type == .integer,
            .string => prop_type == .string,
        });

        const request = Structs.ChangePropertyRequest{
            .mode = @intFromEnum(mode),
            .length = total_length,
            .window = self.handle,
            .property = property,
            .prop_type = prop_type.toInt(),
            .data_len = data.len(),
        };

        try self.connection.send(socket, request);
        try switch (data) {
            .int => |int| self.connection.send(int),
            .string => |string| self.connection.send(string),
        };
        // padding to end the data property
        try self.connection.send(request.pad0[0..Utils.xpad(data.len())]) catch std.debug.print("error", .{});
    }

    pub fn map(self: *XWindow) !void {
        try self.connection.send(Structs.MapWindowRequest{ .window = self.handle });
    }
};
