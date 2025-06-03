const std = @import("std");
const zed = @import("zed");

const ascii = std.ascii;
const term = zed.terminal;
const config = zed.config;

pub fn main() !void {
    const key_bindings = [_]config.KeyBinding{
        .{ .key = config.ctrlKey('q'), .action = config.Action.quit },
    };

    const editor_config = config.Config{
        .key_bindings = &key_bindings,
    };

    const terminal = try term.Terminal.init();

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {
        @panic("PANIC! Cannot disable raw mode!");
    };

    while (true) {
        var c: [1]u8 = .{0};
        _ = try terminal.read(&c);

        if (editor_config.findAction(c[0])) |action| {
            switch (action) {
                .quit => break,
            }
        }

        if (ascii.isControl(c[0])) {
            std.debug.print("{d}\r\n", .{c});
        } else {
            std.debug.print("{d} ('{c}')\r\n", .{ c[0], c[0] });
        }
    }
}
