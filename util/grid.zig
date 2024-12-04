const std = @import("std");

pub const Grid = struct {
    width: usize,
    height: usize,
    data: []u8,

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

    pub fn uninit(self: Grid, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn get(self: Grid, x: isize, y: isize) ?u8 {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height){
            return null;
        }
        const uy: usize = @intCast(y);
        const ux: usize = @intCast(x);
        return self.data[uy * (self.width + 1) + ux];
    }

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
            for (0..self.height) |y| {
                const c = self.get(x, y);
                if (c != null) {
                    f(x, y, c);
                }
            }
        }
    }

    pub const WalkFn = fn(state: u8, c: u8) u8;

    pub const CellFn = fn(x: usize, y: usize, c: u8) void;

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