const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("state.zig");
const Rune = @import("../runes/rune.zig").Rune;

pub const Monster = struct {
    name: [:0]const u8,
    pos: rl.Vector2,
    nameKnown: bool,
    speed: f32,
    health: u32,
    maxHealth: u8,
    damageRange: u8,
    dying: bool,
    gold: u8,
    runes: ?std.ArrayList(*Rune),
    messages: ?std.ArrayList([:0]const u8),
    monsterMsgDecay: u8 = 255,

    pub fn enter(self: *@This(), state: *s.State, dt: f32) bool {
        if (self.pos.x > state.grid.getGroundCenterPos().x + 200) {
            self.pos.x -= rl.math.lerp(0, state.grid.getGroundCenterPos().x + 200, self.speed * dt);
            return false;
        }
        return true;
    }

    pub fn exit(self: *@This(), state: *s.State, dt: f32) bool {
        if (self.pos.x < state.grid.getWidth()) {
            state.adventurer.pos.x += rl.math.lerp(0, state.grid.getWidth(), self.speed * dt);
            return false;
        }
        return true;
    }

    pub fn deinit(self: *@This(), state: *s.State) !void {
        std.debug.print("DEINIT MONSTER {s}\n", .{self.name});
        if (self.runes != null) {
            for (0..self.runes.?.items.len) |i| {
                try self.runes.?.items[i].deinit(state);
                state.allocator.destroy(self.runes.?.items[i]);
            }
            self.runes.?.deinit();
        }
        if (self.messages) |messages| {
            messages.deinit();
        }
    }

    pub fn attack(self: @This(), state: *s.State) !void {
        const damage = state.rand.intRangeAtMost(u8, 1, self.damageRange);
        std.debug.print("Monster did damage: {d}\n", .{damage});
        if (damage > state.adventurer.health) {
            state.adventurer.health = 0;
        } else {
            state.adventurer.health -= damage;

            if (state.player.messages != null) {
                const st = try std.fmt.allocPrintZ(state.allocator, "{d}", .{damage});
                try state.player.messages.?.append(st);
            }
        }
    }

    pub fn update(self: *@This(), state: *s.State) void {
        const monsterMessageDisplayed = self.displayMessages(
            self.monsterMsgDecay,
            rl.getFrameTime() * @as(f32, @floatFromInt(self.monsterMsgDecay)),
            state,
        );
        if (self.monsterMsgDecay == 0) {
            self.monsterMsgDecay = 255;
        }

        if (monsterMessageDisplayed) {
            const ddiff = @as(u8, @intFromFloat(rl.math.clamp(230 * rl.getFrameTime(), 0, 255)));
            const rs = @subWithOverflow(self.monsterMsgDecay, ddiff);
            if (rs[1] != 0) {
                self.monsterMsgDecay = 0;
            } else {
                self.monsterMsgDecay -= ddiff;
            }
        }
    }

    pub fn displayMessages(self: *@This(), decay: u8, dt: f32, state: *s.State) bool {
        if (self.messages == null or self.messages.?.items.len == 0) {
            return false;
        }
        const last = self.messages.?.items.len - 1;
        const msg = self.messages.?.items[last];
        if (decay > 0) {
            rl.drawText(
                msg,
                @as(i32, @intFromFloat(self.pos.x + 62)),
                @as(i32, @intFromFloat(self.pos.y - 65 + (10 * dt))),
                20,
                rl.Color.init(255, 50, 50, decay),
            );
            return true;
        }
        if (decay == 0) {
            const old = self.messages.?.pop();
            if (old != null) {
                state.allocator.free(old.?);
            }
            return false;
        }
        return false;
    }

    pub fn draw(self: @This(), state: *s.State) void {
        const textureWidth = 128;
        const textureHeight = 128;
        if (self.health <= 0 and !self.dying) {
            return;
        }

        if (std.mem.eql(u8, self.name, "Green Goblin")) {
            if (state.textureMap.get(.GREENGOBLIN)) |texture| {
                rl.drawTexturePro(
                    texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = -textureWidth,
                        .height = textureHeight,
                    },
                    .{
                        .height = textureHeight,
                        .width = textureWidth,
                        .x = self.pos.x,
                        .y = self.pos.y,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
        }

        if (std.mem.eql(u8, self.name, "Red Goblin")) {
            if (state.textureMap.get(.REDGOBLIN)) |texture| {
                rl.drawTexturePro(
                    texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = textureWidth,
                        .height = textureHeight,
                    },
                    .{
                        .height = textureHeight,
                        .width = textureWidth,
                        .x = self.pos.x,
                        .y = self.pos.y,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .white,
                );
            }
        }

        if (std.mem.eql(u8, self.name, "Boss")) {
            if (state.textureMap.get(.BOSS)) |texture| {
                rl.drawTexturePro(
                    texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = textureWidth,
                        .height = textureHeight,
                    },
                    .{
                        .height = textureHeight,
                        .width = textureWidth,
                        .x = self.pos.x,
                        .y = self.pos.y,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .magenta,
                );
            }
        }

        if (std.mem.eql(u8, self.name, "Ascend Boss")) {
            if (state.textureMap.get(.ASCENDBOSS)) |texture| {
                rl.drawTexturePro(
                    texture,
                    .{
                        .x = 0,
                        .y = 0,
                        .width = 256,
                        .height = 256,
                    },
                    .{
                        .height = 256,
                        .width = 256,
                        .x = self.pos.x,
                        .y = self.pos.y - 128,
                    },
                    .{ .x = 0, .y = 0 },
                    0.0,
                    .magenta,
                );
            }
        }

        if (self.health > 0) {
            // Draw healthbar, normalized by max health = 100%
            const healthPerc: f32 = rl.math.normalize(@as(f32, @floatFromInt(self.health)), 0.0, @as(
                f32,
                @floatFromInt(self.maxHealth),
            )) * 100.0;
            rl.drawRectanglePro(
                .{
                    .height = 7,
                    .width = healthPerc,
                    .x = self.pos.x + 8,
                    .y = self.pos.y - 5,
                },
                .{ .x = 0, .y = 0 },
                0.0,
                .red,
            );
        } else {
            rl.drawLineEx(
                .{ .x = self.pos.x, .y = self.pos.y },
                .{ .x = self.pos.x + 128, .y = self.pos.y + 128 },
                5.0,
                .red,
            );
            rl.drawLineEx(
                .{ .x = self.pos.x, .y = self.pos.y + 128 },
                .{ .x = self.pos.x + 128, .y = self.pos.y },
                5.0,
                .red,
            );
        }
    }

    pub fn drawPortrait(self: @This(), state: *s.State, dest: rl.Rectangle) void {
        _ = self;
        const textureWidth = 30;
        const textureHeight = 30;

        if (state.textureMap.get(.Adventurer)) |texture| {
            rl.drawTexturePro(
                texture,
                .{
                    .x = 30,
                    .y = 0,
                    .width = textureWidth,
                    .height = textureHeight,
                },
                dest,
                .{ .x = 0, .y = 0 },
                0.0,
                .white,
            );
        }
    }

    pub fn collides(self: @This(), other: rl.Vector2) bool {
        return rl.Vector2.distance(self.pos.normalize(), other.normalize()) <= 1;
    }
};
