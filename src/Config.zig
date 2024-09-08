/// Config, under run method
/// Copied and pasted from juuicebox
const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

const ZWM = @import("ZWM.zig");
const Actions = @import("Actions.zig");

const Keys = @import("x11/keys.zig");
const Input = @import("x11/input.zig");
const Structs = @import("x11/structs.zig");
const XTypes = @import("x11/types.zig");

pub const Action = union(ActionType) {
    function: struct { action: fn (*ZWM, u4) void, arg: @TypeOf(void) },
    cmd: []const []const u8,

    pub const ActionType = enum { function, cmd };
};

pub const KeyBind = struct {
    symbol: XTypes.Types.Keysym,
    modifier: Input.Modifiers = Input.Modifiers.any,
    action: Action,
};

pub const Keybindings = []const KeyBind;

pub const Config = struct {
    /// Lost of keybindings
    border_width: ?u16 = null,
    gaps: ?GapOptions = null,
    bindings: Keybindings,
    border_color_unfocused: u32 = 0x34bdeb,
    border_color_focused: u32 = 0x014c82,
    workspaces: u4 = 10,
};

pub const GapOptions = struct {
    left: u16 = 0,
    right: u16 = 0,
    top: u16 = 0,
    bottom: u16 = 0,
};

pub const default_config: Config = Config{
    .border_width = 1,
    .gaps = .{ .left = 4, .right = 4, .top = 4, .bottom = 4 },
    .bindings = &[_]KeyBind{
        // .{
        //     .symbol = Keys.XK_q,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.closeWindow, .arg = undefined } },
        // },
        .{
            // dmenu command
            .symbol = Keys.XK_d,
            .modifier = .{ .mod4 = true },
            .action = .{ .cmd = &[_][]const u8{"d_menu run"} },
        },
        // .{
        //     .symbol = Keys.XK_f,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.toggleFullscreen, .arg = undefined } },
        // },
        .{
            // terminal
            .symbol = Keys.XK_Return,
            .modifier = .{ .mod4 = true },
            .action = .{ .cmd = &[_][]const u8{"kitty"} },
        },
        // .{
        //     .symbol = Keys.XK_1,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 0)) } },
        // },
        // .{
        //     .symbol = Keys.XK_2,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 1)) } },
        // },
        // .{
        //     .symbol = Keys.XK_3,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 2)) } },
        // },
        // .{
        //     .symbol = Keys.XK_4,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 3)) } },
        // },
        // .{
        //     .symbol = Keys.XK_5,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 4)) } },
        // },
        // .{
        //     .symbol = Keys.XK_6,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 5)) } },
        // },
        // .{
        //     .symbol = Keys.XK_7,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 6)) } },
        // },
        // .{
        //     .symbol = Keys.XK_8,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 7)) } },
        // },
        // .{
        //     .symbol = Keys.XK_9,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 8)) } },
        // },
        // .{
        //     .symbol = Keys.XK_0,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.switchWorkspace, .arg = @TypeOf(@as(u4, 9)) } },
        // },
        // .{
        //     .symbol = Keys.XK_1,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 0)) } },
        // },
        // .{
        //     .symbol = Keys.XK_2,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 1)) } },
        // },
        // .{
        //     .symbol = Keys.XK_3,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 2)) } },
        // },
        // .{
        //     .symbol = Keys.XK_4,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 3)) } },
        // },
        // .{
        //     .symbol = Keys.XK_5,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 4)) } },
        // },
        // .{
        //     .symbol = Keys.XK_6,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 5)) } },
        // },
        // .{
        //     .symbol = Keys.XK_7,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 6)) } },
        // },
        // .{
        //     .symbol = Keys.XK_8,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 7)) } },
        // },
        // .{
        //     .symbol = Keys.XK_9,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 8)) } },
        // },
        // .{
        //     .symbol = Keys.XK_0,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.moveWindow, .arg = @TypeOf(@as(u4, 9)) } },
        // },
        // .{
        //     .symbol = Keys.XK_Right,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.swapWindow, .arg = @TypeOf(@Type(.right)) } },
        // },
        // .{
        //     .symbol = Keys.XK_Left,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.swapWindow, .arg = .left } },
        // },
        // .{
        //     .symbol = Keys.XK_Up,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.swapWindow, .arg = .up } },
        // },
        // .{
        //     .symbol = Keys.XK_Down,
        //     .modifier = .{ .mod4 = true, .shift = true },
        //     .action = .{ .function = .{ .action = Actions.swapWindow, .arg = .down } },
        // },
        // .{
        //     .symbol = Keys.XK_Right,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.swapFocus, .arg = .right } },
        // },
        // .{
        //     .symbol = Keys.XK_Left,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.swapFocus, .arg = .left } },
        // },
        // .{
        //     .symbol = Keys.XK_Up,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.swapFocus, .arg = .up } },
        // },
        // .{
        //     .symbol = Keys.XK_Down,
        //     .modifier = .{ .mod4 = true },
        //     .action = .{ .function = .{ .action = Actions.swapFocus, .arg = .down } },
        // },
    },
};
