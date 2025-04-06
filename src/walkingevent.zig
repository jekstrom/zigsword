const rl = @import("raylib");

// This is an event that can occur while in the walking mode.
pub const WalkingEvent = struct {
    name: [:0]const u8,
    type: WalkingEventType,
    pos: rl.Vector2,
    handled: bool,
};

pub const WalkingEventType = enum(u8) {
    ALTAR,
    CHEST,
};
