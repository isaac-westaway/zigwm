const std = @import("std");
const builtin = @import("builtin");

const XType = @import("types.zig");

/// basic Structs
pub const AuthInfo = struct {
    // endiannes
    family: u16 = undefined,
    address: []const u8 = undefined,
    number: []const u8 = undefined,
    name: []const u8 = undefined,
    data: []const u8 = undefined,
};

/// must stay the asme
pub const SetupRequest = extern struct {
    byte_order: u8 = if (builtin.target.cpu.arch.endian() == .big) 0x42 else 0x6c,
    pad0: u8 = 0,
    major_version: u16 = 11,
    minor_version: u16 = 0,
    name_len: u16,
    data_len: u16,
    pad1: [2]u8 = [_]u8{ 0, 0 },
};

pub const SetupGeneric = extern struct {
    status: u8,
    pad0: [5]u8,
    length: u16,
};

pub const InitialSetup = struct {
    base: u32,
    mask: u32,
    min_keycode: u8,
    max_keycode: u8,
};

pub const FullSetup = extern struct {
    release_number: u32,
    resource_id_base: u32,
    resource_id_mask: u32,
    motion_buffer_size: u32,
    vendor_len: u16,
    maximum_request_length: u16,
    roots_len: u8,
    pixmap_formats_len: u8,
    image_byte_order: u8,
    bitmap_format_bit_order: u8,
    bitmap_format_scanline_unit: u8,
    bitmap_format_scanline_pad: u8,
    min_keycode: XType.Types.Keycode,
    max_keycode: XType.Types.Keycode,
    pad1: [4]u8,
};

pub const Format = extern struct {
    depth: u8,
    bits_per_pixel: u8,
    scanline_pad: u8,
    pad0: [5]u8,
};

pub const Screen = extern struct {
    root: XType.Types.Window,
    default_colormap: u32,
    white_pixel: u32,
    black_pixel: u32,
    current_input_mask: u32,
    width_pixel: u16,
    height_pixel: u16,
    width_milimeter: u16,
    height_milimeter: u16,
    min_installed_maps: u16,
    max_installed_maps: u16,
    root_visual: XType.Types.VisualId,
    backing_store: u8,
    save_unders: u8,
    root_depth: u8,
    allowed_depths_len: u8,
};

pub const Depth = extern struct {
    depth: u8,
    pad0: u8,
    visuals_len: u16,
    pad1: [4]u8,
};

pub const VisualType = extern struct {
    visual_id: XType.Types.VisualId,
    class: u8,
    bits_per_rgb_value: u8,
    colormap_entries: u16,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    pad0: [4]u8,
};

/// Window Manager Classes
pub const XConnection = struct {
    stream: std.net.Stream,
    formats: []Format,
    screen: []Screen,

    pub fn reader(self: *XConnection) std.io.Reader(*XConnection, std.fs.File.ReadError, read) {
        return .{ .context = self };
    }

    pub fn read(self: *XConnection, buffer: []u8) std.fs.File.ReadError!usize {
        return std.posix.read(self.stream.handle, buffer);
    }
};
