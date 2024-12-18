const std = @import("std");

pub const Grid = struct {
    width: usize = 0,
    height: usize = 0,
    data: []u8 = &[_]u8{},

    pub fn init(allocator: std.mem.Allocator, filename: []const u8) !Grid {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();
        const data = try file.reader().readAllAlloc(allocator, 10000000);

        var width: usize = 0;
        for (data, 0..) |c, i| {
            if (c == '\n') {
                width = i;
                break;
            }
        }
        const height: usize = (data.len + 1) / (width+1);

        return Grid {.width = width, .height = height, .data = data };
    }

    pub fn appendRow(self: *Grid, allocator: std.mem.Allocator, line_without_break: []const u8) !void {
        const old_len = self.data.len;
        self.data = try allocator.realloc(self.data, old_len + line_without_break.len + 1);
        @memcpy(self.data[old_len..self.data.len-1], line_without_break);
        self.data[self.data.len-1] = '\n';
        self.height += 1;
        self.width = if (line_without_break.len > self.width) line_without_break.len else self.width;
    }

    pub fn uninit(self: Grid, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn copy(self: Grid, allocator: std.mem.Allocator) !Grid {
        const data_copy = try allocator.dupe(u8, self.data);
        return Grid{.width = self.width, .height = self.height, .data = data_copy};
    }

    pub fn mustSet(self: Grid, x: usize, y: usize, c: u8) void {
        if (x >= self.width or y >= self.height) {
            unreachable;
        }
        self.data[y * (self.width + 1) + x] = c;
    }

    pub fn get(self: Grid, x: isize, y: isize) ?u8 {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height){
            return null;
        }
        const uy: usize = @intCast(y);
        const ux: usize = @intCast(x);
        return self.data[uy * (self.width + 1) + ux];
    }

    pub fn mustGet(self: Grid, x: usize, y: usize) u8 {
        if (x >= self.width or y >= self.height) {
            unreachable;
        }
        return self.data[y * (self.width + 1) + x];
    }

    pub fn set(self: Grid, x: isize, y: isize, c: u8) !void {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height){
            return error.OutOfBounds;
        }
        const uy: usize = @intCast(y);
        const ux: usize = @intCast(x);
        self.data[uy * (self.width + 1) + ux] = c;
    }

    pub const GridError = error {
        OutOfBounds,
    };

    pub fn walk_all_directions(self: Grid, f: WalkFn) void {
        self.dir_scan_x(f, 0, self.width-1, 0, 0, 1);
        self.dir_scan_x(f, 0, self.width-1, self.height-1, 0, -1);

        self.dir_scan_y(f, 0, self.height-1, 0, 1, 0);
        self.dir_scan_y(f, 0, self.height-1, self.width-1, -1, 0);

        self.dir_scan_x(f, 0, self.width-1, 0, 1, 1);
        self.dir_scan_y(f, 1, self.height-1, 0, 1, 1);

        self.dir_scan_x(f, 0, self.width-1, 0, -1, 1);
        self.dir_scan_y(f, 1, self.height-1, self.width-1, -1, 1);

        self.dir_scan_x(f, 0, self.width-1, self.height-1, 1, -1);
        self.dir_scan_y(f, 0, self.height-2, 0, 1, -1);

        self.dir_scan_x(f, 0, self.width-1, self.height-1, -1, -1);
        self.dir_scan_y(f, 0, self.height-2, self.width-1, -1, -1);
    }

    pub fn for_each(self: Grid, f: CellFn) void {
        for (0..self.width) |x| {
            const ix: isize = @intCast(x);
            for (0..self.height) |y| {
                const iy: isize = @intCast(y);
                const c = self.get(ix, iy);
                if (c != null) {
                    f(x, y, c.?);
                }
            }
        }
    }

    pub fn search_first(self: Grid, search_c: u8) ?Pos {
        for (0..self.width) |x| {
            const ix: isize = @intCast(x);
            for (0..self.height) |y| {
                const iy: isize = @intCast(y);
                const c = self.get(ix, iy);
                if (c != null) {
                    if (search_c == c.?) {
                        return Pos{.x = x, .y = y};
                    }
                }
            }
        }
        return null;
    }

    pub const Pos = struct {
        x: usize,
        y: usize
    };

    pub const WalkFn = fn(state: u8, c: u8) u8;

    pub const CellFn = fn(x: usize, y: usize, c: u8) void;

    pub fn print(self: Grid) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const c = self.data[y * (self.width + 1) + x];
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }

    fn dir_scan_x(self: Grid, f: WalkFn, from_x: usize, to_x: usize, sy: usize, dx: isize, dy: isize) void {
        for (from_x..to_x+1) |sx| {
            self.walk(f,dx, dy, sx, sy);
        }
    }

    fn dir_scan_y(self: Grid, f: WalkFn, from_y: usize, to_y: usize, sx: usize, dx: isize, dy: isize) void {
        for (from_y..to_y+1) |sy| {
            self.walk(f, dx, dy, sx, sy);
        }
    }

    fn walk(self: Grid, f: WalkFn, dx: isize, dy: isize, sx: usize, sy: usize) void {
        var x: isize = @intCast(sx);
        var y: isize = @intCast(sy);
        var state: u8 = 0;
        var c = self.get(x, y);
        while (c != null) {
            state = f(state, c.?);
            x += dx;
            y += dy;
            c = self.get(x, y);
        }
    }
};