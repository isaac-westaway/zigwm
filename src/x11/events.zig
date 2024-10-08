const std = @import("std");

const Enums = @import("enums.zig");
const Structs = @import("structs.zig");
const XTypes = @import("types.zig");

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

pub const Mask = packed struct {
    key_press: bool = false,
    key_release: bool = false,
    button_press: bool = false,
    button_release: bool = false,
    enter_window: bool = false,
    leave_window: bool = false,
    pointer_motion: bool = false,
    pointer_motion_hint: bool = false,
    button_1_motion: bool = false,
    button_2_motion: bool = false,
    button_3_motion: bool = false,
    button_4_motion: bool = false,
    button_5_motion: bool = false,
    button_motion: bool = false,
    keymap_state: bool = false,
    exposure: bool = false,
    visibility_change: bool = false,
    structure_notify: bool = false,
    resize_redirect: bool = false,
    substructure_notify: bool = false,
    substructure_redirect: bool = false,
    focus_change: bool = false,
    property_change: bool = false,
    color_map_change: bool = false,
    owwner_grab_button: bool = false,
    padding: u7 = 0,

    pub fn toInt(self: @This()) u32 {
        return @bitCast(self);
    }
};

pub const Event = union(Enums.EventType) {
    key_press: InputDeviceEvent,
    key_release: InputDeviceEvent,
    button_press: InputDeviceEvent,
    button_release: InputDeviceEvent,
    motion_notify: InputDeviceEvent,
    enter_notify: PointerWindowEvent,
    leave_notify: PointerWindowEvent,
    focus_in: InputFocusEvent,
    focus_out: InputFocusEvent,
    keymap_notify: KeymapEvent,
    expose: ExposeEvent,
    graphics_exposure: GraphicsExposeEvent,
    no_exposure: NoExposureEvent,
    visiblity_notify: VisibilityEvent,
    create_notify: CreateEvent,
    destroy_notify: DestroyEvent,
    unmap_notify: UnmapEvent,
    map_notify: MapEvent,
    map_request: MapRequest,
    reparent_notify: ReparentEvent,
    configure_notify: ConfigureEvent,
    configure_request: ConfigureRequest,
    gravity_notify: GravityEvent,
    resize_request: ResizeRequestEvent,
    circulate_notify: CirculateEvent,
    circulate_request: CirculateRequestEvent,
    property_notify: PropertyEvent,
    selection_clear: SelectionClearEvent,
    selection_request: SelectionRequestEvent,
    selection_notify: SelectionEvent,
    colormap_notify: ColormapEvent,
    client_message: ClientMessageEvent,
    mapping_notify: MappingEvent,

    /// Creates an `Event` union from the given bytes and
    /// asserts the first byte value is between 1 and 35 (exclusive).
    /// Note: The Event is copied from the bytes and does not own its memory
    pub fn fromBytes(bytes: [32]u8) Event {
        const response_type = bytes[0];
        std.debug.assert(response_type > 1 and response_type < 35);

        const event_type: EventType = @enumFromInt(response_type);
        const toEvent = std.mem.bytesToValue;

        return switch (event_type) {
            .key_press => Event{ .key_press = toEvent(InputDeviceEvent, &bytes) },
            .key_release => Event{ .key_release = toEvent(InputDeviceEvent, &bytes) },
            .button_press => Event{ .button_press = toEvent(InputDeviceEvent, &bytes) },
            .button_release => Event{ .button_release = toEvent(InputDeviceEvent, &bytes) },
            .motion_notify => Event{ .motion_notify = toEvent(InputDeviceEvent, &bytes) },
            .enter_notify => Event{ .enter_notify = toEvent(PointerWindowEvent, &bytes) },
            .leave_notify => Event{ .leave_notify = toEvent(PointerWindowEvent, &bytes) },
            .focus_in => Event{ .focus_in = toEvent(InputFocusEvent, &bytes) },
            .focus_out => Event{ .focus_out = toEvent(InputFocusEvent, &bytes) },
            .keymap_notify => Event{ .keymap_notify = toEvent(KeymapEvent, &bytes) },
            .expose => Event{ .expose = toEvent(ExposeEvent, &bytes) },
            .graphics_exposure => Event{ .graphics_exposure = toEvent(GraphicsExposeEvent, &bytes) },
            .no_exposure => Event{ .no_exposure = toEvent(NoExposureEvent, &bytes) },
            .visiblity_notify => Event{ .visiblity_notify = toEvent(VisibilityEvent, &bytes) },
            .create_notify => Event{ .create_notify = toEvent(CreateEvent, &bytes) },
            .destroy_notify => Event{ .destroy_notify = toEvent(DestroyEvent, &bytes) },
            .unmap_notify => Event{ .unmap_notify = toEvent(UnmapEvent, &bytes) },
            .map_notify => Event{ .map_notify = toEvent(MapEvent, &bytes) },
            .map_request => Event{ .map_request = toEvent(MapRequest, &bytes) },
            .reparent_notify => Event{ .reparent_notify = toEvent(ReparentEvent, &bytes) },
            .configure_notify => Event{ .configure_notify = toEvent(ConfigureEvent, &bytes) },
            .configure_request => Event{ .configure_request = toEvent(ConfigureRequest, &bytes) },
            .gravity_notify => Event{ .gravity_notify = toEvent(GravityEvent, &bytes) },
            .resize_request => Event{ .resize_request = toEvent(ResizeRequestEvent, &bytes) },
            .circulate_notify => Event{ .circulate_notify = toEvent(CirculateEvent, &bytes) },
            .circulate_request => Event{ .circulate_request = toEvent(CirculateRequestEvent, &bytes) },
            .property_notify => Event{ .property_notify = toEvent(PropertyEvent, &bytes) },
            .selection_clear => Event{ .selection_clear = toEvent(SelectionClearEvent, &bytes) },
            .selection_request => Event{ .selection_request = toEvent(SelectionRequestEvent, &bytes) },
            .selection_notify => Event{ .selection_notify = toEvent(SelectionEvent, &bytes) },
            .colormap_notify => Event{ .colormap_notify = toEvent(ColormapEvent, &bytes) },
            .client_message => Event{ .client_message = toEvent(ClientMessageEvent, &bytes) },
            .mapping_notify => Event{ .mapping_notify = toEvent(MappingEvent, &bytes) },
        };
    }
};

