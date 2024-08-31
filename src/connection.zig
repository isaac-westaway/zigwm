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

pub fn recv(connection: *Structs.XConnection, comptime T: type) !T {
    return connection.reader().readStruct(T);
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

pub fn parseSetup(allocator: *std.mem.Allocator, connection: *Structs.XConnection, buffer: []u8) !void {

    // nevermind, a status code of 1 is a success
    var initial_setup: Structs.FullSetup = undefined;
    var index: usize = parseSetupType(&initial_setup, buffer);

    connection.setup = Structs.InitialSetup{ .base = initial_setup.resource_id_base, .mask = initial_setup.resource_id_mask, .min_keycode = initial_setup.min_keycode, .max_keycode = initial_setup.max_keycode };

    const vendor = buffer[index .. index + initial_setup.vendor_len];
    index += vendor.len;

    // ! TODO: Better Memory Management
    const formats = try allocator.alloc(Structs.Format, initial_setup.pixmap_formats_len);
    // errdefer arena_allocator.free(formats);

    for (formats) |*f| {
        var format: Structs.Format = undefined;

        index += parseSetupType(&format, buffer[index..]);

        f.* = .{
            .depth = format.depth,
            .bits_per_pixel = format.bits_per_pixel,
            .scanline_pad = format.scanline_pad,
            .pad0 = format.pad0,
        };
    }

    // ! TODO: Better Memory Management
    const screens: []Structs.Screen = try allocator.alloc(Structs.Screen, initial_setup.roots_len);
    // errdefer arena_allocator.free(screens);

    for (screens) |*s| {
        var screen: Structs.Screen = undefined;
        index += parseSetupType(&screen, buffer[index..]);

        const depths = try allocator.alloc(Structs.Depth, screen.allowed_depths_len);
        errdefer allocator.free(depths);

        for (depths) |*d| {
            var depth: Structs.Depth = undefined;
            index += parseSetupType(&depth, buffer[index..]);

            const visual_types = try allocator.alloc(Structs.VisualType, depth.visuals_len);
            // errdefer allocator.free(visual_types);

            for (visual_types) |*t| {
                const visual_type: Structs.VisualType = undefined;
                index += parseSetupType(visual_types, buffer[index..]);

                t.* = .{
                    .visual_id = visual_type.visual_id,
                    .class = visual_type.class,
                    .bits_per_rgb_value = visual_type.bits_per_rgb_value,
                    .colormap_entries = visual_type.colormap_entries,
                    .red_mask = visual_type.red_mask,
                    .green_mask = visual_type.green_mask,
                    .blue_mask = visual_type.blue_mask,
                    .pad0 = visual_type.pad0,
                };
            }

            d.* = .{
                .depth = depth.depth,
                .pad0 = depth.pad0,
                .visuals_len = depth.visuals_len,
                // ! .visual_types = visual_types,
                .pad1 = depth.pad1,
            };
        }

        s.* = .{
            .root = screen.root,
            .default_colormap = screen.default_colormap,
            .white_pixel = screen.white_pixel,
            .black_pixel = screen.black_pixel,
            .current_input_mask = screen.current_input_mask,
            .width_pixel = screen.width_pixel,
            .height_pixel = screen.height_pixel,
            .width_milimeter = screen.width_milimeter,
            .height_milimeter = screen.height_milimeter,
            .min_installed_maps = screen.min_installed_maps,
            .max_installed_maps = screen.max_installed_maps,
            .root_visual = screen.root_visual,
            .backing_store = screen.backing_store,
            .save_unders = screen.save_unders,
            .root_depth = screen.root_depth,
            .allowed_depths_len = screen.allowed_depths_len,
            // ! .depths = depths,
        };
    }

    if (index != buffer.len) {
        return error.IncorrectSetup;
    }

    connection.formats = formats;
    connection.screens = screens;
}

pub fn genXId(connection: *Structs.XConnection, socket: std.net.Stream, xid: Structs.XId) !u32 {
    var ret: u32 = 0;

    if (connection.status != .Ok) {
        return error.InvalidConnection;
    }

    var modifiable_xid: Structs.XId = xid;

    const temp = modifiable_xid.max -% modifiable_xid.inc;
    if (modifiable_xid.last >= temp) {
        if (modifiable_xid.last == 0) {
            modifiable_xid.max = connection.setup.mask;
            std.debug.print("Max if Zero: {any}\n", .{modifiable_xid.max});
        } else {
            // ! extension handling
            // ! for the purposes of this simple { :( } window manager do not bother

            try send(socket, Structs.IdRangeRequest{});

            const reply = try recv(@constCast(connection), Structs.IdRangeReply);

            std.debug.print("Modifiable XID:{any}\n", .{modifiable_xid.inc});

            modifiable_xid.last = reply.start_id;
            modifiable_xid.max = reply.start_id + (reply.count - 1) * modifiable_xid.inc;
        }
    } else {
        modifiable_xid.last += modifiable_xid.inc;
    }

    // std.debug.print("{}", .{modifiable_xid});
    std.debug.print("Last: {any}", .{modifiable_xid.last});
    std.debug.print("Base: {any}", .{modifiable_xid.base});

    ret = modifiable_xid.last | modifiable_xid.base | modifiable_xid.max;
    return ret;
}
