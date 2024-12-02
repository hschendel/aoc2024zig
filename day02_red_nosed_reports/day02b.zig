const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const file_name = args[1];
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var line_buf = [_]u8{0} ** 100;
    var safe_count: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        var levels = std.ArrayList(i32).init(allocator);
        defer levels.deinit();
        while (it.next()) |v| {
            if (v.len == 0) {
                continue;
            }
            const level = try std.fmt.parseInt(i32, v, 10);
            try levels.append(level);
        }
        if (!is_report_safe(levels.items, null)) {
            if (!is_report_safe_without_one(levels.items)) {
                continue;
            }
        }
        safe_count += 1;
    }

    std.debug.print("{d}\n", .{safe_count});
}

fn is_report_safe_without_one(levels: []i32) bool {
    for (levels, 0..) |_, i| {
        if (is_report_safe(levels, i)) {
            return true;
        }
    }
    return false;
}

fn is_report_safe(levels: []i32, skip_i: ?usize) bool {
    var previous: ?i32 = null;
    var direction: i32 = 0;
    for (levels, 0..) |level, i| {
        if (skip_i != null and i == skip_i.?) {
            continue;
        }
        if (previous != null) {
            const diff = level - previous.?;
            if (direction == 0) {
                direction = std.math.sign(diff);
            }
            const abs_diff = if (diff < 0) -diff else diff;
            if (direction != std.math.sign(diff) or abs_diff < 1 or abs_diff > 3) {
                return false;
            }
        }
        previous = level;
    }
    return true;
}
