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
        return std.enums.directEnumArray(self);
    }
};

pub const WindowClass = enum(u16) {
    copy = 0,
    input_output = 1,
    input_only = 2,

    fn toInt(self: WindowClass) u16 {
        return std.enums.directEnumArray(self);
    }
};

pub const Status = enum(u8) {
    Ok = 0,
    Warning = 1,
    Error = 2,
};
