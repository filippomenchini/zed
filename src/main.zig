const zed = @import("zed");

const term = zed.terminal;
const config = zed.config;
const input = zed.input;
const output = zed.output;
const editor = zed.editor;

pub fn main() !void {
    const key_bindings = [_]config.KeyBinding{
        .{ .key = config.ctrlKey('c'), .action = config.Action.quit },
    };

    const editor_config = config.Config{
        .key_bindings = &key_bindings,
    };

    const terminal = try term.Terminal.init();
    const current_editor = try editor.Editor.init(&terminal, &editor_config);

    try current_editor.start();
    while (true) {
        try current_editor.handleInput();
    }
}
