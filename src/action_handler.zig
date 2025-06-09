const std = @import("std");
const zed = @import("root.zig");
const movement = @import("commands/movement.zig");

pub const ActionHandler = struct {
    pub fn execute(
        _: *ActionHandler,
        editor: *zed.editor.Editor,
        action: zed.action.Action,
    ) !void {
        switch (action) {
            .moveCursorUp => try movement.moveVertically(editor, .up),
            .moveCursorDown => try movement.moveVertically(editor, .down),
            .moveCursorLeft => try movement.moveHorizontally(editor, .left),
            .moveCursorRight => try movement.moveHorizontally(editor, .right),
            .quit => try quit(editor),
        }
    }

    fn quit(editor: *zed.editor.Editor) !void {
        try editor.output.clearScreen();
        try editor.terminal.disableRawMode();
        std.posix.exit(0);
    }
};
