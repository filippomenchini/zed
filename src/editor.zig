const terminal = @import("terminal.zig");
const config = @import("config.zig");
const output = @import("output.zig");
const input = @import("input.zig");

pub const Editor = struct {
    terminal: *const terminal.Terminal,
    config: *const config.Config,
    terminal_size: output.TerminalSize,

    pub fn init(
        term: *const terminal.Terminal,
        conf: *const config.Config,
    ) !Editor {
        const terminal_size = output.getTerminalSize();
        try output.clearScreen();

        return Editor{
            .terminal = term,
            .config = conf,
            .terminal_size = terminal_size,
        };
    }

    pub fn start(self: *const Editor) !void {
        try self.terminal.enableRawMode();
        try output.refreshScreen(self.terminal_size);
    }

    pub fn handleInput(self: *const Editor) !void {
        try input.processKeypress(self.terminal, self.config);
    }
};
