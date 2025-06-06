const std = @import("std");
const zed = @import("root.zig");

pub const EditorState = struct {
    allocator: std.mem.Allocator,
    rows: std.ArrayList([]const u8),
    filename: []const u8,
    row_index: usize,
    col_index: usize,

    pub fn init(
        allocator: std.mem.Allocator,
        filename: []const u8,
    ) EditorState {
        return .{
            .allocator = allocator,
            .rows = std.ArrayList([]const u8).init(allocator),
            .filename = filename,
            .row_index = 0,
            .col_index = 0,
        };
    }

    fn loadFile(self: *EditorState, filename: []const u8) !void {
        const content = try std.fs.cwd().readFileAlloc(self.allocator, filename, std.math.maxInt(usize));
        defer self.allocator.free(content);

        var lines = std.mem.splitSequence(u8, content, "\n");
        while (lines.next()) |line| {
            const owned_line = try self.allocator.dupe(u8, line);
            try self.rows.append(owned_line);
        }

        self.filename = try self.allocator.dupe(u8, filename);
    }

    fn deinit(self: *EditorState) void {
        for (self.rows.items) |row| {
            self.allocator.free(row);
        }
        self.rows.deinit();
        self.allocator.free(self.filename);
    }
};

pub const Editor = struct {
    config: *zed.config.Config,
    terminal: *zed.terminal.Terminal,
    input: *zed.input.Input,
    output: *zed.output.Output,
    state: *EditorState,
    args: *zed.args.Args,

    pub fn init(
        config: *zed.config.Config,
        terminal: *zed.terminal.Terminal,
        input: *zed.input.Input,
        output: *zed.output.Output,
        state: *EditorState,
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

        try self.output.render(&self.state.rows, self.state.row_index, self.state.col_index);
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
            .moveCursorUp => {
                const current_file_row = (self.terminal.position.y - 1) + self.state.row_index;
                if (current_file_row <= 0) return;

                if (self.terminal.position.y <= 1) {
                    self.state.row_index -= 1;
                } else {
                    try self.terminal.moveCursorByDirection(.up, 1);
                }
            },
            .moveCursorDown => {
                const current_file_row = (self.terminal.position.y - 1) + self.state.row_index;
                if (current_file_row > self.state.rows.items.len - 1) return;

                if (self.terminal.position.y >= self.terminal.size.rows) {
                    self.state.row_index += 1;
                } else {
                    try self.terminal.moveCursorByDirection(.down, 1);
                }
            },
            .moveCursorLeft => {
                const current_file_row = (self.terminal.position.y - 1) + self.state.row_index;
                const current_file_col = (self.terminal.position.x - 1) + self.state.col_index;
                if (current_file_row >= self.state.rows.items.len) return;

                if (current_file_col > 0) {
                    if (self.terminal.position.x <= 1) {
                        self.state.col_index -= 1;
                    } else {
                        try self.terminal.moveCursorByDirection(.left, 1);
                    }
                }
            },
            .moveCursorRight => {
                const current_file_row = (self.terminal.position.y - 1) + self.state.row_index;
                const current_file_col = (self.terminal.position.x - 1) + self.state.col_index;
                if (current_file_row >= self.state.rows.items.len) return;

                const current_row = self.state.rows.items[current_file_row];
                if (current_file_col < current_row.len) {
                    if (self.terminal.position.x >= self.terminal.size.cols) {
                        self.state.col_index += 1;
                    } else {
                        try self.terminal.moveCursorByDirection(.right, 1);
                    }
                }
            },
            .quit => {
                try self.output.clearScreen();
                try self.terminal.disableRawMode();
                std.posix.exit(0);
            },
        }
    }

    fn render(self: *Editor) !void {
        try self.output.render(&self.state.rows, self.state.row_index, self.state.col_index);
        try self.terminal.flush();
    }
};
