const std = @import("std");
const terminal = @import("terminal.zig");
const config = @import("config.zig");
const output = @import("output.zig");

const posix = std.posix;

const InputError = error{
    ReadError,
    ProcessKeypressError,
};

fn readKey(running_terminal: *const terminal.Terminal) InputError!u8 {
    var character: [1]u8 = .{0};
    _ = running_terminal.read(&character) catch {
        return InputError.ReadError;
    };

    return character[0];
}

pub fn processKeypress(
    running_terminal: *const terminal.Terminal,
    editor_config: *const config.Config,
) !void {
    const character = try readKey(running_terminal);

    if (editor_config.findAction(character)) |action| {
        switch (action) {
            .quit => {
                try output.clearScreen();
                try running_terminal.disableRawMode();
                posix.exit(0);
            },
        }
    }
}
