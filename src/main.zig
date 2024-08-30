const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Connection = @import("connection.zig");
const Structs = @import("structs.zig");

pub fn main() !void {
    // for top level allocation
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var socket: std.net.Stream = try std.net.connectUnixSocket("/tmp/.X11-unix/X1");
    defer socket.close();

    const x_authority: std.fs.File = try std.fs.openFileAbsolute(std.posix.getenv("XAUTHORITY").?, .{});
    defer x_authority.close();

    var hostname_buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&hostname_buf);

    // for child allocators inside functions
    var heap_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    var arena_allocator = heap_arena_allocator.allocator();
    defer heap_arena_allocator.deinit();

    const auth_info = while (true) {
        const auth_info = try Connection.deserialize(Structs.AuthInfo, @constCast(&arena_allocator), x_authority);

        // ! more cookie encoding types handled here
        if (std.mem.eql(u8, auth_info.address, hostname) and std.mem.eql(u8, "MIT-MAGIC-COOKIE-1", auth_info.name)) {
            std.debug.print("Good\n", .{});

            break auth_info;
        } else {
            Connection.deallocateAllStrings(@constCast(&allocator), auth_info);
        }
    };

    // make sure authorisation uses mit magic cookies
    std.debug.print("Info: {s}\n", .{auth_info.name});
    std.debug.assert(std.mem.eql(u8, auth_info.name, "MIT-MAGIC-COOKIE-1"));

    // Initiate a setup
    const pad = [3]u8{ 0, 0, 0 };
    try Connection.send(socket, Structs.SetupRequest{
        .name_len = @intCast(auth_info.name.len),
        .data_len = @intCast(auth_info.data.len),
    });
    try Connection.send(socket, auth_info.name);
    try Connection.send(socket, pad[0..Connection.xpad(auth_info.name.len)]);
    try Connection.send(socket, auth_info.data);
    try Connection.send(socket, pad[0..Connection.xpad(auth_info.data.len)]);

    // Read the setup response
    var connection: Structs.XConnection = Structs.XConnection{
        .stream = socket,
        .formats = undefined,
        .screen = undefined,
    };
    const stream = connection.reader();

    const header = try stream.readStruct(Structs.SetupGeneric);

    const setup_buffer = try allocator.alloc(u8, header.length * 4);
    defer allocator.free(setup_buffer);

    try stream.readNoEof(setup_buffer);

    // assert a success, otherwise there is a system error
    std.debug.print("Header Status: {}\n", .{header.status});
    std.debug.assert(header.status == 1);

    // nevermind, a status code of 1 is a success
    var initial_setup: Structs.FullSetup = undefined;
    var index: usize = Connection.parseSetupType(&initial_setup, setup_buffer);

    // self
    const full_setup = Structs.InitialSetup{
        .base = initial_setup.resource_id_base,
        .mask = initial_setup.resource_id_mask,
        .min_keycode = initial_setup.min_keycode,
        .max_keycode = initial_setup.max_keycode,
    };
    _ = full_setup;

    const vendor = setup_buffer[index .. index + initial_setup.vendor_len];
    index += vendor.len;

    // ! TODO: Better Memory Management
    const formats = try arena_allocator.alloc(Structs.Format, initial_setup.pixmap_formats_len);
    // errdefer arena_allocator.free(formats);

    for (formats) |*f| {
        var format: Structs.Format = undefined;

        index += Connection.parseSetupType(&format, setup_buffer[index..]);

        f.* = .{
            .depth = format.depth,
            .bits_per_pixel = format.bits_per_pixel,
            .scanline_pad = format.scanline_pad,
            .pad0 = format.pad0,
        };
    }

    // ! TODO: Better Memory Management
    const screens = try arena_allocator.alloc(Structs.Screen, initial_setup.roots_len);
    // errdefer arena_allocator.free(screens);

    for (screens) |*s| {
        var screen: Structs.Screen = undefined;
        index += Connection.parseSetupType(&screen, setup_buffer[index..]);

        const depths = try arena_allocator.alloc(Structs.Depth, screen.allowed_depths_len);
        errdefer arena_allocator.free(depths);

        for (depths) |*d| {
            var depth: Structs.Depth = undefined;
            index += Connection.parseSetupType(&depth, setup_buffer[index..]);

            const visual_types = try arena_allocator.alloc(Structs.VisualType, depth.visuals_len);
            errdefer arena_allocator.free(visual_types);

            for (visual_types) |*t| {
                const visual_type: Structs.VisualType = undefined;
                index += Connection.parseSetupType(visual_types, setup_buffer[index..]);

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

    if (index != setup_buffer.len) {
        return error.IncorrectSetup;
    }

    connection.formats = formats;
    connection.screen = screens;

    std.debug.print("{any}\n", .{connection.screen});

    // i did it!!!
}
