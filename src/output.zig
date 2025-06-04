const std = @import("std");
const posix = std.posix;
const mem = std.mem;

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

pub const AppendBuffer = struct {
    buffer: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator) AppendBuffer {
        return .{
            .buffer = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *AppendBuffer) void {
        self.buffer.deinit();
    }

    pub fn append(self: *AppendBuffer, data: []const u8) !void {
        try self.buffer.appendSlice(data);
    }

    pub fn appendEscape(self: *AppendBuffer, seq: EscapeSequence) !void {
        try self.append(seq.toString());
    }

    pub fn flush(self: *AppendBuffer) !void {
        _ = try posix.write(posix.STDOUT_FILENO, self.buffer.items);
        self.buffer.clearRetainingCapacity();
    }
};

const EscapeSequence = enum {
    clear_entire_screen,
    move_cursor_to_origin,
    pub fn toString(self: EscapeSequence) []const u8 {
        return switch (self) {
            .clear_entire_screen => "\x1b[2J",
            .move_cursor_to_origin => "\x1b[H",
        };
    }
};

fn drawRows(
    terminal_size: TerminalSize,
    append_buffer: *AppendBuffer,
) !void {
    var row_index: i16 = 0;
    while (row_index < terminal_size.rows) : (row_index += 1) {
        try append_buffer.append("~");

        if (row_index < terminal_size.rows - 1) {
            try append_buffer.append("\r\n");
        }
    }
}

fn sendEscapeSequence(escape_sequence: EscapeSequence) OutputError!void {
    _ = posix.write(posix.STDOUT_FILENO, escape_sequence.toString()) catch {
        return OutputError.SendEscapeSequenceError;
    };
}

pub fn refreshScreen(
    allocator: mem.Allocator,
    terminal_size: TerminalSize,
) !void {
    var append_buffer = AppendBuffer.init(allocator);
    try append_buffer.appendEscape(.clear_entire_screen);
    try drawRows(terminal_size, &append_buffer);
    try append_buffer.appendEscape(.move_cursor_to_origin);
    try append_buffer.flush();
}

pub fn getTerminalSize() TerminalSize {
    var buffer: posix.winsize = undefined;
    _ = posix.system.ioctl(
        posix.STDOUT_FILENO,
        posix.T.IOCGWINSZ,
        @intFromPtr(&buffer),
    );

    return TerminalSize{
        .rows = buffer.row,
        .cols = buffer.col,
    };
}
