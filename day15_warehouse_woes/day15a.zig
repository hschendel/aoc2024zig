const std = @import("std");
const grid = @import("util/grid.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var line_buf = [_]u8{0} ** 1024;

    var map = WarehouseMap{};
    defer map.deinit(allocator);
    var command_list = std.ArrayList(u8).init(allocator);
    defer command_list.deinit();

    var reading_map = true;

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        if (reading_map) {
            if (line.len > 0) {
                try map.appendRow(allocator, line);
            } else {
                reading_map = false;
            }
        } else {
            try command_list.appendSlice(line);
        }
    }

    for (command_list.items) |c| {
        map.moveRobot(c);
    }

    const sum = map.gpsSum();
    std.debug.print("{d}\n", .{sum});
}

const WarehouseMap = struct {
    map: grid.Grid = grid.Grid{},
    rx: usize = 0,
    ry: usize = 0,

    fn deinit(self: *WarehouseMap, allocator: std.mem.Allocator) void {
        self.map.uninit(allocator);
    }

    fn appendRow(self: *WarehouseMap, allocator: std.mem.Allocator, line: []u8) !void {
        for(line, 0..) |c, x| {
            if (c == '@') {
                self.ry = self.map.height;
                self.rx = x;
                break;
            }
        }
        try self.map.appendRow(allocator, line);
    }

    fn moveRobot(self: *WarehouseMap, move: u8) void {
        const dir_x: isize = switch (move) {
            '<' => -1,
            '>' => 1,
            else => 0
        };
        const dir_y: isize = switch (move) {
            '^' => -1,
            'v' => 1,
            else => 0
        };

        if (!self.can_move(dir_x, dir_y)) {
            return;
        }

        var carry: u8 = '.';
        var x = self.rx;
        var y = self.ry;
        self.rx = @intCast(@as(isize, @intCast(self.rx)) + dir_x);
        self.ry = @intCast(@as(isize, @intCast(self.ry)) + dir_y);

        while (true) {
            const new_carry = self.map.mustGet(x, y);
            self.map.mustSet(x, y, carry);
            if (new_carry == '.') {
                break;
            }
            carry = new_carry;
            x = @intCast(@as(isize, @intCast(x)) + dir_x);
            y = @intCast(@as(isize, @intCast(y)) + dir_y);
        }
    }

    fn can_move(self: WarehouseMap, dir_x: isize, dir_y: isize) bool {
        var x: isize = @intCast(self.rx);
        var y: isize = @intCast(self.ry);

        while (true) {
            x += dir_x;
            y += dir_y;
            if(self.map.get(x, y)) |c| {
                switch (c) {
                    '#' => return false,
                    '.' => return true,
                    else => {},
                }
            } else {
                return false;
            }
        }
    }

    fn gpsSum(self: WarehouseMap) usize {
        var sum: usize = 0;

        for (0..self.map.height) |y| {
            for (0..self.map.width) |x| {
                const c = self.map.mustGet(x, y);
                if (c != 'O') {
                    continue;
                }
                sum += y * 100 + x;
            }
        }

        return sum;
    }
};