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

    var map = WarehouseMap.init(allocator);
    defer map.deinit();
    var command_list = std.ArrayList(u8).init(allocator);
    defer command_list.deinit();

    var reading_map = true;

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        if (reading_map) {
            if (line.len > 0) {
                try map.appendRow(line);
            } else {
                reading_map = false;
            }
        } else {
            try command_list.appendSlice(line);
        }
    }

    for (command_list.items) |c| {
        try map.moveRobot(c);
    }

    const sum = map.gpsSum();
    std.debug.print("{d}\n", .{sum});
}

const WarehouseMap = struct {
    map: grid.Grid = grid.Grid{},
    rx: usize = 0,
    ry: usize = 0,
    moved: std.AutoHashMap(IPos, void),

    fn init(allocator: std.mem.Allocator) WarehouseMap {
        return WarehouseMap {
            .moved = std.AutoHashMap(IPos, void).init(allocator)
        };
    }

    fn read_from_file(allocator: std.mem.Allocator, filename: []const u8) !WarehouseMap {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();
        var buf_reader = std.io.bufferedReader(file.reader());
        const reader = buf_reader.reader();
        return try read(allocator, reader);
    }

    fn read(allocator: std.mem.Allocator, reader: anytype) !WarehouseMap {
        var map = WarehouseMap.init(allocator);
        var line_buf = [_]u8{0} ** 1024;
        while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
            if (line.len == 0) {
                return map;
            }
            try map.appendRow(line);
        }
        return map;
    }

    fn deinit(self: *WarehouseMap) void {
        self.map.uninit(self.moved.allocator);
        self.moved.deinit();
    }

    fn appendRow(self: *WarehouseMap, line: []u8) !void {
        var expanded_line = try self.moved.allocator.alloc(u8, line.len * 2);
        defer self.moved.allocator.free(expanded_line);
        for(line, 0..) |c, x| {
            const x2 = x * 2;
            const expanded = switch (c) {
                '#' => "##",
                'O' => "[]",
                '.' => "..",
                '@' => "@.",
                else => unreachable
            };
            expanded_line[x2] = expanded[0];
            expanded_line[x2+1] = expanded[1];
            if (c == '@') {
                self.ry = self.map.height;
                self.rx = x2;
            }
        }
        try self.map.appendRow(self.moved.allocator, expanded_line);
    }

    fn moveRobot(self: *WarehouseMap, c: u8) !void {
        const dir_x: isize = switch (c) {
            '<' => -1,
            '>' => 1,
            else => 0
        };
        const dir_y: isize = switch (c) {
            '^' => -1,
            'v' => 1,
            else => 0
        };

        const x: isize = @intCast(self.rx);
        const y: isize = @intCast(self.ry);
        if (!self.canMove(dir_x, dir_y, x, y)) {
            return;
        }

        defer self.moved.clearRetainingCapacity();

        try self.move(dir_x, dir_y, x, y);
        self.rx = @intCast(x + dir_x);
        self.ry = @intCast(y + dir_y);
    }

    fn move(self: *WarehouseMap, dir_x: isize, dir_y: isize, x: isize, y: isize) !void {
        if (self.moved.get(IPos{.x = x, .y = y}) != null) {
            return;
        }
        const c = self.map.get(x, y);
        if (c == null) {
            return;
        }
        switch (c.?) {
            '.' => {
                try self.moved.put(IPos{.x = x, .y = y}, {});
            },
            '@' => {
                try self.moved.put(IPos{.x = x, .y = y}, {});
                try self.move(dir_x, dir_y, x + dir_x, y + dir_y);
                try self.map.set(x + dir_x, y + dir_y, '@');
                try self.map.set(x, y, '.');
            },
            '#' => unreachable,
            '[' => {
                try self.moved.put(IPos{.x = x, .y = y}, {});
                try self.moved.put(IPos{.x = x + 1, .y = y}, {});
                if (dir_x > 0) {
                    try self.move(dir_x, dir_y, x + 1 + dir_x, y + dir_y);
                    try self.move(dir_x, dir_y, x + dir_x, y + dir_y);
                } else {
                    try self.move(dir_x, dir_y, x + dir_x, y + dir_y);
                    try self.move(dir_x, dir_y, x + 1 + dir_x, y + dir_y);
                }
                try self.map.set(x, y, '.');
                try self.map.set(x + 1, y, '.');
                try self.map.set(x + dir_x, y + dir_y, '[');
                try self.map.set(x + 1 + dir_x, y + dir_y, ']');
            },
            ']' => {
                try self.moved.put(IPos{.x = x, .y = y}, {});
                try self.moved.put(IPos{.x = x-1, .y = y}, {});
                if (dir_x < 0) {
                    try self.move(dir_x, dir_y, x - 1 + dir_x, y + dir_y);
                    try self.move(dir_x, dir_y, x + dir_x, y + dir_y);
                } else {
                    try self.move(dir_x, dir_y, x + dir_x, y + dir_y);
                    try self.move(dir_x, dir_y, x - 1 + dir_x, y + dir_y);
                }
                try self.map.set(x - 1, y, '.');
                try self.map.set(x, y, '.');
                try self.map.set(x - 1 + dir_x, y + dir_y, '[');
                try self.map.set(x + dir_x, y + dir_y, ']');
            },
            else => unreachable
        }
    }

    fn canMove(self: WarehouseMap, dir_x: isize, dir_y: isize, x: isize, y: isize) bool {
        const c = self.map.get(x, y);
        if (c == null) {
            return false;
        }
        switch (c.?) {
            '.' => return true,
            '@' => return self.canMove(dir_x, dir_y, x + dir_x, y + dir_y),
            '#' => return false,
            '[' => {
                if (dir_x < 0) {
                    return self.canMove(dir_x, dir_y, x + dir_x, y + dir_y);
                } else if (dir_x > 0) {
                    return self.canMove(dir_x, dir_y, x + 1 + dir_x, y + dir_y);
                } else {
                    return self.canMove(dir_x, dir_y, x + dir_x, y + dir_y)
                        and self.canMove(dir_x, dir_y, x + 1 + dir_x, y + dir_y);
                }
            },
            ']' => {
                if (dir_x < 0) {
                    return self.canMove(dir_x, dir_y, x - 1 + dir_x, y + dir_y);
                } else if (dir_x > 0) {
                    return self.canMove(dir_x, dir_y, x + dir_x, y + dir_y);
                } else {
                    return self.canMove(dir_x, dir_y, x + dir_x, y + dir_y)
                        and self.canMove(dir_x, dir_y, x - 1 + dir_x, y + dir_y);
                }
            },
            else => unreachable
        }
    }

    fn gpsSum(self: WarehouseMap) usize {
        var sum: usize = 0;

        for (0..self.map.height) |y| {
            for (0..self.map.width) |x| {
                const c = self.map.mustGet(x, y);
                if (c != '[') {
                    continue;
                }
                sum += y * 100 + x;
            }
        }

        return sum;
    }

    const IPos = struct {
        x: isize,
        y: isize
    };
};

