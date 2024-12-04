const std = @import("std");
const grid = @import("util/grid.zig");
const eql = std.mem.eql;

var xmas_count: usize = 0;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const plan = try grid.Grid.init(allocator, args[1]);
    defer plan.uninit(allocator);

    plan.walk_all_directions(step);
    std.debug.print("{d}\n", .{xmas_count});
}

fn step(state: u8, c: u8) u8 {
    switch (state) {
        0 => return if (c == 'X') 1 else 0,
        1 => return if (c == 'M') 2 else if (c == 'X') 1 else 0,
        2 => return if (c == 'A') 3 else if (c == 'X') 1 else 0,
        3 => {
            if (c == 'S') {
                xmas_count += 1;
                return 0;
            }
            return if (c == 'X') 1 else 0;
        },
        else => unreachable
    }
}
