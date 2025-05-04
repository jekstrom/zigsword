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
    ASCEND1BACKGROUND,
    ASCENDBOSSBACKGROUND,
    MENUBACKGROUND,
    MAPBACKGROUND,
    GOODALTAR,
    EVILALTAR,
    TREASURECHEST,
    GREENGOBLIN,
    REDGOBLIN,
    BOSS,
    ASCENDBOSS,
    SHOPCARD,
    FATERUNE,
    KINRUNE,
    DAWNRUNE,
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
    MENU,
    ADVENTURERDEATH,
    NONE,
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

pub const MapSide = enum(u8) {
    left,
    right,
    center,
};
