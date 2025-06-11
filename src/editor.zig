const std = @import("std");
const zed = @import("root.zig");

pub const Editor = struct {
    config: *zed.Config,
    terminal: *zed.Terminal,
    input: *zed.Input,
    output: *zed.Output,
    state: *zed.EditorState,
    args: *zed.Args,
    action_handler: *zed.ActionHandler,

    pub fn init(
        config: *zed.Config,
        terminal: *zed.Terminal,
        input: *zed.Input,
        output: *zed.Output,
        state: *zed.EditorState,
        args: *zed.Args,
        action_handler: *zed.ActionHandler,
    ) !Editor {
        return Editor{
            .config = config,
            .terminal = terminal,
            .input = input,
            .output = output,
            .state = state,
            .args = args,
            .action_handler = action_handler,
        };
    }

    pub fn deinit(self: *Editor) void {
        self.state.deinit();
        self.args.deinit();
    }

    pub fn run(self: *Editor) !void {
        try self.start();
        while (true)
            try self.handleInput();
    }

    fn start(self: *Editor) !void {
        try self.terminal.enableRawMode();
        try self.terminal.setCursorPosition(zed.TerminalCursorPosition{});

        const filename = self.args.getFilename();
        if (filename != null) {
            try self.state.loadFile(filename.?);
        }

        try self.output.render(self.state);
        try self.terminal.flush();
    }

    fn handleInput(self: *Editor) !void {
        if (try self.input.processKeypress(self.config, self.state.mode)) |action| {
            try self.executeAction(action);
            try self.render();
        }
    }

    fn executeAction(self: *Editor, action: zed.Action) !void {
        try self.action_handler.execute(zed.ActionHandlerContext{
            .state = self.state,
            .terminal = self.terminal,
            .output = self.output,
        }, action);
    }

    fn render(self: *Editor) !void {
        try self.output.render(self.state);
        try self.terminal.flush();
    }
};
