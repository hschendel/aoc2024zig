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
    var steps: u32 = 0;

    while(true) {
        var next_x = guard_x;
        var next_y = guard_y;
        std.debug.print("({d},{d})\n", .{guard_x, guard_y});

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
            if (!(next_x == start_pos.x and next_y == start_pos.y)) {
                if (loop_obstacles.get(grid.Grid.Pos{.x = @intCast(next_x), .y = @intCast(next_y)}) == null) {
                    const old_c = next_c.?;
                    try map.set(next_x, next_y, '#');
                    std.debug.print("  try obstacle at ({d},{d}) with dir {d}..", .{next_x, next_y, @mod(dir+1,4)});
                    if (try is_loop(allocator,map, guard_x, guard_y, @mod(dir+1,4))) {
                        std.debug.print("LOOP!\n", .{});
                        try loop_obstacles.put(grid.Grid.Pos{.x = @intCast(next_x), .y = @intCast(next_y)}, {});
                    } else {
                        std.debug.print("-\n", .{});
                    }
                    try map.set(next_x, next_y, old_c);
                }
            }
            steps += 1;
            guard_x = next_x;
            guard_y = next_y;
            try map.set(guard_x, guard_y, 'X');
        }
    }

    std.debug.print("steps: {d}\n", .{steps});
    std.debug.print("{d}\n", .{loop_obstacles.count()});
}

fn is_loop(allocator: std.mem.Allocator, map: grid.Grid, start_x: isize, start_y: isize, start_dir: isize) !bool {
    var pos_x = start_x;
    var pos_y = start_y;
    var dir = start_dir;
    var visited = std.AutoHashMap(MoveKey, void).init(allocator);
    defer visited.deinit();
    var steps: u32 = 0;

    while(true) {
        if(visited.get(MoveKey{.x = pos_x, .y = pos_y, .dir = dir}) != null) {
            std.debug.print("  revisited {d},{d} with dir {d} after {d} steps\n", .{pos_x, pos_y, dir, steps});
            // stuck in loop
            return true;
        }
        try visited.put(MoveKey{.x = pos_x, .y = pos_y, .dir = dir}, {});
        var next_x = pos_x;
        var next_y = pos_y;
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

        const c = map.get(next_x, next_y);
        if (c == null) {
            return false;
        }
        if (c.? == '#') {
            dir = @mod(dir+1, 4);
            continue;
        }

        pos_x = next_x;
        pos_y = next_y;
        steps += 1;

    }
}

const MoveKey = struct {
    x: isize,
    y: isize,
    dir: isize,
};