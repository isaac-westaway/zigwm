const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("x11/structs.zig");
const Enums = @import("x11/enums.zig");
const XTypes = @import("x11/types.zig");
const Atoms = @import("x11/atoms.zig");
const Utils = @import("x11/utils.zig");

const XConnection = @import("Connection.zig").XConnection;
const XInit = @import("Init.zig").XInit;

pub const XWindow = struct {
    handle: u32,
    connection: XConnection,

    pub fn changeProperty(
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

    pub fn changeAttributes(self: *const XWindow, values: []const Structs.ValueMask) !void {
        const mask: u32 = blk: {
            var tmp: u32 = 0;
            for (values) |val| tmp |= val.mask.toInt();
            break :blk tmp;
        };

        try self.connection.send(Structs.ChangeWindowAttributes{ .length = @sizeOf(Structs.ChangeWindowAttributes) / 4 + @as(u16, @intCast(values.len)), .window = self.handle, .mask = mask });
        for (values) |val| try self.connection.send(val.value);
    }

    pub fn map(self: *const XWindow) !void {
        try self.connection.send(Structs.MapWindowRequest{ .window = self.handle });
    }

    pub fn configure(self: XWindow, mask: Structs.WindowConfigMask, config: Structs.WindowChanges) !void {
        try self.connection.send(
            Structs.ConfigureWindowRequest{
                .length = @sizeOf(Structs.ConfigureWindowRequest) / 4 + Structs.maskLen(mask),
                .window = self.handle,
                .mask = mask.toInt(),
            },
        );

        inline for (std.meta.fields(Structs.WindowConfigMask)) |field| {
            if (@TypeOf(field) == bool and @field(mask, field.name)) {
                //@compileLog(@typeInfo(@TypeOf(@field(config, field.name))).Int);
                if (@typeInfo(@TypeOf(@field(config, field.name))).Int.signedness == .signed) {
                    try self.connection.send(@as(i32, @field(config, field.name)));
                } else {
                    try self.connection.send(@as(u32, @field(config, field.name)));
                }
            }
        }
    }

    pub fn inputFocus(self: *const XWindow) !void {
        try self.connection.send(Structs.SetInputFocusRequest{
            .window = self.handle,
            .time_stamp = 0,
            .revert_to = 1,
        });
    }

    pub fn initializeRootWindow(self: *XWindow) !void {

        // access the connection root integer (it is the windowID) and use it to craete windows
        const options: Structs.CreateWindowOptions = comptime Structs.CreateWindowOptions{
            .width = 750,
            .height = 600,
        };

        const mask: u32 = blk: {
            var tmp: u32 = 0;
            for (options.values) |val| tmp |= val.mask.toInt();
            break :blk tmp;
        };

        const window_request = Structs.CreateWindowRequest{
            .length = @sizeOf(Structs.CreateWindowRequest) / 4 + @as(u16, options.values.len),
            .wid = self.handle,
            .parent = self.connection.screens[0].root,
            .width = options.width,
            .height = options.height,
            .visual = self.connection.screens[0].root_visual,
            .value_mask = mask,
            .border_width = 10,
            .class = options.class.toInt(),
        };

        try self.connection.send(window_request);
        for (options.values) |val| {
            try self.connection.send(val.value);
        }

        // std.debug.print("Window: {any}", .{self});
        if (options.title) |title| {
            try changeProperty(self.connection.stream, .replace, Atoms.Atoms.wm_name, Atoms.Atoms.string, .{ .string = title });
        }

        try self.map();
    }
};