const TestCase = struct {
    map: WarehouseMap,
    moves: std.ArrayList(u8),
    expected: grid.Grid,

    fn init(allocator: std.mem.Allocator, filename: []const u8) !TestCase {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();
        var buf_reader = std.io.bufferedReader(file.reader());
        const reader = buf_reader.reader();
        var line_buf = [_]u8{0} ** 1024;

        var map = WarehouseMap.init(allocator);
        while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
            if (line.len == 0) {
                break;
            }
            if (std.mem.indexOf(u8, line, "@")) |rx| {
                map.rx = rx;
                map.ry = map.map.height;
            }
            try map.map.appendRow(allocator, line);
        }

        var moves = std.ArrayList(u8).init(allocator);
        while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
            if (line.len == 0) {
                break;
            }
            try moves.appendSlice(line);
        }

        var expected = grid.Grid{};
        while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
            try expected.appendRow(allocator, line);
        }

        if (map.map.width != expected.width or map.map.height != expected.height) {
            return error.InvalidTestCase;
        }

        return TestCase {
            .map = map,
            .moves = moves,
            .expected = expected,
        };
    }

    fn deinit(self: *TestCase) void {
        self.map.deinit();
        self.expected.uninit(self.moves.allocator);
        self.moves.deinit();
    }

    fn run(self: *TestCase) !void {
        std.debug.print("initial map:\n", .{});
        self.map.map.print();
        for (self.moves.items) |c| {
            try self.map.moveRobot(c);
            std.debug.print("after move {c}:\n", .{c});
            self.map.map.print();
        }
        for (0..self.map.map.width) |x| {
            for (0..self.map.map.height) |y| {
                if (self.expected.mustGet(x,y) != self.map.map.mustGet(x, y)) {
                    std.debug.print("expected end state:\n", .{});
                    self.expected.print();
                    std.debug.print("  different at {d},{d}\n", .{x,y});
                    return error.TestUnexpectedResult;
                }
            }
        }
    }
    
    const TestCaseError = error {
        InvalidTestCase
    };
};

const expect = std.testing.expect;

test "WarehouseMap file test cases" {
    var buf = [_]u8{0} ** std.fs.max_path_bytes;
    var dirname = try std.fs.realpath(".", &buf);
    buf[dirname.len] = std.fs.path.sep;
    @memcpy(buf[dirname.len+1..dirname.len+6], "tests");
    dirname = buf[0..dirname.len+6];
    const dir_prefix_len = dirname.len+1;
    buf[dirname.len] = std.fs.path.sep;
    var dir = try std.fs.openDirAbsolute(dirname, std.fs.Dir.OpenDirOptions{.access_sub_paths = false, .iterate = true});
    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != std.fs.File.Kind.file) {
            continue;
        }
        @memcpy(buf[dir_prefix_len..dir_prefix_len+entry.name.len], entry.name);
        const filename = buf[0..dir_prefix_len+entry.name.len];
        var testCase = TestCase.init(std.testing.allocator, filename) catch |err| {
            std.debug.print("{any}: {s}\n", .{err, filename});
            continue;
        };
        defer testCase.deinit();
        testCase.run() catch |err| {
            std.debug.print("{s} failed: {any}\n", .{filename, err});
            return err;
        };
    }
}

test "WarehouseMap.canMove" {
    var map = try WarehouseMap.read_from_file(std.testing.allocator, "test.txt");
    defer map.deinit();
    try expect(map.canMove(-1, 0, 8, 4));
    map.map.mustSet(4, 4, '@');
    try expect(!map.canMove(0, 1, 4, 4));
    map.map.mustSet(4, 4, '.');
    map.map.mustSet(15, 8, '@');
    try expect(map.canMove(0, -1, 15, 8));
    map.map.mustSet(15, 8, '.');
}

test "WarehouseMap.move" {
    var map = try WarehouseMap.read_from_file(std.testing.allocator, "test.txt");
    defer map.deinit();
    try map.moveRobot('<');
    try expect(map.map.mustGet(8, 3) == '.');
    try expect(map.map.mustGet(8, 4) == '.');
    try expect(map.map.mustGet(9, 4) == '.');
    try expect(map.map.mustGet(8, 5) == '.');
    try expect(map.map.mustGet(7, 4) == '@');
    try expect(map.map.mustGet(6, 4) == ']');
    try expect(map.map.mustGet(5, 4) == '[');
}