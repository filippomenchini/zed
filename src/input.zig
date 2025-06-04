const std = @import("std");
const zed = @import("root.zig");

const InputError = error{
    ReadError,
    ProcessKeypressError,
};

pub const Input = struct {
    terminal: *zed.terminal.Terminal,
    output: *zed.output.Output,

    pub fn init(
        terminal: *zed.terminal.Terminal,
        output: *zed.output.Output,
    ) Input {
        return .{
            .terminal = terminal,
            .output = output,
        };
    }

    pub fn readKey(self: *Input) InputError!u8 {
        var character: [1]u8 = .{0};
        _ = self.terminal.read(&character) catch {
            return InputError.ReadError;
        };

        return character[0];
    }

    pub fn processKeypress(
        self: *Input,
        config: *const zed.config.Config,
    ) !?zed.action.Action {
        const key = try self.readKey();
        return config.findAction(key);
    }
};
