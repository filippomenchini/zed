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

    pub fn render(self: *Output, cursor_position: zed.terminal.CursorPosition) !void {
        try self.terminal.appendEscapeToBuffer(.clear_entire_screen);
        try self.terminal.appendEscapeToBuffer(.move_cursor_to_origin);
        try self.drawRows();
        try self.terminal.setCursorPosition(cursor_position);
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

    fn drawRows(self: *Output) !void {
        var row_index: i16 = 0;
        while (row_index < self.terminal.size.rows) : (row_index += 1) {
            try self.terminal.appendToBuffer("~");

            try self.terminal.appendToBuffer(zed.terminal.EscapeSequence.clear_line.toString());
            if (row_index < self.terminal.size.rows - 1) {
                try self.terminal.appendToBuffer("\r\n");
            }
        }
    }
};
