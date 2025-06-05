const std = @import("std");
const zed = @import("root.zig");

pub const EditorState = struct {
    allocator: std.mem.Allocator,
    rows: std.ArrayList([]const u8),
    filename: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        filename: []const u8,
    ) EditorState {
        return .{
            .allocator = allocator,
            .rows = std.ArrayList([]const u8).init(allocator),
            .filename = filename,
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

        try self.output.render(&self.state.rows);
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
        try self.output.render(&self.state.rows);
        try self.terminal.flush();
    }
};
