const std = @import("std");
const builtin = @import("builtin");

const XType = @import("types.zig");
const Enums = @import("enums.zig");

// ! TODO: Should NOT be here
pub fn maskLen(mask: anytype) u16 {
    const T = @TypeOf(mask);
    std.debug.assert(@typeInfo(T) == .Struct);

    var len: u16 = 0;
    inline for (std.meta.fields(T)) |field| {
        if (@TypeOf(field) == bool and @field(mask, field.name)) len += 1;
    }
    return len;
}

/// basic Structs
pub const ValueMask = struct {
    mask: Enums.WindowAttributes,
    value: u32,
};

pub const AuthInfo = struct {
    // endiannes
    family: u16 = undefined,
    address: []const u8 = undefined,
    number: []const u8 = undefined,
    name: []const u8 = undefined,
    data: []const u8 = undefined,
};

/// Configure Windows
pub const WindowChanges = struct {
    x: i16 = 0,
    y: i16 = 0,
    width: u16 = 0,
    height: u16 = 0,
    border_width: u16 = 0,
    sibling: XType.Types.Window = 0,
    stack_mode: u8 = 0,
};

pub const CreateWindowOptions = struct {
    width: u16,
    height: u16,
    title: ?[]const u8 = null,
    class: Enums.WindowClass = .copy,
    values: []const ValueMask = &[_]ValueMask{},
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

pub const SetInputFocusRequest = extern struct {
    major_opcode: u8 = 42,
    revert_to: u8,
    length: u16 = @sizeOf(SetInputFocusRequest) / 4,
    window: XType.Types.Window,
    time_stamp: u32,
};

pub const WindowConfigMask = packed struct {
    x: bool = false,
    y: bool = false,
    width: bool = false,
    height: bool = false,
    border_width: bool = false,
    sibling: bool = false,
    stack_mode: bool = false,
    pad: u9 = 0,

    pub fn toInt(self: WindowConfigMask) u16 {
        return @bitCast(self);
    }
};

pub const ChangeWindowAttributes = extern struct {
    major_opcode: u8 = 2,
    pad0: u8 = 0,
    length: u16,
    window: XType.Types.Window,
    mask: u32,
};

pub const InputDeviceEvent = extern struct {
    code: u8,
    detail: XType.Types.Keycode,
    sequence: u16,
    time: u32,
    root: XType.Types.Window,
    event: XType.Types.Window,
    child: XType.Types.Window,
    root_x: i16,
    root_y: i16,
    event_x: i16,
    event_y: i16,
    state: u16,
    same_screen: u8,
    pad: u8,

    pub fn sameScreen(self: InputDeviceEvent) bool {
        return self.same_screen == 1;
    }
};

pub const ConfigureWindowRequest = extern struct {
    major_opcode: u8 = 12,
    pad: u8 = 0,
    length: u16,
    window: XType.Types.Window,
    mask: u16,
    pad1: [2]u8 = [_]u8{ 0, 0 },
};

pub const UngrabKeyRequest = extern struct {
    major_opcode: u8 = 34,
    key: XType.Types.Keycode,
    length: u16 = @sizeOf(UngrabKeyRequest) / 4, // 3
    window: XType.Types.Window,
    modifiers: u16,
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

pub const KeyboardMappingRequest = extern struct {
    major_opcode: u8 = 101,
    pad: u8 = 0,
    length: u16 = @sizeOf(KeyboardMappingRequest) / 4,
    first_keycode: XType.Types.Keycode,
    count: u8,
    pad1: [2]u8 = [_]u8{ 0, 0 },
};

pub const GrabButtonRequest = extern struct {
    major_opcode: u8 = 28,
    owner_events: u8,
    length: u16 = @sizeOf(GrabButtonRequest) / 4, // 6
    grab_window: XType.Types.Window,
    event_mask: u16,
    pointer_mode: u8,
    keyboard_mode: u8,
    confine_to: XType.Types.Window,
    cursor: XType.Types.Cursor,
    button: u8,
    pad0: u8 = 0,
    modifiers: u16,
};

pub const UngrabButtonRequest = extern struct {
    major_opcode: u8 = 29,
    button: u8,
    length: u16 = @sizeOf(UngrabButtonRequest) / 4, // 3
    window: XType.Types.Window,
    modifiers: u16,
};

pub const GrabKeyRequest = extern struct {
    major_opcode: u8 = 33,
    owner_events: u8,
    length: u16 = @sizeOf(GrabKeyRequest) / 4, // 4
    grab_window: XType.Types.Window,
    modifiers: u16,
    key: XType.Types.Keycode,
    pointer_mode: u8,
    keyboard_mode: u8,
    pad: [3]u8 = [_]u8{0} ** 3,
};

pub const KeyboardMappingReply = extern struct {
    response_type: u8,
    keysyms_per_keycode: u8,
    sequence: u16,
    length: u32,
    pad: [24]u8,
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

pub const CreateWindowRequest = extern struct {
    major_opcode: u8 = 1,
    depth: u8 = 0,
    length: u16,
    wid: XType.Types.Window,
    parent: XType.Types.Window,
    x: i16 = 0,
    y: i16 = 0,
    width: u16,
    height: u16,
    border_width: u16 = 0,
    class: u16 = 0,
    visual: XType.Types.Window,
    value_mask: u32,
};

pub const MapWindowRequest = extern struct {
    major_opcode: u8 = 8,
    pad0: u8 = 0,
    length: u16 = @sizeOf(MapWindowRequest) / 4,
    window: XType.Types.Window,
};

pub const IdRangeRequest = extern struct {
    major_opcode: u8 = 136,
    minor_opcode: u8 = 1,
    length: u16 = 1,
};

pub const IdRangeReply = extern struct {
    response_type: u8,
    pad0: u8,
    sequence: u16,
    length: u32,
    start_id: u32,
    count: u32,
    pad1: [16]u8,
};

pub const ChangePropertyRequest = extern struct {
    major_opcode: u8 = 18,
    mode: u8,
    length: u16,
    window: XType.Types.Window,
    property: XType.Types.Atom,
    prop_type: XType.Types.Atom,
    format: u8 = 8, // by default make our slices into bytes
    pad0: [3]u8 = [_]u8{0} ** 3,
    data_len: u32,
};
