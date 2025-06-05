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
        try self.terminal.setCursorPosition(zed.terminal.CursorPosition{ .x = 1, .y = 1 });
        try self.output.render(self.terminal.position);
        try self.terminal.flush();
    }

    fn handleInput(self: *Editor) !void {
        if (try self.input.processKeypress(self.config)) |action| {
            try self.executeAction(action);
            try self.render();
        }
    }

    fn executeAction(self: *Editor, action: zed.action.Action) !void {
        switch (action) {
            .moveCursorUp => try self.terminal.moveCursorByDirection(.up, 1),
            .moveCursorDown => try self.terminal.moveCursorByDirection(.down, 1),
            .moveCursorLeft => try self.terminal.moveCursorByDirection(.left, 1),
            .moveCursorRight => try self.terminal.moveCursorByDirection(.right, 1),
            .quit => {
                try self.output.clearScreen();
                try self.terminal.disableRawMode();
                std.posix.exit(0);
            },
        }
    }

    fn render(self: *Editor) !void {
        try self.output.render(self.terminal.position);
        try self.terminal.flush();
    }
};
