pub const SetupRequest = extern struct {
    byte_order: u8 = 0x6C,
    pad: u8 = 0,
    major_version: u16 = 11,
    minor_version: u16 = 0,
    // authorization_protocol_name: []u8 = "mit-magic-cookie-1",
    // authorization_protocol_data: [18]u8 = "designed to error",
};
