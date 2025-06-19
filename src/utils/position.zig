const zed = @import("../root.zig");

pub fn getCurrentFilePosition(
    terminal: *zed.Terminal,
    state: *zed.EditorState,
) struct { row: usize, col: usize } {
    return .{
        .row = (terminal.position.y - 1) + state.row_index,
        .col = (terminal.position.x - 1) + state.col_index,
    };
}
