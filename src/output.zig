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

    pub fn render(self: *Output, rows: *std.ArrayList([]const u8), editor_row_index: usize, editor_col_index: usize) !void {
        try self.terminal.appendEscapeToBuffer(.clear_entire_screen);
        try self.terminal.appendEscapeToBuffer(.move_cursor_to_origin);
        try self.drawRows(rows, editor_row_index, editor_col_index);
        try self.terminal.setCursorPosition(self.terminal.position);
    }

    pub fn refreshScreen(self: *Output) !void {
        try self.render();
        try self.terminal.flush();
    }

    pub fn clearScreen(self: *Output) !void {
        try self.terminal.appendEscapeToBuffer(.clear_entire_screen);
        try self.terminal.appendEscapeToBuffer(.move_cursor_to_origin);
        try self.terminal.flush();
    }

    fn drawRows(self: *Output, rows: *std.ArrayList([]const u8), editor_row_index: usize, editor_col_index: usize) !void {
        var row_index: usize = 0;
        while (row_index < self.terminal.size.rows) : (row_index += 1) {
            const editor_row = row_index + editor_row_index;
            if (editor_row >= rows.items.len) {
                try self.terminal.appendToBuffer("~");
            } else {
                const row = rows.items[editor_row];
                const end_col_index = @min(editor_col_index + self.terminal.size.cols, row.len);

                if (editor_col_index < row.len) {
                    try self.terminal.appendToBuffer(row[editor_col_index..end_col_index]);
                }
            }

            try self.terminal.appendToBuffer(zed.terminal.EscapeSequence.clear_line.toString());
            if (row_index < self.terminal.size.rows - 1) {
                try self.terminal.appendToBuffer("\r\n");
            }
        }
    }
};
