const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("x11/structs.zig");
const Enums = @import("x11/enums.zig");
const Utils = @import("x11/utils.zig");

const XInit = @import("Init.zig").XInit;

const Logger = @import("Log.zig");

pub const XConnection = struct {
    allocator: std.mem.Allocator,
    stream: std.net.Stream,
    formats: []Structs.Format,
    screens: []Structs.Screen,
    setup: Structs.InitialSetup,
    status: Enums.Status,

    // ? Entering manager

    // this is also magic
    fn parseSetupType(wanted: anytype, buffer: []u8) usize {
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

    fn parseSetup(self: *XConnection, allocator: *std.mem.Allocator, buffer: []u8) !void {
        var initial_setup: Structs.FullSetup = undefined;
        var index: usize = parseSetupType(&initial_setup, buffer);

        self.setup = Structs.InitialSetup{ .base = initial_setup.resource_id_base, .mask = initial_setup.resource_id_mask, .min_keycode = initial_setup.min_keycode, .max_keycode = initial_setup.max_keycode };

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

        self.formats = formats;
        self.screens = screens;

        // std.log.scoped(.XConnection_parseSetup).info("Completed setup parsing, returning", .{});
    }

    pub fn recv(self: *XConnection, comptime T: type) !T {
        return self.stream.reader().readStruct(T);
    }

    pub fn send(self: *XConnection, data: anytype) !void {
        const dataType = @TypeOf(data);

        switch (dataType) {
            []u8, []const u8 => {
                try self.stream.writeAll(data);
            },
            else => {
                try self.stream.writeAll(std.mem.asBytes(&data));
            },
        }
    }

    // TODO: Logging
    pub fn initiateConnection(self: *XConnection, x_init: XInit, arena_allocator: *std.mem.Allocator) !void {
        try Logger.Log.info("ZWM_INIT_XCONNECTION_INITIATECONNECTION", "Beginning connection initiation process");
        const pad = [3]u8{ 0, 0, 0 };

        try self.send(Structs.SetupRequest{
            .name_len = @intCast(x_init.x_auth_info.name.len),
            .data_len = @intCast(x_init.x_auth_info.data.len),
        });

        try self.send(x_init.x_auth_info.name);

        try self.send(pad[0..Utils.xpad(x_init.x_auth_info.name.len)]);

        try self.send(x_init.x_auth_info.data);

        try self.send(pad[0..Utils.xpad(x_init.x_auth_info.data.len)]);

        const stream = self.stream.reader();

        const header: Structs.SetupGeneric = try stream.readStruct(Structs.SetupGeneric);
        // const Logger.Log.debug

        const setup_buffer: []u8 = try self.allocator.alloc(u8, header.length * 4);
        defer self.allocator.free(setup_buffer);

        try stream.readNoEof(setup_buffer);
        if (header.status == 1) {
            self.status = .Ok;
            try Logger.Log.info("ZWM_INIT_XCONNECTION_INITIATECONNECTION", "XServer response OK");
        } else if (header.status == 0) {
            // TODO: handle these errors
            self.status = .Error;
            try Logger.Log.err("ZWM_INIT_XCONNECTION_INITIATECONNECTION", "XServer failed to read setup request");
        } else {
            // TODO: Handle further authentication
            self.status = .Warning;
            try Logger.Log.warn("ZWM_INIT_XCONNECTION_INITIATECONNECTION", "Further authentication required");
        }

        try self.parseSetup(@constCast(&arena_allocator.*), setup_buffer);
        try Logger.Log.info("ZWM_INIT_XCONNECTION_INITIATECONNECTION", "Completed connection initiation");
        return;
    }
};
