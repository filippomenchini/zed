const std = @import("std");
const zed = @import("root.zig");

pub const Key = union(enum) {
    char: u8,
    escape,
    delete,

    const ctrl_bitmask = 0x1f;

    pub fn fromChar(char: u8) Key {
        return Key{ .char = char };
    }

    pub fn ctrlKey(char: u8) Key {
        return Key.fromChar(char & ctrl_bitmask);
    }

    pub fn eql(self: Key, other: Key) bool {
        if (@intFromEnum(self) != @intFromEnum(other)) {
            return false;
        }

        return switch (self) {
            .char => |c| c == other.char,
            .escape => true,
            .delete => true,
        };
    }
};

pub const KeyBinding = struct {
    key: Key,
    mode: ?zed.EditorMode,
    action: zed.Action,
};

pub const Config = struct {
    key_bindings: []const KeyBinding,

    pub fn findAction(
        self: *const Config,
        key: Key,
        mode: zed.EditorMode,
    ) ?zed.Action {
        for (self.key_bindings) |binding| {
            if (binding.key.eql(key)) {
                if (binding.mode == null or binding.mode == mode) {
                    return binding.action;
                }
            }
        }

        return null;
    }
};
