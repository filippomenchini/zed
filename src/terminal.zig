const std = @import("std");

const TerminalError = error{
    InitError,
    EnableRawModeError,
    DisableRawModeError,
    ReadingError,
};

pub const Terminal = struct {
    orig_termios: std.posix.termios,

    pub fn init() TerminalError!Terminal {
        const termios = std.posix.tcgetattr(std.posix.STDIN_FILENO) catch {
            return TerminalError.InitError;
        };

        return .{
            .orig_termios = termios,
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
};
