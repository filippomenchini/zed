const std = @import("std");
const posix = std.posix;

const TerminalError = error{
    InitError,
    EnableRowModeError,
    DisableRowModeError,
    ReadingError,
};

pub const Terminal = struct {
    orig_termios: posix.termios,

    pub fn init() TerminalError!Terminal {
        const termios = posix.tcgetattr(posix.STDIN_FILENO) catch {
            return TerminalError.InitError;
        };

        return .{
            .orig_termios = termios,
        };
    }

    pub fn enableRawMode(self: *const Terminal) TerminalError!void {
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

        raw.cc[@intFromEnum(posix.V.MIN)] = 0;
        raw.cc[@intFromEnum(posix.V.TIME)] = 1;

        posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, raw) catch {
            return TerminalError.EnableRowModeError;
        };
    }

    pub fn disableRawMode(self: *const Terminal) TerminalError!void {
        posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, self.orig_termios) catch {
            return TerminalError.DisableRowModeError;
        };
    }

    pub fn read(_: *const Terminal, buffer: []u8) TerminalError!usize {
        return posix.read(posix.STDIN_FILENO, buffer) catch {
            return TerminalError.ReadingError;
        };
    }
};
