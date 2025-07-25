const zed = @import("../root.zig");
const utils = @import("../utils/position.zig");

pub fn moveHorizontally(
    context: zed.action_handler.ActionHandlerContext,
    direction: enum { left, right },
) !void {
    const pos = getCurrentFilePosition(context);
    if (pos.row >= context.state.rows.items.len) return;

    const current_row = context.state.rows.items[pos.row];
    switch (direction) {
        .left => {
            if (pos.col <= 0) return;
            if (context.terminal.position.x <= 1) {
                context.state.col_index -= 1;
            } else {
                try context.terminal.moveCursorByDirection(.left, 1);
            }
        },
        .right => {
            if (pos.col >= current_row.len) return;
            if (context.terminal.position.x >= context.terminal.size.cols) {
                context.state.col_index += 1;
            } else {
                try context.terminal.moveCursorByDirection(.right, 1);
            }
        },
    }

    context.state.preferred_col_index = null;
}

pub fn moveVertically(
    self: zed.action_handler.ActionHandlerContext,
    direction: enum { up, down },
) !void {
    const pos = getCurrentFilePosition(self);

    if (self.state.rows.items.len == 0) return;
    if (direction == .up and pos.row <= 0) return;
    if (direction == .down and pos.row >= self.state.rows.items.len - 1) return;

    if (self.state.preferred_col_index == null) {
        self.state.preferred_col_index = pos.col;
    }

    switch (direction) {
        .up => {
            if (self.terminal.position.y <= 1) {
                self.state.row_index -= 1;
            } else {
                try self.terminal.moveCursorByDirection(.up, 1);
            }
        },
        .down => {
            if (self.terminal.position.y >= self.terminal.size.rows) {
                self.state.row_index += 1;
            } else {
                try self.terminal.moveCursorByDirection(.down, 1);
            }
        },
    }

    const target_row_index = if (direction == .up) pos.row - 1 else pos.row + 1;
    adjustCursorToPreferredColumn(self, target_row_index);
}

fn getCurrentFilePosition(
    self: zed.action_handler.ActionHandlerContext,
) struct { row: usize, col: usize } {
    const position = utils.getCurrentFilePosition(self.terminal, self.state);
    return .{
        .row = position.row,
        .col = position.col,
    };
}

fn adjustCursorForShorterRow(
    self: zed.action_handler.ActionHandlerContext,
    target_row_index: usize,
    current_file_col: usize,
) void {
    const target_row = self.state.rows.items[target_row_index];

    if (current_file_col > target_row.len) {
        const new_col_screen: u16 = @intCast(@min(target_row.len, self.terminal.size.cols - 1));
        const new_col_offset: u16 = @intCast(if (target_row.len > self.terminal.size.cols - 1)
            target_row.len - self.terminal.size.cols + 1
        else
            0);

        self.state.col_index = new_col_offset;
        self.terminal.position.x = new_col_screen - new_col_offset + 1;
    }
}

fn adjustCursorToPreferredColumn(
    self: zed.action_handler.ActionHandlerContext,
    target_row_index: usize,
) void {
    const target_row = self.state.rows.items[target_row_index];
    const preferred_col = self.state.preferred_col_index.?;

    const target_col = @min(preferred_col, target_row.len);

    if (target_col >= self.terminal.size.cols) {
        self.state.col_index = target_col - self.terminal.size.cols + 1;
        self.terminal.position.x = self.terminal.size.cols;
    } else {
        self.state.col_index = 0;
        self.terminal.position.x = @intCast(target_col + 1);
    }
}
