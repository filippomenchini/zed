const zed = @import("zed");

const term = zed.terminal;
const config = zed.config;
const input = zed.input;
const output = zed.output;

pub fn main() !void {
    const key_bindings = [_]config.KeyBinding{
        .{ .key = config.ctrlKey('c'), .action = config.Action.quit },
    };

    const editor_config = config.Config{
        .key_bindings = &key_bindings,
    };

    const terminal = try term.Terminal.init();

    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {
        @panic("PANIC! Cannot disable raw mode!");
    };

    try output.clearScreen();

    while (true) {
        try input.processKeypress(&terminal, &editor_config);
    }
}
