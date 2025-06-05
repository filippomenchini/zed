const std = @import("std");
const ab = @import("append_buffer.zig");

const TerminalError = error{
    InitError,
    EnableRawModeError,
    DisableRawModeError,
    ReadingError,
};

pub const Size = struct {
    rows: u16,
    cols: u16,
};

pub const CursorPosition = struct {
    x: u16,
    y: u16,
};

pub const CursorPositionOffset = struct {
    x: i16 = 0,
    y: i16 = 0,
};

pub const CursorDirection = enum {
    up,
    down,
    left,
    right,
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

    pub fn moveCursorTo(buf: []u8, x: u16, y: u16) ![]const u8 {
        return std.fmt.bufPrint(buf, "\x1b[{d};{d}H", .{ y, x });
    }
};

pub const Terminal = struct {
    orig_termios: std.posix.termios,
    size: Size,
    position: CursorPosition,
    append_buffer: *ab.AppendBuffer,

    pub fn init(append_buffer: *ab.AppendBuffer) TerminalError!Terminal {
        const termios = std.posix.tcgetattr(std.posix.STDIN_FILENO) catch {
            return TerminalError.InitError;
        };

        return .{
            .orig_termios = termios,
            .size = getTerminalSize(),
            .position = CursorPosition{
                .x = 1,
                .y = 1,
            },
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

    pub fn appendEscapeToBuffer(self: *Terminal, escape: EscapeSequence) !void {
        try self.appendToBuffer(escape.toString());
    }

    pub fn setCursorPosition(self: *Terminal, position: CursorPosition) !void {
        var buf: [32]u8 = undefined;
        const escape = try EscapeSequence.moveCursorTo(&buf, position.x, position.y);
        try self.appendToBuffer(escape);

        self.position = position;
    }

    pub fn moveCursorBy(self: *Terminal, offset: CursorPositionOffset) !void {
        const new_x = @as(i32, self.position.x) + offset.x;
        const new_y = @as(i32, self.position.y) + offset.y;

        const position = CursorPosition{
            .x = @max(1, @min(self.size.cols, @as(u16, @intCast(new_x)))),
            .y = @max(1, @min(self.size.rows, @as(u16, @intCast(new_y)))),
        };

        try self.setCursorPosition(position);
    }

    pub fn moveCursorByDirection(self: *Terminal, direction: CursorDirection, offset: u16) !void {
        const cursor_offset = switch (direction) {
            .up => CursorPositionOffset{
                .y = -@as(i16, @intCast(offset)),
            },
            .down => CursorPositionOffset{
                .y = @as(i16, @intCast(offset)),
            },
            .left => CursorPositionOffset{
                .x = -@as(i16, @intCast(offset)),
            },
            .right => CursorPositionOffset{
                .x = @as(i16, @intCast(offset)),
            },
        };

        try self.moveCursorBy(cursor_offset);
    }

    pub fn flush(self: *Terminal) !void {
        try self.append_buffer.flush();
    }

    fn getTerminalSize() Size {
        var buffer: std.posix.winsize = undefined;
        _ = std.posix.system.ioctl(
            std.posix.STDOUT_FILENO,
            std.posix.T.IOCGWINSZ,
            @intFromPtr(&buffer),
        );

        return Size{
            .rows = buffer.row,
            .cols = buffer.col,
        };
    }
};
