const rl = @import("raylib");
const std = @import("std");
const s = @import("../objects/state.zig");
const RollResult = @import("../dice/rollresult.zig").RollResult;

// Interface for runes
pub const Rune = struct {
    ptr: *anyopaque,
    name: [:0]const u8,
    pos: rl.Vector2,
    getNameFn: *const fn (ptr: *anyopaque) anyerror![:0]const u8,
    getPosFn: *const fn (ptr: *anyopaque) anyerror!rl.Vector2,
    handleFn: *const fn (ptr: *anyopaque, state: *s.State, rollResults: ?*std.ArrayList(RollResult)) anyerror!void,
    drawFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,

    pub fn getName(self: *@This()) anyerror![:0]const u8 {
        return self.getNameFn(self.ptr);
    }

    pub fn getPos(self: *@This()) anyerror![:0]const u8 {
        return self.getPosFn(self.ptr);
    }

    pub fn handle(self: *@This(), state: *s.State, rollResults: ?*std.ArrayList(RollResult)) anyerror!void {
        return self.handleFn(self.ptr, state, rollResults);
    }

    pub fn draw(self: *@This(), state: *s.State) anyerror!void {
        return self.drawFn(self.ptr, state);
    }

    pub fn init(
        ptr: anytype,
        name: [:0]const u8,
        allocator: *const std.mem.Allocator,
    ) !*Rune {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn getName(pointer: *anyopaque) anyerror![:0]const u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.getName(self);
            }

            pub fn getPos(pointer: *anyopaque) anyerror!rl.Vector2 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.getPos(self);
            }

            pub fn handle(pointer: *anyopaque, state: *s.State, rollResults: ?*std.ArrayList(RollResult)) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.handle(self, state, rollResults);
            }

            pub fn draw(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.draw(self, state);
            }
        };

        var sobj = try allocator.create(Rune);
        sobj.ptr = ptr;
        sobj.name = name;
        sobj.getNameFn = gen.getName;
        sobj.getPosFn = gen.getPos;
        sobj.drawFn = gen.draw;
        sobj.handleFn = gen.handle;
        return sobj;
    }
};
