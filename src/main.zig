const std = @import("std");
const zed = @import("zed");

const term = zed.terminal;
const config = zed.config;
const input = zed.input;
const output = zed.output;
const editor = zed.editor;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leak detected!");
    }

    const key_bindings = [_]config.KeyBinding{
        .{ .key = config.ctrlKey('c'), .action = config.Action.quit },
    };

    const editor_config = config.Config{
        .key_bindings = &key_bindings,
    };

    const terminal = try term.Terminal.init();
    const current_editor = try editor.Editor.init(allocator, &terminal, &editor_config);

    try current_editor.start();
    while (true) {
        try current_editor.handleInput();
    }
}
