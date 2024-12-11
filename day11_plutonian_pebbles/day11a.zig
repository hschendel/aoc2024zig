const std = @import("std");

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
    var number_buf = [_]u8{0} ** 100;
    var first_stone: ?*Stone = null;
    defer if(first_stone) |stone| {stone.deinit(allocator); };
    var last_stone: ?*Stone = null;

    while (try reader.readUntilDelimiterOrEof(number_buf[0..], ' ')) |number_str| {
        const value = try std.fmt.parseInt(u64, number_str, 10);
        const stone = try allocator.create(Stone);
        stone.value = value;
        stone.next = null;
        if (last_stone == null) {
            first_stone = stone;
            last_stone = stone;
        }
        last_stone.?.next = stone;
        last_stone = stone;
    }

    for(0..25) |_| {
        try first_stone.?.blink(allocator);
    }

    std.debug.print("{d}\n", .{first_stone.?.count()});
}

const Stone = struct {
    value: u64,
    next: ?*Stone,

    pub fn print(self: *Stone) void {
        if (self.next == null) {
            std.debug.print("{d}\n", .{self.value});
        } else {
            std.debug.print("{d} ", .{self.value});
            self.next.?.print();
        }
    }

    pub fn deinit(self: *Stone, allocator: std.mem.Allocator) void {
        if (self.next) |next_stone| {
            next_stone.deinit(allocator);
        }
        allocator.destroy(self);
    }

    pub fn blink(self: *Stone, allocator: std.mem.Allocator) !void {
        if (self.next) |next_stone| {
            try next_stone.blink(allocator);
        }

        if (self.value == 0) {
            self.value = 1;
            return;
        }

        const digits = countDigits(self.value);
        if(@mod(digits, 2) == 0) {
            const divisor = std.math.pow(u64,10, digits / 2);
            const left = self.value / divisor;
            const right = @mod(self.value, divisor);

            const tmp: ?*Stone = self.next;
            self.value = left;
            self.next = try allocator.create(Stone);
            self.next.?.value = right;
            self.next.?.next = tmp;
            return;
        }

        self.value *= 2024;
    }

    pub fn count(self: *Stone) u64 {
        return self.count_rec(0);
    }

    fn count_rec(self: *Stone, sum: u64) u64 {
        if (self.next) |next_stone| {
            return next_stone.count_rec(sum + 1);
        } else {
            return sum+1;
        }
    }
};

fn countDigits(n: u64) u64 {
    if (n == 0) {
        return 1;
    }

    var digits: u64 = 0;
    var nn = n;

    while (nn > 0) {
        nn = nn / 10;
        digits += 1;
    }

    return digits;
}