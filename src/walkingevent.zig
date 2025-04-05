const rl = @import("raylib");

// This is an event that can occur while in the walking mode.
pub const WalkingEvent = struct {
    name: [:0]const u8,
    type: WalkingEventType,
    level: u8,
    mapCount: u8,
    pos: rl.Vector2,
};

pub const WalkingEventType = enum(u8) {
    ALTAR,
    CHEST,
};
