const std = @import("std");

pub const Args = struct {
    allocator: std.mem.Allocator,
    args: [][:0]u8,

    pub fn init(allocator: std.mem.Allocator) !Args {
        return .{
            .allocator = allocator,
            .args = try std.process.argsAlloc(allocator),
        };
    }

    pub fn deinit(self: *Args) void {
        std.process.argsFree(self.allocator, self.args);
    }

    pub fn getFilename(self: *Args) ?[]const u8 {
        return if (self.args.len >= 2) self.args[1] else null;
    }
};
