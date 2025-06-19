const std = @import("std");
const zed = @import("../root.zig");
const position = @import("../utils/position.zig");

pub fn insertCharacter(context: zed.ActionHandlerContext, char: u8) !void {
    const pos = position.getCurrentFilePosition(context.terminal, context.state);

    if (context.state.rows.items.len == 0) {
        const new_row = try context.state.allocator.alloc(u8, 1);
        new_row[0] = char;
        try context.state.rows.append(new_row);
        try context.terminal.moveCursorByDirection(.right, 1);
        return;
    }

    if (pos.row >= context.state.rows.items.len) {
        while (context.state.rows.items.len <= pos.row) {
            const empty_row = try context.state.allocator.dupe(u8, "");
            try context.state.rows.append(empty_row);
        }
    }

    const current_row = context.state.rows.items[pos.row];
    const insert_pos = @min(pos.col, current_row.len);

    var new_row = try context.state.allocator.alloc(u8, current_row.len + 1);

    @memcpy(new_row[0..insert_pos], current_row[0..insert_pos]);

    new_row[insert_pos] = char;

    @memcpy(new_row[insert_pos + 1 ..], current_row[insert_pos..]);

    context.state.allocator.free(current_row);
    context.state.rows.items[pos.row] = new_row;

    try context.terminal.moveCursorByDirection(.right, 1);
}

pub fn insertNewline(context: zed.ActionHandlerContext) !void {
    const pos = position.getCurrentFilePosition(context.terminal, context.state);

    if (pos.row >= context.state.rows.items.len) {
        const new_row = try context.state.allocator.dupe(u8, "");
        try context.state.rows.append(new_row);

        try context.terminal.moveCursorByDirection(.down, 1);
        context.terminal.position.x = 1;
        return;
    }

    const current_row = context.state.rows.items[pos.row];
    const split_pos = @min(pos.col, current_row.len);

    const first_part = try context.state.allocator.dupe(u8, current_row[0..split_pos]);

    const second_part = try context.state.allocator.dupe(u8, current_row[split_pos..]);

    context.state.allocator.free(current_row);
    context.state.rows.items[pos.row] = first_part;
    try context.state.rows.insert(pos.row + 1, second_part);

    try context.terminal.moveCursorByDirection(.down, 1);
    context.terminal.position.x = 1;
}

pub fn insertBackspace(context: zed.ActionHandlerContext) !void {
    const pos = position.getCurrentFilePosition(context.terminal, context.state);

    if (pos.row >= context.state.rows.items.len) return;
    if (pos.col == 0 and pos.row == 0) return;

    const current_row = context.state.rows.items[pos.row];

    if (pos.col == 0) {
        if (pos.row > 0) {
            const prev_row = context.state.rows.items[pos.row - 1];
            const merged = try context.state.allocator.alloc(u8, prev_row.len + current_row.len);

            @memcpy(merged[0..prev_row.len], prev_row);
            @memcpy(merged[prev_row.len..], current_row);

            context.state.allocator.free(prev_row);
            context.state.allocator.free(current_row);
            context.state.rows.items[pos.row - 1] = merged;
            _ = context.state.rows.orderedRemove(pos.row);

            try context.terminal.moveCursorByDirection(.up, 1);
            context.terminal.position.x = @intCast(prev_row.len + 1);
        }
    } else {
        const new_row = try context.state.allocator.alloc(u8, current_row.len - 1);

        @memcpy(new_row[0 .. pos.col - 1], current_row[0 .. pos.col - 1]);
        @memcpy(new_row[pos.col - 1 ..], current_row[pos.col..]);

        context.state.allocator.free(current_row);
        context.state.rows.items[pos.row] = new_row;

        try context.terminal.moveCursorByDirection(.left, 1);
    }
}
