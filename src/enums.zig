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
    SHOPBACKGROUND,
    GOODALTAR,
    EVILALTAR,
    TREASURECHEST,
    GREENGOBLIN,
    REDGOBLIN,
    BOSS,
    SHOPCARD,
    D4,
    D6,
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
    ADVENTURERDEATH,
    DONE,
    WAIT,
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
