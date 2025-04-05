pub const TextureType = enum(u8) {
    SwordIcon,
    AdventurerIcon,
    Adventurer,
    HealthPip,
    DurabilityPip,
    EnergyPip,
    Sword,
    OUTSIDEGROUND,
    DUNGEONGROUND,
    OUTSIDEBACKGROUND,
    DUNGEONBACKGROUND,
};

pub const GamePhase = enum(u8) {
    START,
    PLAY,
    DEATH,
    END,
};

pub const GameMode = enum(u8) {
    PAUSE,
    WALKING,
    BATTLE,
    SHOP,
};
