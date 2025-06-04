const std = @import("std");
const ab = @import("append_buffer.zig");

pub const OutputError = error{
    SendEscapeSequenceError,
};

const TerminalSizeError = error{
    ReadError,
    ParseError,
    InvalidResponse,
    Timeout,
};

pub const TerminalSize = struct {
    rows: u16,
    cols: u16,
};

const EscapeSequence = enum {
    clear_entire_screen,
    move_cursor_to_origin,
    clear_line,
    pub fn toString(self: EscapeSequence) []const u8 {
        return switch (self) {
            .clear_entire_screen => "\x1b[2J",
            .move_cursor_to_origin => "\x1b[H",
            .clear_line => "\x1b[K",
        };
    }
};

pub const Output = struct {
    allocator: std.mem.Allocator,
    append_buffer: ab.AppendBuffer,
    terminal_size: TerminalSize,

    pub fn init(allocator: std.mem.Allocator) Output {
        return .{
            .allocator = allocator,
            .append_buffer = ab.AppendBuffer.init(allocator),
            .terminal_size = getTerminalSize(),
        };
    }

    pub fn deinit(self: *Output) void {
        self.append_buffer.deinit();
    }

    pub fn refreshScreen(self: *Output) !void {
        try self.drawRows();
        try self.append_buffer.append(EscapeSequence.move_cursor_to_origin.toString());
        try self.append_buffer.flush();
    }

    pub fn clearScreen(self: *Output) !void {
        try self.append_buffer.append(EscapeSequence.clear_entire_screen.toString());
        try self.append_buffer.append(EscapeSequence.move_cursor_to_origin.toString());
        try self.append_buffer.flush();
    }

    fn getTerminalSize() TerminalSize {
        var buffer: std.posix.winsize = undefined;
        _ = std.posix.system.ioctl(
            std.posix.STDOUT_FILENO,
            std.posix.T.IOCGWINSZ,
            @intFromPtr(&buffer),
        );

        return TerminalSize{
            .rows = buffer.row,
            .cols = buffer.col,
        };
    }

    fn drawRows(self: *Output) !void {
        var row_index: i16 = 0;
        while (row_index < self.terminal_size.rows) : (row_index += 1) {
            if (row_index == 0) {
                const welcome_msg = "Zed - a simple Zig text EDitor\r\n";
                try self.append_buffer.append(welcome_msg);
                continue;
            }

            try self.append_buffer.append("~");

            try self.append_buffer.append(EscapeSequence.clear_line.toString());
            if (row_index < self.terminal_size.rows - 1) {
                try self.append_buffer.append("\r\n");
            }
        }
    }
};
