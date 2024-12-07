const std = @import("std");
const grid = @import("util/grid.zig");

var count_x: usize = 0;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const map = try grid.Grid.init(allocator, args[1]);
    defer map.uninit(allocator);

    const start_pos = map.search_first('^').?;
    var guard_x: isize = @intCast(start_pos.x);
    var guard_y: isize = @intCast(start_pos.y);
    var dir: isize = 0;
    try map.set(guard_x, guard_y, 'X');
    var loop_obstacles = std.AutoHashMap(grid.Grid.Pos, void).init(allocator);
    defer loop_obstacles.deinit();

    while(true) {
        var next_x = guard_x;
        var next_y = guard_y;

        switch (dir) {
        // up
            0 => next_y -= 1,
            // right
            1 => next_x += 1,
            // down
            2 => next_y += 1,
            // left
            3 => next_x -= 1,
            else => unreachable
        }

        const next_c = map.get(next_x, next_y);
        if (next_c == null) {
            // out of map
            break;
        }

        if (next_c.? == '#') {
            // obstacle
            dir = @mod(dir + 1, 4);
        } else {
            if (next_x != start_pos.x and next_y != start_pos.y) {
                if (is_loop(map, guard_x, guard_y, dir)) {
                    loop_obstacles.put(grid.Grid.Pos{.x = next_x, .y = next_y}, void);
                }
            }
            guard_x = next_x;
            guard_y = next_y;
            try map.set(guard_x, guard_y, 'X');
        }
    }

    map.for_each(count);
    std.debug.print("{d}\n", .{count_x});
}

fn count(_: usize, _: usize, c: u8) void {
    if (c == 'X') {
        count_x += 1;
    }
}

fn is_loop(map: grid.Grid, start_x: isize, start_y: isize, start_dir: isize) bool {
    var pos_x = start_x;
    var pos_y = start_y;
    var dir = start_dir;

    while(true) {
        switch (dir) {
        // up
            0 => pos_y -= 1,
            // right
            1 => pos_x += 1,
            // down
            2 => pos_y += 1,
            // left
            3 => pos_x -= 1,
            else => unreachable
        }
        if (pos_x == start_x and pos_y == start_y) {
            return true;
        }
        const c = map.get(pos_x, pos_y);
        if (c == null) {
            return false;
        }
        if (c.? == '#') {
            dir = @mod(dir+1, 4);
            if (dir == start_dir) {
                return false;
            }
        }
    }
}