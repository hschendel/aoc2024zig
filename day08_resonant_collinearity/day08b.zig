const std = @import("std");
const grid = @import("util/grid.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const map = try grid.Grid.init(allocator, args[1]);
    defer map.uninit(allocator);

    var antennae_by_frequency = std.AutoHashMap(u8, std.ArrayList(grid.Grid.Pos)).init(allocator);
    defer antennae_by_frequency.deinit();

    for (0..map.width) |x| {
        for (0..map.height) |y| {
            const c = map.mustGet(x, y);
            if (!isAntenna(c)) {
                continue;
            }
            if (!antennae_by_frequency.contains(c)) {
                try antennae_by_frequency.put(c, std.ArrayList(grid.Grid.Pos).init(allocator));
            }
            var pos_list = antennae_by_frequency.get(c).?;
            try pos_list.append(grid.Grid.Pos{.x = x, .y = y});
            try antennae_by_frequency.put(c, pos_list);
        }
    }

    var antinodes = std.AutoHashMap(grid.Grid.Pos, void).init(allocator);
    defer antinodes.deinit();

    var antennae_it = antennae_by_frequency.iterator();
    while (antennae_it.next()) |entry| {
        for (entry.value_ptr.*.items, 0..) |pos1, i| {
            for (entry.value_ptr.*.items[i+1..]) |pos2| {
                try putAntinodes(@constCast(&map), pos1, pos2, @constCast(&antinodes));
                try putAntinodes(@constCast(&map), pos2, pos1, @constCast(&antinodes));
            }
        }
        entry.value_ptr.*.deinit();
    }

    //map.print();

    std.debug.print("{d}\n", .{antinodes.count()});
}

fn putAntinodes(map: *grid.Grid, a: grid.Grid.Pos, b: grid.Grid.Pos, antinodes: *std.AutoHashMap(grid.Grid.Pos, void)) !void {
    const ax: isize = @intCast(a.x);
    const bx: isize = @intCast(b.x);
    const ay: isize = @intCast(a.y);
    const by: isize = @intCast(b.y);
    const dx = bx - ax;
    const dy = by - ay;

    var nx = ax + dx;
    var ny = ay + dy;
    while(nx >= 0 and ny >= 0 and nx < map.width and ny < map.height) {
        try antinodes.put(grid.Grid.Pos{.x = @intCast(nx), .y = @intCast(ny)}, {});
        map.mustSet(@intCast(nx), @intCast(ny), '#');
        nx += dx;
        ny += dy;
    }
}

fn isAntenna(c: u8) bool {
    return switch(c) {
        '0'...'9', 'A'...'Z', 'a'...'z' => true,
        else => false
    };
}