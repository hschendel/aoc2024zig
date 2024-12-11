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

    var initial_pebbles = std.ArrayList(u64).init(allocator);
    defer initial_pebbles.deinit();
    var lookup_table = std.AutoHashMap(Key, u64).init(allocator);
    defer lookup_table.deinit();

    while (try reader.readUntilDelimiterOrEof(number_buf[0..], ' ')) |number_str| {
        const value = try std.fmt.parseInt(u64, number_str, 10);
        try initial_pebbles.append(value);
    }

    var final_stones: u64 = 0;
    for(initial_pebbles.items) |initial_value| {
        final_stones += try simulate_blinks(initial_value, 75, &lookup_table);
    }

    std.debug.print("{d}\nlookup size: {d}\n", .{final_stones, lookup_table.count()});
}

fn simulate_blinks(initial_value: u64, blinks: u16, lookup: *std.AutoHashMap(Key, u64)) !u64 {
    if (blinks == 0) {
        return 1;
    }
    const key = Key{.initial_value = initial_value, .blinks = blinks};
    if (lookup.get(key)) |result| {
        return result;
    }

    if (initial_value == 0) {
        const result = try simulate_blinks(1, blinks - 1, lookup);
        try lookup.put(key, result);
        return result;
    }

    const digits = countDigits(initial_value);
    if (@mod(digits, 2) == 0) {
        const divisor = std.math.pow(u64,10, digits / 2);
        const left = initial_value / divisor;
        const right = @mod(initial_value, divisor);

        const sum_left = try simulate_blinks(left, blinks-1, lookup);
        const sum_right = try simulate_blinks(right, blinks-1, lookup);
        const result = sum_left + sum_right;
        try lookup.put(key, result);
        return result;
    }

    const result = try simulate_blinks(initial_value * 2024, blinks-1, lookup);
    try lookup.put(key, result);
    return result;
}

const Key = struct {
    initial_value: u64,
    blinks: u16
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