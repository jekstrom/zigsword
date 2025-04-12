const rl = @import("raylib");
const std = @import("std");
const enums = @import("../enums.zig");
const s = @import("../objects/state.zig");

// Interface for events
pub const Event = struct {
    ptr: *anyopaque,
    name: [:0]const u8,
    eventType: EventType,
    pos: rl.Vector2,
    handled: bool,
    getNameFn: *const fn (ptr: *anyopaque) anyerror![:0]const u8,
    getEventTypeFn: *const fn (ptr: *anyopaque) anyerror!EventType,
    getPosFn: *const fn (ptr: *anyopaque) anyerror!rl.Vector2,
    getHandledFn: *const fn (ptr: *anyopaque) anyerror!bool,
    handleFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,
    drawFn: *const fn (ptr: *anyopaque, state: *s.State) anyerror!void,

    pub fn getName(self: *@This()) anyerror![:0]const u8 {
        return self.getNameFn(self.ptr);
    }

    pub fn getEventType(self: *@This()) anyerror!EventType {
        return self.getEventTypeFn(self.ptr);
    }

    pub fn getPos(self: *@This()) anyerror!rl.Vector2 {
        return self.getPosFn(self.ptr);
    }

    pub fn getHandled(self: *@This()) anyerror!bool {
        return self.getHandledFn(self.ptr);
    }

    pub fn handle(self: *@This(), state: *s.State) anyerror!void {
        return self.handleFn(self.ptr, state);
    }

    pub fn draw(self: *@This(), state: *s.State) anyerror!void {
        return self.drawFn(self.ptr, state);
    }

    pub fn init(
        ptr: anytype,
        name: [:0]const u8,
        eventType: EventType,
        pos: rl.Vector2,
        handled: bool,
        allocator: *const std.mem.Allocator,
    ) !*Event {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn getName(pointer: *anyopaque) anyerror![:0]const u8 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.getName(self);
            }

            pub fn getEventType(pointer: *anyopaque) anyerror!EventType {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.getEventType(self);
            }

            pub fn getPos(pointer: *anyopaque) anyerror!rl.Vector2 {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.getPos(self);
            }

            pub fn getHandled(pointer: *anyopaque) anyerror!bool {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.getHandled(self);
            }

            pub fn handle(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.handle(self, state);
            }

            pub fn draw(pointer: *anyopaque, state: *s.State) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                if (ptr_info != .pointer) @compileError("ptr must be a pointer");
                if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
                return ptr_info.pointer.child.draw(self, state);
            }
        };

        var sobj = try allocator.create(Event);
        sobj.ptr = ptr;
        sobj.name = name;
        sobj.eventType = eventType;
        sobj.pos = pos;
        sobj.handled = handled;
        sobj.getNameFn = gen.getName;
        sobj.getEventTypeFn = gen.getEventType;
        sobj.getPosFn = gen.getPos;
        sobj.getHandledFn = gen.getHandled;
        sobj.drawFn = gen.draw;
        sobj.handleFn = gen.handle;
        return sobj;
    }
};

pub const EventType = enum(u8) {
    ALTAR,
    CHEST,
};