pub const InputDeviceEvent = extern struct {
    code: u8,
    detail: XTypes.Types.Keycode,
    sequence: u16,
    time: u32,
    root: XTypes.Types.Window,
    event: XTypes.Types.Window,
    child: XTypes.Types.Window,
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

/// Event generated when the cursor enters or leaves the window
pub const PointerWindowEvent = extern struct {
    code: u8,
    detail: u8,
    sequence: u16,
    time: u32,
    root: XTypes.Types.Window,
    event: XTypes.Types.Window,
    child: XTypes.Types.Window,
    root_x: i16,
    root_y: i16,
    event_x: i16,
    event_y: i16,
    state: u16,
    mode: u8,
    same_screen: u8,

    pub fn sameScreen(self: PointerWindowEvent) bool {
        return self.same_screen == 1;
    }
};

/// Event generated when the input focus changes
pub const InputFocusEvent = extern struct {
    code: u8,
    detail: u8,
    sequence: u16,
    event: XTypes.Types.Window,
    /// 0 = Normal, 1 = Grab, 2 = Ungrab, 3 = WhileGrabbed
    mode: u8,
    pad: [23]u8,
};

/// Event generated after every `.focus_in` and `enter_notify` event
/// Returns a bit vector of the state of the keyboard as described by
/// https://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.html#requests:QueryKeymap
pub const KeymapEvent = extern struct {
    code: u8,
    keys: [31]u8,
};

/// Event generated when no valid contents are available for regions of a window
pub const ExposeEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    window: XTypes.Types.Window,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    count: u16,
    pad1: [14]u8,
};

/// Event generated when a client uses a graphics content but no destination region could be computed
pub const GraphicsExposeEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    drawable: XTypes.Types.Drawable,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    minor_opcode: u16,
    count: u16,
    major_opcode: u8,
    pad1: [11]u8,
};

/// Event generated when a client that might produce `GraphicsExposeEvent`s does not produce any
pub const NoExposureEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    drawable: XTypes.Types.Drawable,
    minor_opcode: u16,
    major_opcode: u8,
    pad1: [21]u8,
};

/// Event generated when the hierarchy changes
pub const VisibilityEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    window: XTypes.Types.Window,
    state: u8,
    pad1: [23]u8,
};

/// Event generated when a window is created
pub const CreateEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    parent: XTypes.Types.Window,
    window: XTypes.Types.Window,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    override_redirect: u8,
    pad1: [9]u8,

    pub fn overridden(self: CreateEvent) bool {
        return self.override_redirect == 1;
    }
};

/// Event generated when a window is destroyed
pub const DestroyEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    pad1: [20]u8,
};

/// Event generated when a window is unmapped
pub const UnmapEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    from_configure: u8,
    pad1: [19]u8,

    pub fn configured(self: UnmapEvent) bool {
        return self.from_configure == 1;
    }
};

