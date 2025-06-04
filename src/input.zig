const std = @import("std");
const term = @import("terminal.zig");
const config = @import("config.zig");
const output = @import("output.zig");

const posix = std.posix;

const InputError = error{
    ReadError,
    ProcessKeypressError,
};

pub const Input = struct {
    terminal: *const term.Terminal,

    pub fn init(terminal: *const term.Terminal) Input {
        return .{
            .terminal = terminal,
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
        editor_config: *const config.Config,
    ) !void {
        const character = try self.readKey();

        if (editor_config.findAction(character)) |action| {
            switch (action) {
                .quit => {
                    try self.terminal.disableRawMode();
                    posix.exit(0);
                },
            }
        }
    }
};
