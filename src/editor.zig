const std = @import("std");
const zed = @import("root.zig");

pub const Editor = struct {
    config: *zed.config.Config,
    terminal: *zed.terminal.Terminal,
    input: *zed.input.Input,
    output: *zed.output.Output,

    pub fn init(
        config: *zed.config.Config,
        terminal: *zed.terminal.Terminal,
        input: *zed.input.Input,
        output: *zed.output.Output,
    ) !Editor {
        return Editor{
            .config = config,
            .terminal = terminal,
            .input = input,
            .output = output,
        };
    }

    pub fn run(self: *Editor) !void {
        try self.start();
        while (true)
            try self.handleInput();
    }

    fn start(self: *Editor) !void {
        try self.terminal.enableRawMode();
        try self.output.refreshScreen();
    }

    fn handleInput(self: *Editor) !void {
        if (try self.input.processKeypress(self.config)) |action| {
            switch (action) {
                .quit => {
                    try self.output.clearScreen();
                    try self.terminal.disableRawMode();
                    std.posix.exit(0);
                },
            }
        }
    }
};
