const std = @import("std");

pub const Action = enum {
    quit,
};

pub const KeyBinding = struct {
    key: u8,
    action: Action,
};

pub const Config = struct {
    key_bindings: []const KeyBinding,
    pub fn findAction(self: *const Config, key: u8) ?Action {
        for (self.key_bindings) |binding| {
            if (binding.key == key) {
                return binding.action;
            }
        }

        return null;
    }
};

const ctrl_bitmask = 0x1f;
pub fn ctrlKey(key: u8) u8 {
    return key & ctrl_bitmask;
}
