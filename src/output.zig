const std = @import("std");
const zed = @import("root.zig");

pub const OutputError = error{
    SendEscapeSequenceError,
};

pub const Output = struct {
    terminal: *zed.terminal.Terminal,

    pub fn init(terminal: *zed.terminal.Terminal) Output {
        return .{
            .terminal = terminal,
        };
    }

    pub fn render(
        self: *Output,
        editor_state: *zed.editor_state.EditorState,
    ) !void {
        try self.terminal.appendEscapeToBuffer(.clear_entire_screen);
        try self.terminal.appendEscapeToBuffer(.move_cursor_to_origin);
        try self.drawRows(editor_state);
        try self.drawStatusBar(editor_state);
        try self.drawMessageBar(editor_state);
        try self.terminal.setCursorPosition(self.terminal.position);
    }

    pub fn clearScreen(self: *Output) !void {
        try self.terminal.appendEscapeToBuffer(.clear_entire_screen);
        try self.terminal.appendEscapeToBuffer(.move_cursor_to_origin);
        try self.terminal.flush();
    }

    fn drawRows(
        self: *Output,
        editor_state: *zed.editor_state.EditorState,
    ) !void {
        var row_index: usize = 0;
        while (row_index < self.terminal.size.rows) : (row_index += 1) {
            const editor_row = row_index + editor_state.row_index;
            if (editor_row >= editor_state.rows.items.len) {
                try self.terminal.appendToBuffer("~");
            } else {
                const row = editor_state.rows.items[editor_row];
                const end_col_index = @min(editor_state.col_index + self.terminal.size.cols, row.len);

                if (editor_state.col_index < row.len) {
                    try self.terminal.appendToBuffer(row[editor_state.col_index..end_col_index]);
                }
            }

            try self.terminal.appendToBuffer(zed.terminal.EscapeSequence.clear_line.toString());
            if (row_index < self.terminal.size.rows) {
                try self.terminal.appendToBuffer("\r\n");
            }
        }
    }

    fn drawStatusBar(
        self: *Output,
        editor_state: *zed.editor_state.EditorState,
    ) !void {
        try self.terminal.appendToBuffer("\x1b[7m");

        const filename = if (editor_state.filename.len > 0)
            editor_state.filename
        else
            "[No Name]";

        try self.terminal.appendToBuffer(filename);

        var col_index: usize = filename.len;
        while (col_index < self.terminal.size.cols) : (col_index += 1) {
            try self.terminal.appendToBuffer(" ");
        }

        try self.terminal.appendToBuffer("\x1b[m");
    }

    fn drawMessageBar(
        self: *Output,
        editor_state: *zed.editor_state.EditorState,
    ) !void {
        try self.terminal.appendToBuffer(zed.terminal.EscapeSequence.clear_line.toString());

        const current_time = std.time.timestamp();
        if (current_time - editor_state.message_time > 5) return;

        try self.terminal.appendToBuffer(editor_state.message);
    }
};
