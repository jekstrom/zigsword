const rl = @import("raylib");
const std = @import("std");
const s = @import("state.zig");
const d = @import("../die.zig");
const MultDie = @import("../dice/mult.zig").MultDie;
const BasicDie = @import("../dice/basic.zig").BasicDie;

// A dice pack is a booster pack of random dice.
pub const DicePack = struct {
    name: [:0]const u8,
    price: u8,
    pos: rl.Vector2,
    texture: rl.Texture,

    pub fn deinit(self: *@This(), state: *s.State) void {
        // state.allocator.free(self.name);
        _ = self;
        _ = state;
    }

    pub fn init(name: [:0]const u8, price: u8, pos: rl.Vector2, texture: rl.Texture) DicePack {
        return .{
            .name = name,
            .price = price,
            .pos = pos,
            .texture = texture,
        };
    }

    pub fn getRandomDie(state: *s.State) !*d.Die {
        const randDie = state.rand.intRangeAtMost(u8, 0, 100);
        const pos: rl.Vector2 = .{ .x = -256, .y = state.grid.getCenterPos().y };

        var dieToAdd: ?*d.Die = null;
        if (randDie >= 0 and randDie < 40) {
            var d6: *BasicDie = try state.arenaAllocator.create(BasicDie);
            d6.name = "Basic d6";
            d6.sides = 6;
            d6.sellPrice = 2;
            d6.texture = state.textureMap.get(.D6);
            d6.hovered = false;
            d6.selected = false;
            d6.broken = false;
            d6.breakChance = 0;
            d6.nextResult = 0;
            d6.tooltip = "";
            d6.index = 0;
            d6.pos = pos;
            dieToAdd = try d6.die(&state.allocator);
        } else if (randDie >= 40 and randDie < 80) {
            var d4 = try state.arenaAllocator.create(BasicDie);
            d4.name = "Basic d4";
            d4.sides = 4;
            d4.sellPrice = 1;
            d4.texture = state.textureMap.get(.D4);
            d4.hovered = false;
            d4.selected = false;
            d4.broken = false;
            d4.breakChance = 0;
            d4.nextResult = 0;
            d4.tooltip = "";
            d4.index = 0;
            d4.pos = pos;
            dieToAdd = try d4.die(&state.allocator);
        } else if (randDie >= 80 and randDie < 90) {
            var d4 = try state.arenaAllocator.create(MultDie);
            d4.name = "Mult d4";
            d4.sides = 4;
            d4.sellPrice = 4;
            d4.texture = state.textureMap.get(.D4);
            d4.hovered = false;
            d4.selected = false;
            d4.broken = false;
            d4.breakChance = 0;
            d4.nextResult = 0;
            d4.tooltip = "";
            d4.index = 0;
            d4.pos = pos;
            dieToAdd = try d4.die(&state.allocator);
        } else if (randDie >= 90) {
            var d6 = try state.arenaAllocator.create(MultDie);
            d6.name = "Mult d6";
            d6.sides = 6;
            d6.sellPrice = 6;
            d6.texture = state.textureMap.get(.D6);
            d6.hovered = false;
            d6.selected = false;
            d6.broken = false;
            d6.breakChance = 0;
            d6.nextResult = 0;
            d6.tooltip = "";
            d6.index = 0;
            d6.pos = pos;
            dieToAdd = try d6.die(&state.allocator);
        }

        return dieToAdd.?;
    }

    pub fn getRandomDice(num: u8, state: *s.State) !std.ArrayList(*d.Die) {
        var dice = std.ArrayList(*d.Die).init(state.arenaAllocator);
        var i: u8 = 0;
        while (i < num) : (i += 1) {
            const dieToAdd = try getRandomDie(state);
            std.debug.print("Added die {s}\n", .{dieToAdd.name});
            try dice.append(dieToAdd);
        }
        return dice;
    }
};
