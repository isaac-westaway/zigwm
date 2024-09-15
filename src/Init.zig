const std = @import("std");

const Utils = @import("x11/utils.zig");
const Structs = @import("x11/structs.zig");

const Logger = @import("Log.zig");

pub const XInit = struct {
    allocator: std.mem.Allocator,

    x_authority: std.fs.File,
    x_auth_info: Structs.AuthInfo,

    // const self as it does not modify itself
    pub fn deallocateAllStrings(self: *const XInit, Struct: anytype) void {
        inline for (comptime @typeInfo(@TypeOf(Struct)).Struct.fields) |field| {
            // TODO: type []const u8
            if (comptime @typeInfo(field.type) != .Int) {
                self.allocator.free(@field(Struct, field.name));
            }
        }
    }

    fn deserialize(comptime Struct: type, allocator: *std.mem.Allocator, file: std.fs.File) !Struct {
        const reader = file.reader();

        var auth_info = Struct{};
        inline for (@typeInfo(Struct).Struct.fields) |field| {
            @field(auth_info, field.name) = brk: {
                if (comptime @typeInfo(field.type) == .Int) {
                    break :brk try reader.readInt(field.type, .big);

                    // TODO: fix to check u8 const []
                } else if (comptime @typeInfo(field.type) != .Int) {
                    break :brk try Utils.readString(allocator, file);
                } else {
                    @compileError("Unknown field type");
                }
            };
        }

        return auth_info;
    }

    // TODO: add an error union
    pub fn init(self: *XInit, x_authority: std.fs.File, hostname: []u8, arena_allocator: std.mem.Allocator) !void {
        // TODO: fix pass in arean allocator as an argument
        try Logger.Log.info("ZWM_INIT_XINIT_INIT", "Begginning X initialization process");

        while (true) {
            const x_auth: Structs.AuthInfo = try XInit.deserialize(Structs.AuthInfo, @constCast(&arena_allocator), x_authority);

            if (std.mem.eql(u8, x_auth.address, hostname) and std.mem.eql(u8, "MIT-MAGIC-COOKIE-1", x_auth.name)) {
                try Logger.Log.info("ZWM_INIT_XINIT_INIT", "Successfully verified XAuthority contents");
                self.x_auth_info = x_auth;

                break;
            } else {
                try Logger.Log.warn("ZWM_INIT_XINIT_INIT", "Unable to verify XAuthority contents");
                self.x_auth_info = x_auth;

                // Do not fail as this is NOT an error, just an unhandled encoding, not MIT-MAGIC-COOKIE-1
                // XInit.deallocateAllStrings(x_auth);
            }
        }

        // std.log.scoped(.XInit_init).info("Completed initialization", .{});
        try Logger.Log.info("ZWM_INIT_XINIT_INIT", "Completed Initialization");
    }
};
