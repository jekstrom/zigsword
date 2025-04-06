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
    GOODALTAR,
    EVILALTAR,
    GREENGOBLIN,
    REDGOBLIN,
    D4,
};

pub const GamePhase = enum(u8) {
    START,
    PLAY,
    DEATH,
    END,
};

pub const GameMode = enum(u8) {
    TUTORIAL,
    PAUSE,
    WALKING,
    BATTLE,
    SHOP,
    DONE,
};

pub const Turn = enum(u8) {
    PLAYER,
    ADVENTURER,
    MONSTER,
    ENVIRONMENT,
};

pub const Alignment = enum(u8) {
    GOOD,
    EVIL,
};
