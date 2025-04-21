const std = @import("std");
const enums = @import("enums.zig");
const rl = @import("raylib");

pub fn loadGroundTextures() !rl.Texture {
    return try loadTexture("resources/ground_small.png");
}

pub fn loadDungeonGroundTextures() !rl.Texture {
    return try loadTexture("resources/dungeon.png");
}

pub fn loadBackgroundTextures() !rl.Texture {
    return try loadTexture("resources/background.png");
}

pub fn loadDungeonBackgroundTextures() !rl.Texture {
    return try loadTexture("resources/dungeon_background.png");
}

pub fn loadTexture(path: [:0]const u8) !rl.Texture {
    const image = try rl.loadImage(path);
    const texture = try rl.loadTextureFromImage(image);
    rl.unloadImage(image);
    return texture;
}

pub fn loadAndMapAllTextures(map: *std.AutoHashMap(enums.TextureType, rl.Texture)) !void {
    const texture = try loadGroundTextures();

    const dungeonGroundtexture = try loadDungeonGroundTextures();

    const background = try loadBackgroundTextures();

    const dungeonBackground = try loadDungeonBackgroundTextures();

    const shopBackground = try loadTexture("resources/shop.png");
    const ascendBackground = try loadTexture("resources/ascend1.png");
    const ascendBossBackground = try loadTexture("resources/ascend_boss_bg.png");
    const menuBackground = try loadTexture("resources/menu_bg2.png");
    const mapBackground = try loadTexture("resources/map.png");

    const swordIcon = try loadTexture("resources/sword_icon.png");

    const adventurerIcon = try loadTexture("resources/adventurer_icon2.png");

    const adventurer = try loadTexture("resources/adventurer_icon2.png");

    const pipIcon = try loadTexture("resources/Pip.png");

    const pipDurabilityIcon = try loadTexture("resources/Pipdurability.png");

    const pipEnergyIcon = try loadTexture("resources/Pipenergy.png");

    const sword = try loadTexture("resources/sword.png");

    const goodAltar = try loadTexture("resources/good_altar.png");

    const evilAltar = try loadTexture("resources/evil_altar.png");

    const treasureChest = try loadTexture("resources/treasure_chest.png");

    const greenGoblin = try loadTexture("resources/green_goblin.png");

    const redGoblin = try loadTexture("resources/red_goblin.png");

    const boss = try loadTexture("resources/boss.png");
    const ascendBoss = try loadTexture("resources/ascend_boss1.png");

    const shopCard = try loadTexture("resources/shop_card.png");

    const fateRune = try loadTexture("resources/fate_rune.png");
    const kinRune = try loadTexture("resources/kin_rune.png");
    const dawnRune = try loadTexture("resources/dawn_rune.png");

    const d4 = try loadTexture("resources/pyramid.png");

    const d6 = try loadTexture("resources/d6.png");

    try map.put(.SwordIcon, swordIcon);
    try map.put(.AdventurerIcon, adventurerIcon);
    try map.put(.Adventurer, adventurer);
    try map.put(.HealthPip, pipIcon);
    try map.put(.DurabilityPip, pipDurabilityIcon);
    try map.put(.EnergyPip, pipEnergyIcon);
    try map.put(.Sword, sword);
    try map.put(.OUTSIDEGROUND, texture);
    try map.put(.DUNGEONGROUND, dungeonGroundtexture);
    try map.put(.OUTSIDEBACKGROUND, background);
    try map.put(.DUNGEONBACKGROUND, dungeonBackground);
    try map.put(.SHOPBACKGROUND, shopBackground);
    try map.put(.ASCEND1BACKGROUND, ascendBackground);
    try map.put(.ASCENDBOSSBACKGROUND, ascendBossBackground);
    try map.put(.MENUBACKGROUND, menuBackground);
    try map.put(.MAPBACKGROUND, mapBackground);
    try map.put(.GOODALTAR, goodAltar);
    try map.put(.EVILALTAR, evilAltar);
    try map.put(.TREASURECHEST, treasureChest);
    try map.put(.GREENGOBLIN, greenGoblin);
    try map.put(.REDGOBLIN, redGoblin);
    try map.put(.BOSS, boss);
    try map.put(.ASCENDBOSS, ascendBoss);
    try map.put(.D4, d4);
    try map.put(.D6, d6);
    try map.put(.SHOPCARD, shopCard);
    try map.put(.FATERUNE, fateRune);
    try map.put(.KINRUNE, kinRune);
    try map.put(.DAWNRUNE, dawnRune);
}
