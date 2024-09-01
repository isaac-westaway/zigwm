const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const Structs = @import("structs.zig");

const XConnection = @import("Connection.zig").XConnection;

pub const XId = struct {
    last: u32,
    max: u32,
    base: u32,
    inc: u32,

    pub fn genXId(
        self: *XId,
        connection: *XConnection,
    ) !u32 {
        var ret: u32 = 0;

        if (connection.status != .Ok) {
            return error.InvalidConnection;
        }

        var modifiable_xid: XId = self.*;

        const temp = modifiable_xid.max -% modifiable_xid.inc;
        if (modifiable_xid.last >= temp) {
            if (modifiable_xid.last == 0) {
                modifiable_xid.max = connection.setup.mask;
                // std.debug.print("Max if Zero: {any}\n", .{modifiable_xid.max});
            } else {
                // ! extension handling
                // ! for the purposes of this simple { :( } window manager do not bother

                try connection.send(Structs.IdRangeRequest{});

                const reply = try connection.recv(Structs.IdRangeReply);

                // std.debug.print("Modifiable XID:{any}\n", .{modifiable_xid.inc});

                modifiable_xid.last = reply.start_id;
                modifiable_xid.max = reply.start_id + (reply.count - 1) * modifiable_xid.inc;
            }
        } else {
            modifiable_xid.last += modifiable_xid.inc;
        }

        ret = modifiable_xid.last | modifiable_xid.base | modifiable_xid.max;
        return ret;
    }

    // does not error
    pub fn init(self: *XId, connection: XConnection) !void {
        // we could use @setRuntimeSafety(false) in this case
        const inc: u32 = connection.setup.mask & ~connection.setup.mask;
        self.last = 0;
        self.max = 0;
        self.base = connection.setup.base;
        self.inc = @as(u32, inc);
    }
};
