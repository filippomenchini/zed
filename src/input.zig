const std = @import("std");
const zed = @import("root.zig");

const InputError = error{
    ReadError,
    ProcessKeypressError,
};

pub const Input = struct {
    terminal: *zed.Terminal,

    pub fn init(
        terminal: *zed.Terminal,
    ) Input {
        return .{
            .terminal = terminal,
        };
    }

    pub fn readKey(self: *Input) InputError!zed.Key {
        var character: [1]u8 = .{0};
        _ = self.terminal.read(&character) catch {
            return InputError.ReadError;
        };

        if (character[0] != '\x1b') {
            return zed.Key.fromChar(character[0]);
        }

        var seq: [3]u8 = .{ 0, 0, 0 };
        if (self.terminal.read(seq[0..1]) catch 0 == 0) {
            return zed.Key.escape;
        }

        if (self.terminal.read(seq[1..2]) catch 0 == 0) {
            return zed.Key.escape;
        }

        if (seq[0] == '[') {
            switch (seq[1]) {
                '1'...'6' => {
                    var third: [1]u8 = undefined;
                    if (self.terminal.read(&third) catch 0 == 0) {
                        return zed.Key.escape;
                    }

                    if (third[0] == '~') {
                        switch (seq[1]) {
                            '3' => return zed.Key.delete,
                            else => return zed.Key.escape,
                        }
                    }
                    return zed.Key.escape;
                },
                else => return zed.Key.escape,
            }
        }

        return zed.Key.escape;
    }

    pub fn processKeypress(
        self: *Input,
        config: *const zed.Config,
        mode: zed.EditorMode,
    ) !?zed.Action {
        const key = try self.readKey();

        if (mode == .command) {
            return switch (key) {
                .char => |c| switch (c) {
                    '\r', '\n' => .commandRun,
                    127, 8 => .commandDelete,
                    32...126 => zed.Action{ .commandInsert = c },
                    else => null,
                },
                .escape => .commandCancel,
                .delete => .commandDelete,
            };
        }

        return config.findAction(key, mode);
    }
};
