const std = @import("std");
const zed = @import("root.zig");

pub const Editor = struct {
    config: *zed.config.Config,
    terminal: *zed.terminal.Terminal,
    input: *zed.input.Input,
    output: *zed.output.Output,
    state: *zed.editor_state.EditorState,
    args: *zed.args.Args,

    pub fn init(
        config: *zed.config.Config,
        terminal: *zed.terminal.Terminal,
        input: *zed.input.Input,
        output: *zed.output.Output,
        state: *zed.editor_state.EditorState,
        args: *zed.args.Args,
    ) !Editor {
        return Editor{
            .config = config,
            .terminal = terminal,
            .input = input,
            .output = output,
            .state = state,
            .args = args,
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
        try self.terminal.setCursorPosition(zed.terminal.CursorPosition{});

        const filename = self.args.getFilename();
        if (filename != null) {
            try self.state.loadFile(filename.?);
        }

        try self.output.render(self.state);
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
            .moveCursorUp => try self.moveVertically(.up),
            .moveCursorDown => try self.moveVertically(.down),
            .moveCursorLeft => try self.moveHorizontally(.left),
            .moveCursorRight => try self.moveHorizontally(.right),
            .quit => try self.quitEditor(),
        }
    }

    fn render(self: *Editor) !void {
        try self.output.render(self.state);
        try self.terminal.flush();
    }

    fn getCurrentFilePosition(self: *Editor) struct { row: usize, col: usize } {
        return .{
            .row = (self.terminal.position.y - 1) + self.state.row_index,
            .col = (self.terminal.position.x - 1) + self.state.col_index,
        };
    }

    fn adjustCursorForShorterRow(self: *Editor, target_row_index: usize, current_file_col: usize) void {
        const target_row = self.state.rows.items[target_row_index];

        if (current_file_col > target_row.len) {
            const new_col_screen: u16 = @intCast(@min(target_row.len, self.terminal.size.cols - 1));
            const new_col_offset: u16 = @intCast(if (target_row.len > self.terminal.size.cols - 1)
                target_row.len - self.terminal.size.cols + 1
            else
                0);

            self.state.col_index = new_col_offset;
            self.terminal.position.x = new_col_screen - new_col_offset + 1;
        }
    }

    fn moveVertically(self: *Editor, direction: enum { up, down }) !void {
        const pos = self.getCurrentFilePosition();

        if (self.state.rows.items.len == 0) return;
        if (direction == .up and pos.row <= 0) return;
        if (direction == .down and pos.row >= self.state.rows.items.len - 1) return;

        if (self.state.preferred_col_index == null) {
            self.state.preferred_col_index = pos.col;
        }

        switch (direction) {
            .up => {
                if (self.terminal.position.y <= 1) {
                    self.state.row_index -= 1;
                } else {
                    try self.terminal.moveCursorByDirection(.up, 1);
                }
            },
            .down => {
                if (self.terminal.position.y >= self.terminal.size.rows) {
                    self.state.row_index += 1;
                } else {
                    try self.terminal.moveCursorByDirection(.down, 1);
                }
            },
        }

        const target_row_index = if (direction == .up) pos.row - 1 else pos.row + 1;
        self.adjustCursorToPreferredColumn(target_row_index);
    }

    fn adjustCursorToPreferredColumn(self: *Editor, target_row_index: usize) void {
        const target_row = self.state.rows.items[target_row_index];
        const preferred_col = self.state.preferred_col_index.?;

        const target_col = @min(preferred_col, target_row.len);

        if (target_col >= self.terminal.size.cols) {
            self.state.col_index = target_col - self.terminal.size.cols + 1;
            self.terminal.position.x = self.terminal.size.cols;
        } else {
            self.state.col_index = 0;
            self.terminal.position.x = @intCast(target_col + 1);
        }
    }

    fn moveHorizontally(self: *Editor, direction: enum { left, right }) !void {
        const pos = self.getCurrentFilePosition();
        if (pos.row >= self.state.rows.items.len) return;

        const current_row = self.state.rows.items[pos.row];
        switch (direction) {
            .left => {
                if (pos.col <= 0) return;
                if (self.terminal.position.x <= 1) {
                    self.state.col_index -= 1;
                } else {
                    try self.terminal.moveCursorByDirection(.left, 1);
                }
            },
            .right => {
                if (pos.col >= current_row.len) return;
                if (self.terminal.position.x >= self.terminal.size.cols) {
                    self.state.col_index += 1;
                } else {
                    try self.terminal.moveCursorByDirection(.right, 1);
                }
            },
        }

        self.state.preferred_col_index = null;
    }

    fn quitEditor(self: *Editor) !void {
        try self.output.clearScreen();
        try self.terminal.disableRawMode();
        std.posix.exit(0);
    }
};
