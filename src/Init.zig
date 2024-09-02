const std = @import("std");

const Utils = @import("x11/utils.zig");

pub const XInit = struct {
    auth_info: AuthInfo,

    allocator: std.mem.Allocator,

    pub const AuthInfo = struct {
        // endiannes
        family: u16 = undefined,
        address: []const u8 = undefined,
        number: []const u8 = undefined,
        name: []const u8 = undefined,
        data: []const u8 = undefined,
    };

    fn deallocateAllStrings(allocator: *std.mem.Allocator, Struct: anytype) void {
        inline for (comptime @typeInfo(@TypeOf(Struct)).Struct.fields) |field| {
            // TODO: type []const u8
            if (comptime @typeInfo(field.type) != .Int) {
                allocator.free(@field(Struct, field.name));
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

    pub fn init(self: *XInit, x_authority: std.fs.File, hostname: []u8, arena_allocator: std.mem.Allocator) !void {
        // pass in arean allocator as an argument
        std.log.scoped(.XInit_init).info("Beginning XInit initalization", .{});

        while (true) {
            const x_auth: AuthInfo = try XInit.deserialize(XInit.AuthInfo, @constCast(&arena_allocator), x_authority);

            if (std.mem.eql(u8, x_auth.address, hostname) and std.mem.eql(u8, "MIT-MAGIC-COOKIE-1", x_auth.name)) {
                std.log.scoped(.XInit_init_while).info("Successfully found authentication address and matched authentication encoding", .{});

                self.auth_info = x_auth;

                break;
            } else {
                std.log.scoped(.XInit_init_while).err("Unable to verify authenication encoding", .{});

                XInit.deallocateAllStrings(@constCast(&self.allocator), x_auth);
            }
        }

        std.log.scoped(.XInit_init).info("Completed initialization", .{});
        std.log.scoped(.XInit_init_auth_info).info("AuthInfo.address: {s}", .{self.auth_info.address});
        std.log.scoped(.XInit_init_auth_info).info("AuthInfo.address: {s}", .{self.auth_info.number});
        std.log.scoped(.XInit_init_auth_info).info("AuthInfo.address: {s}", .{self.auth_info.name});
        std.log.scoped(.XInit_init_auth_info).info("AuthInfo.address: {s}", .{self.auth_info.data});
    }
};
