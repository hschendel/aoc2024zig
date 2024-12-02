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

    report_loop: while (try reader.readUntilDelimiterOrEof(line_buf[0..], '\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        var direction: i32 = 0;
        var previous: ?i32 = null;
        while (it.next()) |v| {
            if (v.len == 0) {
                continue;
            }
            const level = try std.fmt.parseInt(i32, v, 10);
            if (previous != null) {
                const diff = level - previous.?;
                if (direction == 0) {
                    direction = std.math.sign(diff);
                } else {
                    if (std.math.sign(diff) != direction) {
                        // unsafe because of change in direction
                        continue :report_loop;
                    }
                }
                const abs_diff = if (diff < 0) -diff else diff;
                if (abs_diff < 1 or abs_diff > 3) {
                    // unsafe because difference is too high
                    continue :report_loop;
                }
            }
            previous = level;
        }
        safe_count += 1;
    }

    std.debug.print("{d}\n", .{safe_count});
}
