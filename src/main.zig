const std = @import("std");
const zed = @import("zed");

const ascii = std.ascii;
const term = zed.terminal;

pub fn main() !void {
    const terminal = try term.Terminal.init();

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {
        @panic("PANIC! Cannot disable raw mode!");
    };

    while (true) {
        var c: [1]u8 = .{0};
        _ = try terminal.read(&c);
        if (ascii.isControl(c[0])) {
            std.debug.print("{d}\r\n", .{c});
        } else {
            std.debug.print("{d} ('{c}')\r\n", .{ c, c });
        }

        if (c[0] == 'q') break;
    }
}
