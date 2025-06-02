const std = @import("std");
const posix = std.posix;
const ascii = std.ascii;

var orig_termios: posix.termios = undefined;

pub fn disableRawMode() !void {
    try posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, orig_termios);
}

pub fn enableRawMode() !void {
    orig_termios = try posix.tcgetattr(posix.STDIN_FILENO);

    var raw = orig_termios;

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

    try posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.FLUSH, raw);
}

pub fn main() !void {
    try enableRawMode();
    defer disableRawMode() catch {
        @panic("PANIC! Cannot disable raw mode!");
    };

    while (true) {
        var c: [1]u8 = .{0};
        _ = try posix.read(posix.STDIN_FILENO, &c);
        if (ascii.isControl(c[0])) {
            std.debug.print("{d}\r\n", .{c});
        } else {
            std.debug.print("{d} ('{c}')\r\n", .{ c, c });
        }

        if (c[0] == 'q') break;
    }
}
