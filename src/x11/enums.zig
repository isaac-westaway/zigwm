const std = @import("std");

pub const WindowAttributes = enum(u32) {
    back_pixmap = 1,
    back_pixel = 2,
    border_pixmap = 4,
    border_pixel = 8,
    bit_gravity = 16,
    win_gravity = 32,
    backing_store = 64,
    backing_planes = 128,
    backing_pixel = 256,
    override_redirect = 512,
    save_under = 1024,
    event_mask = 2048,
    dont_propagate = 4096,
    colormap = 8192,
    cursor = 16348,

    pub fn toInt(self: WindowAttributes) u32 {
        return @intFromEnum(self);
    }
};

pub const WindowClass = enum(u16) {
    copy = 0,
    input_output = 1,
    input_only = 2,

    pub fn toInt(self: WindowClass) u16 {
        return @intFromEnum(self);
    }
};

pub const Status = enum(u8) {
    Ok = 0,
    Warning = 1,
    Error = 2,
};

pub const PropertyMode = enum(u8) {
    replace,
    prepend,
    append,
};

pub const Property = union(enum) {
    int: u32,
    string: []const u8,

    /// Returns the length of the underlaying data,
    /// Note that for union Int it first converts it to a byte slice,
    /// and then returns the length of that
    fn len(self: Property) u32 {
        return switch (self) {
            .int => 4,
            .string => |array| @as(u32, array.len),
        };
    }
};

pub const GrabMode = enum(u8) {
    sync = 0,
    @"async" = 1,
};

pub const EventType = enum(u8) {
    key_press = 2,
    key_release = 3,
    button_press = 4,
    button_release = 5,
    motion_notify = 6,
    enter_notify = 7,
    leave_notify = 8,
    focus_in = 9,
    focus_out = 10,
    keymap_notify = 11,
    expose = 12,
    graphics_exposure = 13,
    no_exposure = 14,
    visiblity_notify = 15,
    create_notify = 16,
    destroy_notify = 17,
    unmap_notify = 18,
    map_notify = 19,
    map_request = 20,
    reparent_notify = 21,
    configure_notify = 22,
    configure_request = 23,
    gravity_notify = 24,
    resize_request = 25,
    circulate_notify = 26,
    circulate_request = 27,
    property_notify = 28,
    selection_clear = 29,
    selection_request = 30,
    selection_notify = 31,
    colormap_notify = 32,
    client_message = 33,
    mapping_notify = 34,
};
