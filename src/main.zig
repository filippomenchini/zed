const std = @import("std");
const zed = @import("zed");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const key_bindings = [_]zed.KeyBinding{
        .{
            .key = zed.Config.ctrlKey('c'),
            .mode = .normal,
            .action = zed.Action.quit,
        },
        .{
            .key = 'k',
            .mode = .normal,
            .action = zed.Action.moveCursorUp,
        },
        .{
            .key = 'j',
            .mode = .normal,
            .action = zed.Action.moveCursorDown,
        },
        .{
            .key = 'h',
            .mode = .normal,
            .action = zed.Action.moveCursorLeft,
        },
        .{
            .key = 'l',
            .mode = .normal,
            .action = zed.Action.moveCursorRight,
        },
    };

    var config = zed.Config{ .key_bindings = &key_bindings };
    var append_buffer = zed.AppendBuffer.init(allocator);
    var terminal = try zed.Terminal.init(&append_buffer);
    var output = zed.Output.init(&terminal);
    var input = zed.Input.init(&terminal);
    var editor_state = zed.EditorState.init(allocator, "");
    var args = try zed.Args.init(allocator);
    var action_handler = zed.ActionHandler{};
    var editor = try zed.Editor.init(
        &config,
        &terminal,
        &input,
        &output,
        &editor_state,
        &args,
        &action_handler,
    );
    defer editor.deinit();

    try editor.run();
}
