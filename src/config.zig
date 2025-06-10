const std = @import("std");
const zed = @import("root.zig");

pub const KeyBinding = struct {
    key: u8,
    mode: zed.EditorMode,
    action: zed.Action,
};

pub const Config = struct {
    key_bindings: []const KeyBinding,
    const ctrl_bitmask = 0x1f;

    pub fn findAction(
        self: *const Config,
        key: u8,
        mode: zed.EditorMode,
    ) ?zed.Action {
        for (self.key_bindings) |binding| {
            if (binding.key == key and binding.mode == mode) {
                return binding.action;
            }
        }

        return null;
    }

    pub fn ctrlKey(key: u8) u8 {
        return key & ctrl_bitmask;
    }
};
