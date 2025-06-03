const std = @import("std");
const posix = std.posix;

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
    pub fn toString(self: EscapeSequence) []const u8 {
        return switch (self) {
            .clear_entire_screen => "\x1b[2J",
            .move_cursor_to_origin => "\x1b[H",
        };
    }
};

fn drawRows(terminal_size: TerminalSize) !void {
    var row_index: i16 = 0;
    while (row_index < terminal_size.rows) : (row_index += 1) {
        _ = try posix.write(posix.STDOUT_FILENO, "~\r\n");
    }
}

fn sendEscapeSequence(escape_sequence: EscapeSequence) OutputError!void {
    _ = posix.write(posix.STDOUT_FILENO, escape_sequence.toString()) catch {
        return OutputError.SendEscapeSequenceError;
    };
}

pub fn clearScreen() !void {
    try sendEscapeSequence(.clear_entire_screen);
    try sendEscapeSequence(.move_cursor_to_origin);
}

pub fn refreshScreen(terminal_size: TerminalSize) !void {
    try clearScreen();
    try drawRows(terminal_size);
    try sendEscapeSequence(.move_cursor_to_origin);
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
