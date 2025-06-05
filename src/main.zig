const std = @import("std");
const zed = @import("zed");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const key_bindings = [_]zed.config.KeyBinding{
        .{ .key = zed.config.Config.ctrlKey('c'), .action = zed.action.Action.quit },
        .{ .key = 'k', .action = zed.action.Action.moveCursorUp },
        .{ .key = 'j', .action = zed.action.Action.moveCursorDown },
        .{ .key = 'h', .action = zed.action.Action.moveCursorLeft },
        .{ .key = 'l', .action = zed.action.Action.moveCursorRight },
    };

    var config = zed.config.Config{ .key_bindings = &key_bindings };
    var append_buffer = zed.append_buffer.AppendBuffer.init(allocator);
    var terminal = try zed.terminal.Terminal.init(&append_buffer);
    var output = zed.output.Output.init(&terminal);
    var input = zed.input.Input.init(&terminal);
    var editor = try zed.editor.Editor.init(
        &config,
        &terminal,
        &input,
        &output,
    );

    try editor.run();
}
