const std = @import("std");
const ab = @import("append_buffer.zig");

const TerminalError = error{
    InitError,
    EnableRawModeError,
    DisableRawModeError,
    ReadingError,
};

pub const TerminalSize = struct {
    rows: u16,
    cols: u16,
};

pub const EscapeSequence = enum {
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

pub const Terminal = struct {
    orig_termios: std.posix.termios,
    size: TerminalSize,
    append_buffer: *ab.AppendBuffer,

    pub fn init(append_buffer: *ab.AppendBuffer) TerminalError!Terminal {
        const termios = std.posix.tcgetattr(std.posix.STDIN_FILENO) catch {
            return TerminalError.InitError;
        };

        return .{
            .orig_termios = termios,
            .size = getTerminalSize(),
            .append_buffer = append_buffer,
        };
    }

    pub fn enableRawMode(self: *Terminal) TerminalError!void {
        var raw = self.orig_termios;

        raw.iflag.IXON = false;
        raw.iflag.ICRNL = false;
        raw.iflag.BRKINT = false;
        raw.iflag.INPCK = false;
        raw.iflag.ISTRIP = false;

        raw.oflag.OPOST = false;

        raw.cflag.CSIZE = .CS8;

        raw.lflag.ECHO = false;
        raw.lflag.ICANON = false;
        raw.lflag.ISIG = false;
        raw.lflag.IEXTEN = false;

        raw.cc[@intFromEnum(std.posix.V.MIN)] = 0;
        raw.cc[@intFromEnum(std.posix.V.TIME)] = 1;

        std.posix.tcsetattr(std.posix.STDIN_FILENO, std.posix.TCSA.FLUSH, raw) catch {
            return TerminalError.EnableRawModeError;
        };
    }

    pub fn disableRawMode(self: *Terminal) TerminalError!void {
        std.posix.tcsetattr(std.posix.STDIN_FILENO, std.posix.TCSA.FLUSH, self.orig_termios) catch {
            return TerminalError.DisableRawModeError;
        };
    }

    pub fn read(_: *Terminal, buffer: []u8) TerminalError!usize {
        return std.posix.read(std.posix.STDIN_FILENO, buffer) catch {
            return TerminalError.ReadingError;
        };
    }

    pub fn appendToBuffer(self: *Terminal, data: []const u8) !void {
        try self.append_buffer.append(data);
    }

    pub fn flush(self: *Terminal) !void {
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
};