/// Event generated when a window is mapped and therefore visible
pub const MapEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    override_redirect: u8,
    pad1: [19]u8,

    pub fn overridden(self: MapEvent) bool {
        return self.override_redirect == 1;
    }
};

/// Event generated when a request is issued on an unmapped window
/// which has its override_redirect set to false
pub const MapRequest = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    parent: XTypes.Types.Window,
    window: XTypes.Types.Window,
    pad1: [20]u8,
};

/// Event generated when the parent of a window is changed
pub const ReparentEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    parent: XTypes.Types.Window,
    x: i16,
    y: i16,
    override_redirect: u8,
    pad1: [11]u8,

    pub fn overridden(self: ReparentEvent) bool {
        return self.override_redirect == 1;
    }
};

/// Event generated when the configuration is changed
pub const ConfigureEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    above_sibling: XTypes.Types.Window,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    override_redirect: u8,
    pad1: [5]u8,

    pub fn overridden(self: ConfigureEvent) bool {
        return self.override_redirect == 1;
    }
};

/// Event generated when an updated configuration is requested
pub const ConfigureRequest = extern struct {
    code: u8,
    stack_mode: u8,
    sequence: u8,
    parent: XTypes.Types.Window,
    window: XTypes.Types.Window,
    sibling: XTypes.Types.Window,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    mask: u16,
    pad: [4]u8,
};

/// Event generated when a window is moved because of a change in size of the parent
pub const GravityEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    x: i16,
    y: i16,
    pad1: [16]u8,
};

/// Event generated when a request has been made to resize a window
pub const ResizeRequestEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    window: XTypes.Types.Window,
    width: u16,
    height: u16,
    pad1: [20]u8,
};

/// Event is generated when the window is actually restacked from a CirculateWindow request
pub const CirculateEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    event: XTypes.Types.Window,
    window: XTypes.Types.Window,
    pad1: u32,
    /// top=0, bottom=1
    place: u8,
    pad2: [15]u8,
};

/// Event generated when a CirculateWindow request is issued on the parent,
/// and a window actually needs to be restacked
pub const CirculateRequestEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    parent: XTypes.Types.Window,
    window: XTypes.Types.Window,
    pad1: u32,
    /// top=0, bottom=1
    place: u8,
    pad2: [15]u8,
};

/// Event generated when a property of the window is changed
pub const PropertyEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    window: XTypes.Types.Window,
    atom: XTypes.Types.Atom,
    time: u32,
    /// NewValue = 0, Deleted = 1
    state: u8,
    pad1: [15]u8,
};

/// Event generated when a selection clear request has been performed
pub const SelectionClearEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    time: u32,
    owner: XTypes.Types.Window,
    selection: XTypes.Types.Atom,
    pad1: [16]u8,
};

/// Event generated when a selection clear is requested but not yet performed
pub const SelectionRequestEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    time: u32,
    owner: XTypes.Types.Window,
    requestor: XTypes.Types.Window,
    selection: XTypes.Types.Atom,
    target: XTypes.Types.Atom,
    /// 0 = None
    property: XTypes.Types.Atom,
    pad1: [4]u8,
};

/// Event generated when a selection has no owner
pub const SelectionEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    time: u32,
    requestor: XTypes.Types.Window,
    selection: XTypes.Types.Atom,
    target: XTypes.Types.Atom,
    /// 0 = None
    property: XTypes.Types.Atom,
    pad1: [8]u8,
};

/// Event generated when the colormap attribute of the window is changed
pub const ColormapEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u8,
    window: XTypes.Types.Window,
    /// 0 = None
    colormap: XTypes.Types.Colormap,
    /// boolean
    new: u8,
    /// 0 = Uninstalled, 1 = Installed
    state: u8,
    pad1: [18]u8,

    pub fn isNew(self: ColormapEvent) bool {
        return self.new == 1;
    }
};

/// Event generated when the client sends the SendEvent message to the server
pub const ClientMessageEvent = extern struct {
    code: u8,
    format: u8,
    sequence: u8,
    window: XTypes.Types.Window,
    type: XTypes.Types.Atom,
    data: [20]u8,
};

/// Event generated when a Modifier, ChangeKeyboard, or PointerMapping is successfully executed
/// The `request` member defines the type that was set
pub const MappingEvent = extern struct {
    code: u8,
    pad: u8,
    sequence: u16,
    request: u8,
    first_keycode: XTypes.Types.Keycode,
    count: u8,
    pad1: [25]u8,
};
